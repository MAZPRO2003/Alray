import 'package:cloud_firestore/cloud_firestore.dart';

class Payable {
  final String id;
  final String projectId;
  final String vendorName;
  final double totalAmount;
  final String description;
  final String categoryId;
  final DateTime dueDate;
  final double rate;
  final double quantity;
  final bool isPaid; // Helper flag

  Payable({
    required this.id,
    required this.projectId,
    required this.vendorName,
    required this.totalAmount,
    required this.description,
    required this.categoryId,
    required this.dueDate,
    this.rate = 0.0,
    this.quantity = 1.0,
    this.isPaid = false,
  });

  factory Payable.fromJson(Map<String, dynamic> json, String documentId) {
    return Payable(
      id: documentId,
      projectId: json['projectId'] ?? '',
      vendorName: json['vendorName'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
      categoryId: json['categoryId'] ?? 'miscExp',
      dueDate: json['dueDate'] != null
          ? (json['dueDate'] as Timestamp).toDate()
          : DateTime.now(),
      rate: (json['rate'] ?? (json['totalAmount'] ?? 0.0)).toDouble(),
      quantity: (json['quantity'] ?? 1.0).toDouble(),
      isPaid: json['isPaid'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'vendorName': vendorName,
      'totalAmount': totalAmount,
      'description': description,
      'categoryId': categoryId,
      'dueDate': Timestamp.fromDate(dueDate),
      'rate': rate,
      'quantity': quantity,
      'isPaid': isPaid,
    };
  }

  Payable copyWith({
    String? id,
    String? projectId,
    String? vendorName,
    double? totalAmount,
    String? description,
    String? categoryId,
    DateTime? dueDate,
    double? rate,
    double? quantity,
    bool? isPaid,
  }) {
    return Payable(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      vendorName: vendorName ?? this.vendorName,
      totalAmount: totalAmount ?? this.totalAmount,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      dueDate: dueDate ?? this.dueDate,
      rate: rate ?? this.rate,
      quantity: quantity ?? this.quantity,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}
