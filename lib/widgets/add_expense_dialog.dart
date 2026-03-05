import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:alray_app/providers/budget_provider.dart';
import 'package:alray_app/models/construction_entry.dart';
import 'package:alray_app/utils/currency_utils.dart';

class AddExpenseDialog extends StatefulWidget {
  final String projectId;
  final ConstructionEntry? entry;

  const AddExpenseDialog({super.key, required this.projectId, this.entry});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _rateController = TextEditingController();
  final _qtyController = TextEditingController(text: '1.0');
  final _chequeDetailsController = TextEditingController();
  final _customMaterialController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = EntryCategory.cementM;
  PaymentMode _selectedPaymentMethod = PaymentMode.cash;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _descController.text = widget.entry!.description;
      _rateController.text = widget.entry!.rate.toString();
      _qtyController.text = widget.entry!.quantity.toString();
      _selectedDate = widget.entry!.date;
      _selectedCategory = widget.entry!.categoryId;
      _selectedPaymentMethod = widget.entry!.paymentMode;
      _chequeDetailsController.text = widget.entry!.referenceData ?? '';

      // Handle custom material name from description if needed
      if (_selectedCategory == EntryCategory.otherMiscMaterials &&
          widget.entry!.description.contains(': ')) {
        final split = widget.entry!.description.split(': ');
        _customMaterialController.text = split[0];
        _descController.text = split.skip(1).join(': ');
      }
    }
  }

  void _presentDatePicker() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 5, now.month, now.day);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstDate,
      lastDate: now,
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    final enteredDesc = _descController.text.trim();
    final customMaterial = _customMaterialController.text.trim();

    String finalDesc = enteredDesc;
    if (_selectedCategory == EntryCategory.otherMiscMaterials &&
        customMaterial.isNotEmpty) {
      finalDesc = '$customMaterial: $enteredDesc';
    }
    final enteredRate = double.tryParse(_rateController.text);
    final enteredQty = double.tryParse(_qtyController.text);

    if (enteredRate == null || enteredRate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid rate.')),
      );
      return;
    }

    if (enteredQty == null || enteredQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity.')),
      );
      return;
    }

    if (_selectedPaymentMethod == PaymentMode.cheque &&
        _chequeDetailsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter cheque details.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final entry = ConstructionEntry(
        id: widget.entry?.id,
        projectId: widget.projectId,
        description: finalDesc,
        transactionType: TransactionType.expense,
        categoryId: _selectedCategory,
        rate: enteredRate,
        quantity: enteredQty,
        date: _selectedDate,
        paymentMode: _selectedPaymentMethod,
        referenceData: _selectedPaymentMethod == PaymentMode.cheque
            ? _chequeDetailsController.text.trim()
            : null,
      );

      if (widget.entry != null) {
        await Provider.of<BudgetProvider>(
          context,
          listen: false,
        ).updateEntry(entry);
      } else {
        await Provider.of<BudgetProvider>(
          context,
          listen: false,
        ).addEntry(entry);
      }
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

  double get _calculatedAmount {
    final rate = double.tryParse(_rateController.text) ?? 0.0;
    final qty = double.tryParse(_qtyController.text) ?? 0.0;
    return rate * qty;
  }

  @override
  void dispose() {
    _descController.dispose();
    _rateController.dispose();
    _qtyController.dispose();
    _chequeDetailsController.dispose();
    _customMaterialController.dispose();
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
                  widget.entry != null ? 'Edit Expense' : 'Add New Expense',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // 1. Category Selection — Grouped Picker
                _GroupedCategoryPicker(
                  selectedCategory: _selectedCategory,
                  onChanged: (val) => setState(() => _selectedCategory = val),
                ),

                if (_selectedCategory == EntryCategory.otherMiscMaterials) ...[
                  const SizedBox(height: 20),
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

                const SizedBox(height: 20),

                // 2. Quantity and Rate
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
                      Text(
                        CurrencyUtils.formatInr(_calculatedAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Payment Method
                DropdownButtonFormField<PaymentMode>(
                  value: _selectedPaymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    prefixIcon: Icon(Icons.payment),
                  ),
                  items: PaymentMode.values.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(method.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPaymentMethod = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Cheque Details (Conditionally visible)
                if (_selectedPaymentMethod == PaymentMode.cheque) ...[
                  TextFormField(
                    controller: _chequeDetailsController,
                    decoration: const InputDecoration(
                      labelText: 'Cheque Details',
                      hintText: 'e.g. Chq No. 123456, HDFC Bank',
                      prefixIcon: Icon(Icons.account_balance),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Required for cheque'
                        : null,
                  ),
                  const SizedBox(height: 20),
                ],

                // 4. Description
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
                  maxLines: 2,
                ),
                const SizedBox(height: 20),

                // 5. Date Picker
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

                // Actions
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
                          : Text(
                              widget.entry != null
                                  ? 'Update Expense'
                                  : 'Save Expense',
                            ),
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
                  'Select Expense Category',
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
      default:
        return Colors.indigo;
    }
  }

  IconData _groupIcon(String group) {
    switch (group) {
      case 'Material':
        return Icons.inventory_2_outlined;
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
                    'Expense Category',
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
