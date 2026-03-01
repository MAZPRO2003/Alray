import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alray_app/providers/contacts_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:alray_app/widgets/add_contact_dialog.dart';
import 'package:alray_app/widgets/add_contact_note_dialog.dart';
import 'package:alray_app/models/contact.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddContactDialog(BuildContext context) {
    showDialog(context: context, builder: (ctx) => const AddContactDialog());
  }

  void _showAddNoteDialog(BuildContext context, Contact contact) {
    showDialog(
      context: context,
      builder: (ctx) => AddContactNoteDialog(
        contactId: contact.id,
        contactName: contact.name,
        initialNote: contact.callNotes,
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      debugPrint('Could not launch $launchUri');
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open WhatsApp: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Team Contacts')),
      body: Consumer<ContactsProvider>(
        builder: (context, contactsProvider, child) {
          final allContacts = contactsProvider.contacts;

          // Filter by Search Query
          final filteredContacts = allContacts.where((contact) {
            final query = _searchQuery.toLowerCase();
            return contact.name.toLowerCase().contains(query) ||
                contact.role.toLowerCase().contains(query) ||
                contact.phoneNumber.contains(query);
          }).toList();

          // Sort by Call Count (Descending)
          filteredContacts.sort((a, b) => b.callCount.compareTo(a.callCount));

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search team by name, role, or phone...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),

              // Filtered / Grouped List
              Expanded(
                child: allContacts.isEmpty
                    ? const Center(
                        child: Text(
                          'No contacts added yet.',
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                    : filteredContacts.isEmpty
                    ? const Center(
                        child: Text(
                          'No matches found.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredContacts.length,
                        itemBuilder: (ctx, index) {
                          final contact = filteredContacts[index];

                          return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 24,
                                            backgroundColor: Theme.of(
                                              context,
                                            ).colorScheme.primaryContainer,
                                            child: Text(
                                              contact.name.isNotEmpty
                                                  ? contact.name[0]
                                                        .toUpperCase()
                                                  : '?',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        contact.name,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 18,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  contact.role,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.phone,
                                                      size: 14,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      contact.phoneNumber,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors
                                                            .grey
                                                            .shade700,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (contact.callNotes != null &&
                                          contact.callNotes!.isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.blueGrey.shade50,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.blueGrey.shade100,
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.notes,
                                                size: 18,
                                                color: Colors.blueGrey.shade400,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  contact.callNotes!,
                                                  style: TextStyle(
                                                    fontStyle: FontStyle.italic,
                                                    color: Colors
                                                        .blueGrey
                                                        .shade800,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      if (contact.callHistory.isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Recent Calls',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...contact.callHistory.reversed
                                            .take(5)
                                            .map(
                                              (date) => Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 6.0,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.history_toggle_off,
                                                      size: 16,
                                                      color: Colors
                                                          .orange
                                                          .shade600,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      DateFormat(
                                                        'MMM d, h:mm a',
                                                      ).format(date),
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors
                                                            .grey
                                                            .shade800,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                      ],
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12.0,
                                        ),
                                        child: Divider(height: 1),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () => _makePhoneCall(
                                              contact.phoneNumber,
                                            ),
                                            icon: const Icon(
                                              Icons.call,
                                              color: Colors.green,
                                              size: 20,
                                            ),
                                            label: const Text(
                                              'Call',
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          TextButton.icon(
                                            onPressed: () => _openWhatsApp(
                                              contact.phoneNumber,
                                            ),
                                            icon: const Icon(
                                              Icons.chat,
                                              color: Colors.teal,
                                              size: 20,
                                            ),
                                            label: const Text(
                                              'WhatsApp',
                                              style: TextStyle(
                                                color: Colors.teal,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          TextButton.icon(
                                            onPressed: () => _showAddNoteDialog(
                                              context,
                                              contact,
                                            ),
                                            icon: const Icon(
                                              Icons.note_alt_outlined,
                                              color: Colors.blue,
                                              size: 20,
                                            ),
                                            label: const Text(
                                              'Note',
                                              style: TextStyle(
                                                color: Colors.blue,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                              size: 22,
                                            ),
                                            onPressed: () => contactsProvider
                                                .deleteContact(contact.id),
                                            tooltip: 'Delete Contact',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .animate()
                              .fade(duration: 300.ms)
                              .slideX(begin: 0.05, end: 0, duration: 300.ms);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_contact_fab',
        onPressed: () => _showAddContactDialog(context),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
