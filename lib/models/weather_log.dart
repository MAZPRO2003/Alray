import 'package:cloud_firestore/cloud_firestore.dart';

class WeatherLog {
  final String id;
  final String projectId;
  final String userId;
  final DateTime date;
  final double temperature; // in Celsius
  final String condition; // e.g. "Clear", "Rain", "Cloudy"
  final String description; // Detailed description if available

  WeatherLog({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.date,
    required this.temperature,
    required this.condition,
    this.description = '',
  });

  factory WeatherLog.fromJson(Map<String, dynamic> json, String id) {
    return WeatherLog(
      id: id,
      projectId: json['projectId'] ?? '',
      userId: json['userId'] ?? '',
      date: json['date'] != null
          ? (json['date'] as Timestamp).toDate()
          : DateTime.now(),
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      condition: json['condition'] ?? 'Unknown',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'temperature': temperature,
      'condition': condition,
      'description': description,
    };
  }
}
