import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alray_app/providers/attendance_provider.dart';
import 'package:alray_app/providers/budget_provider.dart';
import 'package:alray_app/providers/contacts_provider.dart';
import 'package:alray_app/models/attendance.dart';

import 'package:intl/intl.dart';

class AddAttendanceDialog extends StatefulWidget {
  const AddAttendanceDialog({super.key});

  @override
  State<AddAttendanceDialog> createState() => _AddAttendanceDialogState();
}

class _AddAttendanceDialogState extends State<AddAttendanceDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedProjectId;
  DateTime _selectedDate = DateTime.now();
  final Set<String> _selectedWorkerIds = {};

  static const List<String> _predefinedRoles = [
    'Mason',
    'Labour',
    'Electrical',
    'Plumber',
    'Painter',
    'Tile work',
    'Granite',
    'Carpentry',
    'Misc work',
    'Other/Custom',
  ];

  final List<WorkerEntry> _workers = [
    WorkerEntry(
      role: 'Mason',
      countController: TextEditingController(text: '0'),
      wageController: TextEditingController(text: '0'),
      roleController: TextEditingController(text: ''),
    ),
  ];

  bool _isLoading = false;

  @override
  void dispose() {
    for (var w in _workers) {
      w.countController.dispose();
      w.wageController.dispose();
      w.roleController.dispose();
    }
    super.dispose();
  }

  void _addCustomRole() {
    setState(() {
      _workers.add(
        WorkerEntry(
          role: 'Mason',
          countController: TextEditingController(text: '0'),
          wageController: TextEditingController(text: '0'),
          roleController: TextEditingController(text: ''),
        ),
      );
    });
  }

  void _removeWorker(int index) {
    setState(() {
      _workers[index].countController.dispose();
      _workers[index].wageController.dispose();
      _workers[index].roleController.dispose();
      _workers.removeAt(index);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitData() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Site Name/Project.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final Map<String, int> workerCounts = {};
    final Map<String, double> workerWages = {};

    // 1. Add individual selected workers
    final allContacts = Provider.of<ContactsProvider>(
      context,
      listen: false,
    ).contacts;
    for (var workerId in _selectedWorkerIds) {
      final contact = allContacts.firstWhere((c) => c.id == workerId);
      workerWages[workerId] = contact.dailyWage;
    }

    // 2. Add manual role entries
    for (var w in _workers) {
      final roleName = w.role == 'Other/Custom'
          ? w.roleController.text.trim()
          : w.role;
      final count = int.tryParse(w.countController.text) ?? 0;
      final wage = double.tryParse(w.wageController.text) ?? 0.0;
      if (roleName.isNotEmpty && count > 0) {
        workerCounts[roleName] = count;
        // For manual roles, we store the wage by role name (legacy format)
        workerWages[roleName] = wage;
      }
    }

    final newAttendance = Attendance(
      projectId: _selectedProjectId!,
      date: _selectedDate,
      workerCounts: workerCounts,
      workerWages: workerWages,
      presentWorkerIds: _selectedWorkerIds.toList(),
    );

    await Provider.of<AttendanceProvider>(
      context,
      listen: false,
    ).addAttendance(newAttendance);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Widget _buildWorkerRow(int index) {
    final entry = _workers[index];
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: entry.role,
                    decoration: const InputDecoration(
                      labelText: 'Worker Role',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    items: _predefinedRoles.map((role) {
                      return DropdownMenuItem(value: role, child: Text(role));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          entry.role = val;
                        });
                      }
                    },
                    validator: (val) => val == null ? 'Required' : null,
                  ),
                ),
                if (index > 0)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _removeWorker(index),
                  ),
              ],
            ),
            if (entry.role == 'Other/Custom') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: entry.roleController,
                decoration: const InputDecoration(
                  labelText: 'Custom Role Name',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                validator: (val) =>
                    (entry.role == 'Other/Custom' &&
                        (val == null || val.trim().isEmpty))
                    ? 'Required'
                    : null,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: entry.countController,
                    decoration: const InputDecoration(
                      labelText: 'No. of Workers',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.people_outline),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      if (int.tryParse(val) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: entry.wageController,
                    decoration: const InputDecoration(
                      labelText: 'Daily Wage (₹)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      if (double.tryParse(val) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projects = Provider.of<BudgetProvider>(context).projects;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add Manual Attendance',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Site Name',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _selectedProjectId,
                  items: projects.map((project) {
                    return DropdownMenuItem(
                      value: project.id,
                      child: Text(project.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProjectId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) return 'Please select a site';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Select Workers',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Consumer<ContactsProvider>(
                  builder: (context, provider, _) {
                    final workers = provider.contacts
                        .where((c) => c.role.toLowerCase() != 'customer')
                        .toList();

                    if (workers.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'No workers found. Add them in Ledger first.',
                        ),
                      );
                    }

                    return Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        itemCount: workers.length,
                        itemBuilder: (ctx, i) {
                          final worker = workers[i];
                          final isSelected = _selectedWorkerIds.contains(
                            worker.id,
                          );
                          return CheckboxListTile(
                            title: Text(worker.name),
                            subtitle: Text(
                              '${worker.role} • ₹${worker.dailyWage.toInt()}/day',
                            ),
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedWorkerIds.add(worker.id);
                                } else {
                                  _selectedWorkerIds.remove(worker.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Other Group Counts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addCustomRole,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Role'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                ...List.generate(
                  _workers.length,
                  (index) => _buildWorkerRow(index),
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitData,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Record'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WorkerEntry {
  String role;
  TextEditingController countController;
  TextEditingController wageController;
  TextEditingController roleController;

  WorkerEntry({
    required this.role,
    required this.countController,
    required this.wageController,
    required this.roleController,
  });
}
