import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class Milestone {
  final String id;
  final String projectId;
  final String title;
  final bool isCompleted;
  final DateTime dateCreated;

  Milestone({
    String? id,
    required this.projectId,
    required this.title,
    this.isCompleted = false,
    DateTime? dateCreated,
  }) : id = id ?? uuid.v4(),
       dateCreated = dateCreated ?? DateTime.now();

  factory Milestone.fromJson(Map<String, dynamic> json, String id) {
    return Milestone(
      id: id,
      projectId: json['projectId'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Milestone',
      isCompleted: json['isCompleted'] as bool? ?? false,
      dateCreated: json['dateCreated'] != null
          ? (json['dateCreated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'title': title,
      'isCompleted': isCompleted,
      'dateCreated': Timestamp.fromDate(dateCreated),
    };
  }

  Milestone copyWith({
    String? id,
    String? projectId,
    String? title,
    bool? isCompleted,
    DateTime? dateCreated,
  }) {
    return Milestone(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      dateCreated: dateCreated ?? this.dateCreated,
    );
  }
}
