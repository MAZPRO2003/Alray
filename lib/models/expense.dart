import 'package:uuid/uuid.dart';

const uuid = Uuid();

enum ExpenseCategory { contractor, material, other }

class Expense {
  final String id;
  final String projectId;
  final String description;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final String? customCategoryName;
  final double? quantity;
  final String? unit;
  final String? materialType;
  final String? workerName;
  final String? vendorName;

  Expense({
    String? id,
    required this.projectId,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    this.customCategoryName,
    this.quantity,
    this.unit,
    this.materialType,
    this.workerName,
    this.vendorName,
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
      customCategoryName: json['customCategoryName'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      materialType: json['materialType'] as String?,
      workerName: json['workerName'] as String?,
      vendorName: json['vendorName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category.name,
      if (customCategoryName != null) 'customCategoryName': customCategoryName,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (materialType != null) 'materialType': materialType,
      if (workerName != null) 'workerName': workerName,
      if (vendorName != null) 'vendorName': vendorName,
    };
  }

  String get formattedCategory {
    if (category == ExpenseCategory.material) {
      if (vendorName != null && vendorName!.isNotEmpty) {
        return 'Vendor: $vendorName';
      }
      if (materialType != null && materialType!.isNotEmpty) {
        return materialType!;
      }
      return 'Material';
    }
    if (category == ExpenseCategory.contractor) {
      if (workerName != null && workerName!.isNotEmpty) {
        return 'Worker: $workerName';
      }
      return 'Workers';
    }
    if (category == ExpenseCategory.other &&
        customCategoryName != null &&
        customCategoryName!.isNotEmpty) {
      return customCategoryName!;
    }
    return 'Custom';
  }
}
