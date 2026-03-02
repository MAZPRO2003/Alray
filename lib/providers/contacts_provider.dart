import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alray_app/models/contact.dart';

class ContactsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Contact> _contacts = [];
  String? _userId;

  List<Contact> get contacts => [..._contacts];

  void updateUserId(String? uid) {
    if (_userId != uid) {
      _userId = uid;
      _contacts = [];
      if (uid != null) {
        // Defer to avoid "setState() called during build" from proxy provider update
        Future.microtask(() => fetchContacts());
      } else {
        Future.microtask(() => notifyListeners());
      }
    }
  }

  int get totalTeamCalls {
    return _contacts.fold(0, (total, c) => total + c.callCount);
  }

  Future<void> fetchContacts() async {
    if (_userId == null) return;
    try {
      final snapshot = await _firestore
          .collection('contacts')
          .where('userId', isEqualTo: _userId)
          .get();
      _contacts = snapshot.docs
          .map((doc) => Contact.fromFirestore(doc, null))
          .toList();

      // Sort manually in memory to avoid needing a Firestore composite index
      _contacts.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching contacts: $e');
    }
  }

  Future<void> addContact(Contact contact) async {
    if (_userId == null) return;
    try {
      final newContactRef = _firestore.collection('contacts').doc();
      final data = contact.toFirestore();
      data['userId'] = _userId;

      final contactToAdd = Contact(
        id: newContactRef.id,
        name: contact.name,
        role: contact.role,
        phoneNumber: contact.phoneNumber,
        notes: contact.notes,
      );

      await newContactRef.set(data);

      _contacts.add(contactToAdd);

      // Re-sort the list
      _contacts.sort((a, b) => a.name.compareTo(b.name));

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding contact: $e');
    }
  }

  Future<void> deleteContact(String id) async {
    try {
      // OPTIMISTIC UPDATE: Remove locally first for instant UI response
      final contactIndex = _contacts.indexWhere((c) => c.id == id);
      if (contactIndex >= 0) {
        _contacts.removeAt(contactIndex);
        notifyListeners();
      }

      // Slower Network Sync
      await _firestore.collection('contacts').doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting contact: $e');
      // Revert optimism if network fails
      fetchContacts();
    }
  }

  Future<void> incrementCallCount(String id) async {
    try {
      final contactIndex = _contacts.indexWhere((c) => c.id == id);
      if (contactIndex >= 0) {
        final currentContact = _contacts[contactIndex];
        final updatedContact = Contact(
          id: currentContact.id,
          name: currentContact.name,
          role: currentContact.role,
          phoneNumber: currentContact.phoneNumber,
          notes: currentContact.notes,
          callCount: currentContact.callCount + 1,
          callHistory: [...currentContact.callHistory, DateTime.now()],
          callNotes: currentContact.callNotes,
        );

        // Optimistic UI update
        _contacts[contactIndex] = updatedContact;
        notifyListeners();

        // Network Background Sync
        await _firestore.collection('contacts').doc(id).update({
          'callCount': FieldValue.increment(1),
          'callHistory': FieldValue.arrayUnion([Timestamp.now()]),
        });
      }
    } catch (e) {
      debugPrint('Error incrementing call count: $e');
      fetchContacts(); // Revert on failure
    }
  }

  /// Appends a new timestamped note to a contact's noteLog.
  Future<void> addContactNote(String id, String noteText) async {
    if (noteText.trim().isEmpty) return;
    try {
      final contactIndex = _contacts.indexWhere((c) => c.id == id);
      if (contactIndex >= 0) {
        final newNote = ContactNote(
          text: noteText.trim(),
          timestamp: DateTime.now(),
        );
        final currentContact = _contacts[contactIndex];
        final updatedContact = Contact(
          id: currentContact.id,
          name: currentContact.name,
          role: currentContact.role,
          phoneNumber: currentContact.phoneNumber,
          notes: currentContact.notes,
          callCount: currentContact.callCount,
          callHistory: currentContact.callHistory,
          callNotes: currentContact.callNotes,
          noteLog: [...currentContact.noteLog, newNote],
        );

        // Optimistic UI update
        _contacts[contactIndex] = updatedContact;
        notifyListeners();

        // Network Background Sync
        await _firestore.collection('contacts').doc(id).update({
          'noteLog': FieldValue.arrayUnion([newNote.toMap()]),
        });
      }
    } catch (e) {
      debugPrint('Error adding contact note: $e');
      fetchContacts();
    }
  }

  /// Updates the text of an existing note matched by its original timestamp.
  Future<void> updateContactNote(
    String id,
    ContactNote oldNote,
    String newText,
  ) async {
    if (newText.trim().isEmpty) return;
    try {
      final contactIndex = _contacts.indexWhere((c) => c.id == id);
      if (contactIndex >= 0) {
        final currentContact = _contacts[contactIndex];
        final updatedNote = ContactNote(
          text: newText.trim(),
          timestamp: oldNote.timestamp, // keep original timestamp
        );
        final updatedNoteLog = currentContact.noteLog
            .map((n) => n.timestamp == oldNote.timestamp ? updatedNote : n)
            .toList();

        _contacts[contactIndex] = Contact(
          id: currentContact.id,
          name: currentContact.name,
          role: currentContact.role,
          phoneNumber: currentContact.phoneNumber,
          notes: currentContact.notes,
          callCount: currentContact.callCount,
          callHistory: currentContact.callHistory,
          callNotes: currentContact.callNotes,
          noteLog: updatedNoteLog,
        );
        notifyListeners();

        // Write entire updated noteLog back to Firestore
        await _firestore.collection('contacts').doc(id).update({
          'noteLog': updatedNoteLog.map((n) => n.toMap()).toList(),
        });
      }
    } catch (e) {
      debugPrint('Error updating contact note: $e');
      fetchContacts();
    }
  }

  Future<void> updateCallNotes(String id, String newNotes) async {
    try {
      final contactIndex = _contacts.indexWhere((c) => c.id == id);
      if (contactIndex >= 0) {
        final currentContact = _contacts[contactIndex];
        final updatedContact = Contact(
          id: currentContact.id,
          name: currentContact.name,
          role: currentContact.role,
          phoneNumber: currentContact.phoneNumber,
          notes: currentContact.notes,
          callCount: currentContact.callCount,
          callHistory: currentContact.callHistory,
          callNotes: newNotes,
          noteLog: currentContact.noteLog,
        );

        _contacts[contactIndex] = updatedContact;
        notifyListeners();

        await _firestore.collection('contacts').doc(id).update({
          'callNotes': newNotes,
        });
      }
    } catch (e) {
      debugPrint('Error updating call notes: $e');
      fetchContacts();
    }
  }
}
