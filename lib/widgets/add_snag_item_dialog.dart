import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alray_app/providers/budget_provider.dart';
import 'package:alray_app/models/snag_item.dart';
import 'package:uuid/uuid.dart';

class AddSnagItemDialog extends StatefulWidget {
  final String projectId;
  final SnagItem? existingSnag; // If editing

  const AddSnagItemDialog({
    super.key,
    required this.projectId,
    this.existingSnag,
  });

  @override
  State<AddSnagItemDialog> createState() => _AddSnagItemDialogState();
}

class _AddSnagItemDialogState extends State<AddSnagItemDialog> {
  final _formKey = GlobalKey<FormState>();
  String _description = '';
  SnagPriority _priority = SnagPriority.medium;
  SnagStatus _status = SnagStatus.pending;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingSnag != null) {
      _description = widget.existingSnag!.description;
      _priority = widget.existingSnag!.priority;
      _status = widget.existingSnag!.status;
    }
  }

  void _submitData() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<BudgetProvider>(context, listen: false);

      if (widget.existingSnag == null) {
        // Adding new snag
        final newSnag = SnagItem(
          id: const Uuid().v4(),
          projectId: widget.projectId,
          description: _description,
          status: _status,
          priority: _priority,
          createdAt: DateTime.now(),
        );

        await provider.addSnagItem(newSnag);
      } else {
        // Updating existing snag
        final isResolved = _status == SnagStatus.resolved;
        final wasResolved = widget.existingSnag!.status == SnagStatus.resolved;

        DateTime? resolvedAt = widget.existingSnag!.resolvedAt;
        if (isResolved && !wasResolved) {
          resolvedAt = DateTime.now();
        } else if (!isResolved && wasResolved) {
          resolvedAt = null;
        }

        final updatedSnag = SnagItem(
          id: widget.existingSnag!.id,
          projectId: widget.projectId,
          description: _description,
          status: _status,
          priority: _priority,
          createdAt: widget.existingSnag!.createdAt,
          resolvedAt: resolvedAt,
        );

        await provider.updateSnagItem(updatedSnag);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving snag item: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine colors based on priority
    Color priorityColor(SnagPriority p) {
      switch (p) {
        case SnagPriority.low:
          return Colors.green;
        case SnagPriority.medium:
          return Colors.orange;
        case SnagPriority.high:
          return Colors.red;
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.existingSnag == null
                      ? 'Add Snag / Defect'
                      : 'Edit Snag / Defect',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  initialValue: _description,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Paint peeling on north wall',
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description.';
                    }
                    return null;
                  },
                  onSaved: (value) => _description = value!.trim(),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Priority',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: SnagPriority.values.map((priority) {
                    final isSelected = _priority == priority;
                    final color = priorityColor(priority);
                    return ChoiceChip(
                      label: Text(
                        priority.toString().split('.').last.toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : color,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: color,
                      backgroundColor: color.withValues(alpha: 0.1),
                      onSelected: (selected) {
                        if (selected) setState(() => _priority = priority);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Status',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<SnagStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  items: SnagStatus.values.map((status) {
                    String label = status.toString().split('.').last;
                    if (status == SnagStatus.inProgress) label = 'In Progress';
                    return DropdownMenuItem(
                      value: status,
                      child: Text(label.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _status = value);
                  },
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Snag'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
