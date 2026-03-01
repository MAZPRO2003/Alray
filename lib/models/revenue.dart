import 'package:cloud_firestore/cloud_firestore.dart';

class Revenue {
  final String id;
  final String projectId;
  final double amount;
  final String description;
  final DateTime date;

  Revenue({
    required this.id,
    required this.projectId,
    required this.amount,
    required this.description,
    required this.date,
  });

  factory Revenue.fromJson(Map<String, dynamic> json, String id) {
    return Revenue(
      id: id,
      projectId: json['projectId'] as String? ?? '',
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] ?? '',
      date: (json['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'amount': amount,
      'description': description,
      'date': Timestamp.fromDate(date),
    };
  }
}
