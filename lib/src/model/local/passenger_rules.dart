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

  /// Urg'uli lotin harflari → asosiy harf (pasport MRZ'dagidek): Ç→C, İ→I,
  /// Ş→S, Ü→U, Ñ→N... Aviachipta tizimlari faqat A–Z ni qabul qiladi.
  static const Map<String, String> _latinFold = {
    'À': 'A',
    'Á': 'A',
    'Â': 'A',
    'Ã': 'A',
    'Ä': 'A',
    'Å': 'A',
    'Ā': 'A',
    'Ă': 'A',
    'Ą': 'A',
    'Æ': 'AE',
    'Ç': 'C',
    'Ć': 'C',
    'Č': 'C',
    'Ď': 'D',
    'Đ': 'D',
    'Ð': 'D',
    'È': 'E',
    'É': 'E',
    'Ê': 'E',
    'Ë': 'E',
    'Ē': 'E',
    'Ė': 'E',
    'Ę': 'E',
    'Ě': 'E',
    'Ğ': 'G',
    'Ģ': 'G',
    'Ì': 'I',
    'Í': 'I',
    'Î': 'I',
    'Ï': 'I',
    'Ī': 'I',
    'Į': 'I',
    'İ': 'I',
    'Ķ': 'K',
    'Ł': 'L',
    'Ľ': 'L',
    'Ļ': 'L',
    'Ñ': 'N',
    'Ń': 'N',
    'Ň': 'N',
    'Ņ': 'N',
    'Ò': 'O',
    'Ó': 'O',
    'Ô': 'O',
    'Õ': 'O',
    'Ö': 'O',
    'Ø': 'O',
    'Ō': 'O',
    'Ő': 'O',
    'Œ': 'OE',
    'Ŕ': 'R',
    'Ř': 'R',
    'Ś': 'S',
    'Š': 'S',
    'Ş': 'S',
    'Ș': 'S',
    'ẞ': 'SS',
    'Ť': 'T',
    'Ţ': 'T',
    'Ț': 'T',
    'Þ': 'TH',
    'Ù': 'U',
    'Ú': 'U',
    'Û': 'U',
    'Ü': 'U',
    'Ū': 'U',
    'Ů': 'U',
    'Ű': 'U',
    'Ų': 'U',
    'Ý': 'Y',
    'Ÿ': 'Y',
    'Ź': 'Z',
    'Ž': 'Z',
    'Ż': 'Z',
  };

  /// Harf (modifikator harflarsiz: o'zbekcha ʻ/ʼ Unicode'da "harf" deb
  /// hisoblanadi, lekin ular apostrof — tashlanadi).
  static final RegExp _letter =
      RegExp(r'[\p{Lu}\p{Ll}\p{Lt}\p{Lo}]', unicode: true);

  /// Ismni aviachipta ko'rinishiga keltiradi: katta harf, urg'uli lotin →
  /// asosiy harf, apostrof (O'G'LI → OGLI, pasport MRZ'dagidek), raqam, bo'sh
  /// joy va tinish belgilari tashlanadi.
  ///
  /// Kirill va boshqa yozuvlardagi harflar ATAYIN o'zgartirilmaydi va
  /// o'chirilmaydi: o'zbek va rus pasportlarida imlo har xil (ХУРШИД →
  /// XURSHID yoki KHURSHID), noto'g'ri transliteratsiya chiptani yaroqsiz
  /// qiladi. Ular maydonda qoladi va [isLatinName] "pasportdagidek lotincha
  /// yozing" xatosini beradi — harf hech qachon jimgina yo'qolmaydi.
  static String normalizeName(String? value) {
    final upper = (value ?? '').toUpperCase();
    final buffer = StringBuffer();
    for (final rune in upper.runes) {
      final char = String.fromCharCode(rune);
      final folded = _latinFold[char];
      if (folded != null) {
        buffer.write(folded);
      } else if (char == '-' || _letter.hasMatch(char)) {
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
            // Uchishda 2 yoshga to'lmagan, lekin qaytishgacha to'ladigan
            // bola chaqaloq sifatida o'tmaydi — bola sifatida bron qilinadi.
            final turnsTwoOnTrip =
                age < _childMinAge && ageAt(birth, end) >= _childMinAge;
            return ((age >= _childMinAge || turnsTwoOnTrip) &&
                    age < _adultMinAge)
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

/// Ism maydonlari uchun formatter: yozish paytida katta harfga o'tkazadi,
/// urg'uli lotin harflarini asosiy harfga keltiradi, apostrof/raqam/bo'sh
/// joyni tashlaydi. Kirill harflari qoladi — tekshiruv lotincha yozishni
/// so'raydi.
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
