import 'package:uuid/uuid.dart';
import 'package:alray_app/models/expense.dart';
import 'package:alray_app/models/revenue.dart';

const uuid = Uuid();

class Project {
  final String id;
  final String name;
  final double budget;
  final List<Expense> expenses;
  final List<Revenue> revenues;

  Project({
    String? id,
    required this.name,
    required this.budget,
    List<Expense>? expenses,
    List<Revenue>? revenues,
  }) : id = id ?? uuid.v4(),
       expenses = expenses ?? [],
       revenues = revenues ?? [];

  factory Project.fromJson(
    Map<String, dynamic> json,
    String documentId,
    List<Expense> projectExpenses,
    List<Revenue> projectRevenues,
  ) {
    return Project(
      id: documentId,
      name: json['name'] as String? ?? 'Unnamed Project',
      budget: (json['budget'] as num?)?.toDouble() ?? 0.0,
      expenses: projectExpenses,
      revenues: projectRevenues,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'budget': budget};
  }

  /// Total funds received from the customer for this specific project.
  double get totalReceived {
    return revenues.fold(0.0, (sum, item) => sum + item.amount);
  }

  /// Total funds spent on this specific project.
  double get totalSpent {
    return expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  /// Current cash available for the project (Received - Spent).
  double get cashOnHand {
    return totalReceived - totalSpent;
  }

  /// Original budget minus what has been spent.
  double get remainingBudget {
    return budget - totalSpent;
  }

  double get customerReceived => totalReceived;

  double get contractorExpenses {
    return expenses
        .where((e) => e.category == ExpenseCategory.contractor)
        .fold(0, (sum, item) => sum + item.amount);
  }

  double get materialExpenses {
    return expenses
        .where((e) => e.category == ExpenseCategory.material)
        .fold(0, (sum, item) => sum + item.amount);
  }

  double get otherExpenses {
    return expenses
        .where((e) => e.category == ExpenseCategory.other)
        .fold(0, (sum, item) => sum + item.amount);
  }

  @Deprecated('Use totalSpent instead')
  double get totalExpenses => totalSpent;
}
