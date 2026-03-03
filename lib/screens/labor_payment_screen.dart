import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alray_app/providers/budget_provider.dart';
import 'package:alray_app/models/project.dart';
import 'package:alray_app/models/labor_payment.dart';
import 'package:alray_app/utils/currency_utils.dart';
import 'package:alray_app/utils/labor_report_generator.dart';
import 'package:intl/intl.dart';

class LaborPaymentScreen extends StatefulWidget {
  final String projectId;

  const LaborPaymentScreen({super.key, required this.projectId});

  @override
  State<LaborPaymentScreen> createState() => _LaborPaymentScreenState();
}

class _LaborPaymentScreenState extends State<LaborPaymentScreen> {
  DateTimeRange? _selectedDateRange;

  void _showPaymentDialog([LaborPayment? existingPayment]) {
    final nameController = TextEditingController(
      text: existingPayment?.laborerName,
    );
    final amountController = TextEditingController(
      text: existingPayment?.amount.toString() ?? '',
    );
    final descController = TextEditingController(
      text: existingPayment?.description,
    );
    DateTimeRange? tempRange = existingPayment != null
        ? DateTimeRange(
            start: existingPayment.periodStart,
            end: existingPayment.periodEnd,
          )
        : _selectedDateRange;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            existingPayment == null
                ? 'Add Labor Payment'
                : 'Edit Labor Payment',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Laborer Name / Group',
                  ),
                ),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount Paid'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    tempRange == null
                        ? 'Select Period'
                        : '${DateFormat.yMMMd().format(tempRange!.start)} - ${DateFormat.yMMMd().format(tempRange!.end)}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDateRange: tempRange,
                    );
                    if (picked != null) {
                      setDialogState(() => tempRange = picked);
                    }
                  },
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (tempRange == null ||
                    nameController.text.isEmpty ||
                    amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required fields'),
                    ),
                  );
                  return;
                }
                final payment = LaborPayment(
                  id: existingPayment?.id,
                  projectId: widget.projectId,
                  laborerName: nameController.text,
                  amount: double.tryParse(amountController.text) ?? 0.0,
                  periodStart: tempRange!.start,
                  periodEnd: tempRange!.end,
                  description: descController.text,
                  date: existingPayment?.date,
                );

                final provider = Provider.of<BudgetProvider>(
                  context,
                  listen: false,
                );
                if (existingPayment == null) {
                  provider.addLaborPayment(payment);
                } else {
                  provider.updateLaborPayment(payment);
                }
                Navigator.pop(ctx);
              },
              child: Text(
                existingPayment == null ? 'Add Payment' : 'Save Changes',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bp = Provider.of<BudgetProvider>(context);
    final Project project = bp.projects.firstWhere(
      (p) => p.id == widget.projectId,
    );
    final payments = project.laborPayments.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Labor Payments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => LaborReportGenerator.generateAndShare(
              context: context,
              project: project,
              payments: payments,
              tasks: project.laborTasks,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.table_view),
            onPressed: () => LaborReportGenerator.generateExcelAndShare(
              context: context,
              project: project,
              payments: payments,
              tasks: project.laborTasks,
            ),
          ),
        ],
      ),
      body: payments.isEmpty
          ? const Center(child: Text('No payments recorded yet.'))
          : ListView.builder(
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(
                      payment.laborerName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${DateFormat.yMMMd().format(payment.periodStart)} - ${DateFormat.yMMMd().format(payment.periodEnd)}',
                        ),
                        if (payment.description.isNotEmpty)
                          Text(
                            payment.description,
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyUtils.formatInr(payment.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              DateFormat.yMMMd().format(payment.date),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => _showPaymentDialog(payment),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            size: 18,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Payment?'),
                                content: const Text(
                                  'Are you sure you want to remove this payment record?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      bp.removeLaborPayment(
                                        widget.projectId,
                                        payment.id,
                                      );
                                      Navigator.pop(ctx);
                                    },
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPaymentDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
