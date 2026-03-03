import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:alray_app/models/project.dart';
import 'package:alray_app/utils/currency_utils.dart';
import 'package:alray_app/models/labor_task.dart';
import 'package:alray_app/models/labor_payment.dart';
import 'package:provider/provider.dart';
import 'package:alray_app/providers/budget_provider.dart';
import 'package:alray_app/utils/labor_report_generator.dart';

class LabourTab extends StatefulWidget {
  final Project project;

  const LabourTab({super.key, required this.project});

  @override
  State<LabourTab> createState() => _LabourTabState();
}

class _LabourTabState extends State<LabourTab> {
  void _showAddTaskDialog() {
    final nameController = TextEditingController();
    final countController = TextEditingController();
    final roleController = TextEditingController();
    DateTime selectedStartDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Labor Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Task Name (e.g. Brickwork)',
                ),
              ),
              TextField(
                controller: countController,
                decoration: const InputDecoration(labelText: 'Laborer Count'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: roleController,
                decoration: const InputDecoration(
                  labelText: 'Role (e.g. Masons)',
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedStartDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedStartDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('dd MMM yyyy').format(selectedStartDate),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final task = LaborTask(
                  projectId: widget.project.id,
                  name: nameController.text,
                  laborerCount: int.tryParse(countController.text) ?? 0,
                  role: roleController.text,
                  startDate: selectedStartDate,
                );
                Provider.of<BudgetProvider>(
                  context,
                  listen: false,
                ).addLaborTask(task);
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateTaskProgress(LaborTask task, double value) {
    Provider.of<BudgetProvider>(
      context,
      listen: false,
    ).updateLaborTaskPercentage(widget.project.id, task.id, value);
  }

  @override
  Widget build(BuildContext context) {
    final bp = Provider.of<BudgetProvider>(context);
    final project = bp.projects.firstWhere((p) => p.id == widget.project.id);

    final totalSpent = project.contractorExpenses;

    final pendingTasks = project.laborTasks
        .where((t) => t.completionPercentage == 0)
        .toList();
    final ongoingTasks = project.laborTasks
        .where((t) => t.completionPercentage > 0 && t.completionPercentage < 1)
        .toList();
    final doneTasks = project.laborTasks
        .where((t) => t.completionPercentage == 1)
        .toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(totalSpent),
                const SizedBox(height: 24),

                _buildSectionHeader(
                  'Task Management',
                  onAdd: _showAddTaskDialog,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.picture_as_pdf_outlined,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        tooltip: 'PDF Report',
                        onPressed: () => LaborReportGenerator.generateAndShare(
                          context: context,
                          project: project,
                          payments: project.laborPayments,
                          tasks: project.laborTasks,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.table_chart_outlined,
                          color: Colors.green,
                          size: 20,
                        ),
                        tooltip: 'Excel Report',
                        onPressed: () =>
                            LaborReportGenerator.generateExcelAndShare(
                              context: context,
                              project: project,
                              payments: project.laborPayments,
                              tasks: project.laborTasks,
                            ),
                      ),
                    ],
                  ),
                ),

                if (project.laborTasks.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No tasks added yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else ...[
                  if (ongoingTasks.isNotEmpty) ...[
                    _buildSubHeader('Ongoing Tasks', Colors.orange),
                    ...ongoingTasks.map((task) => _buildTaskItem(task)),
                    const SizedBox(height: 12),
                  ],
                  if (pendingTasks.isNotEmpty) ...[
                    _buildSubHeader('Pending Tasks', Colors.grey),
                    ...pendingTasks.map((task) => _buildTaskItem(task)),
                    const SizedBox(height: 12),
                  ],
                  if (doneTasks.isNotEmpty) ...[
                    _buildSubHeader('Completed / Done', Colors.green),
                    ...doneTasks.map((task) => _buildTaskItem(task)),
                    const SizedBox(height: 12),
                  ],
                ],

                const SizedBox(height: 12),
                _buildSectionHeader(
                  'Weekly Payments',
                  onAdd: () {
                    context.push(
                      '/projects/details/${widget.project.id}/labor-payments',
                    );
                  },
                ),
                const SizedBox(height: 8),
                if (project.laborPayments.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No weekly payments recorded.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...project.laborPayments
                      .take(5)
                      .map((p) => _buildPaymentItem(p)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double totalSpent) {
    return Card(
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.payments, color: Colors.orange.shade700, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Labour Spent',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  CurrencyUtils.formatInr(totalSpent),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    VoidCallback? onAdd,
    Widget? trailing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null) trailing,
            if (onAdd != null)
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                onPressed: onAdd,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskItem(LaborTask task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  '${task.laborerCount} Laborers • ${task.role}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: Colors.blueGrey.shade300,
                ),
                const SizedBox(width: 4),
                Text(
                  'Started: ${DateFormat('dd MMM').format(task.startDate)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blueGrey.shade600,
                  ),
                ),
                if (task.endDate != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.event_available,
                    size: 12,
                    color: Colors.green.shade300,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Ended: ${DateFormat('dd MMM').format(task.endDate!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade600,
                    ),
                  ),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${task.durationInDays} Days',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: task.completionPercentage,
                    backgroundColor: Colors.grey.shade200,
                    color: Colors.green,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(task.completionPercentage * 100).toInt()}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Slider(
              value: task.completionPercentage,
              onChanged: (val) => _updateTaskProgress(task, val),
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentItem(LaborPayment payment) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Colors.blueGrey,
        child: Icon(Icons.person, color: Colors.white),
      ),
      title: Text(
        payment.laborerName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${DateFormat.yMMMd().format(payment.periodStart)} - ${DateFormat.yMMMd().format(payment.periodEnd)}',
      ),
      trailing: Text(
        CurrencyUtils.formatInr(payment.amount),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
      ),
    );
  }
}
