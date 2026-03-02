import 'package:flutter/material.dart';
import 'package:alray_app/models/project.dart';
import 'package:provider/provider.dart';
import 'package:alray_app/providers/budget_provider.dart';
import 'package:alray_app/providers/contacts_provider.dart';
import 'package:alray_app/providers/auth_provider.dart';
import 'package:alray_app/widgets/add_project_dialog.dart';
import 'package:alray_app/utils/currency_utils.dart';
import 'package:alray_app/widgets/add_revenue_dialog.dart';
import 'package:alray_app/widgets/add_expense_dialog.dart';
import 'package:alray_app/widgets/transaction_details_dialog.dart';
import 'package:alray_app/widgets/shimmer_loading.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:alray_app/widgets/weather_widget.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final contactsProvider = Provider.of<ContactsProvider>(
      context,
      listen: false,
    );
    _loadFuture = Future.microtask(() async {
      await Future.wait([
        budgetProvider.fetchAndSetProjects(),
        contactsProvider.fetchContacts(),
      ]);
    });
  }

  void _showAddProjectDialog(BuildContext context) {
    showDialog(context: context, builder: (ctx) => const AddProjectDialog());
  }

  void _showAddRevenueDialog(BuildContext context) {
    showDialog(context: context, builder: (ctx) => const AddRevenueDialog());
  }

  void _showAddExpenseDialog(BuildContext context) {
    // For Dashboard, we default to no specific project or ask user to pick
    // Since our AddExpenseDialog requires a projectId, we'll suggest adding
    // from project details or provide a picker. For now, let's just open
    // the first project's dialog if available, or guide to project list.
    final projects = Provider.of<BudgetProvider>(
      context,
      listen: false,
    ).projects;
    if (projects.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add a project first!')));
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AddExpenseDialog(projectId: projects.first.id),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d').format(now);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userName =
        authProvider.user?.displayName ??
        authProvider.user?.email?.split('@').first ??
        'User';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back,',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '$userName 👋',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context, BudgetProvider provider) {
    double totalOutstanding = 0;
    double totalRevenues = 0;
    double totalExpenses = 0;
    double totalBudget = 0;

    for (var p in provider.projects) {
      totalRevenues += p.totalReceived;
      totalExpenses += p.totalExpenses;
      totalBudget += p.budget;
      for (var payable in p.payables) {
        final paid = p.expenses
            .where((e) => e.payableId == payable.id)
            .fold(0.0, (s, e) => s + e.amount);
        totalOutstanding += (payable.totalAmount - paid);
      }
    }

    final cashBalance = totalRevenues - totalExpenses;
    final isPositive = cashBalance >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main Balance Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPositive
                    ? [
                        const Color(0xFF0F2027),
                        const Color(0xFF203A43),
                        const Color(0xFF2C5364),
                      ]
                    : [const Color(0xFF4B1248), const Color(0xFFF0C27B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (isPositive ? Colors.blueGrey : Colors.deepPurple)
                      .withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Company Cash Balance',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: isPositive
                          ? Colors.greenAccent
                          : Colors.orangeAccent,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyUtils.formatInr(cashBalance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Revenue: ${CurrencyUtils.formatInr(totalRevenues)}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      'Spent: ${CurrencyUtils.formatInr(totalExpenses)}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick Stats Row
          Row(
            children: [
              Expanded(
                child: _buildMiniStatCard(
                  context,
                  'Active Projects',
                  provider.projects.length.toString(),
                  Icons.business,
                  Colors.indigo,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStatCard(
                  context,
                  'Total Budgets',
                  CurrencyUtils.formatInr(totalBudget),
                  Icons.account_balance,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStatCard(
                  context,
                  'To Pay',
                  CurrencyUtils.formatInr(totalOutstanding),
                  Icons.receipt_long,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionItem(
                context,
                'New Project',
                Icons.add_business_outlined,
                Colors.indigo,
                () => _showAddProjectDialog(context),
              ),
              _buildActionItem(
                context,
                'Add Payment',
                Icons.account_balance_outlined,
                Colors.teal,
                () => _showAddRevenueDialog(context),
              ),
              _buildActionItem(
                context,
                'Add Expense',
                Icons.shopping_bag_outlined,
                Colors.orange,
                () => _showAddExpenseDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.28,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, BudgetProvider provider) {
    final allItems = provider.projects.expand((p) {
      return [
        ...p.expenses.map(
          (e) => (
            title: e.formattedCategory,
            amount: e.amount,
            isRevenue: false,
            date: e.date,
            projectName: p.name,
            original: e,
          ),
        ),
        ...p.revenues.map(
          (r) => (
            title: "Customer Payment",
            amount: r.amount,
            isRevenue: true,
            date: r.date,
            projectName: p.name,
            original: r,
          ),
        ),
      ];
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    final recent = allItems.take(3).toList();

    if (recent.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              TextButton(
                onPressed: () => context.go('/expenses'),
                child: const Text('View All'),
              ),
            ],
          ),
          ...recent.map(
            (item) => Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              color: Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                onTap: () => TransactionDetailsDialog.show(
                  context,
                  item.original,
                  item.projectName,
                ),
                dense: true,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (item.isRevenue ? Colors.blue : Colors.red)
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.isRevenue ? Icons.south_west : Icons.north_east,
                    size: 16,
                    color: item.isRevenue ? Colors.blue : Colors.red,
                  ),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  item.projectName,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                trailing: Text(
                  CurrencyUtils.formatInr(item.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: item.isRevenue ? Colors.blue : Colors.red,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _loadFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmer(context);
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading data!'));
          }

          return Consumer2<BudgetProvider, ContactsProvider>(
            builder: (context, budgetProvider, contactsProvider, child) {
              final projects = budgetProvider.projects;

              return RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    budgetProvider.fetchAndSetProjects(),
                    contactsProvider.fetchContacts(),
                  ]);
                },
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 100,
                      floating: true,
                      pinned: true,
                      elevation: 0,
                      backgroundColor: Theme.of(
                        context,
                      ).scaffoldBackgroundColor,
                      flexibleSpace: FlexibleSpaceBar(
                        titlePadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        title: const Text(
                          'Dashboard',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ).animate().fadeIn(duration: 500.ms),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(
                            Icons.settings_outlined,
                            color: Colors.black,
                          ),
                          onPressed: () => context.go('/settings'),
                        ),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: _buildHeader(
                        context,
                      ).animate().fadeIn().slideX(begin: -0.1, end: 0),
                    ),
                    SliverToBoxAdapter(
                      child: const WeatherWidget().animate().fadeIn(
                        delay: 50.ms,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildSummarySection(
                        context,
                        budgetProvider,
                      ).animate().fadeIn(delay: 100.ms),
                    ),
                    SliverToBoxAdapter(
                      child: _buildQuickActions(
                        context,
                      ).animate().fadeIn(delay: 200.ms),
                    ),
                    SliverToBoxAdapter(
                      child: _buildRecentActivity(
                        context,
                        budgetProvider,
                      ).animate().fadeIn(delay: 300.ms),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          'Active Projects',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    if (projects.isEmpty)
                      const SliverFillRemaining(
                        child: Center(
                          child: Text('No projects yet. Tap + to start!'),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((ctx, index) {
                            final project = projects[index];
                            return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  elevation: 2,
                                  shadowColor: Colors.black12,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: InkWell(
                                    onTap: () => context.go(
                                      '/projects/details/${project.id}',
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Hero(
                                                tag:
                                                    'project_icon_${project.id}',
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    10,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    Icons.business_outlined,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Hero(
                                                      tag:
                                                          'project_name_${project.id}',
                                                      child: Material(
                                                        type: MaterialType
                                                            .transparency,
                                                        child: Text(
                                                          project.name,
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 18,
                                                              ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      'Budget: ${CurrencyUtils.formatInr(project.budget)}',
                                                      style: TextStyle(
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(
                                                Icons.chevron_right,
                                                color: Colors.grey,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              _buildMiniStat(
                                                'Spent',
                                                project.totalExpenses,
                                                Colors.red,
                                              ),
                                              _buildMiniStat(
                                                'Remaining',
                                                project.remainingBudget,
                                                project.remainingBudget >= 0
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                              _buildHealthBadge(project),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: LinearProgressIndicator(
                                              value: project.budget > 0
                                                  ? (project.totalExpenses /
                                                            project.budget)
                                                        .clamp(0.0, 1.0)
                                                  : 0.0,
                                              minHeight: 6,
                                              backgroundColor:
                                                  Colors.grey.shade200,
                                              color:
                                                  project.remainingBudget >= 0
                                                  ? Theme.of(
                                                      context,
                                                    ).colorScheme.primary
                                                  : Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: (400 + index * 50).ms)
                                .slideY(begin: 0.1, end: 0);
                          }, childCount: projects.length),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'ai_chat_fab_dashboard',
            onPressed: () => context.push('/chat'),
            backgroundColor: Colors.indigo,
            tooltip: 'AI Chat Assistant',
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'dashboard_add_fab',
            onPressed: () => _showAddProjectDialog(context),
            child: const Icon(Icons.add),
          ).animate().scale(delay: 500.ms),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        Text(
          CurrencyUtils.formatInr(amount),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 100), // Approximate SliverAppBar height
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerLoading.rectangular(height: 14, width: 100),
                const SizedBox(height: 8),
                const ShimmerLoading.rectangular(height: 30, width: 150),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(child: ShimmerLoading.rounded(height: 100)),
                const SizedBox(width: 12),
                Expanded(child: ShimmerLoading.rounded(height: 100)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                3,
                (index) => SizedBox(
                  width: MediaQuery.of(context).size.width * 0.28,
                  child: ShimmerLoading.rounded(height: 80, borderRadius: 16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ShimmerLoading.rounded(height: 140, borderRadius: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthBadge(Project project) {
    final percent = project.budget > 0
        ? (project.totalExpenses / project.budget)
        : 0;
    String label;
    Color color;
    if (percent < 0.8) {
      label = 'Healthy';
      color = Colors.green;
    } else if (percent <= 1.0) {
      label = 'Warning';
      color = Colors.orange;
    } else {
      label = 'Over Budget';
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
