import 'package:intl/intl.dart';

class CurrencyUtils {
  static String formatInr(double amount) {
    if (amount >= 10000000) {
      final crores = amount / 10000000;
      return '₹${crores.toStringAsFixed(2)} Crores';
    } else if (amount >= 100000) {
      final lakhs = amount / 100000;
      return '₹${lakhs.toStringAsFixed(2)} Lakhs';
    } else {
      // Use standard Indian comma formatting for smaller amounts
      final formatter = NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: 2,
      );
      return formatter.format(amount);
    }
  }
}
