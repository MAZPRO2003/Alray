import 'package:alray_app/utils/date_utils.dart' as alray_date;
import 'package:uuid/uuid.dart';
import 'package:alray_app/models/construction_entry.dart';
import 'package:alray_app/models/milestone.dart';
import 'package:alray_app/models/payable.dart';
import 'package:alray_app/models/snag_item.dart';
import 'package:alray_app/models/labor_task.dart';
import 'package:alray_app/models/labor_payment.dart';

const uuid = Uuid();

class Project {
  final String id;
  final String name;
  final double budget;
  final List<ConstructionEntry> entries;
  final List<Milestone> milestones;
  final List<Payable> payables;
  final List<SnagItem> snagItems;
  final List<LaborTask> laborTasks;
  final List<LaborPayment> laborPayments;
  final double? latitude;
  final double? longitude;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? customerPhone;

  Project({
    String? id,
    required this.name,
    required this.budget,
    List<ConstructionEntry>? entries,
    List<Milestone>? milestones,
    List<Payable>? payables,
    List<SnagItem>? snagItems,
    List<LaborTask>? laborTasks,
    List<LaborPayment>? laborPayments,
    this.latitude,
    this.longitude,
    this.startDate,
    this.endDate,
    this.customerPhone,
  }) : id = id ?? uuid.v4(),
       entries = entries ?? [],
       milestones = milestones ?? [],
       payables = payables ?? [],
       snagItems = snagItems ?? [],
       laborTasks = laborTasks ?? [],
       laborPayments = laborPayments ?? [];

  factory Project.fromJson(
    Map<String, dynamic> json,
    String documentId,
    List<ConstructionEntry> projectEntries,
    List<Milestone> projectMilestones,
    List<Payable> projectPayables,
    List<SnagItem> projectSnagItems,
    List<LaborTask> projectLaborTasks,
    List<LaborPayment> projectLaborPayments,
  ) {
    return Project(
      id: documentId,
      name: json['name'] as String? ?? 'Unnamed Project',
      budget: (json['budget'] as num?)?.toDouble() ?? 0.0,
      entries: projectEntries,
      milestones: projectMilestones,
      payables: projectPayables,
      snagItems: projectSnagItems,
      laborTasks: projectLaborTasks,
      laborPayments: projectLaborPayments,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      startDate: alray_date.DateUtils.parse(json['startDate']),
      endDate: alray_date.DateUtils.parse(json['endDate']),
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
    return entries
        .where((e) => e.transactionType == TransactionType.credit)
        .fold(0.0, (total, item) => total + item.amount);
  }

  /// Total funds spent on this specific project.
  double get totalSpent {
    final entrySpent = entries
        .where((e) => e.transactionType == TransactionType.expense)
        .fold(0.0, (total, item) => total + item.amount);
    final laborSpent = laborPayments.fold(
      0.0,
      (total, item) => total + item.amount,
    );
    return entrySpent + laborSpent;
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
      final paidAmount = entries
          .where(
            (e) =>
                e.payableId == p.id &&
                e.transactionType == TransactionType.expense,
          )
          .fold(0.0, (total, e) => total + e.amount);
      final remaining = p.totalAmount - paidAmount;
      if (remaining > 0) pending += remaining;
    }
    return pending;
  }

  double get contractorExpenses {
    final entryContractor = entries
        .where(
          (e) =>
              e.transactionType == TransactionType.expense &&
              (e.categoryId.endsWith('-L') ||
                  e.categoryId == EntryCategory.planApproval),
        )
        .fold(0.0, (total, item) => total + item.amount);
    final laborSpent = laborPayments.fold(
      0.0,
      (total, item) => total + item.amount,
    );
    return entryContractor + laborSpent;
  }

  double get materialExpenses {
    return entries
        .where(
          (e) =>
              e.transactionType == TransactionType.expense &&
              e.categoryId.endsWith('-M'),
        )
        .fold(0, (total, item) => total + item.amount);
  }

  double get otherExpenses {
    return entries
        .where(
          (e) =>
              e.transactionType == TransactionType.expense &&
              !e.categoryId.endsWith('-L') &&
              e.categoryId != EntryCategory.planApproval &&
              !e.categoryId.endsWith('-M'),
        )
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

  /// Evaluates risk based on budget and timeline.
  String get riskLevel {
    // 1. Financial Risk (takes priority)
    if (budget > 0) {
      if (totalSpent > budget) return 'Critical (Budget)';
      if (totalSpent > budget * 0.9) return 'High (Budget)';
    }

    // 2. Schedule Risk
    if (startDate != null && endDate != null && milestones.isNotEmpty) {
      final timePassed = timeElapsedPercentage;
      final progress = milestoneCompletionPercentage;

      if (timePassed > 1.0 && progress < 1.0) {
        return 'Critical (Overdue)';
      }
      if (timePassed - progress > 0.20) {
        return 'High';
      }
      if (timePassed - progress > 0.10) {
        return 'Medium';
      }
    }

    // 3. Informational / No Data
    if (entries.isEmpty && milestones.isEmpty && budget == 0) {
      return 'Unknown';
    }

    return 'Low';
  }

  /// Project is considered completed if all its milestones are done.
  bool get isCompleted =>
      milestones.isNotEmpty && milestoneCompletionPercentage == 1.0;
}
