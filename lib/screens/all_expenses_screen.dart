import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:alray_app/providers/budget_provider.dart';
import 'package:alray_app/models/expense.dart';
import 'package:alray_app/utils/currency_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Mapping from [ExpenseCategory] to the labels and styles used in this screen.
const _categoryLabel = {
  ExpenseCategory.vendor: 'Customer',
  ExpenseCategory.contractor: 'Workers',
  ExpenseCategory.other: 'Others',
};

const _categoryIcon = {
  ExpenseCategory.vendor: Icons.handshake_outlined,
  ExpenseCategory.contractor: Icons.construction,
  ExpenseCategory.other: Icons.category_outlined,
};

const _categoryColor = {
  ExpenseCategory.vendor: Color(0xFF6750A4), // purple - customer
  ExpenseCategory.contractor: Color(0xFFE65100), // deep orange - workers
  ExpenseCategory.other: Color(0xFF0277BD), // blue - others
};

class AllExpensesScreen extends StatefulWidget {
  const AllExpensesScreen({super.key});

  @override
  State<AllExpensesScreen> createState() => _AllExpensesScreenState();
}

class _AllExpensesScreenState extends State<AllExpensesScreen> {
  /// null = all categories
  ExpenseCategory? _selectedCategory;
  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    // Fetch independently — works even if the user goes directly to this tab
    // without visiting the Projects tab first.
    _loadFuture = Provider.of<BudgetProvider>(context, listen: false)
        .fetchAndSetProjects();
  }

  Icon _getCategoryIcon(ExpenseCategory category) {
    return Icon(_categoryIcon[category], color: _categoryColor[category]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Expenses')),
      body: FutureBuilder(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('Failed to load expenses.\n${snapshot.error}',
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }
          return _buildBody();
        },
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<BudgetProvider>(
      builder: (context, budgetProvider, child) {
          // Flatten all expenses across all projects
          final allExpenses =
              budgetProvider.projects
                  .expand(
                    (project) => project.expenses.map(
                      (e) => _ExpenseWithProject(
                        expense: e,
                        projectName: project.name,
                        projectId: project.id,
                      ),
                    ),
                  )
                  .toList()
                ..sort((a, b) => b.expense.date.compareTo(a.expense.date));

// Per-category totals (always from full list)
double totalVendor = 0, totalContractor = 0, totalOther = 0;

for (final item in allExpenses) {
  switch (item.expense.category) {
    case ExpenseCategory.vendor:
      totalVendor += item.expense.amount;
      break;

    case ExpenseCategory.contractor:
      totalContractor += item.expense.amount;
      break;

    case ExpenseCategory.other:
      totalOther += item.expense.amount;
      break;
  }
}

          // Filtered list for the list view
          final filtered = _selectedCategory == null
              ? allExpenses
              : allExpenses
                    .where((e) => e.expense.category == _selectedCategory)
                    .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Top summary panel ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    _SummaryCard(
                          label: 'Customer',
                          amount: totalVendor,
                          color: _categoryColor[ExpenseCategory.vendor]!,
                          icon: _categoryIcon[ExpenseCategory.vendor]!,
                        )
                        .animate()
                        .fade(duration: 400.ms)
                        .slideY(
                          begin: -0.15,
                          end: 0,
                          duration: 400.ms,
                          curve: Curves.easeOutQuad,
                        ),
                    const SizedBox(width: 8),
                    _SummaryCard(
                          label: 'Workers',
                          amount: totalContractor,
                          color: _categoryColor[ExpenseCategory.contractor]!,
                          icon: _categoryIcon[ExpenseCategory.contractor]!,
                        )
                        .animate()
                        .fade(duration: 400.ms, delay: 60.ms)
                        .slideY(
                          begin: -0.15,
                          end: 0,
                          duration: 400.ms,
                          curve: Curves.easeOutQuad,
                        ),
                    const SizedBox(width: 8),
                    _SummaryCard(
                          label: 'Others',
                          amount: totalOther,
                          color: _categoryColor[ExpenseCategory.other]!,
                          icon: _categoryIcon[ExpenseCategory.other]!,
                        )
                        .animate()
                        .fade(duration: 400.ms, delay: 120.ms)
                        .slideY(
                          begin: -0.15,
                          end: 0,
                          duration: 400.ms,
                          curve: Curves.easeOutQuad,
                        ),
                  ],
                ),
              ),

              // ── Filter chips ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: _selectedCategory == null,
                        color: Colors.grey.shade700,
                        icon: Icons.list_alt,
                        onTap: () => setState(() => _selectedCategory = null),
                      ),
                      const SizedBox(width: 8),
                      ...ExpenseCategory.values.map(
                        (cat) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChip(
                            label: _categoryLabel[cat]!,
                            isSelected: _selectedCategory == cat,
                            color: _categoryColor[cat]!,
                            icon: _categoryIcon[cat]!,
                            onTap: () =>
                                setState(() => _selectedCategory = cat),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1),

              // ── Expense list ─────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 56,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedCategory == null
                                  ? 'No expenses recorded yet.'
                                  : 'No ${_categoryLabel[_selectedCategory]} expenses.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 4, bottom: 16),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, index) {
                          final item = filtered[index];
                          final expense = item.expense;
                          final color =
                              _categoryColor[expense.category] ?? Colors.grey;

                          return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: color.withOpacity(0.12),
                                    child: _getCategoryIcon(expense.category),
                                  ),
                                  title: Text(
                                    expense.description,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${item.projectName}  •  '
                                    '${DateFormat.yMMMd().format(expense.date)}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  isThreeLine: false,
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        CurrencyUtils.formatInr(expense.amount),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: color,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        _categoryLabel[expense.category]!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .animate()
                              .fade(duration: 300.ms, delay: (index * 25).ms)
                              .slideX(
                                begin: 0.04,
                                end: 0,
                                duration: 300.ms,
                                curve: Curves.easeOutQuad,
                              );
                        },
                      ),
              ),
            ],
          );
        },
      
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _ExpenseWithProject {
  final Expense expense;
  final String projectName;
  final String projectId;
  const _ExpenseWithProject({
    required this.expense,
    required this.projectName,
    required this.projectId,
  });
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              CurrencyUtils.formatInr(amount),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
