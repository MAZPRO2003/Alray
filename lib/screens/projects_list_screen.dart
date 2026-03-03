import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alray_app/providers/budget_provider.dart';
import 'package:alray_app/utils/currency_utils.dart';
import 'package:alray_app/widgets/add_project_dialog.dart';
import 'package:alray_app/models/project.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ProjectsListScreen extends StatefulWidget {
  const ProjectsListScreen({super.key});

  @override
  State<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends State<ProjectsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(
      () => Provider.of<BudgetProvider>(
        context,
        listen: false,
      ).fetchAndSetProjects(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddProjectDialog() {
    showDialog(context: context, builder: (ctx) => const AddProjectDialog());
  }

  String _getStatus(Project p) {
    if (p.isCompleted) return 'Completed';
    final now = DateTime.now();
    if (p.endDate != null && p.endDate!.isBefore(now)) return 'Completed';
    if (p.startDate != null && p.startDate!.isAfter(now)) return 'Upcoming';
    return 'Active';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return const Color(0xFF4CAF50);
      case 'Completed':
        return const Color(0xFF03A9F4);
      case 'Upcoming':
        return const Color(0xFFFF9800);
      default:
        return Colors.grey;
    }
  }

  Map<String, dynamic> _getHealthInfo(Project p) {
    if (p.budget <= 0)
      return {'label': 'No Budget', 'color': Colors.grey, 'score': 0.0};
    final budgetUsed = p.totalSpent / p.budget;
    final timeRatio = p.timeElapsedPercentage;
    final overrun = budgetUsed - timeRatio;

    if (p.totalSpent > p.budget)
      return {
        'label': 'Critical',
        'color': Colors.red,
        'score': budgetUsed.clamp(0.0, 1.5),
      };
    if (overrun > 0.2)
      return {
        'label': 'At Risk',
        'color': Colors.orange,
        'score': budgetUsed.clamp(0.0, 1.0),
      };
    if (budgetUsed < 0.5)
      return {
        'label': 'Healthy',
        'color': Colors.green,
        'score': budgetUsed.clamp(0.0, 1.0),
      };
    return {
      'label': 'Good',
      'color': Colors.blue,
      'score': budgetUsed.clamp(0.0, 1.0),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<BudgetProvider>(
      builder: (context, provider, _) {
        final all = provider.projects;
        final active = all.where((p) => _getStatus(p) == 'Active').toList();
        final completed = all
            .where((p) => _getStatus(p) == 'Completed')
            .toList();
        final upcoming = all.where((p) => _getStatus(p) == 'Upcoming').toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            title: Text(
              'Projects',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: theme.colorScheme.primary,
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: _showAddProjectDialog,
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              tabs: [
                Tab(text: 'Active (${active.length})'),
                Tab(text: 'Upcoming (${upcoming.length})'),
                Tab(text: 'Done (${completed.length})'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildList(active),
              _buildList(upcoming),
              _buildList(completed),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showAddProjectDialog,
            icon: const Icon(Icons.add),
            label: const Text('New Project'),
          ),
        );
      },
    );
  }

  Widget _buildList(List<Project> projects) {
    if (projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_center_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No projects here',
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _showAddProjectDialog,
              child: const Text('Add a Project'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => Provider.of<BudgetProvider>(
        context,
        listen: false,
      ).fetchAndSetProjects(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: projects.length,
        itemBuilder: (ctx, i) {
          return _buildProjectCard(projects[i], i);
        },
      ),
    );
  }

  Widget _buildProjectCard(Project project, int index) {
    final status = _getStatus(project);
    final statusColor = _getStatusColor(status);
    final health = _getHealthInfo(project);
    final healthColor = health['color'] as Color;
    final healthLabel = health['label'] as String;
    final healthScore = health['score'] as double;
    final daysLeft = project.endDate != null
        ? project.endDate!.difference(DateTime.now()).inDays
        : null;

    return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: InkWell(
            onTap: () => context.push('/projects/details/${project.id}'),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: Name + status badges
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.domain_outlined,
                          color: statusColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.name,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _badge(status, statusColor),
                                if (status != 'Completed') ...[
                                  const SizedBox(width: 8),
                                  _badge(healthLabel, healthColor),
                                ],
                                if (daysLeft != null &&
                                    status != 'Completed') ...[
                                  const SizedBox(width: 8),
                                  _badge(
                                    daysLeft >= 0
                                        ? '$daysLeft days left'
                                        : '${daysLeft.abs()}d overdue',
                                    daysLeft >= 0 ? Colors.grey : Colors.red,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Financial stats
                  Row(
                    children: [
                      _statCell(
                        'Budget',
                        CurrencyUtils.formatInr(project.budget),
                        Colors.grey.shade700,
                      ),
                      const SizedBox(width: 16),
                      _statCell(
                        'Spent',
                        CurrencyUtils.formatInr(project.totalSpent),
                        Colors.red.shade600,
                      ),
                      const SizedBox(width: 16),
                      _statCell(
                        'Remaining',
                        CurrencyUtils.formatInr(project.remainingBudget),
                        project.remainingBudget >= 0
                            ? Colors.green.shade600
                            : Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Health bar
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Budget Used',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                Text(
                                  '${(healthScore * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: healthColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: healthScore.clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor: Colors.grey.shade200,
                                color: healthColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Dates
                  if (status != 'Completed' &&
                      (project.startDate != null ||
                          project.endDate != null)) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${project.startDate != null ? DateFormat('d MMM yy').format(project.startDate!) : '?'} → ${project.endDate != null ? DateFormat('d MMM yy').format(project.endDate!) : 'Ongoing'}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 80 * index))
        .slideY(begin: 0.05);
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _statCell(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
