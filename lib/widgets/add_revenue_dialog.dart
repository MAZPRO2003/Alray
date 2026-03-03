import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alray_app/providers/budget_provider.dart';
import 'package:alray_app/models/construction_entry.dart';
import 'package:alray_app/utils/inr_to_words.dart';
import 'package:intl/intl.dart';

class AddRevenueDialog extends StatefulWidget {
  final String? projectId;

  const AddRevenueDialog({super.key, this.projectId});

  @override
  State<AddRevenueDialog> createState() => _AddRevenueDialogState();
}

class _AddRevenueDialogState extends State<AddRevenueDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _receiverController = TextEditingController();
  final _receiptNoController = TextEditingController();
  final _bankController = TextEditingController();
  final _branchController = TextEditingController();
  final _amountInWordsController = TextEditingController();
  final _chequeController = TextEditingController();

  String? _selectedProjectId;
  PaymentMode _paymentMode = PaymentMode.cash;

  // Default to today
  DateTime _receiptDate = DateTime.now();
  DateTime? _paymentDate; // Only for cheque/online
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedProjectId = widget.projectId;
    _amountController.addListener(_updateAmountInWords);
    // Auto-generate a basic receipt number if possible
    _receiptNoController.text =
        '${DateFormat('yyyyMMdd').format(DateTime.now())}-${DateTime.now().millisecond}';
  }

  void _updateAmountInWords() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount > 0) {
      _amountInWordsController.text = InrToWords.convert(amount);
    } else {
      _amountInWordsController.text = '';
    }
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    final enteredAmount = double.tryParse(_amountController.text);
    if (enteredAmount == null || enteredAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final newRevenue = ConstructionEntry(
        projectId: _selectedProjectId ?? '',
        transactionType: TransactionType.credit,
        categoryId: EntryCategory.paymentReceived,
        description: _descriptionController.text.trim(),
        rate: enteredAmount,
        quantity: 1,
        date: _receiptDate,
        paymentMode: _paymentMode,
        referenceData: _paymentMode == PaymentMode.cash
            ? 'Cash'
            : _chequeController.text,
        receiverName: _receiverController.text.trim(),
        receiptNumber: _receiptNoController.text.trim(),
        amountInWords: _amountInWordsController.text.trim(),
        bankName: _bankController.text.trim(),
        branchName: _branchController.text.trim(),
        paymentDate: _paymentDate ?? _receiptDate,
      );

      await Provider.of<BudgetProvider>(
        context,
        listen: false,
      ).addEntry(newRevenue);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save revenue: $e')));
      }
    }
  }

  void _presentDatePickers(bool isReceiptDate) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isReceiptDate
          ? _receiptDate
          : (_paymentDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null) return;
    setState(() {
      if (isReceiptDate) {
        _receiptDate = pickedDate;
      } else {
        _paymentDate = pickedDate;
      }
    });
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateAmountInWords);
    _amountController.dispose();
    _descriptionController.dispose();
    _receiverController.dispose();
    _receiptNoController.dispose();
    _bankController.dispose();
    _branchController.dispose();
    _amountInWordsController.dispose();
    _chequeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projects = Provider.of<BudgetProvider>(context).projects;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Issue Receipt',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _receiptNoController,
                        decoration: const InputDecoration(
                          labelText: 'Receipt No.',
                          prefixIcon: Icon(Icons.numbers),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => _presentDatePickers(true),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Receipt Date',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(_receiptDate),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _receiverController,
                  decoration: const InputDecoration(
                    labelText: 'Received From (Customer Name)',
                    hintText: 'e.g., Mr. Peer Mohamed',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String?>(
                  value: _selectedProjectId,
                  decoration: const InputDecoration(
                    labelText: 'Project',
                    prefixIcon: Icon(Icons.business_center_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('General'),
                    ),
                    ...projects.map(
                      (p) => DropdownMenuItem(value: p.id, child: Text(p.name)),
                    ),
                  ],
                  onChanged: (val) => setState(() => _selectedProjectId = val),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹)',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountInWordsController,
                  decoration: const InputDecoration(
                    labelText: 'Amount in Words',
                    prefixIcon: Icon(Icons.text_fields),
                  ),
                  readOnly: true,
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Payment Details',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _modeButton(PaymentMode.cash, 'Cash', Icons.money),
                    const SizedBox(width: 8),
                    _modeButton(
                      PaymentMode.cheque,
                      'Cheque',
                      Icons.account_balance_wallet_outlined,
                    ),
                    const SizedBox(width: 8),
                    _modeButton(PaymentMode.online, 'Online', Icons.vibration),
                  ],
                ),
                const SizedBox(height: 16),

                if (_paymentMode != PaymentMode.cash) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _chequeController,
                          decoration: InputDecoration(
                            labelText: _paymentMode == PaymentMode.cheque
                                ? 'Cheque No.'
                                : 'Ref/TXN ID',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => _presentDatePickers(false),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Dated',
                            ),
                            child: Text(
                              _paymentDate == null
                                  ? 'Select Date'
                                  : DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(_paymentDate!),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _bankController,
                          decoration: const InputDecoration(
                            labelText: 'Drawn On (Bank)',
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _branchController,
                          decoration: const InputDecoration(
                            labelText: 'Branch',
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Towards (Reason/Stage)',
                    hintText: 'e.g., Construction Advance',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _submitData,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save & Issue Receipt',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeButton(PaymentMode mode, String label, IconData icon) {
    bool isSelected = _paymentMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _paymentMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
