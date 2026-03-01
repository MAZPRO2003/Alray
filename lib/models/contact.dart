import 'package:cloud_firestore/cloud_firestore.dart';

class Contact {
  const Contact({
    required this.id,
    required this.name,
    required this.role,
    required this.phoneNumber,
    this.notes,
    this.callCount = 0,
    this.callHistory = const [],
    this.callNotes,
  });

  final String id;
  final String name;
  final String role;
  final String phoneNumber;
  final String? notes; // Initial creation notes
  final int callCount; // Automated frequency tracking
  final List<DateTime> callHistory; // Exact timestamps of each call
  final String? callNotes; // Post-call discussion notes

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
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (name != null) "name": name,
      if (role != null) "role": role,
      if (phoneNumber != null) "phoneNumber": phoneNumber,
      if (notes != null) "notes": notes,
      "callCount": callCount,
      "callHistory": callHistory
          .map((date) => Timestamp.fromDate(date))
          .toList(),
      if (callNotes != null) "callNotes": callNotes,
    };
  }
}
