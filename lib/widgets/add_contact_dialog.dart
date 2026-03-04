import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alray_app/providers/contacts_provider.dart';
import 'package:alray_app/models/contact.dart' as app_model;
import 'package:alray_app/utils/validators.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class AddContactDialog extends StatefulWidget {
  final app_model.Contact? contact;
  const AddContactDialog({super.key, this.contact});

  @override
  State<AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<AddContactDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedRole = 'Mason / Labour';
  final _customRoleController = TextEditingController();
  bool _isCustomRole = false;

  @override
  void initState() {
    super.initState();
    if (widget.contact != null) {
      _nameController.text = widget.contact!.name;
      _phoneController.text = widget.contact!.phoneNumber;

      bool found = false;
      for (var group in _roleGroups.values) {
        if (group.contains(widget.contact!.role)) {
          _selectedRole = widget.contact!.role;
          found = true;
          break;
        }
      }

      if (!found) {
        _selectedRole = 'Custom Role';
        _isCustomRole = true;
        _customRoleController.text = widget.contact!.role;
      }
    }
  }

  Future<void> _pickExternalContact() async {
    if (await Permission.contacts.request().isGranted) {
      final contact = await FlutterContacts.openExternalPick();
      if (contact != null) {
        final fullContact = await FlutterContacts.getContact(contact.id);
        if (fullContact != null) {
          setState(() {
            _nameController.text = fullContact.displayName;
            if (fullContact.phones.isNotEmpty) {
              String rawPhone = fullContact.phones.first.number;
              String cleanDigits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
              if (cleanDigits.length > 10) {
                _phoneController.text = cleanDigits.substring(
                  cleanDigits.length - 10,
                );
              } else {
                _phoneController.text = cleanDigits;
              }
            }
          });
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contacts permission is required.')),
        );
      }
    }
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    final enteredName = _nameController.text.trim();
    final enteredPhone = _phoneController.text.trim();

    final role = _isCustomRole
        ? _customRoleController.text.trim()
        : _selectedRole;

    final contact = app_model.Contact(
      id: widget.contact?.id ?? '',
      name: enteredName,
      role: role,
      phoneNumber: enteredPhone,
      dailyWage: widget.contact?.dailyWage ?? 0.0,
      userId: widget.contact?.userId,
      createdAt: widget.contact?.createdAt,
      noteLog: widget.contact?.noteLog ?? [],
      callCount: widget.contact?.callCount ?? 0,
      callHistory: widget.contact?.callHistory ?? [],
      callNotes: widget.contact?.callNotes,
    );

    try {
      if (widget.contact != null) {
        await Provider.of<ContactsProvider>(
          context,
          listen: false,
        ).updateContact(contact);
      } else {
        await Provider.of<ContactsProvider>(
          context,
          listen: false,
        ).addContact(contact);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error adding contact: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _customRoleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.contact != null ? 'Edit Person' : 'Add New Person',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickExternalContact,
                  icon: const Icon(Icons.contacts),
                  label: const Text('Pick from Device'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const Divider(height: 32),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.badge),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 16),
                _GroupedRolePicker(
                  selectedRole: _selectedRole,
                  onChanged: (val) {
                    setState(() {
                      _selectedRole = val;
                      _isCustomRole = val == 'Custom Role';
                    });
                  },
                ),
                if (_isCustomRole) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customRoleController,
                    decoration: const InputDecoration(
                      labelText: 'Custom Role',
                      hintText: 'e.g. Interior Designer',
                      prefixIcon: Icon(Icons.edit_note),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        (_isCustomRole && (v == null || v.trim().isEmpty))
                        ? 'Role is required'
                        : null,
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                    hintText: '10 digits',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: AppValidators.validatePhone,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _submitData,
                      child: Text(widget.contact != null ? 'Update' : 'Save'),
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

const _roleGroups = {
  'Labour': [
    'Mason / Labour',
    'Electrician',
    'Plumber',
    'Carpenter',
    'Tile Fixer',
    'Painter',
    'Helper',
    'Misc Labour',
  ],
  'Others': [
    'Contractor',
    'Client',
    'Supervisor',
    'Architect',
    'Engineer',
    'Custom Role',
  ],
};

class _GroupedRolePicker extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onChanged;

  const _GroupedRolePicker({
    required this.selectedRole,
    required this.onChanged,
  });

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, controller) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Select Role',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    children: _roleGroups.entries.expand((group) {
                      return [
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: _groupColor(group.key),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                group.key.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: _groupColor(group.key),
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...group.value.map((role) {
                          final isSelected = role == selectedRole;
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            tileColor: isSelected
                                ? _groupColor(group.key).withValues(alpha: 0.12)
                                : null,
                            leading: Icon(
                              role == 'Custom Role'
                                  ? Icons.add_circle_outline
                                  : _groupIcon(group.key),
                              size: 18,
                              color: isSelected
                                  ? _groupColor(group.key)
                                  : Colors.grey,
                            ),
                            title: Text(
                              role,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? _groupColor(group.key)
                                    : null,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: _groupColor(group.key),
                                    size: 18,
                                  )
                                : null,
                            onTap: () {
                              onChanged(role);
                              Navigator.pop(ctx);
                            },
                          );
                        }),
                      ];
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _groupColor(String group) {
    if (group == 'Labour') return Colors.orange.shade700;
    return Colors.indigo;
  }

  IconData _groupIcon(String group) {
    if (group == 'Labour') return Icons.construction;
    return Icons.work_outline;
  }

  @override
  Widget build(BuildContext context) {
    String? groupName;
    for (final e in _roleGroups.entries) {
      if (e.value.contains(selectedRole)) {
        groupName = e.key;
        break;
      }
    }
    final color = groupName == 'Labour'
        ? Colors.orange.shade700
        : Colors.indigo;

    return InkWell(
      onTap: () => _showPicker(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.badge_outlined, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Role',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedRole,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }
}
