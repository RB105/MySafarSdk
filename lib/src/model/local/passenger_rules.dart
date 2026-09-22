import 'package:flutter/services.dart';
import 'package:mysafar_sdk/src/model/local/passenger_model.dart';

/// Yo'lovchi ma'lumotlari uchun aviakompaniya qoidalari — bron serverga
/// yuborilishidan OLDIN tekshiriladi. Aks holda foydalanuvchi 3 ta ekranni
/// to'ldirib, faqat oxirgi qadamda server xatosini olardi (muddati o'tgan
/// pasport, yosh toifasiga mos kelmaydigan tug'ilgan sana, kirill ism).
class PassengerRules {
  PassengerRules._();

  static const int _childMinAge = 2;
  static const int _adultMinAge = 12;

  // ── Ism ────────────────────────────────────────────────────────────

  /// Kirill (rus, o'zbek, qozoq, tojik) → lotin, ICAO 9303 transliteratsiyasiga
  /// yaqin. Aviachipta tizimlari faqat A–Z harflarini qabul qiladi.
  static const Map<String, String> _cyrillicToLatin = {
    'А': 'A', 'Б': 'B', 'В': 'V', 'Г': 'G', 'Д': 'D', 'Е': 'E', 'Ё': 'E',
    'Ж': 'ZH', 'З': 'Z', 'И': 'I', 'Й': 'I', 'К': 'K', 'Л': 'L', 'М': 'M',
    'Н': 'N', 'О': 'O', 'П': 'P', 'Р': 'R', 'С': 'S', 'Т': 'T', 'У': 'U',
    'Ф': 'F', 'Х': 'KH', 'Ц': 'TS', 'Ч': 'CH', 'Ш': 'SH', 'Щ': 'SHCH',
    'Ъ': 'IE', 'Ы': 'Y', 'Ь': '', 'Э': 'E', 'Ю': 'IU', 'Я': 'IA',
    // O'zbek
    'Ў': 'O', 'Қ': 'Q', 'Ғ': 'G', 'Ҳ': 'H',
    // Qozoq / tojik
    'Ә': 'A', 'Ң': 'N', 'Ө': 'O', 'Ұ': 'U', 'Ү': 'U', 'Һ': 'H', 'І': 'I',
    'Ӣ': 'I', 'Ӯ': 'U', 'Ҷ': 'J',
  };

  /// Ismni hujjat/aviachipta ko'rinishiga keltiradi: katta harf, kirill →
  /// lotin, apostroflar (O'G'LI → OGLI, pasport MRZ'dagidek) va raqam, bo'sh
  /// joy, boshqa belgilar olib tashlanadi. Faqat A–Z va `-` qoladi.
  static String normalizeName(String? value) {
    final upper = (value ?? '').toUpperCase();
    final buffer = StringBuffer();
    for (final rune in upper.runes) {
      final char = String.fromCharCode(rune);
      final latin = _cyrillicToLatin[char];
      if (latin != null) {
        buffer.write(latin);
      } else if (RegExp(r'[A-Z-]').hasMatch(char)) {
        buffer.write(char);
      }
      // Qolganlari (', ’, ʻ, raqam, bo'sh joy, nuqta...) tashlab yuboriladi.
    }
    return buffer.toString();
  }

  static bool isLatinName(String value) =>
      RegExp(r'^[A-Z]+(-[A-Z]+)*$').hasMatch(value);

  // ── Sanalar ────────────────────────────────────────────────────────

  /// Forma sanasi `dd.MM.yyyy` (qat'iy). Noto'g'ri bo'lsa `null`.
  static DateTime? parseFormDate(String? raw) {
    final match =
        RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$').firstMatch((raw ?? '').trim());
    if (match == null) return null;
    final day = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final year = int.parse(match[3]!);
    final date = DateTime(year, month, day);
    // 31.02.2000 kabi mavjud bo'lmagan sanalar.
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  /// Reys sanasi: `dd.MM.yyyy` yoki ISO (`yyyy-MM-dd...`).
  static DateTime? parseFlightDate(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;
    final form =
        parseFormDate(value.length >= 10 ? value.substring(0, 10) : value);
    if (form != null) return form;
    final iso = DateTime.tryParse(value);
    return iso == null ? null : DateTime(iso.year, iso.month, iso.day);
  }

  /// [at] sanasida to'liq yillar soni.
  static int ageAt(DateTime birth, DateTime at) {
    var age = at.year - birth.year;
    if (at.month < birth.month ||
        (at.month == birth.month && at.day < birth.day)) {
      age--;
    }
    return age;
  }

  // ── Tekshiruv ──────────────────────────────────────────────────────

  /// Bitta maydon uchun qoida xatosi (tarjima kaliti) yoki `null`.
  /// Bo'sh qiymatlar bu yerda tekshirilmaydi — ular "to'ldirilmagan" xatosi.
  ///
  /// [ageType] — `adt` / `chd` / `inf`. [firstFlight] / [lastFlight] —
  /// birinchi uchish va oxirgi qo'nish sanalari (noma'lum bo'lsa bugun).
  static String? fieldError(
    String field,
    String value, {
    required String ageType,
    DateTime? firstFlight,
    DateTime? lastFlight,
    DateTime? today,
  }) {
    final text = value.trim();
    if (text.isEmpty) return null;
    final now = _dateOnly(today ?? DateTime.now());
    final start = firstFlight ?? now;
    final end = lastFlight ?? start;

    switch (field) {
      case 'firstname':
      case 'lastname':
      case 'middlename':
        return isLatinName(text) ? null : 'name_latin_only';
      case 'birthdate':
        final birth = parseFormDate(text);
        if (birth == null) return 'invalid_date_format';
        if (birth.isAfter(now)) return 'birthdate_in_future';
        // Kattalar va bolalar yoshi uchish kuni, chaqaloq esa butun safar
        // davomida 2 yoshga to'lmagan bo'lishi kerak.
        switch (ageType) {
          case PassengerConstants.ageInfant:
            return ageAt(birth, end) < _childMinAge
                ? null
                : 'passenger_age_mismatch_infant';
          case PassengerConstants.ageChild:
            final age = ageAt(birth, start);
            return (age >= _childMinAge && age < _adultMinAge)
                ? null
                : 'passenger_age_mismatch_child';
          default:
            return ageAt(birth, start) >= _adultMinAge
                ? null
                : 'passenger_age_mismatch_adult';
        }
      case 'docexp':
        final expiry = parseFormDate(text);
        if (expiry == null) return 'invalid_date_format';
        // Hujjat safar tugaguncha amal qilishi shart.
        return expiry.isBefore(end) ? 'passport_expires_before_trip' : null;
    }
    return null;
  }

  /// Qoidaga zid maydonlar (forma tartibida): `(maydon, tarjima kaliti)`.
  static List<(String, String)> invalidFields(
    PassengerModel passenger, {
    DateTime? firstFlight,
    DateTime? lastFlight,
    DateTime? today,
  }) {
    final values = <String, String>{
      'lastname': passenger.lastname,
      'firstname': passenger.firstname,
      'middlename': passenger.middlename,
      'birthdate': passenger.birthdate,
      'docexp': passenger.docexp,
    };
    return [
      for (final entry in values.entries)
        if (fieldError(
          entry.key,
          entry.value,
          ageType: passenger.age,
          firstFlight: firstFlight,
          lastFlight: lastFlight,
          today: today,
        )
            case final String error)
          (entry.key, error),
    ];
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

/// Ism maydonlari uchun formatter: yozish paytida kirill harflarini lotinga
/// o'giradi, apostrof/raqam/bo'sh joyni tashlaydi (aviachipta faqat A–Z).
class PassengerNameFormatter extends TextInputFormatter {
  const PassengerNameFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // IME kompozitsiyasi paytida (masalan, klaviatura taklifi) tegmaymiz.
    if (newValue.composing.isValid && !newValue.composing.isCollapsed) {
      return newValue;
    }
    final normalized = PassengerRules.normalizeName(newValue.text);
    if (normalized == newValue.text) return newValue;
    final cursorBase =
        newValue.selection.baseOffset.clamp(0, newValue.text.length);
    final beforeCursor =
        PassengerRules.normalizeName(newValue.text.substring(0, cursorBase));
    return TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: beforeCursor.length),
    );
  }
}
