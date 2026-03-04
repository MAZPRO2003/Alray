import 'package:cloud_firestore/cloud_firestore.dart';

class DateUtils {
  static DateTime? parse(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static DateTime parseRequired(dynamic value, {DateTime? fallback}) {
    return parse(value) ?? fallback ?? DateTime.now();
  }
}
