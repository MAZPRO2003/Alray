import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:alray_app/providers/budget_provider.dart';
import 'package:alray_app/models/payable.dart';

class AddPayableDialog extends StatefulWidget {
  final String projectId;

  const AddPayableDialog({super.key, required this.projectId});

  @override
  State<AddPayableDialog> createState() => _AddPayableDialogState();
}

class _AddPayableDialogState extends State<AddPayableDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _vendorController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

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

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() => _isLoading = true);

    try {
      final payable = Payable(
        id: '',
        projectId: widget.projectId,
        vendorName: _vendorController.text.trim(),
        totalAmount: amount,
        description: _descController.text.trim(),
        dueDate: _dueDate,
      );

      await Provider.of<BudgetProvider>(
        context,
        listen: false,
      ).addPayable(payable);
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
                  'Add New Payable',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _vendorController,
                  decoration: const InputDecoration(
                    labelText: 'Vendor Name',
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

                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Total Amount (₹)',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0
                      ? 'Invalid amount'
                      : null,
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
                          : const Text('Save'),
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
