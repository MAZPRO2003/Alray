import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:alray_app/providers/budget_provider.dart';
import 'package:alray_app/utils/currency_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:alray_app/models/expense.dart';
import 'package:alray_app/models/revenue.dart';
import 'package:alray_app/models/project.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BudgetProvider>(context);

    // Aggregate Data
    final projects = provider.projects;
    final expenses = provider.expenses;
    final revenues = provider.revenues;

    final totalBudget = projects.fold(0.0, (total, p) => total + p.budget);
    final totalSpent = expenses.fold(0.0, (total, e) => total + e.amount);
    final totalRevenue = revenues.fold(0.0, (total, r) => total + r.amount);

    double totalOutstanding = 0;
    for (var p in projects) {
      for (var payable in p.payables) {
        final paid = p.expenses
            .where((e) => e.payableId == payable.id)
            .fold(0.0, (s, e) => s + e.amount);
        totalOutstanding += (payable.totalAmount - paid);
      }
    }

    final double profitMargin = totalRevenue > 0
        ? ((totalRevenue - totalSpent) / totalRevenue) * 100
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      floatingActionButton: FloatingActionButton(
        heroTag: 'ai_chat_fab_analytics',
        onPressed: () => context.push('/chat'),
        backgroundColor: Colors.indigo,
        tooltip: 'AI Chat Assistant',
        child: const Icon(Icons.smart_toy, color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              title: const Text(
                'Insights & Analytics',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(duration: 500.ms),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMainGradientCard(
                    context,
                    totalRevenue,
                    totalSpent,
                    profitMargin,
                  ),
                  const SizedBox(height: 16),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Cash on Hand',
                            CurrencyUtils.formatInr(totalRevenue - totalSpent),
                            Icons.account_balance_wallet,
                            Colors.teal,
                          ).animate().fade().slideY(begin: 0.15),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Avg Spent / Project',
                            projects.isNotEmpty
                                ? CurrencyUtils.formatInr(
                                    totalSpent / projects.length,
                                  )
                                : '₹0',
                            Icons.analytics,
                            Colors.indigo,
                          ).animate().fade().slideY(begin: 0.15),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Portfolio Budget',
                            CurrencyUtils.formatInr(totalBudget),
                            Icons.account_balance,
                            Colors.blue,
                          ).animate().fade().slideY(begin: 0.2),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Avg Project Budget',
                            projects.isNotEmpty
                                ? CurrencyUtils.formatInr(
                                    totalBudget / projects.length,
                                  )
                                : '₹0',
                            Icons.pie_chart,
                            Colors.deepOrange,
                          ).animate().fade().slideY(begin: 0.2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Active',
                            projects.length.toString(),
                            Icons.business,
                            Colors.purple,
                          ).animate().fade().slideY(begin: 0.25),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Payables',
                            CurrencyUtils.formatInr(totalOutstanding),
                            Icons.receipt_long,
                            Colors.orange,
                          ).animate().fade().slideY(begin: 0.25),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildStatCard(
                    context,
                    'Profit Margin',
                    '${profitMargin.toStringAsFixed(1)}%',
                    Icons.trending_up,
                    Colors.green,
                  ).animate().fade().slideY(begin: 0.3),
                  const SizedBox(height: 24),
                  _buildBudgetProgressSection(context, totalBudget, totalSpent),
                  const SizedBox(height: 24),
                  _buildSpendByCategoryChart(context, expenses),
                  const SizedBox(height: 24),
                  _buildMonthlyCashFlow(context, expenses, revenues),
                  const SizedBox(height: 24),
                  _buildTopProjects(context, projects),
                  const SizedBox(height: 24),
                  _buildRecentTransactions(context, expenses, revenues),
                  const SizedBox(height: 80), // Padding for bottom nav
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainGradientCard(
    BuildContext context,
    double revenue,
    double spent,
    double margin,
  ) {
    final netIncome = revenue - spent;
    final isPositive = netIncome >= 0;

    return Container(
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
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? Colors.blueGrey : Colors.deepPurple)
                .withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
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
                'Net Portfolio Income',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${isPositive ? '+' : ''}${margin.toStringAsFixed(1)}% Margin',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyUtils.formatInr(netIncome),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildMiniGlassCard(
                  'Total Revenue',
                  revenue,
                  Icons.arrow_upward,
                  Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniGlassCard(
                  'Total Spent',
                  spent,
                  Icons.arrow_downward,
                  Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fade().slideY(begin: 0.1);
  }

  Widget _buildMiniGlassCard(
    String title,
    double amount,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyUtils.formatInr(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendByCategoryChart(
    BuildContext context,
    List<Expense> expenses,
  ) {
    if (expenses.isEmpty) return const SizedBox.shrink();

    final categoryMap = <String, double>{
      'Workers': 0.0,
      'Materials': 0.0,
      'Other': 0.0,
    };

    for (var e in expenses) {
      if (e.category == ExpenseCategory.contractor) {
        categoryMap['Workers'] = categoryMap['Workers']! + e.amount;
      } else if (e.category == ExpenseCategory.material) {
        categoryMap['Materials'] = categoryMap['Materials']! + e.amount;
      } else {
        categoryMap['Other'] = categoryMap['Other']! + e.amount;
      }
    }

    final total = expenses.fold(0.0, (t, e) => t + e.amount);

    final sections = <PieChartSectionData>[];
    if (categoryMap['Workers']! > 0) {
      sections.add(
        _buildPieSection(categoryMap['Workers']!, total, Colors.orange),
      );
    }
    if (categoryMap['Materials']! > 0) {
      sections.add(
        _buildPieSection(categoryMap['Materials']!, total, Colors.green),
      );
    }
    if (categoryMap['Other']! > 0) {
      sections.add(_buildPieSection(categoryMap['Other']!, total, Colors.blue));
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Expense Distribution',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 50,
                sections: sections,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('Workers', Colors.orange),
              _buildLegendItem('Materials', Colors.green),
              _buildLegendItem('Other', Colors.blue),
            ],
          ),
        ],
      ),
    ).animate().fade().slideY(begin: 0.4);
  }

  PieChartSectionData _buildPieSection(
    double value,
    double total,
    Color color,
  ) {
    final percentage = (value / total) * 100;
    return PieChartSectionData(
      value: value,
      title: '${percentage.toStringAsFixed(0)}%',
      color: color,
      radius: percentage > 40 ? 65 : 55, // Highlight larger sections slightly
      titleStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: 13,
      ),
      badgeWidget: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Icon(Icons.circle, size: 8, color: color),
      ),
      badgePositionPercentageOffset: .98,
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyCashFlow(
    BuildContext context,
    List<Expense> expenses,
    List<Revenue> revenues,
  ) {
    if (expenses.isEmpty && revenues.isEmpty) return const SizedBox.shrink();

    // Map to group by YYYYMM
    Map<int, double> incomeByMonth = {};
    Map<int, double> expenseByMonth = {};

    // Initialize last 6 months
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      final key = d.year * 100 + d.month;
      incomeByMonth[key] = 0.0;
      expenseByMonth[key] = 0.0;
    }

    for (var r in revenues) {
      final key = r.date.year * 100 + r.date.month;
      if (incomeByMonth.containsKey(key)) {
        incomeByMonth[key] = incomeByMonth[key]! + r.amount;
      }
    }

    for (var e in expenses) {
      final key = e.date.year * 100 + e.date.month;
      if (expenseByMonth.containsKey(key)) {
        expenseByMonth[key] = expenseByMonth[key]! + e.amount;
      }
    }

    final sortedKeys = incomeByMonth.keys.toList()..sort();
    List<BarChartGroupData> barGroups = [];
    double maxY = 0.0;

    for (int i = 0; i < sortedKeys.length; i++) {
      final key = sortedKeys[i];
      final income = incomeByMonth[key]!;
      final expense = expenseByMonth[key]!;
      if (income > maxY) maxY = income;
      if (expense > maxY) maxY = expense;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: income,
              color: Colors.greenAccent.shade400,
              width: 10,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: expense,
              color: Colors.redAccent.shade400,
              width: 10,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    if (maxY == 0) maxY = 100;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              Text(
                '6-Month Cash Flow',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Row(
                children: [
                  _buildLegendItem('In', Colors.greenAccent.shade400),
                  const SizedBox(width: 12),
                  _buildLegendItem('Out', Colors.redAccent.shade400),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.black87,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        CurrencyUtils.formatInr(rod.toY),
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= sortedKeys.length) {
                          return const SizedBox.shrink();
                        }
                        final key = sortedKeys[index];
                        final month = key % 100;
                        final monthStr = DateFormat(
                          'MMM',
                        ).format(DateTime(2020, month));
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            monthStr,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    ).animate().fade().slideY(begin: 0.5);
  }

  Widget _buildBudgetProgressSection(
    BuildContext context,
    double totalBudget,
    double totalSpent,
  ) {
    if (totalBudget == 0) return const SizedBox.shrink();

    final double progress = (totalSpent / totalBudget).clamp(0.0, 1.0);
    final isOverBudget = totalSpent > totalBudget;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              Text(
                'Budget Utilization',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: isOverBudget ? Colors.red : Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverBudget ? Colors.redAccent : Colors.blueAccent,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Spent',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    CurrencyUtils.formatInr(totalSpent),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Budget',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    CurrencyUtils.formatInr(totalBudget),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fade().slideY(begin: 0.35);
  }

  Widget _buildTopProjects(BuildContext context, List<Project> projects) {
    if (projects.isEmpty) return const SizedBox.shrink();

    final sortedProjects = List<Project>.from(projects)
      ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));

    final topProjects = sortedProjects.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Projects (By Spend)',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          ...topProjects.map((p) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.business,
                      color: Colors.deepPurple,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Budget: ${CurrencyUtils.formatInr(p.budget)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyUtils.formatInr(p.totalSpent),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().fade().slideY(begin: 0.55);
  }

  Widget _buildRecentTransactions(
    BuildContext context,
    List<Expense> expenses,
    List<Revenue> revenues,
  ) {
    if (expenses.isEmpty && revenues.isEmpty) return const SizedBox.shrink();

    // Combine and sort
    final List<dynamic> transactions = [...expenses, ...revenues];
    transactions.sort(
      (a, b) => (b.date as DateTime).compareTo(a.date as DateTime),
    );

    final recent = transactions.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Transactions',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          ...recent.map((tx) {
            final isExpense = tx is Expense;
            final amount = tx.amount;
            final date = tx.date;
            final title = isExpense ? tx.description : 'Payment Received';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (isExpense ? Colors.redAccent : Colors.greenAccent)
                          .withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExpense ? Icons.arrow_outward : Icons.arrow_downward,
                      color: isExpense ? Colors.redAccent : Colors.greenAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy').format(date),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    isExpense
                        ? '-${CurrencyUtils.formatInr(amount)}'
                        : '+${CurrencyUtils.formatInr(amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isExpense ? Colors.redAccent : Colors.greenAccent,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().fade().slideY(begin: 0.6);
  }
}
