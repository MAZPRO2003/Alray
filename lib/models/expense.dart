import 'package:uuid/uuid.dart';

const uuid = Uuid();

enum ExpenseCategory { vendor, contractor, other }

class Expense {
  final String id;
  final String projectId;
  final String description;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;

  Expense({
    String? id,
    required this.projectId,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
  }) : id = id ?? uuid.v4();

  factory Expense.fromJson(Map<String, dynamic> json, String documentId) {
    return Expense(
      id: documentId,
      projectId: json['projectId'] as String? ?? '',
      description: json['description'] as String? ?? 'No Description',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ExpenseCategory.other,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category.name,
    };
  }

  String get formattedCategory {
    switch (category) {
      case ExpenseCategory.vendor:
        return 'Vendor';
      case ExpenseCategory.contractor:
        return 'Contractor';
      case ExpenseCategory.other:
        return 'Other';
    }
  }
}
