import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alray_app/providers/attendance_provider.dart';
import 'package:alray_app/providers/contacts_provider.dart';
import 'package:alray_app/providers/budget_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class InstantPayrollDialog extends StatefulWidget {
  const InstantPayrollDialog({super.key});

  @override
  State<InstantPayrollDialog> createState() => _InstantPayrollDialogState();
}

class _InstantPayrollDialogState extends State<InstantPayrollDialog> {
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _projectId;
  bool _isCalculating = false;
  bool _isPosting = false;
  Map<String, double> _payrollResults = {};

  Future<void> _pickDate(bool isFrom) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? (_fromDate ?? now) : (_toDate ?? now),
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        if (isFrom)
          _fromDate = picked;
        else
          _toDate = picked;
      });
    }
  }

  void _calculate() {
    if (_fromDate == null || _toDate == null) return;
    setState(() {
      _isCalculating = true;
    });

    final attendanceProvider = Provider.of<AttendanceProvider>(
      context,
      listen: false,
    );
    final contactsProvider = Provider.of<ContactsProvider>(
      context,
      listen: false,
    );

    final from = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
    final to = DateTime(
      _toDate!.year,
      _toDate!.month,
      _toDate!.day,
      23,
      59,
      59,
    );

    final relevant = attendanceProvider.attendances.where((a) {
      final inRange = !a.date.isBefore(from) && !a.date.isAfter(to);
      final matchProject = _projectId == null || a.projectId == _projectId;
      return inRange && matchProject;
    }).toList();

    final Map<String, double> wages = {};
    final contactMap = {for (var c in contactsProvider.contacts) c.id: c};

    for (final att in relevant) {
      for (final workerId in att.presentWorkerIds) {
        final wage =
            att.workerWages[workerId] ?? contactMap[workerId]?.dailyWage ?? 0.0;
        wages[workerId] = (wages[workerId] ?? 0) + wage;
      }
    }

    setState(() {
      _payrollResults = wages;
      _isCalculating = false;
    });
  }

  Future<void> _postToLedger() async {
    if (_payrollResults.isEmpty) return;
    setState(() {
      _isPosting = true;
    });

    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final contactsProvider = Provider.of<ContactsProvider>(
      context,
      listen: false,
    );
    final contacts = contactsProvider.contacts;
    final firestore = FirebaseFirestore.instance;

    // Find user ID from budget provider
    final userId = budgetProvider.currentUserId;
    final projectId =
        _projectId ?? budgetProvider.projects.firstOrNull?.id ?? '';
    final periodLabel =
        '${DateFormat('d MMM').format(_fromDate!)} – ${DateFormat('d MMM yyyy').format(_toDate!)}';

    try {
      final batch = firestore.batch();
      for (final entry in _payrollResults.entries) {
        final workerId = entry.key;
        final amount = entry.value;
        if (amount <= 0) continue;

        final ref = firestore.collection('entries').doc();
        batch.set(ref, {
          'id': ref.id,
          'projectId': projectId,
          'contactId': workerId,
          'amount': amount,
          'transactionType': 'expense',
          'description': 'Payroll: $periodLabel',
          'date': DateTime.now().toIso8601String(),
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'quantity': 1,
          'rate': amount,
          'categoryId': 'Labor',
        });
      }
      await batch.commit();
      await budgetProvider.fetchAndSetProjects();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Payroll posted for ${_payrollResults.length} workers',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post payroll: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted)
        setState(() {
          _isPosting = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contactMap = {
      for (var c in Provider.of<ContactsProvider>(
        context,
        listen: false,
      ).contacts)
        c.id: c,
    };
    final projects = Provider.of<BudgetProvider>(
      context,
      listen: false,
    ).projects;

    final totalPayroll = _payrollResults.values.fold(0.0, (s, v) => s + v);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.payments_outlined,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Instant Payroll',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Calculate & post wages for a period',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Project picker
              DropdownButtonFormField<String?>(
                value: _projectId,
                decoration: InputDecoration(
                  labelText: 'Project (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Projects'),
                  ),
                  ...projects.map(
                    (p) => DropdownMenuItem<String?>(
                      value: p.id,
                      child: Text(p.name, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() {
                  _projectId = v;
                  _payrollResults = {};
                }),
              ),
              const SizedBox(height: 16),

              // Date range
              Row(
                children: [
                  Expanded(
                    child: _datePicker(
                      'From',
                      _fromDate,
                      () => _pickDate(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _datePicker('To', _toDate, () => _pickDate(false)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Calculate button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      (_fromDate != null && _toDate != null && !_isCalculating)
                      ? _calculate
                      : null,
                  icon: _isCalculating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.calculate_outlined),
                  label: const Text('Calculate Wages'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              // Results
              if (_payrollResults.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Payroll Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '₹${totalPayroll.toInt()} total',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...(_payrollResults.entries.map((entry) {
                  final contact = contactMap[entry.key];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        contact?.name.isNotEmpty == true
                            ? contact!.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      contact?.name ?? 'Unknown Worker',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      contact?.role ?? '',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Text(
                      '₹${entry.value.toInt()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  );
                })),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isPosting ? null : _postToLedger,
                    icon: _isPosting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(_isPosting ? 'Posting...' : 'Post to Ledger'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _datePicker(String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              date != null
                  ? DateFormat('d MMM yyyy').format(date)
                  : 'Select date',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: date != null ? Colors.black87 : Colors.grey.shade500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
