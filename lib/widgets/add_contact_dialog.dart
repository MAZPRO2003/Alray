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
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _phoneController = TextEditingController();

  Future<void> _pickExternalContact() async {
    // 1. Check and request Contacts OS permission
    if (await Permission.contacts.request().isGranted) {
      // 2. Open Native Android/iOS Contact Picker
      final contact = await FlutterContacts.openExternalPick();

      if (contact != null) {
        // Fetch full details of the picked contact to get phone numbers
        final fullContact = await FlutterContacts.getContact(contact.id);

        if (fullContact != null) {
          setState(() {
            _nameController.text = fullContact.displayName;
            // Use the first available phone number, or leave empty if none
            if (fullContact.phones.isNotEmpty) {
              _phoneController.text = fullContact.phones.first.number;
            }
          });
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Contacts permission is required to use this feature.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _submitData() async {
    final enteredName = _nameController.text;
    final enteredRole = _roleController.text;
    final enteredPhone = _phoneController.text;

    if (enteredName.isEmpty || enteredRole.isEmpty || enteredPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields.')),
      );
      return;
    }

    final newContact = app_model.Contact(
      id: '', // Handled by Firestore
      name: enteredName,
      role: enteredRole,
      phoneNumber: enteredPhone,
    );

    try {
      await Provider.of<ContactsProvider>(
        context,
        listen: false,
      ).addContact(newContact);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Handle error visually if necessary
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Contact',
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
                label: const Text('Pick from Device Contacts'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.secondary,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _roleController,
                decoration: const InputDecoration(
                  labelText: 'Role (e.g., Plumber, Contractor)',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
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
                    onPressed: _submitData,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
