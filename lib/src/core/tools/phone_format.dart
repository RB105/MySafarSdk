import 'package:mysafar_sdk/src/core/widgets/county_pick/src/country_codes.dart'
    show codes;

/// Xalqaro telefon raqamini davlat kodiga mos maska bilan formatlaydi.
///
/// Masalan: `998901234567` → `+998 90 123 45 67`
/// Davlat topilmasa: `+998901234567`
String formatInternationalPhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return '';

  Map<String, String>? match;
  var bestLen = 0;
  for (final country in codes) {
    final dial = country['country_code'] ?? '';
    if (dial.isNotEmpty &&
        digits.startsWith(dial) &&
        dial.length > bestLen) {
      bestLen = dial.length;
      match = country;
    }
  }

  if (match == null) return '+$digits';

  final dial = match['country_code']!;
  final national = digits.substring(dial.length);
  final mask = match['phone_mask'] ?? '## ### ## ##';
  final formattedNational = _applyPhoneMask(national, mask);
  if (formattedNational.isEmpty) return '+$dial';
  return '+$dial $formattedNational';
}

/// Faqat raqamlarni qaytaradi (`998901234567`).
String normalizePhoneDigits(String raw) =>
    raw.replaceAll(RegExp(r'[^0-9]'), '');

String _applyPhoneMask(String digits, String mask) {
  if (digits.isEmpty) return '';
  final buf = StringBuffer();
  var di = 0;
  for (var i = 0; i < mask.length; i++) {
    final ch = mask[i];
    if (ch == '#' || ch == 'X' || ch == 'x') {
      if (di >= digits.length) break;
      buf.write(digits[di++]);
    } else {
      if (di >= digits.length) break;
      buf.write(ch);
    }
  }
  if (di < digits.length) {
    buf.write(digits.substring(di));
  }
  return buf.toString();
}
