import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alray_app/utils/date_utils.dart' as alray_date;
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class LaborTask {
  final String id;
  final String projectId;
  final String name;
  final int laborerCount;
  final String role;
  final double completionPercentage; // 0.0 to 1.0
  final DateTime startDate;
  final DateTime? endDate;

  LaborTask({
    String? id,
    required this.projectId,
    required this.name,
    required this.laborerCount,
    required this.role,
    this.completionPercentage = 0.0,
    DateTime? startDate,
    this.endDate,
  }) : id = id ?? uuid.v4(),
       startDate = startDate ?? DateTime.now();

  int get durationInDays {
    final end = endDate ?? DateTime.now();
    return end.difference(startDate).inDays;
  }

  factory LaborTask.fromJson(Map<String, dynamic> json, String id) {
    return LaborTask(
      id: id,
      projectId: json['projectId'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Task',
      laborerCount: json['laborerCount'] as int? ?? 0,
      role: json['role'] as String? ?? '',
      completionPercentage: (json['completionPercentage'] as num? ?? 0.0)
          .toDouble(),
      startDate: alray_date.DateUtils.parseRequired(
        json['startDate'] ?? json['date'],
      ),
      endDate: alray_date.DateUtils.parse(json['endDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'name': name,
      'laborerCount': laborerCount,
      'role': role,
      'completionPercentage': completionPercentage,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    };
  }

  LaborTask copyWith({
    String? id,
    String? projectId,
    String? name,
    int? laborerCount,
    String? role,
    double? completionPercentage,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
  }) {
    return LaborTask(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      laborerCount: laborerCount ?? this.laborerCount,
      role: role ?? this.role,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
    );
  }
}
