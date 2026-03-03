import 'package:flutter/material.dart';
import 'package:alray_app/models/project.dart';
import 'package:alray_app/models/construction_entry.dart';
import 'package:alray_app/utils/currency_utils.dart';
import 'package:intl/intl.dart';
import 'package:alray_app/widgets/transaction_details_dialog.dart';

class LabourTab extends StatelessWidget {
  final Project project;

  const LabourTab({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    // Filter labour entries
    final labourEntries =
        project.entries
            .where(
              (e) =>
                  e.transactionType == TransactionType.expense &&
                  (e.categoryId.endsWith('-L') &&
                      e.categoryId != EntryCategory.planApproval),
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    if (labourEntries.isEmpty) {
      return const Center(child: Text('No labour entries found.'));
    }

    // Display a master ledger for labour
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((ctx, index) {
              final item = labourEntries[index];
              return Card(
                child: InkWell(
                  onTap: () => TransactionDetailsDialog.show(
                    context,
                    item,
                    project.name,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.construction,
                      color: Colors.orange,
                    ),
                    title: Text(
                      item.categoryId,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${item.description}\n${DateFormat.yMMMd().format(item.date)}',
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          CurrencyUtils.formatInr(item.amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }, childCount: labourEntries.length),
          ),
        ),
      ],
    );
  }
}
