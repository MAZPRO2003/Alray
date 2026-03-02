import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:alray_app/providers/budget_provider.dart';
import 'package:alray_app/models/expense.dart';

class AddExpenseDialog extends StatefulWidget {
  final String projectId;

  const AddExpenseDialog({super.key, required this.projectId});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _materialTypeController = TextEditingController();
  final _workerNameController = TextEditingController();
  final _vendorNameController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  ExpenseCategory _selectedCategory = ExpenseCategory.contractor;
  bool _isLoading = false;

  void _presentDatePicker() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, now.month, now.day);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: firstDate,
      lastDate: now,
    );
    setState(() {
      if (pickedDate != null) _selectedDate = pickedDate;
    });
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    final enteredDesc = _descController.text.trim();
    final enteredAmount = double.tryParse(_amountController.text);
    final enteredCustomCategory = _customCategoryController.text.trim();
    final enteredQuantity = double.tryParse(_quantityController.text);
    final enteredUnit = _unitController.text.trim();
    final enteredMaterialType = _materialTypeController.text.trim();
    final enteredWorkerName = _workerNameController.text.trim();
    final enteredVendorName = _vendorNameController.text.trim();

    if (enteredAmount == null || enteredAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final newExpense = Expense(
        projectId: widget.projectId,
        description: enteredDesc,
        amount: enteredAmount,
        date: _selectedDate,
        category: _selectedCategory,
        customCategoryName: _selectedCategory == ExpenseCategory.other
            ? enteredCustomCategory
            : null,
        quantity: _selectedCategory == ExpenseCategory.material
            ? enteredQuantity
            : null,
        unit: _selectedCategory == ExpenseCategory.material
            ? enteredUnit
            : null,
        materialType: _selectedCategory == ExpenseCategory.material
            ? enteredMaterialType
            : null,
        workerName: _selectedCategory == ExpenseCategory.contractor
            ? enteredWorkerName
            : null,
        vendorName: _selectedCategory == ExpenseCategory.material
            ? enteredVendorName
            : null,
        attachmentUrl: null,
      );

      await Provider.of<BudgetProvider>(
        context,
        listen: false,
      ).addExpense(widget.projectId, newExpense);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add expense: $e')));
      }
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    _customCategoryController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _materialTypeController.dispose();
    _workerNameController.dispose();
    _vendorNameController.dispose();
    super.dispose();
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
                  'Add New Expense',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // 1. Category Selection
                DropdownButtonFormField<ExpenseCategory>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: ExpenseCategory.values.map((category) {
                    String label = category.name.toUpperCase();
                    if (category == ExpenseCategory.contractor) {
                      label = 'WORKERS';
                    }
                    if (category == ExpenseCategory.material) {
                      label = 'MATERIAL';
                    }
                    if (category == ExpenseCategory.other) label = 'CUSTOM';

                    return DropdownMenuItem(
                      value: category,
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // 2. Specialized Details
                if (_selectedCategory == ExpenseCategory.material) ...[
                  TextFormField(
                    controller: _materialTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Material Name',
                      hintText: 'e.g. Cement, Steel, Sand',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        (_selectedCategory == ExpenseCategory.material &&
                            (v == null || v.trim().isEmpty))
                        ? 'Material name is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _vendorNameController,
                    decoration: const InputDecoration(
                      labelText: 'Vendor Name',
                      hintText: 'Where was this bought?',
                      prefixIcon: Icon(Icons.store_outlined),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 20),
                ],
                if (_selectedCategory == ExpenseCategory.contractor) ...[
                  TextFormField(
                    controller: _workerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Contractor / Worker Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        (_selectedCategory == ExpenseCategory.contractor &&
                            (v == null || v.trim().isEmpty))
                        ? 'Worker name is required'
                        : null,
                  ),
                  const SizedBox(height: 20),
                ],
                if (_selectedCategory == ExpenseCategory.other) ...[
                  TextFormField(
                    controller: _customCategoryController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'Enter Name',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        (_selectedCategory == ExpenseCategory.other &&
                            (v == null || v.trim().isEmpty))
                        ? 'Category name is required'
                        : null,
                  ),
                  const SizedBox(height: 20),
                ],

                // 3. Amount & Measurement
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹)',
                    hintText: 'e.g. 50000',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Amount is required';
                    final parsed = double.tryParse(v);
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid positive number';
                    }
                    return null;
                  },
                ),
                if (_selectedCategory == ExpenseCategory.material) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _quantityController,
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                            prefixIcon: Icon(Icons.numbers),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (v) =>
                              (_selectedCategory == ExpenseCategory.material &&
                                  (v == null ||
                                      double.tryParse(v) == null ||
                                      double.parse(v) <= 0))
                              ? 'Enter qty'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _unitController,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            hintText: 'Bags, Nos, etc.',
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) =>
                              (_selectedCategory == ExpenseCategory.material &&
                                  (v == null || v.trim().isEmpty))
                              ? 'Enter unit'
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),

                // 4. Supplementary Info
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Description is required'
                      : null,
                ),
                const SizedBox(height: 20),
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
                      children: [
                        Icon(
                          Icons.calendar_month,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Transaction Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                DateFormat(
                                  'EEEE, d MMMM yyyy',
                                ).format(_selectedDate),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.edit, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitData,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
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
