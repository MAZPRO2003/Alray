import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:alray_app/models/expense.dart';
import 'package:alray_app/models/revenue.dart';
import 'package:alray_app/utils/currency_utils.dart';

class TransactionDetailsDialog extends StatelessWidget {
  final dynamic transaction;
  final String projectName;

  const TransactionDetailsDialog({
    super.key,
    required this.transaction,
    required this.projectName,
  });

  static void show(
    BuildContext context,
    dynamic transaction,
    String projectName,
  ) {
    showDialog(
      context: context,
      builder: (context) => TransactionDetailsDialog(
        transaction: transaction,
        projectName: projectName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRevenue = transaction is Revenue;
    final color = isRevenue ? Colors.blue : _getExpenseColor();
    final title = isRevenue ? 'Customer Payment' : _getExpenseTitle();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildDetailRow('Project', projectName),
            _buildDetailRow('Type', title, color: color),
            _buildDetailRow(
              'Date',
              DateFormat.yMMMMEEEEd().format(transaction.date),
            ),
            _buildDetailRow(
              'Amount',
              CurrencyUtils.formatInr(transaction.amount),
              isBold: true,
              color: isRevenue ? Colors.blue : Colors.red,
            ),
            _buildDetailRow('Description', transaction.description),
            if (!isRevenue) ..._buildExpenseSpecificDetails(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildExpenseSpecificDetails() {
    final e = transaction as Expense;
    final List<Widget> details = [];

    if (e.category == ExpenseCategory.material) {
      if (e.materialType != null) {
        details.add(_buildDetailRow('Material', e.materialType!));
      }
      if (e.vendorName != null) {
        details.add(_buildDetailRow('Vendor', e.vendorName!));
      }
      if (e.quantity != null && e.unit != null) {
        details.add(_buildDetailRow('Quantity', '${e.quantity} ${e.unit}'));
      }
    } else if (e.category == ExpenseCategory.contractor) {
      if (e.workerName != null) {
        details.add(_buildDetailRow('Worker/Contractor', e.workerName!));
      }
    } else if (e.category == ExpenseCategory.other) {
      if (e.customCategoryName != null) {
        details.add(_buildDetailRow('Custom Category', e.customCategoryName!));
      }
    }

    return details;
  }

  Color _getExpenseColor() {
    final e = transaction as Expense;
    switch (e.category) {
      case ExpenseCategory.contractor:
        return Colors.orange;
      case ExpenseCategory.material:
        return Colors.green;
      case ExpenseCategory.other:
        return Colors.blue;
    }
  }

  String _getExpenseTitle() {
    final e = transaction as Expense;
    switch (e.category) {
      case ExpenseCategory.contractor:
        return 'Workers';
      case ExpenseCategory.material:
        return 'Material';
      case ExpenseCategory.other:
        return 'Custom';
    }
  }
}
