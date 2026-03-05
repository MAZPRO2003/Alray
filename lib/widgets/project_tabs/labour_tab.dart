import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:alray_app/models/project.dart';
import 'package:alray_app/models/attendance_record.dart';
import 'package:alray_app/providers/budget_provider.dart';
import 'package:alray_app/utils/attendance_report_generator.dart';
import 'package:alray_app/widgets/add_attendance_sheet.dart';

String _formatRate(double v) =>
    v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(0);

// ─────────────────────────────────────────────────────────────────────────────
// Public widget — exported as LabourTab so no other file needs renaming
// ─────────────────────────────────────────────────────────────────────────────
class LabourTab extends StatelessWidget {
  final Project project;
  const LabourTab({super.key, required this.project});

  @override
  Widget build(BuildContext context) => _AttendanceBody(project: project);
}

// ─────────────────────────────────────────────────────────────────────────────
// Main body
// ─────────────────────────────────────────────────────────────────────────────
class _AttendanceBody extends StatefulWidget {
  final Project project;
  const _AttendanceBody({required this.project});

  @override
  State<_AttendanceBody> createState() => _AttendanceBodyState();
}

class _AttendanceBodyState extends State<_AttendanceBody> {
  DateTime? _filterDate; // null = show all (weekly grouped)

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _pickFilterDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _filterDate = picked);
  }

  void _clearFilter() => setState(() => _filterDate = null);

  // ── Open add / edit sheet ─────────────────────────────────────────────────
  void _openSheet({AttendanceRecord? existing, DateTime? presetDate}) {
    showAddAttendanceSheet(
      context,
      widget.project,
      existing: existing,
      presetDate: presetDate,
    );
  }

  void _confirmDelete(AttendanceRecord record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: Text(
          'Remove attendance for ${DateFormat('dd MMM yyyy').format(record.date)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Provider.of<BudgetProvider>(
                context,
                listen: false,
              ).deleteAttendanceRecord(widget.project.id, record.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final records = project.attendanceRecords;

    final totalWorkerDays = records.fold(0, (s, r) => s + r.totalWorkers);
    final totalCost = records.fold(0.0, (s, r) => s + r.totalCost);

    // ── Date-filtered view ────────────────────────────────────────────────
    if (_filterDate != null) {
      final dayRecords = records
          .where((r) => _isSameDay(r.date, _filterDate!))
          .toList();
      return Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Filter banner
              SliverToBoxAdapter(
                child: _FilterBanner(
                  date: _filterDate!,
                  onClear: _clearFilter,
                  onPickDate: _pickFilterDate,
                ),
              ),
              if (dayRecords.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 56,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No attendance on ${DateFormat('dd MMM yyyy').format(_filterDate!)}',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add for this day'),
                          onPressed: () => _openSheet(presetDate: _filterDate),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _DayCard(
                        record: dayRecords[i],
                        onEdit: () => _openSheet(existing: dayRecords[i]),
                        onDelete: () => _confirmDelete(dayRecords[i]),
                      ),
                      childCount: dayRecords.length,
                    ),
                  ),
                ),
            ],
          ),
          // FAB
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: 'attendance_add_${widget.project.id}',
              onPressed: () => _openSheet(presetDate: _filterDate),
              icon: const Icon(Icons.add),
              label: const Text('Add Attendance'),
            ),
          ),
        ],
      );
    }

    // ── Full weekly view (no filter) ───────────────────────────────────────
    final weekMap = AttendanceReportGenerator.groupByWeek(records);
    final weekStarts = weekMap.keys.toList()..sort((a, b) => b.compareTo(a));

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // ── Summary card ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _SummaryCard(
                  totalWorkerDays: totalWorkerDays,
                  totalCost: totalCost,
                  totalDays: records.length,
                  onExport: records.isEmpty
                      ? null
                      : () => AttendanceReportGenerator.generateExcelAndShare(
                          context: context,
                          project: project,
                          records: records,
                        ),
                  onExportPdf: records.isEmpty
                      ? null
                      : () => AttendanceReportGenerator.generatePdfAndShare(
                          context: context,
                          project: project,
                          records: records,
                        ),
                  onPickDate: _pickFilterDate,
                  onAdd: _openSheet,
                ),
              ),
            ),

            // ── Empty state ────────────────────────────────────────────────
            if (records.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No attendance recorded yet.',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add First Entry'),
                        onPressed: _openSheet,
                      ),
                    ],
                  ),
                ),
              )
            else
              // ── Weekly grouped list ────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((ctx, i) {
                    final weekStart = weekStarts[i];
                    final (start, end) = AttendanceReportGenerator.weekRangeFor(
                      weekStart,
                    );
                    final weekRecords = weekMap[weekStart]!
                      ..sort((a, b) => b.date.compareTo(a.date));
                    final weekWorkers = weekRecords.fold(
                      0,
                      (s, r) => s + r.totalWorkers,
                    );
                    final weekCost = weekRecords.fold(
                      0.0,
                      (s, r) => s + r.totalCost,
                    );

                    return _WeekSection(
                      weekStart: start,
                      weekEnd: end,
                      records: weekRecords,
                      totalWorkers: weekWorkers,
                      totalCost: weekCost,
                      onExport: () =>
                          AttendanceReportGenerator.generateWeeklyExcelAndShare(
                            context: context,
                            project: project,
                            records: records,
                            weekStart: start,
                            weekEnd: end,
                          ),
                      onExportPdf: () =>
                          AttendanceReportGenerator.generateWeeklyPdfAndShare(
                            context: context,
                            project: project,
                            records: records,
                            weekStart: start,
                            weekEnd: end,
                          ),
                      onEdit: (r) => _openSheet(existing: r),
                      onDelete: _confirmDelete,
                    );
                  }, childCount: weekStarts.length),
                ),
              ),
          ],
        ),

        // ── FAB overlay removed since we now use the global FAB ────────────
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary card
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final int totalWorkerDays;
  final double totalCost;
  final int totalDays;
  final VoidCallback? onExport;
  final VoidCallback? onExportPdf;
  final VoidCallback? onPickDate; // null = no filter button
  final VoidCallback onAdd;
  const _SummaryCard({
    required this.totalWorkerDays,
    required this.totalCost,
    required this.totalDays,
    required this.onExport,
    required this.onExportPdf,
    this.onPickDate,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.##', 'en_IN');
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Attendance Register',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
                if (onExport != null)
                  IconButton(
                    icon: const Icon(
                      Icons.table_chart_outlined,
                      color: Colors.green,
                    ),
                    tooltip: 'Export All to Excel',
                    onPressed: onExport,
                  ),
                if (onExportPdf != null)
                  IconButton(
                    icon: const Icon(
                      Icons.picture_as_pdf_outlined,
                      color: Colors.red,
                    ),
                    tooltip: 'Export All to PDF',
                    onPressed: onExportPdf,
                  ),
                // ── Date filter button
                IconButton(
                  icon: const Icon(Icons.calendar_month_outlined),
                  tooltip: 'Filter by date',
                  onPressed: onPickDate,
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: Colors.blue.shade700,
                  ),
                  tooltip: 'Add Attendance',
                  onPressed: onAdd,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _chip(Icons.today, '$totalDays Days', Colors.blue),
                const SizedBox(width: 8),
                _chip(
                  Icons.people,
                  '$totalWorkerDays Worker-Days',
                  Colors.deepPurple,
                ),
                const SizedBox(width: 8),
                if (totalCost > 0)
                  _chip(
                    Icons.currency_rupee,
                    '₹${fmt.format(totalCost)}',
                    Colors.green,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter banner — shown above single-day view
// ─────────────────────────────────────────────────────────────────────────────
class _FilterBanner extends StatelessWidget {
  final DateTime date;
  final VoidCallback onClear;
  final VoidCallback onPickDate;
  const _FilterBanner({
    required this.date,
    required this.onClear,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          InkWell(
            onTap: onPickDate,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('EEE, d MMMM yyyy').format(date),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 16, color: Colors.grey.shade700),
            ),
          ),
          const Spacer(),
          Text(
            'Tap date to change',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Weekly section
// ─────────────────────────────────────────────────────────────────────────────
class _WeekSection extends StatelessWidget {
  final DateTime weekStart;
  final DateTime weekEnd;
  final List<AttendanceRecord> records;
  final int totalWorkers;
  final double totalCost;
  final VoidCallback onExport;
  final VoidCallback onExportPdf;
  final void Function(AttendanceRecord) onEdit;
  final void Function(AttendanceRecord) onDelete;

  const _WeekSection({
    required this.weekStart,
    required this.weekEnd,
    required this.records,
    required this.totalWorkers,
    required this.totalCost,
    required this.onExport,
    required this.onExportPdf,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0', 'en_IN');
    final weekLabel = weekStart.month == weekEnd.month
        ? '${DateFormat('d').format(weekStart)} – ${DateFormat('d MMMM yyyy').format(weekEnd)}'
        : '${DateFormat('d MMM').format(weekStart)} – ${DateFormat('d MMM yyyy').format(weekEnd)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Week header
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  weekLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              // Week totals chips
              if (totalWorkers > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.shade100),
                  ),
                  child: Text(
                    '$totalWorkers workers',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.purple.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                if (totalCost > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade100),
                    ),
                    child: Text(
                      '₹${fmt.format(totalCost)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
              // Weekly export buttons (Excel + PDF)
              IconButton(
                icon: const Icon(
                  Icons.table_chart_outlined,
                  color: Colors.green,
                  size: 20,
                ),
                tooltip: 'Export week to Excel',
                visualDensity: VisualDensity.compact,
                onPressed: onExport,
              ),
              IconButton(
                icon: const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: Colors.red,
                  size: 20,
                ),
                tooltip: 'Export week to PDF',
                visualDensity: VisualDensity.compact,
                onPressed: onExportPdf,
              ),
            ],
          ),
        ),
        // Daily cards in this week
        ...records.map(
          (r) => _DayCard(
            record: r,
            onEdit: () => onEdit(r),
            onDelete: () => onDelete(r),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single day card
// ─────────────────────────────────────────────────────────────────────────────
class _DayCard extends StatelessWidget {
  final AttendanceRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DayCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0', 'en_IN');
    final presentRoles = attendanceRoles
        .where((r) => getRoleCount(r, record) > 0)
        .toList();

    return Dismissible(
      key: ValueKey(record.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: Colors.white),
            Text('Delete', style: TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        DateFormat('dd MMM yyyy (EEE)').format(record.date),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (record.totalCost > 0)
                      Text(
                        '₹${fmt.format(record.totalCost)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                          fontSize: 13,
                        ),
                      ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      visualDensity: VisualDensity.compact,
                      color: Colors.grey.shade500,
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      visualDensity: VisualDensity.compact,
                      color: Colors.red.shade300,
                      onPressed: onDelete,
                    ),
                  ],
                ),
                if (presentRoles.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: presentRoles.map((r) {
                      final c = getRoleCount(r, record);
                      final rt = getRoleRate(r, record);
                      final label = rt > 0
                          ? '${r.label}: $c – ₹${_formatRate(rt)}'
                          : '${r.label}: $c';
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              r.icon,
                              size: 11,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  // Add dynamic custom role if present
                  if (record.customEntered > 0)
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              record.customRoleName.isEmpty
                                  ? 'Custom'
                                  : record.customRoleName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '${record.customEntered} × ₹${_formatRate(record.customEnteredRate)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                if (record.notes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.notes, size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          record.notes,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// (Roles row and total views extracted to add_attendance_sheet)
