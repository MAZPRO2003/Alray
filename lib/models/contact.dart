import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alray_app/utils/date_utils.dart' as alray_date;

/// A single timestamped note entry attached to a contact.
class ContactNote {
  final String text;
  final DateTime timestamp;

  const ContactNote({required this.text, required this.timestamp});

  factory ContactNote.fromMap(Map<String, dynamic> map) {
    return ContactNote(
      text: map['text'] as String? ?? '',
      timestamp: alray_date.DateUtils.parseRequired(map['timestamp']),
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
    this.userId,
    this.notes,
    this.callCount = 0,
    this.callHistory = const [],
    // Legacy single note — kept for migration purposes, use noteLog going forward
    this.callNotes,
    this.noteLog = const [],
    this.createdAt,
    this.dailyWage = 0.0,
  });

  final String id;
  final String name;
  final String role;
  final String phoneNumber;
  final String? userId;
  final String? notes;
  final int callCount;
  final List<DateTime> callHistory;
  final String? callNotes; // Legacy field — kept for backward compat
  final List<ContactNote> noteLog; // New: list of timestamped notes
  final DateTime? createdAt;
  final double dailyWage;

  factory Contact.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Contact(
      id: snapshot.id,
      name: data?['name'] as String? ?? 'Unnamed',
      role: data?['role'] as String? ?? 'General',
      userId: data?['userId'] as String?,
      phoneNumber: data?['phoneNumber'] as String? ?? '',
      notes: data?['notes'] as String?,
      callCount: data?['callCount'] as int? ?? 0,
      createdAt: alray_date.DateUtils.parse(
        data?['createdAt'] ?? data?['timestamp'],
      ),
      callHistory:
          (data?['callHistory'] as List<dynamic>?)
              ?.map((ts) => alray_date.DateUtils.parseRequired(ts))
              .toList() ??
          [],
      callNotes: data?['callNotes'] as String?,
      noteLog:
          (data?['noteLog'] as List<dynamic>?)
              ?.map((m) => ContactNote.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      dailyWage: (data?['dailyWage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "name": name,
      "role": role,
      "phoneNumber": phoneNumber,
      if (userId != null) "userId": userId,
      if (notes != null) "notes": notes,
      "callCount": callCount,
      "createdAt": createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      "callHistory": callHistory
          .map((date) => Timestamp.fromDate(date))
          .toList(),
      if (callNotes != null) "callNotes": callNotes,
      "noteLog": noteLog.map((n) => n.toMap()).toList(),
      "dailyWage": dailyWage,
    };
  }
}
