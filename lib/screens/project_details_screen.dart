import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:alray_app/models/project.dart';
import 'package:alray_app/providers/budget_provider.dart';
import 'package:alray_app/providers/auth_provider.dart';
import 'package:alray_app/widgets/add_expense_dialog.dart';
import 'package:alray_app/widgets/add_revenue_dialog.dart';
import 'package:alray_app/widgets/edit_project_dialog.dart';
import 'package:alray_app/widgets/add_payable_dialog.dart';
import 'package:alray_app/widgets/add_partial_payment_dialog.dart';
import 'package:alray_app/models/construction_entry.dart';
import 'package:alray_app/models/payable.dart';
import 'package:alray_app/models/snag_item.dart';
import 'package:alray_app/utils/currency_utils.dart';
import 'package:alray_app/widgets/add_snag_item_dialog.dart';
import 'package:alray_app/widgets/transaction_details_dialog.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:alray_app/widgets/project_tabs/material_tab.dart';
import 'package:alray_app/widgets/project_tabs/labour_tab.dart';
import 'package:alray_app/widgets/project_tabs/specialized_tab.dart';
import 'package:alray_app/widgets/ai_risk_dialog.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailsScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  String get projectId => widget.projectId;

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

  void _showAiRiskAnalysis(BuildContext context, Project project) {
    showDialog(
      context: context,
      builder: (ctx) => AiRiskDialog(project: project),
    );
  }

  void _confirmDeleteProject(
    BuildContext context,
    BudgetProvider bp,
    String projectName,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project?'),
        content: Text(
          'Are you sure you want to delete "$projectName"? All associated expenses and payments will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to dashboard
              bp.removeProject(projectId); // Fire and forget
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddMilestoneDialog(BuildContext context, BudgetProvider bp) {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Milestone'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Milestone Title',
            hintText: 'e.g., Foundation Completed',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                bp.addMilestone(projectId, title);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddPayableDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AddPayableDialog(projectId: projectId),
    );
  }

  void _showAddSnagItemDialog(BuildContext context, [SnagItem? existingSnag]) {
    showDialog(
      context: context,
      builder: (ctx) =>
          AddSnagItemDialog(projectId: projectId, existingSnag: existingSnag),
    );
  }

  void _showAddPartialPaymentDialog(
    BuildContext context,
    Payable payable,
    double remaining,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AddPartialPaymentDialog(
        payable: payable,
        remainingBalance: remaining,
      ),
    );
  }

  Icon _getCategoryIcon(dynamic item) {
    if (item is ConstructionEntry) {
      if (item.transactionType == TransactionType.credit) {
        return const Icon(Icons.handshake_outlined, color: Colors.blue);
      }
      if (item.categoryId.endsWith('-M') ||
          item.categoryId == EntryCategory.otherMiscMaterials) {
        return const Icon(Icons.inventory_2, color: Colors.green);
      } else if (item.categoryId.endsWith('-L') ||
          item.categoryId == EntryCategory.planApproval) {
        return const Icon(Icons.construction, color: Colors.orange);
      }
    }
    return const Icon(Icons.more_horiz, color: Colors.grey);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text('Project Details'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Material (-M)'),
              Tab(text: 'Labour (-L)'),
              Tab(text: 'Specialized'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Export PDF Report',
              onPressed: () => _generatePdfReport(context, projectId),
            ),
            Consumer<BudgetProvider>(
              builder: (ctx, bp, _) {
                final idx = bp.projects.indexWhere((p) => p.id == projectId);
                if (idx == -1) return const SizedBox.shrink();
                final project = bp.projects[idx];
                return Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit project',
                      onPressed: () => _showEditProjectDialog(ctx, project),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Delete project',
                      onPressed: () =>
                          _confirmDeleteProject(context, bp, project.name),
                    ),
                  ],
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
            final List<ConstructionEntry> allTransactions = [...project.entries]
              ..sort((a, b) => b.date.compareTo(a.date));

            final List<ConstructionEntry> transactions = allTransactions
                .where((item) => item.transactionType == TransactionType.credit)
                .toList();

            final pendingPayables = project.payables.where((p) {
              final paidAmount = project.entries
                  .where((e) => e.payableId == p.id)
                  .fold(0.0, (total, e) => total + e.amount);
              return (p.totalAmount - paidAmount) > 0;
            }).toList();

            return TabBarView(
              children: [
                _buildOverviewTab(
                  context,
                  budgetProvider,
                  project,
                  transactions,
                  pendingPayables,
                ),
                MaterialTab(project: project),
                LabourTab(project: project),
                SpecializedTab(project: project),
              ],
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
      ),
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    BudgetProvider budgetProvider,
    Project project,
    List<ConstructionEntry> transactions,
    List<Payable> pendingPayables,
  ) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Summary Card
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Hero(
                            tag: 'project_icon_$projectId',
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.business_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Hero(
                              tag: 'project_name_$projectId',
                              child: Material(
                                type: MaterialType.transparency,
                                child: Text(
                                  project.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Budget:'),
                          Text(
                            CurrencyUtils.formatInr(project.budget),
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Pending:'),
                          Text(
                            CurrencyUtils.formatInr(
                              project.pendingPayablesTotal,
                            ),
                            style: const TextStyle(
                              color: Colors.orange,
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
                            'Remaining:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              _buildHealthBadge(project),
                              const SizedBox(width: 8),
                              Text(
                                CurrencyUtils.formatInr(project.cashOnHand),
                                style: TextStyle(
                                  color: project.cashOnHand >= 0
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
                      if (project.cashOnHand < 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Cash deficit of ${CurrencyUtils.formatInr(project.cashOnHand.abs())}. Notify client.',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              if (project.customerPhone != null &&
                                  project.customerPhone!.isNotEmpty)
                                GestureDetector(
                                  onTap: () async {
                                    final shortage = CurrencyUtils.formatInr(
                                      project.cashOnHand.abs(),
                                    );
                                    final encodedText = Uri.encodeComponent(
                                      'Dear client, the project "${project.name}" has a cash deficit of $shortage. To proceed to the next step, please transfer the required funds at the earliest. Thank you.',
                                    );
                                    final uri = Uri.parse(
                                      'https://wa.me/${project.customerPhone}?text=$encodedText',
                                    );
                                    try {
                                      await launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    } catch (_) {}
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF25D366),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.send,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'WhatsApp',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ).animate().fade().slideY(begin: -0.1, end: 0),
              const SizedBox(height: 16),

              // --- NEW: Timeline & Risk ---
              if (project.startDate != null && project.endDate != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Timeline & Risk',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Row(
                              children: [
                                _buildRiskBadge(project.riskLevel),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.smart_toy,
                                    color: Colors.indigo,
                                  ),
                                  onPressed: () =>
                                      _showAiRiskAnalysis(context, project),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Start: ${DateFormat.yMMMd().format(project.startDate!)}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'End: ${DateFormat.yMMMd().format(project.endDate!)}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: project.timeElapsedPercentage,
                            minHeight: 12,
                            backgroundColor: Colors.grey.shade200,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${(project.timeElapsedPercentage * 100).toStringAsFixed(1)}% Time Elapsed',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        if (project.milestones.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 4),
                          Builder(
                            builder: (ctx) {
                              final total = project.milestones.length;
                              final completed = project.milestones
                                  .where((m) => m.isCompleted)
                                  .length;
                              final pct = total > 0 ? completed / total : 0.0;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Milestones',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        '$completed / $total  (${(pct * 100).toStringAsFixed(0)}%)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: pct == 1.0
                                              ? Colors.green
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: pct,
                                      minHeight: 8,
                                      backgroundColor: Colors.grey.shade200,
                                      color: pct == 1.0
                                          ? Colors.green
                                          : Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          ...project.milestones.map((m) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    m.isCompleted
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    size: 18,
                                    color: m.isCompleted
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      m.title,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: m.isCompleted
                                            ? Colors.grey
                                            : null,
                                        decoration: m.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                        decorationColor: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  if (m.isCompleted)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.green.shade200,
                                        ),
                                      ),
                                      child: Text(
                                        'Completed',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.orange.shade200,
                                        ),
                                      ),
                                      child: Text(
                                        'Pending',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.orange.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ).animate().fade().slideY(begin: -0.1, end: 0, delay: 50.ms),
              if (project.startDate != null && project.endDate != null)
                const SizedBox(height: 16),

              // Milestones Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Project Milestones',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            onPressed: () => _showAddMilestoneDialog(
                              context,
                              budgetProvider,
                            ),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add'),
                          ),
                        ],
                      ),
                      const Divider(),
                      if (project.milestones.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: Text(
                              'No milestones added yet.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: project.milestones.length,
                          itemBuilder: (ctx, i) {
                            final m = project.milestones[i];
                            return CheckboxListTile(
                              title: Text(
                                m.title,
                                style: TextStyle(
                                  decoration: m.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: m.isCompleted ? Colors.grey : null,
                                ),
                              ),
                              value: m.isCompleted,
                              onChanged: (val) async {
                                if (val != null) {
                                  final triggeredCall = await budgetProvider
                                      .toggleMilestone(projectId, m.id, val);
                                  if (triggeredCall && ctx.mounted) {
                                    if (project.customerPhone != null &&
                                        project.customerPhone!.isNotEmpty) {
                                      final encodedText = Uri.encodeComponent(
                                        'Capital Call: ${project.name}\n\nThe milestone "${m.title}" has been completed. Please submit the next tranche of funding.',
                                      );
                                      final Uri whatsappUri = Uri.parse(
                                        'https://wa.me/${project.customerPhone}?text=$encodedText',
                                      );
                                      try {
                                        await launchUrl(
                                          whatsappUri,
                                          mode: LaunchMode.externalApplication,
                                        );
                                      } catch (e) {
                                        debugPrint(
                                          'Could not launch WhatsApp: $e',
                                        );
                                      }
                                    }

                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: const [
                                              Icon(
                                                Icons.monetization_on,
                                                color: Colors.yellow,
                                              ),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'Milestone completed! Capital Call notification sent to investors.',
                                                ),
                                              ),
                                            ],
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          duration: const Duration(seconds: 4),
                                          backgroundColor: Colors.blue.shade900,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              secondary: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                onPressed: () => budgetProvider.removeMilestone(
                                  projectId,
                                  m.id,
                                ),
                              ),
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ).animate().fade(delay: 200.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 24),

              // Payables Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Accounts Payable',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            onPressed: () => _showAddPayableDialog(context),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add'),
                          ),
                        ],
                      ),
                      const Divider(),
                      if (project.payables.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: Text(
                              'No outstanding payables.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: project.payables.length,
                          itemBuilder: (ctx, i) {
                            final p = project.payables[i];
                            final paidAmount = project.entries
                                .where((e) => e.payableId == p.id)
                                .fold(0.0, (total, e) => total + e.amount);
                            final remaining = p.totalAmount - paidAmount;
                            final isFullyPaid = remaining <= 0;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                p.vendorName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: isFullyPaid
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: isFullyPaid ? Colors.grey : null,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.description),
                                  Text(
                                    'Remaining: ${CurrencyUtils.formatInr(remaining > 0 ? remaining : 0)} of ${CurrencyUtils.formatInr(p.totalAmount)}',
                                    style: TextStyle(
                                      color: isFullyPaid
                                          ? Colors.grey
                                          : Colors.red,
                                      fontWeight: isFullyPaid
                                          ? FontWeight.normal
                                          : FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isFullyPaid)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.payment,
                                        color: Colors.green,
                                      ),
                                      tooltip: 'Record Payment',
                                      onPressed: () =>
                                          _showAddPartialPaymentDialog(
                                            context,
                                            p,
                                            remaining,
                                          ),
                                    ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () => budgetProvider
                                        .removePayable(projectId, p.id),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ).animate().fade(delay: 250.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 24),

              // Snag List Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Snag List / Defects',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            onPressed: () => _showAddSnagItemDialog(context),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add'),
                          ),
                        ],
                      ),
                      const Divider(),
                      if (project.snagItems.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: Text(
                              'No snags reported.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: project.snagItems.length,
                          itemBuilder: (ctx, i) {
                            final snag = project.snagItems[i];
                            final isResolved =
                                snag.status == SnagStatus.resolved;

                            // Priority Color
                            Color priorityColor;
                            switch (snag.priority) {
                              case SnagPriority.low:
                                priorityColor = Colors.green;
                                break;
                              case SnagPriority.medium:
                                priorityColor = Colors.orange;
                                break;
                              case SnagPriority.high:
                                priorityColor = Colors.red;
                                break;
                            }

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              onTap: () =>
                                  _showAddSnagItemDialog(context, snag),
                              title: Text(
                                snag.description,
                                style: TextStyle(
                                  decoration: isResolved
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: isResolved ? Colors.grey : null,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: priorityColor.withValues(
                                        alpha: isResolved ? 0.1 : 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      snag.priority.name.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isResolved
                                            ? Colors.grey
                                            : priorityColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    snag.status == SnagStatus.inProgress
                                        ? 'IN PROGRESS'
                                        : snag.status.name.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isResolved
                                          ? Colors.grey
                                          : Colors.blueGrey,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Checkbox(
                                value: isResolved,
                                onChanged: (val) {
                                  if (val != null) {
                                    final updatedSnag = SnagItem(
                                      id: snag.id,
                                      projectId: snag.projectId,
                                      description: snag.description,
                                      status: val
                                          ? SnagStatus.resolved
                                          : SnagStatus.inProgress,
                                      priority: snag.priority,
                                      createdAt: snag.createdAt,
                                      resolvedAt: val ? DateTime.now() : null,
                                    );
                                    budgetProvider.updateSnagItem(updatedSnag);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ).animate().fade(delay: 300.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 24),

              // End Snags Section
              // Transactions header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Income Tracker',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ]),
          ),
        ),
        transactions.isEmpty
            ? SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: const Center(
                    child: Text('No transactions for this project.'),
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((ctx, index) {
                    final item = transactions[index];

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
                                item.transactionType == TransactionType.credit
                                    ? "Customer Payment"
                                    : item.categoryId,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                item.transactionType == TransactionType.credit
                                    ? item.description
                                    : item.categoryId.endsWith('-M') ||
                                          item.categoryId ==
                                              EntryCategory.otherMiscMaterials
                                    ? DateFormat.yMMMd().format(item.date)
                                    : '${item.description}\n${DateFormat.yMMMd().format(item.date)}',
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    CurrencyUtils.formatInr(item.amount),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          item.transactionType ==
                                              TransactionType.credit
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
                                          title: Text('Delete Transaction?'),
                                          content: const Text(
                                            'Are you sure you want to delete this transaction? This action cannot be undone.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                budgetProvider.removeEntry(
                                                  item.id,
                                                );
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
                  }, childCount: transactions.length),
                ),
              ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 8,
            ),
            child: Text(
              'Pending Payments',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        pendingPayables.isEmpty
            ? SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: const Center(
                    child: Text('No pending payments for this project.'),
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((ctx, index) {
                    final p = pendingPayables[index];
                    final paidAmount = project.entries
                        .where((e) => e.payableId == p.id)
                        .fold(0.0, (total, e) => total + e.amount);
                    final remaining = p.totalAmount - paidAmount;

                    return Card(
                          child: ListTile(
                            title: Text(
                              p.vendorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(p.description),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Total: ${CurrencyUtils.formatInr(p.totalAmount)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  'Pending: ${CurrencyUtils.formatInr(remaining)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .animate()
                        .fade(delay: (200 + index * 30).ms)
                        .slideY(begin: 0.1, end: 0);
                  }, childCount: pendingPayables.length),
                ),
              ),
      ],
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

  Future<void> _generatePdfReport(
    BuildContext context,
    String projectId,
  ) async {
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final project = budgetProvider.projects.firstWhere(
      (p) => p.id == projectId,
    );

    final userName =
        authProvider.user?.displayName ??
        authProvider.user?.email?.split('@').first ??
        'User';

    String safeCurrency(double amount) {
      return CurrencyUtils.formatInr(amount).replaceAll('₹', 'Rs. ');
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Project Report: ${project.name}',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(DateFormat.yMMMd().format(DateTime.now())),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Prepared by: $userName',
              style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'Summary',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Budget:'),
                pw.Text(safeCurrency(project.budget)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Received:'),
                pw.Text(safeCurrency(project.totalReceived)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Spent:'),
                pw.Text(safeCurrency(project.totalSpent)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Remaining:'),
                pw.Text(
                  safeCurrency(project.cashOnHand),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            pw.SizedBox(height: 30),
            pw.Text(
              'Transactions',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Divider(),
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Description', 'Category', 'Type', 'Amount'],
              data: [
                ...project.entries
                    .where((e) => e.transactionType == TransactionType.credit)
                    .map(
                      (r) => [
                        DateFormat.yMMMd().format(r.date),
                        r.description,
                        r.categoryId,
                        'IN',
                        safeCurrency(r.amount),
                      ],
                    ),
                ...project.entries
                    .where((e) => e.transactionType == TransactionType.expense)
                    .map(
                      (e) => [
                        DateFormat.yMMMd().format(e.date),
                        e.description,
                        e.categoryId,
                        'OUT',
                        safeCurrency(e.amount),
                      ],
                    ),
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${project.name}_Report.pdf',
    );
  }

  Widget _buildRiskBadge(String riskLevel) {
    Color color;
    switch (riskLevel) {
      case 'Low':
        color = Colors.green;
        break;
      case 'Medium':
        color = Colors.orange;
        break;
      case 'High':
      case 'Critical (Overdue)':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '$riskLevel Risk',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
