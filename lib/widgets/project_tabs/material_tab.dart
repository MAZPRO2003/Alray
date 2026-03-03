import 'package:flutter/material.dart';
import 'package:alray_app/models/project.dart';
import 'package:alray_app/models/construction_entry.dart';
import 'package:alray_app/utils/currency_utils.dart';
import 'package:intl/intl.dart';
import 'package:alray_app/widgets/transaction_details_dialog.dart';

class MaterialTab extends StatelessWidget {
  final Project project;

  const MaterialTab({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    // Filter material entries
    final materialEntries =
        project.entries
            .where(
              (e) =>
                  e.transactionType == TransactionType.expense &&
                  (e.categoryId.endsWith('-M') ||
                      e.categoryId == EntryCategory.otherMiscMaterials),
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    if (materialEntries.isEmpty) {
      return const Center(child: Text('No material entries found.'));
    }

    // Group entries if necessary, or just display a list
    // For now, let's display a master ledger
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((ctx, index) {
              final item = materialEntries[index];
              return Card(
                child: InkWell(
                  onTap: () => TransactionDetailsDialog.show(
                    context,
                    item,
                    project.name,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.inventory_2, color: Colors.green),
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
            }, childCount: materialEntries.length),
          ),
        ),
      ],
    );
  }
}
