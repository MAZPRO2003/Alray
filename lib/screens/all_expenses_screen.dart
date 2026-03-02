import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:alray_app/providers/budget_provider.dart';
import 'package:alray_app/models/expense.dart';
import 'package:alray_app/models/revenue.dart';
import 'package:alray_app/utils/currency_utils.dart';
import 'package:alray_app/widgets/transaction_details_dialog.dart';
import 'package:flutter_animate/flutter_animate.dart';

const _categoryIcon = {
  'revenue': Icons.handshake_outlined,
  ExpenseCategory.contractor: Icons.construction,
  ExpenseCategory.material: Icons.inventory_2_outlined,
  ExpenseCategory.other: Icons.category_outlined,
};

const _categoryColor = {
  'revenue': Color(0xFF6750A4), // purple - revenue
  ExpenseCategory.contractor: Color(0xFFE65100), // deep orange - workers
  ExpenseCategory.material: Color(0xFF2E7D32), // green - material
  ExpenseCategory.other: Color(0xFF0277BD), // blue - others
};

class AllExpensesScreen extends StatefulWidget {
  const AllExpensesScreen({super.key});

  @override
  State<AllExpensesScreen> createState() => _AllExpensesScreenState();
}

class _AllExpensesScreenState extends State<AllExpensesScreen> {
  /// null = all, 'revenue' = customer payments, or ExpenseCategory
  dynamic _selectedFilter;
  String? _selectedProjectId;
  String _paymentFilter = 'all'; // 'all' | 'pending' | 'paid'
  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = Provider.of<BudgetProvider>(
      context,
      listen: false,
    ).fetchAndSetProjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Transactions')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'ai_chat_fab_expenses',
        onPressed: () => context.push('/chat'),
        backgroundColor: Colors.indigo,
        tooltip: 'AI Chat Assistant',
        child: const Icon(Icons.smart_toy, color: Colors.white),
      ),
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
                  Text(
                    'Failed to load data.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loadFuture = Provider.of<BudgetProvider>(
                          context,
                          listen: false,
                        ).fetchAndSetProjects();
                      });
                    },
                    child: const Text('Retry'),
                  ),
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
        // Build the unified list of transactions
        final List<_TransactionItem> allTransactions = [];

        // 1. Add global revenues
        for (var r in budgetProvider.revenues) {
          allTransactions.add(
            _TransactionItem(data: r, projectName: 'General'),
          );
        }

        // 2. Add project specific revenues and expenses
        for (var p in budgetProvider.projects) {
          for (var r in p.revenues) {
            allTransactions.add(_TransactionItem(data: r, projectName: p.name));
          }
          for (var e in p.expenses) {
            allTransactions.add(_TransactionItem(data: e, projectName: p.name));
          }
        }

        // Sort by date newest first
        allTransactions.sort((a, b) => b.date.compareTo(a.date));

        // 1. Filter by Project first (if selected)
        final projectFiltered = _selectedProjectId == null
            ? allTransactions
            : allTransactions
                  .where(
                    (t) => _selectedProjectId == 'General'
                        ? t.projectName == 'General'
                        : budgetProvider.projects.any(
                            (p) =>
                                p.id == _selectedProjectId &&
                                p.name == t.projectName,
                          ),
                  )
                  .toList();

        // Calculate totals based on project filter
        double totalRevenue = 0;
        double totalWorkers = 0;
        double totalMaterial = 0;
        double totalCustom = 0;

        for (final item in projectFiltered) {
          if (item.data is Revenue) {
            totalRevenue += (item.data as Revenue).amount;
          } else {
            final e = item.data as Expense;
            if (e.category == ExpenseCategory.contractor) {
              totalWorkers += e.amount;
            }
            if (e.category == ExpenseCategory.material) {
              totalMaterial += e.amount;
            }
            if (e.category == ExpenseCategory.other) totalCustom += e.amount;
          }
        }

        // 2. Filter by Category for the list display
        final categoryFiltered = _selectedFilter == null
            ? projectFiltered
            : projectFiltered.where((t) {
                if (_selectedFilter == 'revenue') return t.data is Revenue;
                if (t.data is Expense) {
                  return (t.data as Expense).category == _selectedFilter;
                }
                return false;
              }).toList();

        // 3. Build set of expense IDs that are "pending" (linked to a payable with remaining balance)
        final pendingExpenseIds = <String>{};
        for (var project in budgetProvider.projects) {
          final pendingPayableIds = project.payables
              .where((p) {
                final paid = project.expenses
                    .where((e) => e.payableId == p.id)
                    .fold(0.0, (sum, e) => sum + e.amount);
                return (p.totalAmount - paid) > 0;
              })
              .map((p) => p.id)
              .toSet();
          for (var e in project.expenses) {
            if (e.payableId != null &&
                pendingPayableIds.contains(e.payableId)) {
              pendingExpenseIds.add(e.id);
            }
          }
        }

        // 4. Filter by payment status
        final filteredList = _paymentFilter == 'all'
            ? categoryFiltered
            : _paymentFilter == 'pending'
            ? categoryFiltered.where((t) {
                if (t.data is Revenue) return false;
                return pendingExpenseIds.contains((t.data as Expense).id);
              }).toList()
            : categoryFiltered.where((t) {
                if (t.data is Revenue) return true;
                return !pendingExpenseIds.contains((t.data as Expense).id);
              }).toList();

        return Column(
          children: [
            // Summary Cards Panel
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _SummaryCard(
                      label: 'Received',
                      amount: totalRevenue,
                      color: _categoryColor['revenue']!,
                      icon: _categoryIcon['revenue']!,
                    ).animate().fade().slideY(begin: -0.1, end: 0),
                    const SizedBox(width: 8),
                    _SummaryCard(
                      label: 'Workers',
                      amount: totalWorkers,
                      color: _categoryColor[ExpenseCategory.contractor]!,
                      icon: _categoryIcon[ExpenseCategory.contractor]!,
                    ).animate().fade(delay: 100.ms).slideY(begin: -0.1, end: 0),
                    const SizedBox(width: 8),
                    _SummaryCard(
                      label: 'Material',
                      amount: totalMaterial,
                      color: _categoryColor[ExpenseCategory.material]!,
                      icon: _categoryIcon[ExpenseCategory.material]!,
                    ).animate().fade(delay: 150.ms).slideY(begin: -0.1, end: 0),
                    const SizedBox(width: 8),
                    _SummaryCard(
                      label: 'Custom',
                      amount: totalCustom,
                      color: _categoryColor[ExpenseCategory.other]!,
                      icon: _categoryIcon[ExpenseCategory.other]!,
                    ).animate().fade(delay: 200.ms).slideY(begin: -0.1, end: 0),
                  ],
                ),
              ),
            ),

            // Project Filter Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All Projects',
                      isSelected: _selectedProjectId == null,
                      onTap: () => setState(() => _selectedProjectId = null),
                      color: Theme.of(context).colorScheme.primary,
                      icon: Icons.business,
                    ),
                    const SizedBox(width: 8),
                    ...budgetProvider.projects.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: _FilterChip(
                          label: p.name,
                          isSelected: _selectedProjectId == p.id,
                          onTap: () =>
                              setState(() => _selectedProjectId = p.id),
                          color: Theme.of(context).colorScheme.primary,
                          icon: Icons.folder_open,
                        ),
                      ),
                    ),
                    _FilterChip(
                      label: 'General',
                      isSelected: _selectedProjectId == 'General',
                      onTap: () =>
                          setState(() => _selectedProjectId = 'General'),
                      color: Theme.of(context).colorScheme.primary,
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      isSelected: _selectedFilter == null,
                      onTap: () => setState(() => _selectedFilter = null),
                      color: Colors.grey.shade700,
                      icon: Icons.all_inbox,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Payments',
                      isSelected: _selectedFilter == 'revenue',
                      onTap: () => setState(() => _selectedFilter = 'revenue'),
                      color: _categoryColor['revenue']!,
                      icon: _categoryIcon['revenue']!,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Workers',
                      isSelected: _selectedFilter == ExpenseCategory.contractor,
                      onTap: () => setState(
                        () => _selectedFilter = ExpenseCategory.contractor,
                      ),
                      color: _categoryColor[ExpenseCategory.contractor]!,
                      icon: _categoryIcon[ExpenseCategory.contractor]!,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Material',
                      isSelected: _selectedFilter == ExpenseCategory.material,
                      onTap: () => setState(
                        () => _selectedFilter = ExpenseCategory.material,
                      ),
                      color: _categoryColor[ExpenseCategory.material]!,
                      icon: _categoryIcon[ExpenseCategory.material]!,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Custom',
                      isSelected: _selectedFilter == ExpenseCategory.other,
                      onTap: () => setState(
                        () => _selectedFilter = ExpenseCategory.other,
                      ),
                      color: _categoryColor[ExpenseCategory.other]!,
                      icon: _categoryIcon[ExpenseCategory.other]!,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Pending / Paid tab bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _TabButton(
                      label: 'All',
                      isSelected: _paymentFilter == 'all',
                      onTap: () => setState(() => _paymentFilter = 'all'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TabButton(
                      label: 'Pending',
                      isSelected: _paymentFilter == 'pending',
                      onTap: () => setState(() => _paymentFilter = 'pending'),
                      activeColor: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TabButton(
                      label: 'Paid',
                      isSelected: _paymentFilter == 'paid',
                      onTap: () => setState(() => _paymentFilter = 'paid'),
                      activeColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),

            // List of Transactions
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await budgetProvider.fetchAndSetProjects();
                },
                child: filteredList.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: const Center(
                              child: Text(
                                'No transactions found.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: filteredList.length,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemBuilder: (ctx, index) {
                          final item = filteredList[index];
                          final isRevenue = item.data is Revenue;
                          final color = isRevenue
                              ? _categoryColor['revenue']!
                              : _categoryColor[(item.data as Expense)
                                    .category]!;
                          final icon = isRevenue
                              ? _categoryIcon['revenue']!
                              : _categoryIcon[(item.data as Expense).category]!;

                          // Determine Pending / Paid badge
                          final bool isPending =
                              !isRevenue &&
                              pendingExpenseIds.contains(
                                (item.data as Expense).id,
                              );
                          final String statusLabel = isRevenue
                              ? 'Received'
                              : (isPending ? 'Pending' : 'Paid');
                          final Color statusColor = isRevenue
                              ? Colors.blue
                              : (isPending ? Colors.orange : Colors.green);

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: InkWell(
                              onTap: () => TransactionDetailsDialog.show(
                                context,
                                item.data,
                                item.projectName,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: color.withValues(alpha: 0.1),
                                  child: Icon(icon, color: color, size: 20),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isRevenue
                                            ? "Customer Payment"
                                            : (item.data as Expense)
                                                  .formattedCategory,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: statusColor.withValues(
                                            alpha: 0.4,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  isRevenue
                                      ? '${(item.data as Revenue).description}\n${item.projectName}  •  ${DateFormat.yMMMd().format(item.date)}'
                                      : (item.data as Expense).category ==
                                            ExpenseCategory.material
                                      ? '${item.projectName}  •  ${DateFormat.yMMMd().format(item.date)}'
                                      : '${(item.data as Expense).description}\n${item.projectName}  •  ${DateFormat.yMMMd().format(item.date)}',
                                ),
                                isThreeLine: true,
                                trailing: Text(
                                  CurrencyUtils.formatInr(
                                    isRevenue
                                        ? (item.data as Revenue).amount
                                        : (item.data as Expense).amount,
                                  ),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isRevenue ? Colors.blue : Colors.red,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ).animate().fade().slideX(begin: 0.1, end: 0);
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TransactionItem {
  final dynamic data;
  final String projectName;
  DateTime get date => data.date;
  _TransactionItem({required this.data, required this.projectName});
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
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyUtils.formatInr(amount),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;
  final IconData icon;
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.activeColor = const Color(0xFF6750A4),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade300,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
