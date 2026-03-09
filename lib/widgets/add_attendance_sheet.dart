import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:alray_app/models/attendance_record.dart';
import 'package:alray_app/providers/budget_provider.dart';
import 'package:alray_app/models/project.dart';

// ── Role definitions ────────────────────────────────────────────────────────
class LaborRole {
  final String label;
  final IconData icon;
  final String countKey;
  final String rateKey;

  const LaborRole({
    required this.label,
    required this.icon,
    required this.countKey,
    required this.rateKey,
  });
}

const attendanceRoles = [
  LaborRole(
    label: 'Mason',
    icon: Icons.handyman,
    countKey: 'mason',
    rateKey: 'masonRate',
  ),
  LaborRole(
    label: 'Helper',
    icon: Icons.engineering,
    countKey: 'helper',
    rateKey: 'helperRate',
  ),
  LaborRole(
    label: 'Plumber',
    icon: Icons.plumbing,
    countKey: 'plumber',
    rateKey: 'plumberRate',
  ),
  LaborRole(
    label: 'Electrician',
    icon: Icons.electrical_services,
    countKey: 'electrician',
    rateKey: 'electricianRate',
  ),
  LaborRole(
    label: 'Carpenter',
    icon: Icons.carpenter,
    countKey: 'carpenter',
    rateKey: 'carpenterRate',
  ),
  LaborRole(
    label: 'Steel worker',
    icon: Icons.construction,
    countKey: 'steelWorker',
    rateKey: 'steelWorkerRate',
  ),
  LaborRole(
    label: 'Grill worker',
    icon: Icons.architecture,
    countKey: 'grillWorker',
    rateKey: 'grillWorkerRate',
  ),
  LaborRole(
    label: 'Tile labour',
    icon: Icons.grid_on,
    countKey: 'tileLabour',
    rateKey: 'tileLabourRate',
  ),
  LaborRole(
    label: 'Painter',
    icon: Icons.format_paint,
    countKey: 'painter',
    rateKey: 'painterRate',
  ),
  LaborRole(
    label: 'Others',
    icon: Icons.people_outline,
    countKey: 'others',
    rateKey: 'othersRate',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Public utility methods for calculating totals
// ─────────────────────────────────────────────────────────────────────────────
int getRoleCount(LaborRole role, AttendanceRecord r) {
  switch (role.countKey) {
    case 'mason':
      return r.mason;
    case 'helper':
      return r.helper;
    case 'plumber':
      return r.plumber;
    case 'electrician':
      return r.electrician;
    case 'carpenter':
      return r.carpenter;
    case 'steelWorker':
      return r.steelWorker;
    case 'grillWorker':
      return r.grillWorker;
    case 'tileLabour':
      return r.tileLabour;
    case 'painter':
      return r.painter;
    case 'others':
      return r.others;
    case 'customEntered':
      return r.customEntered;
    default:
      return 0;
  }
}

double getRoleRate(LaborRole role, AttendanceRecord r) {
  switch (role.rateKey) {
    case 'masonRate':
      return r.masonRate;
    case 'helperRate':
      return r.helperRate;
    case 'plumberRate':
      return r.plumberRate;
    case 'electricianRate':
      return r.electricianRate;
    case 'carpenterRate':
      return r.carpenterRate;
    case 'steelWorkerRate':
      return r.steelWorkerRate;
    case 'grillWorkerRate':
      return r.grillWorkerRate;
    case 'tileLabourRate':
      return r.tileLabourRate;
    case 'painterRate':
      return r.painterRate;
    case 'othersRate':
      return r.othersRate;
    case 'customEnteredRate':
      return r.customEnteredRate;
    default:
      return 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Public utility method
// ─────────────────────────────────────────────────────────────────────────────
void showAddAttendanceSheet(
  BuildContext context,
  Project project, {
  AttendanceRecord? existing,
  DateTime? presetDate,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _AttendanceSheetBody(
      project: project,
      existing: existing,
      presetDate: presetDate,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Stateful body of the bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
class _AttendanceSheetBody extends StatefulWidget {
  final Project project;
  final AttendanceRecord? existing;
  final DateTime? presetDate;

  const _AttendanceSheetBody({
    required this.project,
    this.existing,
    this.presetDate,
  });

  @override
  State<_AttendanceSheetBody> createState() => _AttendanceSheetBodyState();
}

class _AttendanceSheetBodyState extends State<_AttendanceSheetBody> {
  late DateTime selectedDate;
  late Map<String, TextEditingController> countCtrl;
  late Map<String, TextEditingController> rateCtrl;
  late TextEditingController notesCtrl;
  late TextEditingController customNameCtrl;
  late TextEditingController customCountCtrl;
  late TextEditingController customRateCtrl;
  bool showCustom = false;

  String _formatRate(double rate) {
    if (rate == 0) return '';
    return rate == rate.truncateToDouble()
        ? rate.toInt().toString()
        : rate.toStringAsFixed(2);
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    selectedDate = existing?.date ?? widget.presetDate ?? DateTime.now();

    countCtrl = {
      for (final r in attendanceRoles)
        r.countKey: TextEditingController(
          text: existing == null
              ? ''
              : getRoleCount(r, existing) == 0
              ? ''
              : getRoleCount(r, existing).toString(),
        ),
    };

    rateCtrl = {
      for (final r in attendanceRoles)
        r.rateKey: TextEditingController(
          text: existing == null
              ? ''
              : getRoleRate(r, existing) == 0
              ? ''
              : _formatRate(getRoleRate(r, existing)),
        ),
    };

    notesCtrl = TextEditingController(text: existing?.notes ?? '');
    customNameCtrl = TextEditingController(
      text: existing?.customRoleName ?? '',
    );
    customCountCtrl = TextEditingController(
      text: (existing?.customEntered ?? 0) == 0
          ? ''
          : existing!.customEntered.toString(),
    );
    customRateCtrl = TextEditingController(
      text: (existing?.customEnteredRate ?? 0) == 0
          ? ''
          : _formatRate(existing!.customEnteredRate),
    );

    showCustom =
        (existing?.customEntered ?? 0) > 0 ||
        (existing?.customRoleName.isNotEmpty ?? false);
  }

  @override
  void dispose() {
    for (final c in countCtrl.values) {
      c.dispose();
    }
    for (final c in rateCtrl.values) {
      c.dispose();
    }
    customNameCtrl.dispose();
    customCountCtrl.dispose();
    customRateCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 1,
        expand: false,
        builder: (_, scroll) => Column(
        children: [
          // ── Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // ── Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  existing == null ? 'Add Attendance' : 'Edit Attendance',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Divider(),
          // ── Scrollable form
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                // Date
                _DateTile(
                  date: selectedDate,
                  onChanged: (d) => setState(() => selectedDate = d),
                ),
                const SizedBox(height: 16),
                // Column headers
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Expanded(
                        flex: 3,
                        child: Text(
                          'Worker type',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Count',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Daily Rate (₹)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Regular roles
                ...attendanceRoles.map(
                  (r) => _RoleRow(
                    role: r,
                    countController: countCtrl[r.countKey]!,
                    rateController: rateCtrl[r.rateKey]!,
                  ),
                ),
                // Custom role
                const SizedBox(height: 12),
                if (showCustom)
                  _CustomRoleRow(
                    nameController: customNameCtrl,
                    countController: customCountCtrl,
                    rateController: customRateCtrl,
                    onRemove: () => setState(() {
                      showCustom = false;
                      customNameCtrl.clear();
                      customCountCtrl.clear();
                      customRateCtrl.clear();
                    }),
                  )
                else
                  TextButton.icon(
                    onPressed: () => setState(() => showCustom = true),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Add Custom Labor Type'),
                  ),
                const SizedBox(height: 12),
                // ── Live total
                _LiveTotal(
                  countCtrl: countCtrl,
                  rateCtrl: rateCtrl,
                  customCountCtrl: customCountCtrl,
                  customRateCtrl: customRateCtrl,
                ),
                const SizedBox(height: 12),
                // Notes
                TextField(
                  controller: notesCtrl,
                  decoration: InputDecoration(
                    labelText: 'Notes (optional)',
                    prefixIcon: const Icon(Icons.notes),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          // ── Save button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  icon: const Icon(Icons.save_outlined),
                  label: Text(existing == null ? 'Save' : 'Update'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    int c(String k) =>
                        int.tryParse(countCtrl[k]?.text.trim() ?? '') ?? 0;
                    double rt(String k) =>
                        double.tryParse(rateCtrl[k]?.text.trim() ?? '') ?? 0;

                    final record = AttendanceRecord(
                      id: existing?.id,
                      projectId: widget.project.id,
                      date: selectedDate,
                      mason: c('mason'),
                      helper: c('helper'),
                      plumber: c('plumber'),
                      electrician: c('electrician'),
                      carpenter: c('carpenter'),
                      steelWorker: c('steelWorker'),
                      grillWorker: c('grillWorker'),
                      tileLabour: c('tileLabour'),
                      painter: c('painter'),
                      others: c('others'),
                      customEntered:
                          int.tryParse(customCountCtrl.text.trim()) ?? 0,
                      masonRate: rt('masonRate'),
                      helperRate: rt('helperRate'),
                      plumberRate: rt('plumberRate'),
                      electricianRate: rt('electricianRate'),
                      carpenterRate: rt('carpenterRate'),
                      steelWorkerRate: rt('steelWorkerRate'),
                      grillWorkerRate: rt('grillWorkerRate'),
                      tileLabourRate: rt('tileLabourRate'),
                      painterRate: rt('painterRate'),
                      othersRate: rt('othersRate'),
                      customEnteredRate:
                          double.tryParse(customRateCtrl.text.trim()) ?? 0,
                      customRoleName: customNameCtrl.text.trim(),
                      notes: notesCtrl.text.trim(),
                    );

                    try {
                      if (existing == null) {
                        await Provider.of<BudgetProvider>(
                          context,
                          listen: false,
                        ).addAttendanceRecord(record);
                      } else {
                        await Provider.of<BudgetProvider>(
                          context,
                          listen: false,
                        ).updateAttendanceRecord(record);
                      }

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error saving attendance: $e'),
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Sub-Widgets (LiveTotal, DateTile, RoleRow, CustomRoleRow)
// ─────────────────────────────────────────────────────────────────────────────

class _LiveTotal extends StatefulWidget {
  final Map<String, TextEditingController> countCtrl;
  final Map<String, TextEditingController> rateCtrl;
  final TextEditingController customCountCtrl;
  final TextEditingController customRateCtrl;

  const _LiveTotal({
    required this.countCtrl,
    required this.rateCtrl,
    required this.customCountCtrl,
    required this.customRateCtrl,
  });

  @override
  State<_LiveTotal> createState() => _LiveTotalState();
}

class _LiveTotalState extends State<_LiveTotal> {
  int _workers = 0;
  double _cost = 0;

  @override
  void initState() {
    super.initState();
    final all = [
      ...widget.countCtrl.values,
      ...widget.rateCtrl.values,
      widget.customCountCtrl,
      widget.customRateCtrl,
    ];
    for (final c in all) {
      c.addListener(_recalc);
    }
  }

  void _recalc() {
    int w = 0;
    double cost = 0;
    for (final role in attendanceRoles) {
      final count =
          int.tryParse(widget.countCtrl[role.countKey]?.text.trim() ?? '') ?? 0;
      final rate =
          double.tryParse(widget.rateCtrl[role.rateKey]?.text.trim() ?? '') ??
          0;
      w += count;
      cost += count * rate;
    }
    // Add custom
    final cw = int.tryParse(widget.customCountCtrl.text.trim()) ?? 0;
    final cr = double.tryParse(widget.customRateCtrl.text.trim()) ?? 0;
    w += cw;
    cost += cw * cr;

    if (mounted) {
      setState(() {
        _workers = w;
        _cost = cost;
      });
    }
  }

  @override
  void dispose() {
    final all = [
      ...widget.countCtrl.values,
      ...widget.rateCtrl.values,
      widget.customCountCtrl,
      widget.customRateCtrl,
    ];
    for (final c in all) {
      c.removeListener(_recalc);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0', 'en_IN');
    final hasData = _workers > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: hasData ? Colors.blue.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasData ? Colors.blue.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calculate_outlined,
            size: 20,
            color: hasData ? Colors.blue.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Total',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: hasData ? Colors.blue.shade800 : Colors.grey.shade400,
              ),
            ),
          ),
          // Workers chip
          _TotalChip(
            icon: Icons.people_outline,
            label: '$_workers workers',
            color: hasData ? Colors.blue : Colors.grey,
            faint: !hasData,
          ),
          if (_cost > 0) ...[
            const SizedBox(width: 8),
            // Cost chip
            _TotalChip(
              icon: Icons.currency_rupee,
              label: fmt.format(_cost),
              color: Colors.green,
              faint: false,
            ),
          ],
        ],
      ),
    );
  }
}

class _TotalChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool faint;
  const _TotalChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.faint,
  });

  @override
  Widget build(BuildContext context) {
    final c = faint ? Colors.grey : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  const _DateTile({required this.date, required this.onChanged});

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) onChanged(picked);
    },
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: 'Date',
        prefixIcon: const Icon(Icons.calendar_today),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        DateFormat('dd MMM yyyy (EEEE)').format(date),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
  );
}

class _RoleRow extends StatelessWidget {
  final LaborRole role;
  final TextEditingController countController;
  final TextEditingController rateController;

  const _RoleRow({
    required this.role,
    required this.countController,
    required this.rateController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          // Role label
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Icon(role.icon, size: 16, color: Colors.blueGrey.shade400),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    role.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Count
          Expanded(
            flex: 2,
            child: TextField(
              controller: countController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Rate
          Expanded(
            flex: 3,
            child: TextField(
              controller: rateController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0',
                prefixText: '₹ ',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomRoleRow extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController countController;
  final TextEditingController rateController;
  final VoidCallback onRemove;

  const _CustomRoleRow({
    required this.nameController,
    required this.countController,
    required this.rateController,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_outline, size: 16, color: Colors.orange),
              const SizedBox(width: 8),
              const Text(
                'Custom Worker Type',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 16, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: 'Worker type name (e.g. Painter)',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: countController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Count',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: rateController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Rate',
                    prefixText: '₹ ',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
