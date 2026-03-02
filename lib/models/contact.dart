import 'package:cloud_firestore/cloud_firestore.dart';

/// A single timestamped note entry attached to a contact.
class ContactNote {
  final String text;
  final DateTime timestamp;

  const ContactNote({required this.text, required this.timestamp});

  factory ContactNote.fromMap(Map<String, dynamic> map) {
    return ContactNote(
      text: map['text'] as String? ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'text': text,
    'timestamp': Timestamp.fromDate(timestamp),
  };
}

class Contact {
  const Contact({
    required this.id,
    required this.name,
    required this.role,
    required this.phoneNumber,
    this.notes,
    this.callCount = 0,
    this.callHistory = const [],
    // Legacy single note — kept for migration purposes, use noteLog going forward
    this.callNotes,
    this.noteLog = const [],
  });

  final String id;
  final String name;
  final String role;
  final String phoneNumber;
  final String? notes;
  final int callCount;
  final List<DateTime> callHistory;
  final String? callNotes; // Legacy field — kept for backward compat
  final List<ContactNote> noteLog; // New: list of timestamped notes

  factory Contact.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Contact(
      id: snapshot.id,
      name: data?['name'],
      role: data?['role'],
      phoneNumber: data?['phoneNumber'],
      notes: data?['notes'],
      callCount: data?['callCount'] ?? 0,
      callHistory:
          (data?['callHistory'] as List<dynamic>?)
              ?.map((ts) => (ts as Timestamp).toDate())
              .toList() ??
          [],
      callNotes: data?['callNotes'],
      noteLog:
          (data?['noteLog'] as List<dynamic>?)
              ?.map((m) => ContactNote.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "name": name,
      "role": role,
      "phoneNumber": phoneNumber,
      if (notes != null) "notes": notes,
      "callCount": callCount,
      "callHistory": callHistory
          .map((date) => Timestamp.fromDate(date))
          .toList(),
      if (callNotes != null) "callNotes": callNotes,
      "noteLog": noteLog.map((n) => n.toMap()).toList(),
    };
  }
}
