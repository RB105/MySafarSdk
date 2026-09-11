import 'package:flutter/services.dart';
import 'package:mysafar_sdk/src/core/widgets/county_pick/src/country_codes.dart'
    show codes;

/// E.164 bo'yicha maksimal raqamlar soni.
const int kMaxPhoneDigits = 15;

/// Xalqaro telefon raqamini davlat kodiga mos maska bilan formatlaydi.
///
/// Masalan: `998901234567` → `+998 90 123 45 67`
/// Davlat topilmasa: `+998901234567`
String formatInternationalPhone(String raw) {
  final digits = normalizePhoneDigits(raw);
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

/// Faqat raqamlarni qabul qiladi; `+` va bo'shliqlarni o'zi qo'yadi.
/// User `+`, `-`, harf va boshqa belgilarni kiritolmaydi.
class InternationalPhoneInputFormatter extends TextInputFormatter {
  const InternationalPhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = normalizePhoneDigits(newValue.text);
    if (digits.length > kMaxPhoneDigits) {
      digits = digits.substring(0, kMaxPhoneDigits);
    }
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final formatted = formatInternationalPhone(digits);

    final rawSelection = newValue.selection.end;
    final clampedSelection =
        rawSelection.clamp(0, newValue.text.length).toInt();
    var digitsBeforeCursor =
        normalizePhoneDigits(newValue.text.substring(0, clampedSelection))
            .length;
    if (digitsBeforeCursor > digits.length) {
      digitsBeforeCursor = digits.length;
    }

    var cursor = formatted.length;
    if (digitsBeforeCursor == 0) {
      // `+` dan keyin turadi — user `+`ni o'chira olmaydi.
      cursor = formatted.startsWith('+') ? 1 : 0;
    } else {
      var seen = 0;
      for (var i = 0; i < formatted.length; i++) {
        final code = formatted.codeUnitAt(i);
        if (code >= 0x30 && code <= 0x39) {
          seen++;
          if (seen == digitsBeforeCursor) {
            cursor = i + 1;
            break;
          }
        }
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}
