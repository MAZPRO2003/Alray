import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:alray_app/providers/budget_provider.dart';
import 'package:alray_app/widgets/add_expense_dialog.dart';
import 'package:alray_app/widgets/add_revenue_dialog.dart';
import 'package:alray_app/widgets/edit_project_dialog.dart';
import 'package:alray_app/models/expense.dart';
import 'package:alray_app/models/revenue.dart';
import 'package:alray_app/utils/currency_utils.dart';
import 'package:alray_app/widgets/transaction_details_dialog.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProjectDetailsScreen extends StatelessWidget {
  final String projectId;

  const ProjectDetailsScreen({super.key, required this.projectId});

  void _showAddExpenseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AddExpenseDialog(projectId: projectId),
    );
  }

  void _showAddRevenueDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AddRevenueDialog(projectId: projectId),
    );
  }

  void _showEditProjectDialog(BuildContext context, project) {
    showDialog(
      context: context,
      builder: (ctx) => EditProjectDialog(project: project),
    );
  }

  Icon _getCategoryIcon(dynamic item) {
    if (item is Revenue) {
      return const Icon(Icons.handshake_outlined, color: Colors.blue);
    }
    final category = (item as Expense).category;
    switch (category) {
      case ExpenseCategory.contractor:
        return const Icon(Icons.construction, color: Colors.orange);
      case ExpenseCategory.material:
        return const Icon(Icons.inventory_2, color: Colors.green);
      case ExpenseCategory.other:
        return const Icon(Icons.more_horiz, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Project Details'),
        actions: [
          Consumer<BudgetProvider>(
            builder: (ctx, bp, _) {
              final idx = bp.projects.indexWhere((p) => p.id == projectId);
              if (idx == -1) return const SizedBox.shrink();
              final project = bp.projects[idx];
              return IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit project',
                onPressed: () => _showEditProjectDialog(ctx, project),
              );
            },
          ),
        ],
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, budgetProvider, child) {
          final projectIndex = budgetProvider.projects.indexWhere(
            (p) => p.id == projectId,
          );

          if (projectIndex == -1) {
            return const Center(child: Text('Project not found.'));
          }

          final project = budgetProvider.projects[projectIndex];

          // Combine expenses and revenues into a single sorted list
          final List<dynamic> transactions = [
            ...project.expenses,
            ...project.revenues,
          ]..sort((a, b) => b.date.compareTo(a.date));

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Summary Card
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Budget:'),
                            Text(
                              CurrencyUtils.formatInr(project.budget),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Received:'),
                            Text(
                              CurrencyUtils.formatInr(project.totalReceived),
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Spent:'),
                            Text(
                              CurrencyUtils.formatInr(project.totalSpent),
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Cash in Hand:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              CurrencyUtils.formatInr(project.cashOnHand),
                              style: TextStyle(
                                color: project.cashOnHand >= 0
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Remaining:'),
                            Text(
                              CurrencyUtils.formatInr(project.remainingBudget),
                              style: TextStyle(
                                color: project.remainingBudget >= 0
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ).animate().fade().slideY(begin: -0.1, end: 0),
                const SizedBox(height: 16),

                // Breakdown section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Breakdown',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(
                            Icons.handshake_outlined,
                            color: Colors.blue,
                          ),
                          title: const Text('Customer (Received)'),
                          trailing: Text(
                            CurrencyUtils.formatInr(project.totalReceived),
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.construction,
                            color: Colors.orange,
                          ),
                          title: const Text('Workers'),
                          trailing: Text(
                            CurrencyUtils.formatInr(project.contractorExpenses),
                          ),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.green,
                          ),
                          title: const Text('Material'),
                          trailing: Text(
                            CurrencyUtils.formatInr(project.materialExpenses),
                          ),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.category_outlined,
                            color: Colors.grey,
                          ),
                          title: const Text('Custom'),
                          trailing: Text(
                            CurrencyUtils.formatInr(project.otherExpenses),
                          ),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                ).animate().fade(delay: 100.ms).slideX(begin: 0.05, end: 0),
                const SizedBox(height: 16),

                Text(
                  'Recent Transactions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: transactions.isEmpty
                      ? const Center(
                          child: Text('No transactions for this project.'),
                        )
                      : ListView.builder(
                          itemCount: transactions.length,
                          itemBuilder: (ctx, index) {
                            final item = transactions[index];
                            final isRevenue = item is Revenue;

                            return Card(
                                  child: InkWell(
                                    onTap: () => TransactionDetailsDialog.show(
                                      context,
                                      item,
                                      project.name,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    child: ListTile(
                                      leading: _getCategoryIcon(item),
                                      title: Text(
                                        isRevenue
                                            ? "Customer Payment"
                                            : (item as Expense)
                                                  .formattedCategory,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Text(
                                        isRevenue
                                            ? item.description
                                            : item.category ==
                                                  ExpenseCategory.material
                                            ? DateFormat.yMMMd().format(
                                                item.date,
                                              )
                                            : '${item.description}\n${DateFormat.yMMMd().format(item.date)}',
                                      ),
                                      isThreeLine: true,
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            CurrencyUtils.formatInr(
                                              isRevenue
                                                  ? item.amount
                                                  : item.amount,
                                            ),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isRevenue
                                                  ? Colors.blue
                                                  : Colors.red,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: Text(
                                                    'Delete ${isRevenue ? 'Payment' : 'Expense'}?',
                                                  ),
                                                  content: Text(
                                                    'Are you sure you want to delete this ${isRevenue ? 'payment' : 'expense'}? This action cannot be undone.',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            ctx,
                                                          ).pop(),
                                                      child: const Text(
                                                        'Cancel',
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        if (isRevenue) {
                                                          budgetProvider
                                                              .removeRevenue(
                                                                item.id,
                                                              );
                                                        } else {
                                                          budgetProvider
                                                              .removeExpense(
                                                                projectId,
                                                                (item as Expense)
                                                                    .id,
                                                              );
                                                        }
                                                        Navigator.of(ctx).pop();
                                                      },
                                                      child: const Text(
                                                        'Delete',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
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
                                  ),
                                )
                                .animate()
                                .fade(delay: (200 + index * 30).ms)
                                .slideY(begin: 0.1, end: 0);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'add_revenue_fab_$projectId',
            onPressed: () => _showAddRevenueDialog(context),
            backgroundColor: Colors.teal.shade100,
            child: const Icon(Icons.attach_money, color: Colors.teal),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'add_expense_fab_$projectId',
            onPressed: () => _showAddExpenseDialog(context),
            child: const Icon(Icons.add_shopping_cart),
          ),
        ],
      ),
    );
  }
}
