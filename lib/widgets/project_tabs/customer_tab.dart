import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:alray_app/models/project.dart';
import 'package:alray_app/providers/budget_provider.dart';
import 'package:alray_app/models/construction_entry.dart';
import 'package:alray_app/utils/currency_utils.dart';
import 'package:alray_app/utils/receipt_generator.dart';
import 'package:alray_app/widgets/add_revenue_dialog.dart';
import 'package:alray_app/widgets/transaction_details_dialog.dart';

class CustomerTab extends StatelessWidget {
  final Project project;

  const CustomerTab({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final customerPayments =
        project.entries
            .where((e) => e.transactionType == TransactionType.credit)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFinanceSummary(context),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Payment History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddPaymentDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Payment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (customerPayments.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'No payments received from customer yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...customerPayments.map(
                    (entry) => _buildPaymentCard(context, entry),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinanceSummary(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildSummaryRow(
              'Total Project Budget',
              project.budget,
              isBold: true,
            ),
            const Divider(height: 24),
            _buildSummaryRow(
              'Total Amount Received',
              project.totalReceived,
              valueColor: Colors.green.shade700,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'Pending Balance',
              project.budget - project.totalReceived,
              valueColor: Colors.orange.shade800,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: Colors.blueGrey.shade700,
          ),
        ),
        Text(
          CurrencyUtils.formatInr(amount),
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard(BuildContext context, ConstructionEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () =>
            TransactionDetailsDialog.show(context, entry, project.name),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.description.isEmpty
                              ? 'Customer Payment'
                              : entry.description,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMM yyyy').format(entry.date),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyUtils.formatInr(entry.amount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showAddPaymentDialog(context, entry),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _handleDelete(context, entry),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => ReceiptGenerator.generateAndShare(
                      context: context,
                      entry: entry,
                    ),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Receipt'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.teal.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddPaymentDialog(BuildContext context, [ConstructionEntry? entry]) {
    showDialog(
      context: context,
      builder: (ctx) =>
          AddRevenueDialog(projectId: project.id, initialEntry: entry),
    );
  }

  void _handleDelete(BuildContext context, ConstructionEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Payment?'),
        content: const Text(
          'Are you sure you want to delete this payment record?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      Provider.of<BudgetProvider>(context, listen: false).removeEntry(entry.id);
    }
  }
}
