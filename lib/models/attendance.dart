import 'package:uuid/uuid.dart';

const uuid = Uuid();

class Attendance {
  final String id;
  final String projectId;
  final DateTime date;
  final Map<String, int> workerCounts;
  final Map<String, double> workerWages;
  final List<String> presentWorkerIds;

  Attendance({
    String? id,
    required this.projectId,
    required this.date,
    this.workerCounts = const {},
    this.workerWages = const {},
    this.presentWorkerIds = const [],
  }) : id = id ?? uuid.v4();

  factory Attendance.fromJson(Map<String, dynamic> json, String documentId) {
    // Support legacy data structure by migrating to map
    Map<String, int> parsedCounts = {};
    if (json.containsKey('workerCounts')) {
      final counts = json['workerCounts'] as Map<String, dynamic>? ?? {};
      counts.forEach((key, value) {
        if (value is int) {
          parsedCounts[key] = value;
        } else if (value is String) {
          parsedCounts[key] = int.tryParse(value) ?? 0;
        }
      });
    } else {
      // Legacy data migration
      // Try resolving fields like mason, labour etc.
      final legacyFields = [
        'mason',
        'labour',
        'electrical',
        'plumber',
        'painter',
        'tileWork',
        'granite',
        'carpentry',
        'miscWork',
      ];
      for (var field in legacyFields) {
        if (json.containsKey(field) && json[field] != null) {
          final val = json[field];
          if (val is int && val > 0) {
            parsedCounts[field] = val;
          }
        }
      }
    }

    Map<String, double> parsedWages = {};
    if (json.containsKey('workerWages')) {
      final wages = json['workerWages'] as Map<String, dynamic>? ?? {};
      wages.forEach((key, value) {
        if (value is num) {
          parsedWages[key] = value.toDouble();
        } else if (value is String) {
          parsedWages[key] = double.tryParse(value) ?? 0.0;
        }
      });
    }

    return Attendance(
      id: documentId,
      projectId: json['projectId'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      workerCounts: parsedCounts,
      workerWages: parsedWages,
      presentWorkerIds:
          (json['presentWorkerIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'date': date.toIso8601String(),
      'workerCounts': workerCounts,
      'workerWages': workerWages,
      'presentWorkerIds': presentWorkerIds,
    };
  }
}
