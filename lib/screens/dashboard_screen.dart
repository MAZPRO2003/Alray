import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alray_app/providers/budget_provider.dart';
import 'package:alray_app/providers/contacts_provider.dart';
import 'package:alray_app/providers/attendance_provider.dart';
import 'package:alray_app/models/construction_entry.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      await Future.wait([
        Provider.of<BudgetProvider>(
          context,
          listen: false,
        ).fetchAndSetProjects(),
        Provider.of<ContactsProvider>(context, listen: false).fetchContacts(),
        Provider.of<AttendanceProvider>(
          context,
          listen: false,
        ).fetchAttendances(),
      ]);
    });
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000)
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
    return '₹${amount.toInt()}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Consumer3<BudgetProvider, ContactsProvider, AttendanceProvider>(
      builder: (context, budgetProvider, contactsProvider, attendanceProvider, _) {
        // ── This Week Calculations ─────────────────────────────────────────
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekStartDay = DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day,
        );

        final allEntries = budgetProvider.allEntries;
        final weekEntries = allEntries
            .where((e) => e.date.isAfter(weekStartDay))
            .toList();

        final weekIn = weekEntries
            .where((e) => e.transactionType == TransactionType.credit)
            .fold(0.0, (s, e) => s + e.amount);
        final weekOut = weekEntries
            .where((e) => e.transactionType == TransactionType.expense)
            .fold(0.0, (s, e) => s + e.amount);
        final weekNet = weekIn - weekOut;

        // ── Active projects ────────────────────────────────────────────────
        final projects = budgetProvider.projects;
        final activeProjects = projects.where((p) {
          if (p.endDate == null) return true;
          return p.endDate!.isAfter(now);
        }).toList();

        // ── Today's attendance count ───────────────────────────────────────
        final todayStr = DateFormat('yyyy-MM-dd').format(now);
        int todayWorkers = 0;
        for (final att in attendanceProvider.attendances) {
          if (DateFormat('yyyy-MM-dd').format(att.date) == todayStr) {
            todayWorkers +=
                att.presentWorkerIds.length +
                att.workerCounts.values.fold<int>(0, (s, c) => s + c);
          }
        }

        // ── Activity feed ─────────────────────────────────────────────────
        final sortedEntries = List<ConstructionEntry>.from(allEntries)
          ..sort((a, b) => b.date.compareTo(a.date));
        final recentEntries = sortedEntries.take(12).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                budgetProvider.fetchAndSetProjects(),
                contactsProvider.fetchContacts(),
                attendanceProvider.fetchAttendances(),
              ]);
            },
            child: CustomScrollView(
              slivers: [
                // ── AppBar ────────────────────────────────────────────────
                SliverAppBar(
                  pinned: true,
                  floating: false,
                  backgroundColor: primaryColor,
                  expandedHeight: 0,
                  toolbarHeight: 64,
                  title: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alray Associates',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            DateFormat('EEEE, d MMM').format(now),
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                      ),
                      tooltip: 'AI Assistant',
                      onPressed: () => context.push('/chat'),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),

                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── This Week Banner ──────────────────────────────
                      _buildThisWeekBanner(
                        weekIn,
                        weekOut,
                        weekNet,
                        primaryColor,
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

                      // ── Quick Stats Row ───────────────────────────────
                      _buildQuickStats(
                        activeProjects.length,
                        todayWorkers,
                        contactsProvider.contacts.length,
                        primaryColor,
                      ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

                      // ── Section: Active Projects ──────────────────────
                      if (activeProjects.isNotEmpty) ...[
                        _sectionHeader(
                          'Active Projects',
                          'View All',
                          () => context.go('/projects'),
                        ),
                        SizedBox(
                          height: 130,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: activeProjects.take(5).length,
                            itemBuilder: (ctx, i) {
                              final project = activeProjects[i];
                              final health = _getHealthScore(
                                project.remainingBudget,
                                project.budget,
                                project.timeElapsedPercentage,
                              );
                              return _buildProjectChip(
                                project.name,
                                health,
                                () {
                                  context.push(
                                    '/projects/details/${project.id}',
                                  );
                                },
                              ).animate().fadeIn(
                                delay: Duration(milliseconds: 150 * i),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── Section: Activity Feed ────────────────────────
                      _sectionHeader('Recent Activity', '', null),
                      if (recentEntries.isEmpty)
                        _buildEmptyActivity()
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: recentEntries.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, indent: 56),
                          itemBuilder: (ctx, i) {
                            final entry = recentEntries[i];
                            return _buildActivityTile(entry).animate().fadeIn(
                              delay: Duration(milliseconds: 50 * i),
                            );
                          },
                        ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThisWeekBanner(
    double weekIn,
    double weekOut,
    double weekNet,
    Color primaryColor,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THIS WEEK',
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatCurrency(weekNet.abs()),
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            weekNet >= 0
                ? 'Net positive this week 📈'
                : 'Net negative this week 📉',
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _weekStatPill(
                  'Money In',
                  _formatCurrency(weekIn),
                  Colors.greenAccent.shade100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _weekStatPill(
                  'Money Out',
                  _formatCurrency(weekOut),
                  Colors.redAccent.shade100,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weekStatPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white60, fontSize: 10),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(
    int projects,
    int workers,
    int contacts,
    Color primaryColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _quickStatCard(
            projects.toString(),
            'Projects',
            Icons.business_center_outlined,
            const Color(0xFF6750A4),
          ),
          const SizedBox(width: 12),
          _quickStatCard(
            workers.toString(),
            'Workers Today',
            Icons.how_to_reg_outlined,
            const Color(0xFF4CAF50),
          ),
          const SizedBox(width: 12),
          _quickStatCard(
            contacts.toString(),
            'Contacts',
            Icons.people_outline,
            const Color(0xFF03A9F4),
          ),
        ],
      ),
    );
  }

  Widget _quickStatCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String action, VoidCallback? onAction) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          if (action.isNotEmpty && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                action,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProjectChip(String name, String health, VoidCallback onTap) {
    final color = health == 'Great'
        ? Colors.green
        : health == 'Good'
        ? Colors.blue
        : health == 'At Risk'
        ? Colors.orange
        : Colors.red;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                health,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  String _getHealthScore(
    double remainingBudget,
    double budget,
    double timeElapsed,
  ) {
    if (budget <= 0) return 'Unknown';
    final budgetRatio = remainingBudget / budget;
    if (budgetRatio > 0.5 && timeElapsed < 0.7) return 'Great';
    if (budgetRatio > 0.2) return 'Good';
    if (budgetRatio > 0) return 'At Risk';
    return 'Critical';
  }

  Widget _buildActivityTile(ConstructionEntry entry) {
    final isCredit = entry.transactionType == TransactionType.credit;
    final color = isCredit ? Colors.green : Colors.red;
    final icon = isCredit
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        entry.description.isEmpty ? entry.categoryId : entry.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        DateFormat('d MMM yyyy').format(entry.date),
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Text(
        '${isCredit ? '+' : '-'}₹${entry.amount.toInt()}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildEmptyActivity() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'No activity yet. Start by adding a project!',
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
