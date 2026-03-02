import 'package:intl/intl.dart';

class CurrencyUtils {
  static bool useIndianSystem = true;

  static String formatInr(double amount) {
    if (useIndianSystem) {
      if (amount >= 10000000) {
        final crores = amount / 10000000;
        return '₹${crores.toStringAsFixed(2)} Cr';
      } else if (amount >= 100000) {
        final lakhs = amount / 100000;
        return '₹${lakhs.toStringAsFixed(2)} Lk';
      } else {
        final formatter = NumberFormat.currency(
          locale: 'en_IN',
          symbol: '₹',
          decimalDigits: 2,
        );
        return formatter.format(amount);
      }
    } else {
      // International System (Million/Billion)
      if (amount >= 1000000000) {
        final billions = amount / 1000000000;
        return '₹${billions.toStringAsFixed(2)} B';
      } else if (amount >= 1000000) {
        final millions = amount / 1000000;
        return '₹${millions.toStringAsFixed(2)} M';
      } else {
        final formatter = NumberFormat.currency(
          locale: 'en_US',
          symbol: '₹',
          decimalDigits: 2,
        );
        return formatter.format(amount);
      }
    }
  }
}
