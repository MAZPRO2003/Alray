class AppValidators {
  /// Validates email address using a standard regex.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validates Indian phone number (10 digits starting with 6-9).
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    // Remove all non-digits for validation
    final clean = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Check if it's 10 digits and starts with 6, 7, 8, or 9
    final phoneRegex = RegExp(r'^[6-9]\d{9}$');

    if (!phoneRegex.hasMatch(clean)) {
      if (clean.length != 10) {
        return 'Must be exactly 10 digits';
      }
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  /// Optional phone validation (returns null if empty, but validates if not empty)
  static String? validateOptionalPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return validatePhone(value);
  }
}
