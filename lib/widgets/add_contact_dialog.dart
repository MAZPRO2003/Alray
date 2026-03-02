import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alray_app/providers/contacts_provider.dart';
import 'package:alray_app/models/contact.dart' as app_model;
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class AddContactDialog extends StatefulWidget {
  const AddContactDialog({super.key});

  @override
  State<AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<AddContactDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _phoneController = TextEditingController();
  String _contactType = 'Worker';

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
    final enteredRole = _contactType == 'Customer'
        ? 'Customer'
        : _roleController.text.trim();
    final enteredPhone = _phoneController.text.trim();

    final newContact = app_model.Contact(
      id: '',
      name: enteredName,
      role: enteredRole,
      phoneNumber: enteredPhone,
    );

    try {
      await Provider.of<ContactsProvider>(
        context,
        listen: false,
      ).addContact(newContact);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error adding contact: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _phoneController.dispose();
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
                  'Add New Person',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary,
                    selectedForegroundColor: Theme.of(
                      context,
                    ).colorScheme.onPrimary,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                  ),
                  segments: const [
                    ButtonSegment(
                      value: 'Worker',
                      label: Text('Worker'),
                      icon: Icon(Icons.engineering),
                    ),
                    ButtonSegment(
                      value: 'Customer',
                      label: Text('Customer'),
                      icon: Icon(Icons.person),
                    ),
                  ],
                  selected: {_contactType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() => _contactType = newSelection.first);
                  },
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
                if (_contactType == 'Worker')
                  TextFormField(
                    controller: _roleController,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      hintText: 'e.g. Plumber, Contractor',
                      prefixIcon: Icon(Icons.work),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Role is required'
                        : null,
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                    hintText: '10 digits',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Phone required';
                    final clean = v.replaceAll(RegExp(r'[^0-9]'), '');
                    return clean.length == 10 ? null : 'Must be 10 digits';
                  },
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
                      child: const Text('Save'),
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
