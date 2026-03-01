import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alray_app/models/contact.dart';

class ContactsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Contact> _contacts = [];

  List<Contact> get contacts => [..._contacts];

  int get totalTeamCalls {
    return _contacts.fold(0, (sum, c) => sum + c.callCount);
  }

  Future<void> fetchContacts() async {
    try {
      final snapshot = await _firestore
          .collection('contacts')
          .orderBy('name')
          .get();
      _contacts = snapshot.docs
          .map((doc) => Contact.fromFirestore(doc, null))
          .toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching contacts: $e');
    }
  }

  Future<void> addContact(Contact contact) async {
    try {
      final newContactRef = _firestore.collection('contacts').doc();
      final contactToAdd = Contact(
        id: newContactRef.id,
        name: contact.name,
        role: contact.role,
        phoneNumber: contact.phoneNumber,
        notes: contact.notes,
      );

      await newContactRef.set(contactToAdd.toFirestore());

      _contacts.add(contactToAdd);

      // Re-sort the list
      _contacts.sort((a, b) => a.name.compareTo(b.name));

      notifyListeners();
    } catch (e) {
      print('Error adding contact: $e');
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
      print('Error deleting contact: $e');
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
      print('Error incrementing call count: $e');
      fetchContacts(); // Revert on failure
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
        );

        // Optimistic UI update
        _contacts[contactIndex] = updatedContact;
        notifyListeners();

        // Network Background Sync
        await _firestore.collection('contacts').doc(id).update({
          'callNotes': newNotes,
        });
      }
    } catch (e) {
      print('Error updating call notes: $e');
      fetchContacts(); // Revert on failure
    }
  }
}
