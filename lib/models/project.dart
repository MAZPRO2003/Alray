import 'package:uuid/uuid.dart';
import 'package:alray_app/models/expense.dart';

const uuid = Uuid();

class Project {
  final String id;
  final String name;
  final double budget;
  final List<Expense> expenses;

  Project({
    String? id,
    required this.name,
    required this.budget,
    List<Expense>? expenses,
  }) : id = id ?? uuid.v4(),
       expenses = expenses ?? [];

  factory Project.fromJson(
    Map<String, dynamic> json,
    String documentId,
    List<Expense> projectExpenses,
  ) {
    return Project(
      id: documentId,
      name: json['name'] as String? ?? 'Unnamed Project',
      budget: (json['budget'] as num?)?.toDouble() ?? 0.0,
      expenses: projectExpenses,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'budget': budget};
  }

  double get totalExpenses {
    return expenses.fold(0, (sum, item) => sum + item.amount);
  }

  double get remainingBudget {
    return budget - totalExpenses;
  }

  double get vendorExpenses {
    return expenses
        .where((e) => e.category == ExpenseCategory.vendor)
        .fold(0, (sum, item) => sum + item.amount);
  }

  double get contractorExpenses {
    return expenses
        .where((e) => e.category == ExpenseCategory.contractor)
        .fold(0, (sum, item) => sum + item.amount);
  }

  double get otherExpenses {
    return expenses
        .where((e) => e.category == ExpenseCategory.other)
        .fold(0, (sum, item) => sum + item.amount);
  }
}
