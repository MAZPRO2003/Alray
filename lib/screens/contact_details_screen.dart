import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alray_app/providers/contacts_provider.dart';
import 'package:alray_app/models/contact.dart';
import 'package:alray_app/widgets/add_contact_note_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class ContactDetailsScreen extends StatelessWidget {
  final String contactId;
  final bool openNote;

  const ContactDetailsScreen({
    super.key,
    required this.contactId,
    this.openNote = false,
  });

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      debugPrint('Could not launch $launchUri');
    }
  }

  Future<void> _openWhatsApp(BuildContext context, String phoneNumber) async {
    final String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri webUri = Uri.parse('https://wa.me/$cleanNumber');

    try {
      final launched = await launchUrl(
        webUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw Exception('Could not launch WhatsApp');
      }
    } catch (e) {
      debugPrint('Could not launch WhatsApp: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open WhatsApp: $e')));
      }
    }
  }

  void _showAddNoteDialog(
    BuildContext context,
    String id,
    String name,
    bool isCustomer, [
    String? currentNote,
  ]) {
    showDialog(
      context: context,
      builder: (ctx) => AddContactNoteDialog(
        contactId: id,
        contactName: name,
        isCustomer: isCustomer,
      ),
    );
  }

  void _showEditNoteDialog(
    BuildContext context,
    String contactId,
    ContactNote note,
  ) {
    final controller = TextEditingController(text: note.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Note'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newText = controller.text.trim();
              if (newText.isNotEmpty) {
                Provider.of<ContactsProvider>(
                  ctx,
                  listen: false,
                ).updateContactNote(contactId, note, newText);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContactsProvider>(
      builder: (context, provider, child) {
        final contactIndex = provider.contacts.indexWhere(
          (c) => c.id == contactId,
        );

        if (contactIndex == -1) {
          return Scaffold(
            appBar: AppBar(title: const Text('Contact Details')),
            body: const Center(child: Text('Contact not found or loading...')),
          );
        }

        final contact = provider.contacts[contactIndex];

        // If openNote was passed and it hasn't been handled yet, we could trigger it.
        // However, standard parameter usage in build requires post frame.
        if (openNote) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // We only want to open it once, ideally.
            // For simplicity, we rely on the user to dismiss it, but we should make sure we don't spam it.
            // Since it's a stateless widget, deep links popping dialogs can be tricky.
            // We will just let the user tap the Note button manually, but we can try auto-opening.
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(contact.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Contact?'),
                      content: Text(
                        'Are you sure you want to delete ${contact.name}?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            provider.deleteContact(contact.id);
                            Navigator.of(ctx).pop(); // close dialog
                            Navigator.of(context).pop(); // go back to list
                          },
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Header
                Center(
                  child: Hero(
                    tag: 'avatar_${contact.id}',
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Text(
                        contact.name.isNotEmpty
                            ? contact.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    contact.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      contact.role,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ActionButton(
                      icon: Icons.call,
                      label: 'Call',
                      color: Colors.green,
                      onPressed: () => _makePhoneCall(contact.phoneNumber),
                    ),
                    _ActionButton(
                      icon: Icons.chat,
                      label: 'WhatsApp',
                      color: Colors.teal,
                      onPressed: () =>
                          _openWhatsApp(context, contact.phoneNumber),
                    ),
                    _ActionButton(
                      icon: Icons.note_alt_outlined,
                      label: contact.role == 'Customer'
                          ? 'Description'
                          : 'Notes',
                      color: Colors.blue,
                      onPressed: () => _showAddNoteDialog(
                        context,
                        contact.id,
                        contact.name,
                        contact.role == 'Customer',
                        contact.callNotes,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Contact Info
                Card(
                  elevation: 0,
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Phone Number',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          contact.phoneNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Notes Log ──────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        contact.role == 'Customer' ? 'Description' : 'Notes',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAddNoteDialog(
                        context,
                        contact.id,
                        contact.name,
                        contact.role == 'Customer',
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(
                        contact.role == 'Customer'
                            ? 'Add Description'
                            : 'Add Note',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Build note list from noteLog (newest first) + legacy callNotes
                Builder(
                  builder: (context) {
                    // Combine noteLog + any legacy callNotes
                    final allNotes = [
                      ...contact.noteLog,
                      if (contact.callNotes != null &&
                          contact.callNotes!.isNotEmpty)
                        ContactNote(
                          text: contact.callNotes!,
                          timestamp: DateTime(2000), // legacy — pin to bottom
                        ),
                    ];

                    // Sort newest first
                    allNotes.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                    if (allNotes.isEmpty) {
                      return Card(
                        elevation: 0,
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              contact.role == 'Customer'
                                  ? 'No description yet. Tap \'Add Description\' to write one.'
                                  : 'No notes yet. Tap \'Add Note\' to write one.',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    }

                    return Card(
                      elevation: 0,
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: allNotes.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 16, endIndent: 16),
                        itemBuilder: (context, index) {
                          final note = allNotes[index];
                          final isLegacy = note.timestamp.year == 2000;
                          final dateStr = isLegacy
                              ? 'Earlier'
                              : DateFormat(
                                  'MMM d, yyyy',
                                ).format(note.timestamp);
                          final timeStr = isLegacy
                              ? ''
                              : DateFormat('h:mm a').format(note.timestamp);

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 13,
                                          color: Colors.grey.shade500,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isLegacy
                                              ? 'Earlier'
                                              : '$dateStr · $timeStr',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (!isLegacy)
                                      GestureDetector(
                                        onTap: () => _showEditNoteDialog(
                                          context,
                                          contact.id,
                                          note,
                                        ),
                                        child: Icon(
                                          Icons.edit_outlined,
                                          size: 16,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  note.text.replaceAll(
                                    RegExp(
                                      r'Web Inquiry Received:\s*',
                                      caseSensitive: false,
                                    ),
                                    'Description: ',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Call History
                if (contact.callHistory.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text(
                      'Call History',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: contact.callHistory.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        // Show most recent first
                        final date = contact.callHistory.reversed
                            .toList()[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.call_made,
                            color: Colors.green,
                            size: 20,
                          ),
                          title: Text(DateFormat('MMMM d, yyyy').format(date)),
                          subtitle: Text(DateFormat('h:mm a').format(date)),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filled(
          style: IconButton.styleFrom(
            backgroundColor: color.withValues(alpha: 0.1),
            foregroundColor: color,
            padding: const EdgeInsets.all(16),
          ),
          icon: Icon(icon, size: 28),
          onPressed: onPressed,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
