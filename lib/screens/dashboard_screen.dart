import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alray_app/providers/budget_provider.dart';
import 'package:alray_app/providers/contacts_provider.dart';
import 'package:alray_app/widgets/add_project_dialog.dart';
import 'package:alray_app/utils/currency_utils.dart';
import 'package:alray_app/widgets/add_revenue_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
    // Fetch once when the screen is first created.
    // Storing it in a field prevents FutureBuilder from re-fetching
    // on every rebuild (which would wipe optimistic updates and loop forever).
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final contactsProvider = Provider.of<ContactsProvider>(
      context,
      listen: false,
    );
    _loadFuture = Future.wait([
      budgetProvider.fetchAndSetProjects(),
      contactsProvider.fetchContacts(),
    ]);
  }

  void _showAddProjectDialog(BuildContext context) {
    showDialog(context: context, builder: (ctx) => const AddProjectDialog());
  }

  void _showAddRevenueDialog(BuildContext context) {
    showDialog(context: context, builder: (ctx) => const AddRevenueDialog());
  }

  Widget _buildSummaryCards(BuildContext context, BudgetProvider provider) {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildCard(
            context,
            'Total Expenses',
            provider.allTimeExpenses,
            Colors.red,
            Icons.trending_down,
          ),
          const SizedBox(width: 12),
          _buildCard(
            context,
            'Monthly Return',
            provider.totalMonthlyReturn,
            provider.totalMonthlyReturn >= 0 ? Colors.green : Colors.red,
            Icons.calendar_view_month,
          ),
          const SizedBox(width: 12),
          _buildCard(
            context,
            'Yearly Return',
            provider.totalYearlyReturn,
            provider.totalYearlyReturn >= 0 ? Colors.teal : Colors.red,
            Icons.trending_up,
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            CurrencyUtils.formatInr(amount),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCallsBanner(BuildContext context) {
    return Consumer<ContactsProvider>(
      builder: (ctx, contactsProvider, _) {
        final totalCalls = contactsProvider.totalTeamCalls;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.phone_in_talk, color: Colors.orange.shade700),
              const SizedBox(width: 12),
              Text(
                'Total Team Calls Received: $totalCalls',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade900,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Projects Dashboard')),
      body: FutureBuilder(
        future: _loadFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('An error occurred loading projects!'),
            );
          }

          return Consumer<BudgetProvider>(
            builder: (context, budgetProvider, child) {
              final projects = budgetProvider.projects;

              if (projects.isEmpty) {
                return Column(
                  children: [
                    _buildSummaryCards(context, budgetProvider),
                    _buildCallsBanner(context),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'No projects yet. Add some!',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  _buildSummaryCards(context, budgetProvider),
                  _buildCallsBanner(context),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: projects.length,
                      itemBuilder: (ctx, index) {
                        final project = projects[index];
                        // ... rest of the card code
                        return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: InkWell(
                                onTap: () {
                                  context.go('/projects/details/${project.id}');
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              project.name,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleLarge,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () {
                                              budgetProvider.removeProject(
                                                project.id,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Budget:'),
                                          Text(
                                            CurrencyUtils.formatInr(
                                              project.budget,
                                            ),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Spent:'),
                                          Text(
                                            CurrencyUtils.formatInr(
                                              project.totalExpenses,
                                            ),
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Remaining:'),
                                          Text(
                                            CurrencyUtils.formatInr(
                                              project.remainingBudget,
                                            ),
                                            style: TextStyle(
                                              color:
                                                  project.remainingBudget >= 0
                                                  ? Colors.green
                                                  : Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: project.budget > 0
                                              ? (project.totalExpenses /
                                                        project.budget)
                                                    .clamp(0.0, 1.0)
                                              : 0.0,
                                          minHeight: 10,
                                          backgroundColor: Colors.grey.shade300,
                                          color: project.remainingBudget >= 0
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
                            .fade(duration: 400.ms, delay: (index * 50).ms)
                            .slideY(
                              begin: 0.1,
                              end: 0,
                              duration: 400.ms,
                              curve: Curves.easeOutQuad,
                            );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'add_revenue_fab',
            onPressed: () => _showAddRevenueDialog(context),
            backgroundColor: Colors.teal.shade100,
            child: const Icon(Icons.attach_money, color: Colors.teal),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'add_project_fab',
            onPressed: () => _showAddProjectDialog(context),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
