import 'package:cloud_firestore/cloud_firestore.dart';

class Revenue {
  final String id;
  final String projectId;
  final double amount;
  final String description;
  final DateTime date;
  final String? attachmentUrl;

  Revenue({
    required this.id,
    required this.projectId,
    required this.amount,
    required this.description,
    required this.date,
    this.attachmentUrl,
  });

  factory Revenue.fromJson(Map<String, dynamic> json, String id) {
    return Revenue(
      id: id,
      projectId: json['projectId'] as String? ?? '',
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] ?? '',
      date: (json['date'] as Timestamp).toDate(),
      attachmentUrl: json['attachmentUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'amount': amount,
      'description': description,
      'date': Timestamp.fromDate(date),
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
    };
  }
}
