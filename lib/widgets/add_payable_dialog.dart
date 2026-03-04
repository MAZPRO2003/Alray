import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:alray_app/providers/budget_provider.dart';
import 'package:alray_app/models/payable.dart';
import 'package:alray_app/models/construction_entry.dart';

class AddPayableDialog extends StatefulWidget {
  final String projectId;
  final Payable? payable;

  const AddPayableDialog({super.key, required this.projectId, this.payable});

  @override
  State<AddPayableDialog> createState() => _AddPayableDialogState();
}

class _AddPayableDialogState extends State<AddPayableDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _vendorController = TextEditingController();
  final _qtyController = TextEditingController(text: '1.0');
  final _rateController = TextEditingController();
  final _customMaterialController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  String _selectedCategory = EntryCategory.cementM;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.payable != null) {
      _vendorController.text = widget.payable!.vendorName;
      _descController.text = widget.payable!.description;
      _qtyController.text = widget.payable!.quantity.toString();
      _rateController.text = widget.payable!.rate.toString();
      _dueDate = widget.payable!.dueDate;
      _selectedCategory = widget.payable!.categoryId;

      // Handle custom material name from description if needed
      if (_selectedCategory == EntryCategory.otherMiscMaterials &&
          widget.payable!.description.contains(': ')) {
        final split = widget.payable!.description.split(': ');
        _customMaterialController.text = split[0];
        _descController.text = split.skip(1).join(': ');
      }
    }
  }

  void _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (pickedDate != null) {
      setState(() {
        _dueDate = pickedDate;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final rate = double.tryParse(_rateController.text);
    final qty = double.tryParse(_qtyController.text);
    if (rate == null || rate <= 0) return;
    if (qty == null || qty <= 0) return;

    final amount = rate * qty;

    setState(() => _isLoading = true);

    try {
      final payable = Payable(
        id: widget.payable?.id ?? '',
        projectId: widget.projectId,
        vendorName: _vendorController.text.trim(),
        totalAmount: amount,
        rate: rate,
        quantity: qty,
        description:
            _selectedCategory == EntryCategory.otherMiscMaterials &&
                _customMaterialController.text.trim().isNotEmpty
            ? '${_customMaterialController.text.trim()}: ${_descController.text.trim()}'
            : _descController.text.trim(),
        categoryId: _selectedCategory,
        dueDate: _dueDate,
      );

      if (widget.payable != null) {
        await Provider.of<BudgetProvider>(
          context,
          listen: false,
        ).updatePayable(payable);
      } else {
        await Provider.of<BudgetProvider>(
          context,
          listen: false,
        ).addPayable(payable);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.payable != null ? 'Edit Bill' : 'Add New Bill',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Category Selection
                _GroupedCategoryPicker(
                  selectedCategory: _selectedCategory,
                  onChanged: (val) => setState(() => _selectedCategory = val),
                ),

                if (_selectedCategory == EntryCategory.otherMiscMaterials) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _customMaterialController,
                    decoration: const InputDecoration(
                      labelText: 'Material Name',
                      hintText: 'e.g., Glass Blocks, Temporary Toilet',
                      prefixIcon: Icon(Icons.inventory_2),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        (_selectedCategory ==
                                EntryCategory.otherMiscMaterials &&
                            (v == null || v.trim().isEmpty))
                        ? 'Material name is required'
                        : null,
                  ),
                ],

                const SizedBox(height: 24),

                TextFormField(
                  controller: _vendorController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.store_outlined),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _qtyController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          prefixIcon: Icon(Icons.numbers),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Req';
                          if (double.tryParse(v) == null) return 'Inv';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _rateController,
                        decoration: const InputDecoration(
                          labelText: 'Rate (₹)',
                          prefixIcon: Icon(Icons.currency_rupee),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Calculated Amount Display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Builder(
                        builder: (context) {
                          final rValue =
                              double.tryParse(_rateController.text) ?? 0.0;
                          final qValue =
                              double.tryParse(_qtyController.text) ?? 0.0;
                          final total = rValue * qValue;
                          return Text(
                            '₹${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                              fontSize: 16,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                InkWell(
                  onTap: _presentDatePicker,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text('Due: ${DateFormat.yMMMd().format(_dueDate)}'),
                          ],
                        ),
                        const Icon(Icons.edit, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : Text(widget.payable != null ? 'Update' : 'Save'),
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

  @override
  void dispose() {
    _descController.dispose();
    _vendorController.dispose();
    _qtyController.dispose();
    _rateController.dispose();
    _customMaterialController.dispose();
    super.dispose();
  }
}

const _categoryGroups = {
  'Material': [
    EntryCategory.cementM,
    EntryCategory.sandM,
    EntryCategory.aggregateM,
    EntryCategory.bricksM,
    EntryCategory.steelM,
    EntryCategory.rmcM,
    EntryCategory.electricalM,
    EntryCategory.plumbingM,
    EntryCategory.carpentryM,
    EntryCategory.grillM,
    EntryCategory.tileM,
    EntryCategory.paintM,
    EntryCategory.otherMiscMaterials,
  ],
  'Labour': [
    EntryCategory.masonL,
    EntryCategory.electricalL,
    EntryCategory.plumbingL,
    EntryCategory.carpentryL,
    EntryCategory.tileL,
    EntryCategory.paintL,
    EntryCategory.miscL,
  ],
  'Specialized': [
    EntryCategory.planApproval,
    EntryCategory.additionalWorks,
    EntryCategory.miscExp,
  ],
};

const _categoryLabels = {
  EntryCategory.cementM: 'Cement',
  EntryCategory.sandM: 'Sand',
  EntryCategory.aggregateM: 'Aggregate / Jelly',
  EntryCategory.bricksM: 'Bricks',
  EntryCategory.steelM: 'Steel / TMT',
  EntryCategory.rmcM: 'RMC (Ready Mix)',
  EntryCategory.electricalM: 'Electrical (Material)',
  EntryCategory.plumbingM: 'Plumbing (Material)',
  EntryCategory.carpentryM: 'Carpentry / Wood',
  EntryCategory.grillM: 'Grill / MS Work',
  EntryCategory.tileM: 'Tiles',
  EntryCategory.paintM: 'Paint (Material)',
  EntryCategory.otherMiscMaterials: 'Other Materials',
  EntryCategory.masonL: 'Mason / Labour',
  EntryCategory.electricalL: 'Electrician (Labour)',
  EntryCategory.plumbingL: 'Plumber (Labour)',
  EntryCategory.carpentryL: 'Carpenter (Labour)',
  EntryCategory.tileL: 'Tile Fixer (Labour)',
  EntryCategory.paintL: 'Painter (Labour)',
  EntryCategory.miscL: 'Misc Labour',
  EntryCategory.planApproval: 'Plan Approval / Permit',
  EntryCategory.additionalWorks: 'Additional Works',
  EntryCategory.miscExp: 'Miscellaneous',
};

class _GroupedCategoryPicker extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onChanged;

  const _GroupedCategoryPicker({
    required this.selectedCategory,
    required this.onChanged,
  });

  String get _displayLabel =>
      _categoryLabels[selectedCategory] ?? selectedCategory;

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, controller) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Select Category',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    children: _categoryGroups.entries.expand((group) {
                      return [
                        // Group Header
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: _groupColor(group.key),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                group.key.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: _groupColor(group.key),
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Sub-items
                        ...group.value.map((cat) {
                          final isSelected = cat == selectedCategory;
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            tileColor: isSelected
                                ? _groupColor(group.key).withValues(alpha: 0.12)
                                : null,
                            leading: Icon(
                              _groupIcon(group.key),
                              size: 18,
                              color: isSelected
                                  ? _groupColor(group.key)
                                  : Colors.grey,
                            ),
                            title: Text(
                              _categoryLabels[cat] ?? cat,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? _groupColor(group.key)
                                    : null,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: _groupColor(group.key),
                                    size: 18,
                                  )
                                : null,
                            onTap: () {
                              onChanged(cat);
                              Navigator.pop(ctx);
                            },
                          );
                        }),
                      ];
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _groupColor(String group) {
    switch (group) {
      case 'Material':
        return Colors.green.shade700;
      case 'Labour':
        return Colors.orange.shade700;
      default:
        return Colors.indigo;
    }
  }

  IconData _groupIcon(String group) {
    switch (group) {
      case 'Material':
        return Icons.inventory_2_outlined;
      case 'Labour':
        return Icons.construction;
      default:
        return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Detect the group of selected category
    String? groupName;
    for (final e in _categoryGroups.entries) {
      if (e.value.contains(selectedCategory)) {
        groupName = e.key;
        break;
      }
    }
    final color = groupName != null
        ? _groupColor(groupName)
        : Colors.grey.shade700;

    return InkWell(
      onTap: () => _showPicker(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.category_outlined, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (groupName != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            groupName,
                            style: TextStyle(
                              fontSize: 10,
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        _displayLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }
}
