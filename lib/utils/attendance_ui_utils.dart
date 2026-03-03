import 'package:alray_app/models/attendance.dart';
import 'package:intl/intl.dart';

class AttendanceUIUtils {
  static double calculateTotalCost(Attendance attendance) {
    double total = 0;
    attendance.workerCounts.forEach((role, count) {
      final wage = attendance.workerWages[role] ?? 0.0;
      total += count * wage;
    });
    return total;
  }

  static String formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(amount);
  }

  static double calculateRoleCost(Attendance attendance, String role) {
    final count = attendance.workerCounts[role] ?? 0;
    final wage = attendance.workerWages[role] ?? 0.0;
    return count * wage;
  }
}
