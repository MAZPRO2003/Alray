import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:alray_app/models/construction_entry.dart';
import 'package:alray_app/utils/currency_utils.dart';
import 'package:alray_app/utils/receipt_generator.dart';

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
    final entry = transaction is ConstructionEntry
        ? transaction as ConstructionEntry
        : null;
    final isRevenue =
        entry != null && entry.transactionType == TransactionType.credit;

    final color = isRevenue ? Colors.blue : _getExpenseColor();
    final title = isRevenue ? 'Customer Payment' : _getExpenseTitle();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
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

              if (isRevenue && entry.receiverName != null)
                _buildDetailRow('Received From', entry.receiverName!),

              if (isRevenue && entry.receiptNumber != null)
                _buildDetailRow('Receipt Number', entry.receiptNumber!),

              _buildDetailRow('Description', transaction.description),

              if (!isRevenue)
                ..._buildExpenseSpecificDetails()
              else
                ..._buildRevenueSpecificDetails(),

              const SizedBox(height: 24),
              Row(
                children: [
                  if (isRevenue) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => ReceiptGenerator.generateAndShare(
                          context: context,
                          entry: entry,
                        ),
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Download Receipt'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Close'),
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

  List<Widget> _buildRevenueSpecificDetails() {
    final List<Widget> details = [];
    if (transaction is! ConstructionEntry) return details;
    final e = transaction as ConstructionEntry;

    details.add(
      _buildDetailRow('Payment Mode', e.paymentMode.name.toUpperCase()),
    );

    if (e.paymentMode != PaymentMode.cash) {
      if (e.referenceData != null) {
        details.add(
          _buildDetailRow(
            e.paymentMode == PaymentMode.cheque ? 'Cheque No.' : 'TXN ID',
            e.referenceData!,
          ),
        );
      }
      if (e.paymentDate != null) {
        details.add(
          _buildDetailRow(
            'Value Date',
            DateFormat.yMMMd().format(e.paymentDate!),
          ),
        );
      }
      if (e.bankName != null && e.bankName!.isNotEmpty) {
        details.add(_buildDetailRow('Bank', e.bankName!));
      }
      if (e.branchName != null && e.branchName!.isNotEmpty) {
        details.add(_buildDetailRow('Branch', e.branchName!));
      }
    }

    return details;
  }

  List<Widget> _buildExpenseSpecificDetails() {
    final List<Widget> details = [];

    if (transaction is! ConstructionEntry) return details;
    final e = transaction as ConstructionEntry;

    details.add(_buildDetailRow('Category', e.categoryId));
    if (e.quantity != 1.0) {
      details.add(_buildDetailRow('Quantity', e.quantity.toStringAsFixed(2)));
      details.add(_buildDetailRow('Rate', CurrencyUtils.formatInr(e.rate)));
    }
    details.add(
      _buildDetailRow('Payment Mode', e.paymentMode.name.toUpperCase()),
    );

    if (e.paymentMode == PaymentMode.cheque && e.referenceData != null) {
      details.add(_buildDetailRow('Cheque Details', e.referenceData!));
    }

    return details;
  }

  Color _getExpenseColor() {
    if (transaction is! ConstructionEntry) return Colors.blue;
    final e = transaction as ConstructionEntry;
    if (e.categoryId.endsWith('-M') ||
        e.categoryId == EntryCategory.otherMiscMaterials)
      return Colors.green;
    if (e.categoryId.endsWith('-L') ||
        e.categoryId == EntryCategory.planApproval)
      return Colors.orange;
    return Colors.blue;
  }

  String _getExpenseTitle() {
    if (transaction is! ConstructionEntry) return 'Custom';
    final e = transaction as ConstructionEntry;
    if (e.categoryId.endsWith('-M') ||
        e.categoryId == EntryCategory.otherMiscMaterials)
      return 'Material';
    if (e.categoryId.endsWith('-L') ||
        e.categoryId == EntryCategory.planApproval)
      return 'Workers';
    return 'Custom';
  }
}
