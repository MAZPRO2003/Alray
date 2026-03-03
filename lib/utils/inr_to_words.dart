class InrToWords {
  static const List<String> _units = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen',
  ];

  static const List<String> _tens = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety',
  ];

  static String convert(double amount) {
    if (amount == 0) return 'Zero Rupees Only';

    int whole = amount.floor();
    int paise = ((amount - whole) * 100).round();

    String result = _convertWhole(whole);
    if (result.isEmpty) {
      result = 'Zero';
    }
    result += ' Rupees';

    if (paise > 0) {
      result += ' and ${_convertWhole(paise)} Paise';
    }

    return '$result Only';
  }

  static String _convertWhole(int n) {
    if (n < 0) return 'Minus ${_convertWhole(-n)}';
    if (n == 0) return '';

    if (n < 20) return _units[n];

    if (n < 100) {
      return '${_tens[n ~/ 10]}${n % 10 != 0 ? ' ${_units[n % 10]}' : ''}';
    }

    if (n < 1000) {
      return '${_units[n ~/ 100]} Hundred${n % 100 != 0 ? ' and ${_convertWhole(n % 100)}' : ''}';
    }

    if (n < 100000) {
      return '${_convertWhole(n ~/ 1000)} Thousand${n % 1000 != 0 ? ' ${_convertWhole(n % 1000)}' : ''}';
    }

    if (n < 10000000) {
      return '${_convertWhole(n ~/ 100000)} Lakh${n % 100000 != 0 ? ' ${_convertWhole(n % 100000)}' : ''}';
    }

    return '${_convertWhole(n ~/ 10000000)} Crore${n % 10000000 != 0 ? ' ${_convertWhole(n % 10000000)}' : ''}';
  }
}
