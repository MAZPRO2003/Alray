import 'package:uuid/uuid.dart';
import 'package:alray_app/models/expense.dart';
import 'package:alray_app/models/revenue.dart';
import 'package:alray_app/models/milestone.dart';
import 'package:alray_app/models/payable.dart';
import 'package:alray_app/models/snag_item.dart';

const uuid = Uuid();

class Project {
  final String id;
  final String name;
  final double budget;
  final List<Expense> expenses;
  final List<Revenue> revenues;
  final List<Milestone> milestones;
  final List<Payable> payables;
  final List<SnagItem> snagItems;
  final double? latitude;
  final double? longitude;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? customerPhone;

  Project({
    String? id,
    required this.name,
    required this.budget,
    List<Expense>? expenses,
    List<Revenue>? revenues,
    List<Milestone>? milestones,
    List<Payable>? payables,
    List<SnagItem>? snagItems,
    this.latitude,
    this.longitude,
    this.startDate,
    this.endDate,
    this.customerPhone,
  }) : id = id ?? uuid.v4(),
       expenses = expenses ?? [],
       revenues = revenues ?? [],
       milestones = milestones ?? [],
       payables = payables ?? [],
       snagItems = snagItems ?? [];

  factory Project.fromJson(
    Map<String, dynamic> json,
    String documentId,
    List<Expense> projectExpenses,
    List<Revenue> projectRevenues,
    List<Milestone> projectMilestones,
    List<Payable> projectPayables,
    List<SnagItem> projectSnagItems,
  ) {
    return Project(
      id: documentId,
      name: json['name'] as String? ?? 'Unnamed Project',
      budget: (json['budget'] as num?)?.toDouble() ?? 0.0,
      expenses: projectExpenses,
      revenues: projectRevenues,
      milestones: projectMilestones,
      payables: projectPayables,
      snagItems: projectSnagItems,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      customerPhone: json['customerPhone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'budget': budget,
      'latitude': latitude,
      'longitude': longitude,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'customerPhone': customerPhone,
    };
  }

  /// Total funds received from the customer for this specific project.
  double get totalReceived {
    return revenues.fold(0.0, (total, item) => total + item.amount);
  }

  /// Total funds spent on this specific project.
  double get totalSpent {
    return expenses.fold(0.0, (total, item) => total + item.amount);
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

  double get pendingPayablesTotal {
    double pending = 0;
    for (var p in payables) {
      final paidAmount = expenses
          .where((e) => e.payableId == p.id)
          .fold(0.0, (total, e) => total + e.amount);
      final remaining = p.totalAmount - paidAmount;
      if (remaining > 0) pending += remaining;
    }
    return pending;
  }

  double get contractorExpenses {
    return expenses
        .where((e) => e.category == ExpenseCategory.contractor)
        .fold(0, (total, item) => total + item.amount);
  }

  double get materialExpenses {
    return expenses
        .where((e) => e.category == ExpenseCategory.material)
        .fold(0, (total, item) => total + item.amount);
  }

  double get otherExpenses {
    return expenses
        .where((e) => e.category == ExpenseCategory.other)
        .fold(0, (total, item) => total + item.amount);
  }

  double get totalExpenses => totalSpent;

  // --- NEW FEATURES: Time, Progress & Risk ---

  /// Percentage of time elapsed (0.0 to 1.0)
  double get timeElapsedPercentage {
    if (startDate == null || endDate == null) return 0.0;

    final now = DateTime.now();
    if (now.isBefore(startDate!)) return 0.0;
    if (now.isAfter(endDate!)) return 1.0;

    final totalDuration = endDate!.difference(startDate!).inMilliseconds;
    final elapsedDuration = now.difference(startDate!).inMilliseconds;

    if (totalDuration <= 0) return 1.0;
    return elapsedDuration / totalDuration;
  }

  /// Percentage of milestones completed (0.0 to 1.0)
  double get milestoneCompletionPercentage {
    if (milestones.isEmpty) return 0.0;
    final completed = milestones.where((m) => m.isCompleted).length;
    return completed / milestones.length;
  }

  /// Evaluates risk based on time elapsed vs milestones completed
  /// If time is moving much faster than progress, risk is high.
  String get riskLevel {
    if (startDate == null || endDate == null || milestones.isEmpty) {
      return 'Unknown';
    }

    final timePassed = timeElapsedPercentage;
    final progress = milestoneCompletionPercentage;

    if (timePassed > 1.0 && progress < 1.0) {
      return 'Critical (Overdue)';
    }

    // if passing time is 20% ahead of progress
    if (timePassed - progress > 0.20) {
      return 'High';
    }

    // if passing time is 10% ahead of progress
    if (timePassed - progress > 0.10) {
      return 'Medium';
    }

    return 'Low';
  }
}
