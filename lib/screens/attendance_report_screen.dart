import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alray_app/providers/attendance_provider.dart';
import 'package:alray_app/providers/budget_provider.dart';
import 'package:alray_app/models/attendance.dart';
import 'package:alray_app/utils/report_exporter.dart';
import 'package:alray_app/utils/attendance_ui_utils.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';

enum ReportPeriod { daily, weekly, monthly, yearly }

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTimeRange _dateRange;
  String? _selectedProjectId;
  ReportPeriod _selectedPeriod = ReportPeriod.weekly;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Default to current week
    _updateDateRangeForPeriod(DateTime.now());
  }

  void _updateDateRangeForPeriod(DateTime date) {
    setState(() {
      switch (_selectedPeriod) {
        case ReportPeriod.daily:
          _dateRange = DateTimeRange(start: date, end: date);
          break;
        case ReportPeriod.weekly:
          final start = date.subtract(Duration(days: date.weekday - 1));
          _dateRange = DateTimeRange(
            start: start,
            end: start.add(const Duration(days: 6)),
          );
          break;
        case ReportPeriod.monthly:
          final start = DateTime(date.year, date.month, 1);
          final end = DateTime(date.year, date.month + 1, 0);
          _dateRange = DateTimeRange(start: start, end: end);
          break;
        case ReportPeriod.yearly:
          final start = DateTime(date.year, 1, 1);
          final end = DateTime(date.year, 12, 31);
          _dateRange = DateTimeRange(start: start, end: end);
          break;
      }
    });
  }

  void _navigatePeriod(int direction) {
    DateTime current = _dateRange.start;
    switch (_selectedPeriod) {
      case ReportPeriod.daily:
        _updateDateRangeForPeriod(current.add(Duration(days: direction)));
        break;
      case ReportPeriod.weekly:
        _updateDateRangeForPeriod(current.add(Duration(days: direction * 7)));
        break;
      case ReportPeriod.monthly:
        _updateDateRangeForPeriod(
          DateTime(current.year, current.month + direction, 1),
        );
        break;
      case ReportPeriod.yearly:
        _updateDateRangeForPeriod(DateTime(current.year + direction, 1, 1));
        break;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
        // If they pick a custom range, we might want to unset the fixed period icons or keep monthly as is?
        // For now, custom range is only available via the picker.
      });
    }
  }

  String _getPeriodDisplayString() {
    switch (_selectedPeriod) {
      case ReportPeriod.daily:
        return DateFormat('EEEE, dd MMM yyyy').format(_dateRange.start);
      case ReportPeriod.weekly:
        return '${DateFormat('dd MMM').format(_dateRange.start)} - ${DateFormat('dd MMM yyyy').format(_dateRange.end)}';
      case ReportPeriod.monthly:
        return DateFormat('MMMM yyyy').format(_dateRange.start);
      case ReportPeriod.yearly:
        return DateFormat('yyyy').format(_dateRange.start);
    }
  }

  List<Attendance> _getFilteredAttendances() {
    final all = Provider.of<AttendanceProvider>(
      context,
      listen: false,
    ).attendances;
    return all.where((a) {
      // Date filter
      final aDate = DateTime(a.date.year, a.date.month, a.date.day);
      final sDate = DateTime(
        _dateRange.start.year,
        _dateRange.start.month,
        _dateRange.start.day,
      );
      final eDate = DateTime(
        _dateRange.end.year,
        _dateRange.end.month,
        _dateRange.end.day,
      );
      final isWithinDate =
          (aDate.isAtSameMomentAs(sDate) || aDate.isAfter(sDate)) &&
          (aDate.isAtSameMomentAs(eDate) || aDate.isBefore(eDate));

      // Project filter
      if (_selectedProjectId != null && a.projectId != _selectedProjectId) {
        return false;
      }

      return isWithinDate;
    }).toList();
  }

  void _handleExport(String format) async {
    final attendances = _getFilteredAttendances();
    final isAttendanceReport = _tabController.index == 0;
    final rangeStr =
        '${DateFormat('MMM d').format(_dateRange.start)} - ${DateFormat('MMM d').format(_dateRange.end)}';

    if (isAttendanceReport) {
      final Map<String, int> counts = {};
      for (var att in attendances) {
        att.workerCounts.forEach((role, count) {
          counts[role] = (counts[role] ?? 0) + count;
        });
      }

      final sorted = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final headers = ['Role', 'Total Count'];
      final data = sorted.map((e) => [e.key, e.value]).toList();

      final totalWorkers = sorted.fold(0, (sum, e) => sum + e.value);
      data.add(['Total', totalWorkers]);

      final title = 'Attendance Report ($rangeStr)';

      if (format == 'csv') {
        await ReportExporter.exportToCsv(
          context: context,
          title: title,
          rows: [headers, ...data],
        );
      } else {
        await ReportExporter.exportToPdf(
          context: context,
          title: title,
          headers: headers,
          data: data,
        );
      }
    } else {
      // Payout Report
      final Map<String, _PayoutData> payoutMap = {};
      for (var att in attendances) {
        att.workerCounts.forEach((role, count) {
          final wage = att.workerWages[role] ?? 0.0;
          final totalPay = count * wage;

          if (!payoutMap.containsKey(role)) {
            payoutMap[role] = _PayoutData(0, 0.0);
          }
          payoutMap[role]!.headcount += count;
          payoutMap[role]!.totalPay += totalPay;
        });
      }

      final sorted = payoutMap.entries.toList()
        ..sort((a, b) => b.value.totalPay.compareTo(a.value.totalPay));
      final headers = ['Role', 'Headcount', 'Total Payout (₹)'];

      final data = sorted.map((e) {
        return [
          e.key,
          e.value.headcount,
          NumberFormat('#,##0.00', 'en_IN').format(e.value.totalPay),
        ];
      }).toList();

      final grandTotalHeadcount = sorted.fold(
        0,
        (sum, e) => sum + e.value.headcount,
      );
      final grandTotalPay = sorted.fold(
        0.0,
        (sum, e) => sum + e.value.totalPay,
      );

      data.add([
        'Total',
        grandTotalHeadcount,
        NumberFormat('#,##0.00', 'en_IN').format(grandTotalPay),
      ]);

      final title = 'Payout Report ($rangeStr)';

      if (format == 'csv') {
        await ReportExporter.exportToCsv(
          context: context,
          title: title,
          rows: [headers, ...data],
        );
      } else {
        await ReportExporter.exportToPdf(
          context: context,
          title: title,
          headers: headers,
          data: data,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Financial Reports',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_rounded),
            onPressed: _pickDateRange,
            tooltip: 'Select Date Range',
          ),
          IconButton(
            icon: Icon(
              _selectedProjectId == null
                  ? Icons.filter_alt_off
                  : Icons.filter_alt,
              color: _selectedProjectId == null
                  ? Colors.black
                  : theme.primaryColor,
            ),
            onPressed: () {
              final projects = Provider.of<BudgetProvider>(
                context,
                listen: false,
              ).projects;
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (ctx) => Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Filter by Site',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.all_inclusive),
                        title: const Text('All Sites'),
                        onTap: () {
                          setState(() => _selectedProjectId = null);
                          Navigator.pop(ctx);
                        },
                        selected: _selectedProjectId == null,
                      ),
                      ...projects.map(
                        (p) => ListTile(
                          leading: const Icon(Icons.location_on),
                          title: Text(p.name),
                          onTap: () {
                            setState(() => _selectedProjectId = p.id);
                            Navigator.pop(ctx);
                          },
                          selected: _selectedProjectId == p.id,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Export Report',
            onSelected: _handleExport,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Export as PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Export as Excel (CSV)'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: theme.primaryColor,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Headcount'),
            Tab(text: 'Payouts'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ReportPeriod.values.map((period) {
                  final isSelected = _selectedPeriod == period;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        period.name.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.grey,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: theme.primaryColor,
                      backgroundColor: Colors.grey.shade100,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedPeriod = period;
                            _updateDateRangeForPeriod(_dateRange.start);
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => _navigatePeriod(-1),
                ),
                Expanded(
                  child: InkWell(
                    onTap: _pickDateRange,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          size: 18,
                          color: theme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _getPeriodDisplayString(),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              color: theme.primaryColor,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () => _navigatePeriod(1),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _AttendanceReportView(attendances: _getFilteredAttendances()),
                _PayoutReportView(attendances: _getFilteredAttendances()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PayoutData {
  int headcount;
  double totalPay;

  _PayoutData(this.headcount, this.totalPay);
}

class _AttendanceReportView extends StatelessWidget {
  final List<Attendance> attendances;

  const _AttendanceReportView({required this.attendances});

  @override
  Widget build(BuildContext context) {
    if (attendances.isEmpty) {
      return const Center(
        child: Text('No attendance records for this period.'),
      );
    }

    final Map<String, int> counts = {};
    for (var att in attendances) {
      att.workerCounts.forEach((role, count) {
        counts[role] = (counts[role] ?? 0) + count;
      });
    }

    final sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalWorkers = sortedEntries.fold(0, (sum, e) => sum + e.value);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Total Man-Days',
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '$totalWorkers',
                  style: GoogleFonts.outfit(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          Text(
            'Headcount Breakdown',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...sortedEntries.map((entry) {
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.blue),
                ),
                title: Text(
                  entry.key,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Across all projects',
                  style: GoogleFonts.outfit(fontSize: 12),
                ),
                trailing: Text(
                  '${entry.value}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _PayoutReportView extends StatelessWidget {
  final List<Attendance> attendances;

  const _PayoutReportView({required this.attendances});

  @override
  Widget build(BuildContext context) {
    if (attendances.isEmpty) {
      return const Center(
        child: Text('No attendance records for this period.'),
      );
    }

    final Map<String, _PayoutData> payoutMap = {};
    for (var att in attendances) {
      att.workerCounts.forEach((role, count) {
        final wage = att.workerWages[role] ?? 0.0;
        final totalPay = count * wage;

        if (!payoutMap.containsKey(role)) {
          payoutMap[role] = _PayoutData(0, 0.0);
        }
        payoutMap[role]!.headcount += count;
        payoutMap[role]!.totalPay += totalPay;
      });
    }

    final sortedEntries = payoutMap.entries.toList()
      ..sort((a, b) => b.value.totalPay.compareTo(a.value.totalPay));

    final grandTotalPay = sortedEntries.fold(
      0.0,
      (sum, e) => sum + e.value.totalPay,
    );

    final List<Color> chartColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade700, Colors.green.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Total Period Payout',
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                Text(
                  AttendanceUIUtils.formatCurrency(grandTotalPay),
                  style: GoogleFonts.outfit(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          if (sortedEntries.isNotEmpty) ...[
            Text(
              'Cost Distribution',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 40,
                  sections: sortedEntries.asMap().entries.map((e) {
                    final index = e.key;
                    final entry = e.value;
                    final percentage =
                        (entry.value.totalPay / grandTotalPay) * 100;
                    return PieChartSectionData(
                      color: chartColors[index % chartColors.length],
                      value: entry.value.totalPay,
                      title: percentage > 10
                          ? '${percentage.toStringAsFixed(0)}%'
                          : '',
                      radius: 60,
                      titleStyle: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            'Payout Details',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...sortedEntries.asMap().entries.map((e) {
            final index = e.key;
            final entry = e.value;
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: chartColors[index % chartColors.length].withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.payments_rounded,
                    color: chartColors[index % chartColors.length],
                  ),
                ),
                title: Text(
                  entry.key,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Man-days: ${entry.value.headcount}',
                  style: GoogleFonts.outfit(fontSize: 12),
                ),
                trailing: Text(
                  AttendanceUIUtils.formatCurrency(entry.value.totalPay),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
