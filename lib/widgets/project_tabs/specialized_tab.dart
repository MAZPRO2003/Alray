import 'package:flutter/material.dart';
import 'package:alray_app/models/project.dart';
import 'package:alray_app/models/construction_entry.dart';
import 'package:alray_app/utils/currency_utils.dart';
import 'package:intl/intl.dart';
import 'package:alray_app/models/payable.dart';
import 'package:alray_app/widgets/transaction_details_dialog.dart';
import 'package:provider/provider.dart';
import 'package:alray_app/providers/budget_provider.dart';
import 'package:alray_app/widgets/add_payable_dialog.dart';
import 'package:alray_app/widgets/add_expense_dialog.dart';

class SpecializedTab extends StatefulWidget {
  final Project project;

  const SpecializedTab({super.key, required this.project});

  @override
  State<SpecializedTab> createState() => _SpecializedTabState();
}

class _SpecializedTabState extends State<SpecializedTab> {
  bool _showPending = false;

  @override
  Widget build(BuildContext context) {
    final specializedEntries =
        widget.project.entries
            .where(
              (e) =>
                  e.categoryId == EntryCategory.planApproval ||
                  e.categoryId == EntryCategory.additionalWorks ||
                  e.paymentMode == PaymentMode.cheque,
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    final totalSpent = specializedEntries
        .where((e) => e.transactionType == TransactionType.expense)
        .fold(0.0, (sum, e) => sum + e.amount);

    // Filter relevant payables
    final specializedPayables = widget.project.payables
        .where(
          (p) =>
              p.categoryId == EntryCategory.planApproval ||
              p.categoryId == EntryCategory.additionalWorks ||
              p.categoryId == EntryCategory.miscExp,
        )
        .toList();

    // Calculate actual pending amount (remaining balance)
    double pendingAmount = 0;
    final List<Map<String, dynamic>> pendingItems = [];

    for (var p in specializedPayables) {
      final paidForPayable = widget.project.entries
          .where((e) => e.payableId == p.id)
          .fold(0.0, (s, e) => s + e.amount);
      final remaining = p.totalAmount - paidForPayable;
      if (remaining > 0) {
        pendingAmount += remaining;
        pendingItems.add({'payable': p, 'remaining': remaining});
      }
    }

    final pendingExpenseIds = widget.project.entries
        .where((e) => e.payableId != null)
        .map((e) => e.id)
        .toSet();

    return CustomScrollView(
      slivers: [
        // Summary banner
        SliverToBoxAdapter(
          child: _SummaryBanner(
            totalSpent: totalSpent,
            pendingAmount: pendingAmount,
            color: Colors.indigo,
            showPending: _showPending,
            onToggle: (val) => setState(() => _showPending = val),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: _showPending
              ? _buildPendingList(pendingItems)
              : _buildPaidList(specializedEntries, pendingExpenseIds),
        ),
      ],
    );
  }

  Widget _buildPaidList(
    List<ConstructionEntry> entries,
    Set<String> pendingIds,
  ) {
    if (entries.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text('No specialized expenditures or cheque payments found.'),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate((ctx, index) {
        final item = entries[index];
        final isCheque = item.paymentMode == PaymentMode.cheque;
        final isPartiallyPaid = pendingIds.contains(item.id);

        return Card(
          child: InkWell(
            onTap: () => TransactionDetailsDialog.show(
              context,
              item,
              widget.project.name,
            ),
            child: ListTile(
              leading: Icon(
                isCheque ? Icons.account_balance_outlined : Icons.more_horiz,
                color: isCheque ? Colors.indigo : Colors.grey,
              ),
              title: Text(
                isCheque
                    ? 'Cheque Payment'
                    : EntryCategory.getLabel(item.categoryId),
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
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyUtils.formatInr(item.amount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: item.transactionType == TransactionType.credit
                              ? Colors.blue
                              : Colors.red,
                        ),
                      ),
                      if (isPartiallyPaid)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'From Bill',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (item.transactionType == TransactionType.expense)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onSelected: (val) async {
                        if (val == 'edit') {
                          showDialog(
                            context: context,
                            builder: (ctx) => AddExpenseDialog(
                              projectId: widget.project.id,
                              entry: item,
                            ),
                          );
                        } else if (val == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Expense?'),
                              content: const Text(
                                'Are you sure you want to delete this expense?',
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
                            if (context.mounted) {
                              await Provider.of<BudgetProvider>(
                                context,
                                listen: false,
                              ).removeEntry(item.id);
                            }
                          }
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit, size: 20),
                            title: Text('Edit'),
                            dense: true,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                            title: Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      }, childCount: entries.length),
    );
  }

  Widget _buildPendingList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('No pending specialized bills found.')),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate((ctx, index) {
        final p = items[index]['payable'] as Payable;
        final remaining = items[index]['remaining'] as double;
        return Card(
          child: ListTile(
            leading: const Icon(Icons.receipt_long, color: Colors.orange),
            title: Text(
              p.vendorName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${EntryCategory.getLabel(p.categoryId)} • Due ${DateFormat.yMMMd().format(p.dueDate)}',
                ),
                if (p.quantity != 1.0 || p.rate != p.totalAmount)
                  Text(
                    '${p.quantity} x ${CurrencyUtils.formatInr(p.rate)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                Text(p.description),
              ],
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Owed',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Text(
                      CurrencyUtils.formatInr(remaining),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (val) async {
                    if (val == 'edit') {
                      showDialog(
                        context: context,
                        builder: (ctx) => AddPayableDialog(
                          projectId: widget.project.id,
                          payable: p,
                        ),
                      );
                    } else if (val == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Bill?'),
                          content: const Text(
                            'Are you sure you want to delete this bill?',
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
                        if (context.mounted) {
                          await Provider.of<BudgetProvider>(
                            context,
                            listen: false,
                          ).removePayable(widget.project.id, p.id);
                        }
                      }
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit, size: 20),
                        title: Text('Edit'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 20,
                        ),
                        title: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }, childCount: items.length),
    );
  }
}

// ─── Shared Summary Banner ───────────────────────────────────────────────────

class _SummaryBanner extends StatelessWidget {
  final double totalSpent;
  final double pendingAmount;
  final Color color;
  final bool showPending;
  final ValueChanged<bool> onToggle;

  const _SummaryBanner({
    required this.totalSpent,
    required this.pendingAmount,
    required this.color,
    required this.showPending,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _statCard(
              'Actual Paid',
              CurrencyUtils.formatInr(totalSpent),
              Colors.red.shade700,
              Icons.payments_outlined,
              !showPending,
              () => onToggle(false),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statCard(
              'Still Pending',
              CurrencyUtils.formatInr(pendingAmount),
              pendingAmount > 0 ? Colors.orange.shade800 : Colors.grey,
              Icons.hourglass_bottom_rounded,
              showPending,
              () => onToggle(true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String label,
    String value,
    Color color,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.12)
              : color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? color : color.withValues(alpha: 0.1),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isActive ? color : color.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isActive ? color : color.withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isActive ? color : color.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
