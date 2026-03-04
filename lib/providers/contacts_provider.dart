import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alray_app/models/contact.dart';

class ContactsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Contact> _contacts = [];
  String? _userId;

  StreamSubscription? _teamSubscription;

  List<Contact> get contacts => [..._contacts];

  void updateUserId(String? uid) {
    if (_userId != uid) {
      _userId = uid;
      _contacts = [];
      _teamSubscription?.cancel();

      if (uid != null) {
        Future.microtask(() => startListening());
      } else {
        Future.microtask(() => notifyListeners());
      }
    }
  }

  int get totalTeamCalls {
    return _contacts.fold(0, (total, c) => total + c.callCount);
  }

  @override
  void dispose() {
    _teamSubscription?.cancel();
    super.dispose();
  }

  void startListening() {
    if (_userId == null) return;

    // Listen to personal team contacts only
    _teamSubscription = _firestore
        .collection('contacts')
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .listen((snapshot) {
          _updateLocalContacts(snapshot.docs);
        });
  }

  // Temporary storage
  final Map<String, Contact> _teamMap = {};

  void _updateLocalContacts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final newContacts = docs
        .map((doc) => Contact.fromFirestore(doc, null))
        .toList();
    _teamMap.clear();
    for (var c in newContacts) {
      _teamMap[c.id] = c;
    }
    _contacts = _teamMap.values.toList();

    // Sort by createdAt (Newest First)
    _contacts.sort((a, b) {
      if (a.createdAt != null && b.createdAt != null) {
        return b.createdAt!.compareTo(a.createdAt!);
      }
      return 0;
    });

    notifyListeners();
  }

  // legacy fetch method — now handled by listeners
  Future<void> fetchContacts() async {
    // If listeners are active, this is redundant, but kept for interface consistency
    if (_teamSubscription == null) startListening();
  }

  Future<void> updateContact(Contact contact) async {
    try {
      final contactIndex = _contacts.indexWhere((c) => c.id == contact.id);
      if (contactIndex >= 0) {
        // Optimistic UI update
        _contacts[contactIndex] = contact;
        notifyListeners();

        // Network Background Sync
        await _firestore
            .collection('contacts')
            .doc(contact.id)
            .update(contact.toFirestore());
      }
    } catch (e) {
      debugPrint('Error updating contact: $e');
      fetchContacts();
    }
  }

  Future<void> addContact(Contact contact) async {
    if (_userId == null) return;
    try {
      final newContactRef = _firestore.collection('contacts').doc();
      final data = contact.toFirestore();
      data['userId'] = _userId;
      data['createdAt'] = FieldValue.serverTimestamp();

      final contactToAdd = Contact(
        id: newContactRef.id,
        name: contact.name,
        role: contact.role,
        phoneNumber: contact.phoneNumber,
        userId: _userId,
        notes: contact.notes,
        createdAt: DateTime.now(),
      );

      await newContactRef.set(data);
      _contacts.add(contactToAdd);
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
          noteLog: currentContact.noteLog,
          createdAt: currentContact.createdAt,
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
          createdAt: currentContact.createdAt,
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
          createdAt: currentContact.createdAt,
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
          createdAt: currentContact.createdAt,
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
