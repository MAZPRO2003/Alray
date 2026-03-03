import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alray_app/providers/contacts_provider.dart';
import 'package:alray_app/providers/budget_provider.dart';
import 'package:alray_app/models/contact.dart';
import 'package:alray_app/models/construction_entry.dart';
import 'package:alray_app/widgets/add_contact_note_dialog.dart';
import 'package:alray_app/widgets/ledger_transaction_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

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
    }
  }

  Future<void> _openWhatsApp(BuildContext context, String phoneNumber) async {
    final String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri webUri = Uri.parse('https://wa.me/$cleanNumber');
    try {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _showTransactionDialog(
    BuildContext context,
    Contact contact,
    TransactionType type,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => LedgerTransactionDialog(
        contactId: contact.id,
        contactName: contact.name,
        transactionType: type,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ContactsProvider, BudgetProvider>(
      builder: (context, contactsProvider, budgetProvider, child) {
        final contactIndex = contactsProvider.contacts.indexWhere(
          (c) => c.id == contactId,
        );

        if (contactIndex == -1) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loading...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final contact = contactsProvider.contacts[contactIndex];
        final personEntries = budgetProvider.allEntries
            .where((e) => e.contactId == contact.id)
            .toList();

        // Sort reverse chronological
        personEntries.sort((a, b) => b.date.compareTo(a.date));

        final netBalance = contact.calculateNetBalance(
          budgetProvider.allEntries,
        );
        final balanceColor = netBalance == 0
            ? Colors.grey
            : netBalance > 0
            ? Colors.red
            : Colors.green;

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: Text(contact.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.call_outlined),
                onPressed: () => _makePhoneCall(contact.phoneNumber),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () =>
                    _confirmDelete(context, contactsProvider, contact),
              ),
            ],
          ),
          body: Column(
            children: [
              // ── Header: Balance ──────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Net Balance',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹ ${netBalance.abs().toInt()}',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: balanceColor,
                      ),
                    ),
                    Text(
                      netBalance == 0
                          ? 'Settled'
                          : netBalance > 0
                          ? 'You Owe'
                          : 'You Will Get',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: balanceColor,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Quick Actions Bar ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _smallActionBtn(
                        icon: Icons.chat_bubble_outline,
                        label: 'WhatsApp',
                        onTap: () =>
                            _openWhatsApp(context, contact.phoneNumber),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _smallActionBtn(
                        icon: Icons.note_alt_outlined,
                        label: 'Notes',
                        onTap: () => _showNotes(context, contact),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Transaction List ─────────────────────────────────────────
              Expanded(
                child: personEntries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No transactions yet with ${contact.name}',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: personEntries.length,
                        itemBuilder: (ctx, idx) {
                          final entry = personEntries[idx];
                          final isGiving =
                              entry.transactionType == TransactionType.expense;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              title: Text(
                                entry.description,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                DateFormat('dd MMM yyyy').format(entry.date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹ ${entry.amount.toInt()}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isGiving
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  ),
                                  Text(
                                    isGiving ? 'You Gave' : 'You Got',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isGiving
                                          ? Colors.red
                                          : Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),

          // ── Bottom Action Buttons ────────────────────────────────────────
          bottomSheet: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _showTransactionDialog(
                      context,
                      contact,
                      TransactionType.expense,
                    ),
                    child: const Text(
                      'YOU GAVE ₹',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade50,
                      foregroundColor: Colors.green,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _showTransactionDialog(
                      context,
                      contact,
                      TransactionType.credit,
                    ),
                    child: const Text(
                      'YOU GOT ₹',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _smallActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotes(BuildContext context, Contact contact) {
    showDialog(
      context: context,
      builder: (ctx) => AddContactNoteDialog(
        contactId: contact.id,
        contactName: contact.name,
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    ContactsProvider provider,
    Contact contact,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Contact?'),
        content: Text(
          'Are you sure you want to delete ${contact.name}? All ledger history will be kept but unlinked.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteContact(contact.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
