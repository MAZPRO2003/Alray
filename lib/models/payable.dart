import 'package:cloud_firestore/cloud_firestore.dart';

class Payable {
  final String id;
  final String projectId;
  final String vendorName;
  final double totalAmount;
  final String description;
  final DateTime dueDate;
  final bool isPaid; // Helper flag

  Payable({
    required this.id,
    required this.projectId,
    required this.vendorName,
    required this.totalAmount,
    required this.description,
    required this.dueDate,
    this.isPaid = false,
  });

  factory Payable.fromJson(Map<String, dynamic> json, String documentId) {
    return Payable(
      id: documentId,
      projectId: json['projectId'] ?? '',
      vendorName: json['vendorName'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
      dueDate: json['dueDate'] != null
          ? (json['dueDate'] as Timestamp).toDate()
          : DateTime.now(),
      isPaid: json['isPaid'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'vendorName': vendorName,
      'totalAmount': totalAmount,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'isPaid': isPaid,
    };
  }

  Payable copyWith({
    String? id,
    String? projectId,
    String? vendorName,
    double? totalAmount,
    String? description,
    DateTime? dueDate,
    bool? isPaid,
  }) {
    return Payable(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      vendorName: vendorName ?? this.vendorName,
      totalAmount: totalAmount ?? this.totalAmount,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}
