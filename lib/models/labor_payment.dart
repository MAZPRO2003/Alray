import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class LaborPayment {
  final String id;
  final String projectId;
  final String laborerName;
  final double amount;
  final DateTime date;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String description;

  LaborPayment({
    String? id,
    required this.projectId,
    required this.laborerName,
    required this.amount,
    DateTime? date,
    required this.periodStart,
    required this.periodEnd,
    this.description = '',
  }) : id = id ?? uuid.v4(),
       date = date ?? DateTime.now();

  factory LaborPayment.fromJson(Map<String, dynamic> json, String id) {
    return LaborPayment(
      id: id,
      projectId: json['projectId'] as String? ?? '',
      laborerName: json['laborerName'] as String? ?? 'Unnamed Laborer',
      amount: (json['amount'] as num? ?? 0.0).toDouble(),
      date: json['date'] != null
          ? (json['date'] as Timestamp).toDate()
          : DateTime.now(),
      periodStart: json['periodStart'] != null
          ? (json['periodStart'] as Timestamp).toDate()
          : DateTime.now(),
      periodEnd: json['periodEnd'] != null
          ? (json['periodEnd'] as Timestamp).toDate()
          : DateTime.now(),
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'laborerName': laborerName,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'periodStart': Timestamp.fromDate(periodStart),
      'periodEnd': Timestamp.fromDate(periodEnd),
      'description': description,
    };
  }

  LaborPayment copyWith({
    String? id,
    String? projectId,
    String? laborerName,
    double? amount,
    DateTime? date,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? description,
  }) {
    return LaborPayment(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      laborerName: laborerName ?? this.laborerName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      description: description ?? this.description,
    );
  }
}
