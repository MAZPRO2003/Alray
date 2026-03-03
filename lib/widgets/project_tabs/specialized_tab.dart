import 'package:flutter/material.dart';
import 'package:alray_app/models/project.dart';
import 'package:alray_app/models/construction_entry.dart';
import 'package:alray_app/utils/currency_utils.dart';
import 'package:intl/intl.dart';
import 'package:alray_app/widgets/transaction_details_dialog.dart';

class SpecializedTab extends StatelessWidget {
  final Project project;

  const SpecializedTab({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    // Filter specialized entries (Plan Approval, Cheques, Additional Works)
    final specializedEntries =
        project.entries
            .where(
              (e) =>
                  e.categoryId == EntryCategory.planApproval ||
                  e.categoryId == EntryCategory.additionalWorks ||
                  e.paymentMode == PaymentMode.cheque,
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    if (specializedEntries.isEmpty) {
      return const Center(
        child: Text('No specialized expenditures or cheque payments found.'),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((ctx, index) {
              final item = specializedEntries[index];
              final isCheque = item.paymentMode == PaymentMode.cheque;

              return Card(
                child: InkWell(
                  onTap: () => TransactionDetailsDialog.show(
                    context,
                    item,
                    project.name,
                  ),
                  child: ListTile(
                    leading: Icon(
                      isCheque
                          ? Icons.account_balance_outlined
                          : Icons.more_horiz,
                      color: isCheque ? Colors.indigo : Colors.grey,
                    ),
                    title: Text(
                      isCheque ? 'Cheque Payment' : item.categoryId,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.description),
                        if (isCheque && item.referenceData != null)
                          Text(
                            'Cheque #: ${item.referenceData}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                        Text(DateFormat.yMMMd().format(item.date)),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          CurrencyUtils.formatInr(item.amount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                item.transactionType == TransactionType.credit
                                ? Colors.blue
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }, childCount: specializedEntries.length),
          ),
        ),
      ],
    );
  }
}
