import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alray_app/providers/contacts_provider.dart';
import 'package:alray_app/providers/budget_provider.dart';
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

class _ContactsScreenState extends State<ContactsScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String _selectedRole = 'All';
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  bool _deepLinkHandled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedRole = 'All';
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
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
      appBar: AppBar(
        title: const Text('Ledger'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          indicatorColor: Colors.white,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 15,
          ),
          tabs: const [
            Tab(text: 'Workers'),
            Tab(text: 'Customers'),
          ],
        ),
      ),
      body: Consumer2<ContactsProvider, BudgetProvider>(
        builder: (context, contactsProvider, budgetProvider, child) {
          final allContacts = contactsProvider.contacts;
          final allEntries = budgetProvider.allEntries;

          if (!_deepLinkHandled && allContacts.isNotEmpty) {
            _handleDeepLink(allContacts);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildContactsTab(allContacts, allEntries, isWorker: true),
              _buildContactsTab(allContacts, allEntries, isWorker: false),
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

  Widget _buildContactsTab(
    List<Contact> allContacts,
    List<dynamic> allEntries, {
    required bool isWorker,
  }) {
    // Filter by type
    final typeFiltered = allContacts.where((c) {
      final isActuallyCustomer = c.role == 'Customer';
      return isWorker ? !isActuallyCustomer : isActuallyCustomer;
    }).toList();

    // Extract unique roles/types
    final roles = isWorker
        ? ['All', ...typeFiltered.map((c) => c.role).toSet().toList()..sort()]
        : ['All', 'Web', 'App'];

    // Apply Search and Role/Source filters
    final finalFiltered = typeFiltered.where((contact) {
      final matchesQuery =
          _searchQuery.isEmpty ||
          contact.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          contact.role.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          contact.phoneNumber.contains(_searchQuery);

      bool matchesFilter = true;
      if (isWorker) {
        matchesFilter = _selectedRole == 'All' || contact.role == _selectedRole;
      } else {
        if (_selectedRole == 'Web') {
          matchesFilter = contact.userId == 'WEB_INQUIRY';
        } else if (_selectedRole == 'App') {
          matchesFilter = contact.userId != 'WEB_INQUIRY';
        }
      }

      return matchesQuery && matchesFilter;
    }).toList();

    // Sort by createdAt (Newest First), then Call Count
    finalFiltered.sort((a, b) {
      if (a.createdAt != null && b.createdAt != null) {
        return b.createdAt!.compareTo(a.createdAt!);
      }
      return b.callCount.compareTo(a.callCount);
    });

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: isWorker ? 'Search workers...' : 'Search customers...',
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
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),

        // Filter Bar
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
                    onSelected: (selected) =>
                        setState(() => _selectedRole = role),
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
                          : Theme.of(context).colorScheme.onSurfaceVariant,
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

        Expanded(
          child: finalFiltered.isEmpty
              ? Center(
                  child: Text(
                    _searchQuery.isEmpty
                        ? 'No contacts yet.'
                        : 'No matches found.',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: finalFiltered.length,
                  itemBuilder: (ctx, index) =>
                      _buildContactCard(finalFiltered[index], allEntries),
                ),
        ),
      ],
    );
  }

  Widget _buildContactCard(Contact contact, List<dynamic> allEntries) {
    final isCustomer = contact.role == 'Customer';
    final netBalance = contact.calculateNetBalance(allEntries);

    return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push('/contacts/details/${contact.id}'),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Hero(
                    tag: 'avatar_${contact.id}',
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: isCustomer ? 0.3 : 1.0),
                      child: Text(
                        contact.name.isNotEmpty
                            ? contact.name[0].toUpperCase()
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              contact.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            if (contact.userId == 'WEB_INQUIRY') ...[
                              const SizedBox(width: 8),
                              _buildBadge('WEB', Colors.blue),
                            ] else if (isCustomer) ...[
                              const SizedBox(width: 8),
                              _buildBadge('APP', Colors.green),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          contact.role,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isCustomer
                                ? Colors.orange.shade700
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹ ${netBalance.abs().toInt()}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: netBalance == 0
                              ? Colors.grey
                              : netBalance > 0
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                      Text(
                        netBalance == 0
                            ? 'Settled'
                            : netBalance > 0
                            ? 'You Owe'
                            : 'You Will Get',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: netBalance == 0
                              ? Colors.grey
                              : netBalance > 0
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fade(duration: 300.ms)
        .slideX(begin: 0.05, end: 0, duration: 300.ms);
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
