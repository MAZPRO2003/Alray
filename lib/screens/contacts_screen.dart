import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alray_app/providers/contacts_provider.dart';
import 'package:alray_app/widgets/add_contact_dialog.dart';
import 'package:alray_app/widgets/add_contact_note_dialog.dart';
import 'package:alray_app/models/contact.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class ContactsScreen extends StatefulWidget {
  final String? highlightId;
  final String? openNoteId;
  const ContactsScreen({super.key, this.highlightId, this.openNoteId});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  String _searchQuery = '';
  String _selectedRole = 'All';
  final TextEditingController _searchController = TextEditingController();

  bool _deepLinkHandled = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleDeepLink(List<Contact> contacts) {
    if (_deepLinkHandled) return;
    final targetId = widget.openNoteId ?? widget.highlightId;
    if (targetId == null) return;

    try {
      final contact = contacts.firstWhere((c) => c.id == targetId);
      _deepLinkHandled = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _searchQuery = contact.name;
          _searchController.text = contact.name;
        });
        if (widget.openNoteId != null && mounted) {
          _showAddNoteDialog(context, contact);
        }
      });
    } catch (e) {
      // Contact not found or not loaded yet
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Team Contacts')),
      body: Consumer<ContactsProvider>(
        builder: (context, contactsProvider, child) {
          final allContacts = contactsProvider.contacts;

          if (!_deepLinkHandled && allContacts.isNotEmpty) {
            _handleDeepLink(allContacts);
          }

          // Extract unique roles
          final roles = [
            'All',
            ...allContacts.map((c) => c.role).toSet().toList()..sort(),
          ];

          // Filter by Search Query AND Role
          final filteredContacts = allContacts.where((contact) {
            final matchesQuery =
                _searchQuery.isEmpty ||
                contact.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                contact.role.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                contact.phoneNumber.contains(_searchQuery);

            final matchesRole =
                _selectedRole == 'All' || contact.role == _selectedRole;

            return matchesQuery && matchesRole;
          }).toList();

          // Sort by Call Count (Descending)
          filteredContacts.sort((a, b) => b.callCount.compareTo(a.callCount));

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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

              // Role Filter Bar
              if (roles.length > 1)
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: roles.length,
                    itemBuilder: (ctx, index) {
                      final role = roles[index];
                      final isSelected = _selectedRole == role;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(role),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedRole = role;
                            });
                          },
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          selectedColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          checkmarkColor: Theme.of(context).colorScheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 8),

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
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    context.push(
                                      '/contacts/details/${contact.id}',
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        Hero(
                                          tag: 'avatar_${contact.id}',
                                          child: CircleAvatar(
                                            radius: 28,
                                            backgroundColor: Theme.of(
                                              context,
                                            ).colorScheme.primaryContainer,
                                            child: Text(
                                              contact.name.isNotEmpty
                                                  ? contact.name[0]
                                                        .toUpperCase()
                                                  : '?',
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                contact.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
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
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.phone,
                                                    size: 14,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    contact.phoneNumber,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color:
                                                          Colors.grey.shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'ai_chat_fab_contacts',
            onPressed: () => context.push('/chat'),
            backgroundColor: Colors.indigo,
            tooltip: 'AI Chat Assistant',
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'add_contact_fab',
            onPressed: () => _showAddContactDialog(context),
            child: const Icon(Icons.person_add),
          ),
        ],
      ),
    );
  }
}
