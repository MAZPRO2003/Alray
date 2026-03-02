import 'package:cloud_firestore/cloud_firestore.dart';

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
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      resolvedAt: json['resolvedAt'] != null
          ? (json['resolvedAt'] as Timestamp).toDate()
          : null,
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
