import 'package:flutter/services.dart';

/// Nepali mobile numbers: exactly 10 digits, starting with 98 or 97.
final RegExp kNepaliMobileRegExp = RegExp(r'^9[78]\d{8}$');

/// Validate a Nepali mobile number (the part after the +977 prefix).
///
/// Returns an error message when invalid, or null when valid.
/// When [required] is false an empty value is accepted (returns null).
String? validateNepaliPhone(String raw, {bool required = true}) {
  final p = raw.trim();
  if (p.isEmpty) {
    return required ? 'Phone number is required' : null;
  }
  if (!kNepaliMobileRegExp.hasMatch(p)) {
    return 'Enter a valid 10-digit number starting with 98 or 97';
  }
  return null;
}

/// Input formatter that keeps a phone field constrained to a valid Nepali
/// mobile number as the user types: digits only, max 10, first digit 9 and
/// second digit 7 or 8. Invalid keystrokes are rejected (old value kept).
class NepaliMobileFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) digits = digits.substring(0, 10);

    // Enforce the 98/97 prefix as it's typed.
    if (digits.isNotEmpty && digits[0] != '9') return oldValue;
    if (digits.length >= 2 && digits[1] != '7' && digits[1] != '8') {
      return oldValue;
    }

    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}
