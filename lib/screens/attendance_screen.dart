import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alray_app/providers/attendance_provider.dart';
import 'package:alray_app/providers/budget_provider.dart';
import 'package:alray_app/models/attendance.dart';
import 'package:alray_app/models/project.dart';
import 'package:alray_app/widgets/add_attendance_dialog.dart';
import 'package:alray_app/widgets/instant_payroll_dialog.dart';
import 'package:alray_app/utils/attendance_ui_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String? _selectedProjectId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final projects = Provider.of<BudgetProvider>(context).projects;
    final allAttendances = Provider.of<AttendanceProvider>(context).attendances;

    final filteredAttendances = _selectedProjectId == null
        ? allAttendances
        : allAttendances
              .where((a) => a.projectId == _selectedProjectId)
              .toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Attendance Register',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.primaryColor,
                      theme.primaryColor.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.payments_outlined, color: Colors.white),
                tooltip: 'Instant Payroll',
                onPressed: () => showDialog(
                  context: context,
                  builder: (ctx) => const InstantPayrollDialog(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.bar_chart_rounded, color: Colors.white),
                tooltip: 'Attendance Reports',
                onPressed: () => context.go('/attendance/reports'),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<String?>(
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.search_rounded),
                        hintText: 'Filter by Site',
                      ),
                      initialValue: _selectedProjectId,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Sites'),
                        ),
                        ...projects.map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.name),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedProjectId = val;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          filteredAttendances.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_note_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No attendance records found.',
                          style: GoogleFonts.outfit(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final attendance = filteredAttendances[index];
                      final project = projects.firstWhere(
                        (p) => p.id == attendance.projectId,
                        orElse: () => Project(name: 'Unknown Site', budget: 0),
                      );

                      return _buildAttendanceCard(attendance, project, theme)
                          .animate()
                          .fadeIn(duration: 400.ms, delay: (index * 50).ms)
                          .slideX(begin: 0.1, end: 0);
                    }, childCount: filteredAttendances.length),
                  ),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => const AddAttendanceDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Attendance'),
      ),
    );
  }

  Widget _buildAttendanceCard(
    Attendance attendance,
    Project project,
    ThemeData theme,
  ) {
    final totalCost = AttendanceUIUtils.calculateTotalCost(attendance);
    final totalWorkers = attendance.workerCounts.values.fold(
      0,
      (sum, count) => sum + count,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.03),
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      color: theme.primaryColor,
                      size: 20,
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
                        ),
                        Text(
                          DateFormat(
                            'EEEE, d MMM yyyy',
                          ).format(attendance.date),
                          style: GoogleFonts.outfit(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AttendanceUIUtils.formatCurrency(totalCost),
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '$totalWorkers Workers',
                        style: GoogleFonts.outfit(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: attendance.workerCounts.entries
                    .where((e) => e.value > 0)
                    .map((entry) {
                      final roleCost = AttendanceUIUtils.calculateRoleCost(
                        attendance,
                        entry.key,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withValues(
                                  alpha: 0.5,
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              entry.key,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${entry.value} × ₹${(attendance.workerWages[entry.key] ?? 0).toInt()}',
                              style: GoogleFonts.outfit(
                                color: Colors.grey.shade500,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              AttendanceUIUtils.formatCurrency(roleCost),
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
