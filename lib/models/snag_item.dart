import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alray_app/utils/date_utils.dart' as alray_date;

enum SnagStatus { pending, inProgress, resolved }

enum SnagPriority { low, medium, high }

class SnagItem {
  final String id;
  final String projectId;
  final String description;
  final SnagStatus status;
  final SnagPriority priority;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  SnagItem({
    required this.id,
    required this.projectId,
    required this.description,
    this.status = SnagStatus.pending,
    this.priority = SnagPriority.medium,
    required this.createdAt,
    this.resolvedAt,
  });

  factory SnagItem.fromJson(Map<String, dynamic> json, String id) {
    return SnagItem(
      id: id,
      projectId: json['projectId'] ?? '',
      description: json['description'] ?? '',
      status: SnagStatus.values.firstWhere(
        (e) => e.toString() == 'SnagStatus.${json['status']}',
        orElse: () => SnagStatus.pending,
      ),
      priority: SnagPriority.values.firstWhere(
        (e) => e.toString() == 'SnagPriority.${json['priority']}',
        orElse: () => SnagPriority.medium,
      ),
      createdAt: alray_date.DateUtils.parseRequired(json['createdAt']),
      resolvedAt: alray_date.DateUtils.parse(json['resolvedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'description': description,
      'status': status.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }
}
