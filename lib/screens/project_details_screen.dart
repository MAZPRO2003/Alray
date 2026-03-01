import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:alray_app/providers/budget_provider.dart';
import 'package:alray_app/widgets/add_expense_dialog.dart';
import 'package:alray_app/widgets/edit_project_dialog.dart';
import 'package:alray_app/models/expense.dart';
import 'package:alray_app/utils/currency_utils.dart';
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

  void _showEditProjectDialog(BuildContext context, project) {
    showDialog(
      context: context,
      builder: (ctx) => EditProjectDialog(project: project),
    );
  }

  Icon _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.vendor:
        return const Icon(Icons.store, color: Colors.blue);
      case ExpenseCategory.contractor:
        return const Icon(Icons.handyman, color: Colors.orange);
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
          final expenses = project.expenses;
          expenses.sort((a, b) => b.date.compareTo(a.date));

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
                                const Text('Spent:'),
                                Text(
                                  CurrencyUtils.formatInr(
                                    project.totalExpenses,
                                  ),
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Remaining:'),
                                Text(
                                  CurrencyUtils.formatInr(
                                    project.remainingBudget,
                                  ),
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
                    )
                    .animate()
                    .fade(duration: 400.ms)
                    .slideY(
                      begin: -0.1,
                      end: 0,
                      duration: 400.ms,
                      curve: Curves.easeOutQuad,
                    ),
                const SizedBox(height: 16),

                // Expenses Breakdown
                Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expenses Breakdown',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(
                                Icons.store,
                                color: Colors.blue,
                              ),
                              title: const Text('Vendor'),
                              trailing: Text(
                                CurrencyUtils.formatInr(project.vendorExpenses),
                              ),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.handyman,
                                color: Colors.orange,
                              ),
                              title: const Text('Contractor'),
                              trailing: Text(
                                CurrencyUtils.formatInr(
                                  project.contractorExpenses,
                                ),
                              ),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.more_horiz,
                                color: Colors.grey,
                              ),
                              title: const Text('Other'),
                              trailing: Text(
                                CurrencyUtils.formatInr(project.otherExpenses),
                              ),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ],
                        ),
                      ),
                    )
                    .animate()
                    .fade(duration: 400.ms, delay: 100.ms)
                    .slideX(
                      begin: 0.05,
                      end: 0,
                      duration: 400.ms,
                      curve: Curves.easeOutQuad,
                    ),
                const SizedBox(height: 16),

                Text(
                  'Recent Expenses',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: expenses.isEmpty
                      ? const Center(
                          child: Text('No expenses recorded for this project.'),
                        )
                      : ListView.builder(
                          itemCount: expenses.length,
                          itemBuilder: (ctx, index) {
                            final expense = expenses[index];
                            return Card(
                                  child: ListTile(
                                    leading: _getCategoryIcon(expense.category),
                                    title: Text(expense.description),
                                    subtitle: Text(
                                      '${DateFormat.yMMMd().format(expense.date)} • ${expense.formattedCategory}',
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          CurrencyUtils.formatInr(
                                            expense.amount,
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            budgetProvider.removeExpense(
                                              projectId,
                                              expense.id,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .animate()
                                .fade(
                                  duration: 300.ms,
                                  delay: (200 + index * 30).ms,
                                )
                                .slideY(
                                  begin: 0.1,
                                  end: 0,
                                  duration: 300.ms,
                                  curve: Curves.easeOutQuad,
                                );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_expense_fab_$projectId',
        onPressed: () => _showAddExpenseDialog(context),
        child: const Icon(Icons.add_shopping_cart),
      ),
    );
  }
}
