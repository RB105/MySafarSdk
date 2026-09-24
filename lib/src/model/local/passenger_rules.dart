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
  /// asosiy harf, apostrof (O'G'LI → OGLI, pasport MRZ'dagidek), raqam va
  /// tinish belgilari tashlanadi. Ism ichidagi bo'sh joy saqlanadi (№73):
  /// "ANNA MARIA" pasportdagidek qoladi — ketma-ket bo'sh joylar bittaga
  /// qisqaradi, boshi/oxiri kesiladi, `-` atrofidagi bo'sh joy tashlanadi.
  ///
  /// Kirill va boshqa yozuvlardagi harflar ATAYIN o'zgartirilmaydi va
  /// o'chirilmaydi: o'zbek va rus pasportlarida imlo har xil (ХУРШИД →
  /// XURSHID yoki KHURSHID), noto'g'ri transliteratsiya chiptani yaroqsiz
  /// qiladi. Ular maydonda qoladi va [isLatinName] "pasportdagidek lotincha
  /// yozing" xatosini beradi — harf hech qachon jimgina yo'qolmaydi.
  static String normalizeName(String? value) =>
      normalizeNameInput(value).trim();

  /// Yozish paytidagi ko'rinish ([normalizeName] bilan bir xil, faqat oxirgi
  /// bitta bo'sh joy saqlanadi — "ANNA " dan keyin "MARIA" yozish mumkin).
  static String normalizeNameInput(String? value) {
    final upper = (value ?? '').toUpperCase();
    var out = '';
    for (final rune in upper.runes) {
      final char = String.fromCharCode(rune);
      final folded = _latinFold[char];
      if (folded != null) {
        out += folded;
      } else if (char == '-') {
        // "ANNA - MARIA" → "ANNA-MARIA".
        if (out.endsWith(' ')) out = out.substring(0, out.length - 1);
        out += char;
      } else if (_letter.hasMatch(char)) {
        out += char;
      } else if (_space.hasMatch(char)) {
        if (out.isNotEmpty && !out.endsWith(' ') && !out.endsWith('-')) {
          out += ' ';
        }
      }
      // Qolganlari (', ’, ʻ, raqam, nuqta...) tashlab yuboriladi.
    }
    return out;
  }

  static final RegExp _space = RegExp(r'\s');

  static bool isLatinName(String value) =>
      RegExp(r'^[A-Z]+([ -][A-Z]+)*$').hasMatch(value);

  // ── Hujjat raqami ──────────────────────────────────────────────────

  /// Lotin harfiga o'xshash kirill harflari (rus klaviaturasida "АА1234567"
  /// lotin "AA" dan farq qilmaydi) → lotin harfi (№69).
  static const Map<String, String> _cyrillicLookalike = {
    'А': 'A',
    'В': 'B',
    'Е': 'E',
    'К': 'K',
    'М': 'M',
    'Н': 'H',
    'О': 'O',
    'Р': 'P',
    'С': 'C',
    'Т': 'T',
    'Х': 'X',
    'У': 'Y',
    'І': 'I',
  };

  /// Hujjat raqamini normallashtiradi (№69): katta harf, o'xshash kirill
  /// harflari lotinga o'giriladi, "№", "-", "/", nuqta va bo'sh joylar
  /// tashlanadi.
  ///
  /// Istisno: raqamda o'xshashi yo'q kirill harfi bo'lsa (masalan rus
  /// tug'ilganlik guvohnomasi "V-ЛЮ 123456") — bu haqiqiy kirill seriya,
  /// harflar o'zgartirilmaydi va faqat bo'sh joylar olib tashlanadi
  /// (avvalgi xulq).
  static String normalizeDocnum(String? value) {
    final upper = (value ?? '').toUpperCase();
    if (hasCyrillicSeries(upper)) return upper.replaceAll(_space, '');
    final buffer = StringBuffer();
    for (final rune in upper.runes) {
      final char = String.fromCharCode(rune);
      final mapped = _cyrillicLookalike[char];
      if (mapped != null) {
        buffer.write(mapped);
      } else if (_docnumChar.hasMatch(char) || _letter.hasMatch(char)) {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  static final RegExp _docnumChar = RegExp(r'[A-Z0-9]');

  /// Kirill seriyali hujjatmi: rus tug'ilganlik guvohnomasi (rim raqami +
  /// 2 ta kirill harf, masalan "II-АВ 123456" — harflar lotinga o'xshash
  /// bo'lsa ham) yoki lotinga o'xshashi yo'q kirill harfi bor (Д, Ю, Л, Я ...).
  static bool hasCyrillicSeries(String value) {
    final upper = value.toUpperCase();
    if (_birthCertificate.hasMatch(upper.replaceAll(_space, ''))) return true;
    for (final rune in upper.runes) {
      final char = String.fromCharCode(rune);
      if (_cyrillic.hasMatch(char) && !_cyrillicLookalike.containsKey(char)) {
        return true;
      }
    }
    return false;
  }

  static final RegExp _cyrillic = RegExp(r'[\u0400-\u04FF]');
  static final RegExp _birthCertificate =
      RegExp(r'^[IVXLCІ]+-?[\u0400-\u04FF]{2}\d{6}$');

  /// Yozish paytidagi yengil normallashtirish: faqat katta harf va bo'sh
  /// joylarsiz. To'liq [normalizeDocnum] butun qiymatga (saqlashda) qo'llanadi
  /// — aks holda harf-harf o'girish kirill seriyani buzardi.
  static String typingDocnum(String? value) =>
      (value ?? '').toUpperCase().replaceAll(_space, '');

  static bool isValidDocnum(String value) {
    final normalized = normalizeDocnum(value);
    if (RegExp(r'^[A-Z0-9]+$').hasMatch(normalized)) return true;
    // Kirill seriyali guvohnoma: harf, raqam va "-" ga ruxsat.
    return hasCyrillicSeries(normalized) &&
        RegExp(r'^[A-Z\u0400-\u04FF0-9-]+$').hasMatch(normalized);
  }

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

  /// Server / skaner sanasini (`yyyy-MM-dd...`) forma ko'rinishiga
  /// (`dd.MM.yyyy`) keltiradi (№68). Forma sanasi o'zgarmaydi; tanilmagan
  /// qiymat ham o'zgarmaydi (tekshiruv "noto'g'ri format" deydi).
  static String toFormDate(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty || parseFormDate(value) != null) return value;
    if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(value)) {
      final iso = DateTime.tryParse(value.substring(0, 10));
      if (iso != null) return formatFormDate(iso);
    }
    return value;
  }

  /// `dd.MM.yyyy`.
  static String formatFormDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.'
      '${date.year.toString().padLeft(4, '0')}';

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
      case 'docnum':
        return isValidDocnum(text) ? null : 'docnum_latin_only';
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
      'docnum': passenger.docnum,
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

  /// Tug'ilgan sana tanlagichi qaysi sanadan boshlansin — yosh toifasiga mos
  /// (kattalar ~30, bola ~6, chaqaloq ~1 yosh, uchish kuniga nisbatan) va
  /// bugundan keyin emas.
  static DateTime suggestedBirthdate(
    String ageType, {
    DateTime? firstFlight,
    DateTime? today,
  }) {
    final now = _dateOnly(today ?? DateTime.now());
    final base = firstFlight ?? now;
    final years = switch (ageType) {
      PassengerConstants.ageInfant => 1,
      PassengerConstants.ageChild => 6,
      _ => 30,
    };
    final suggested = DateTime(base.year - years, base.month, 1);
    return suggested.isAfter(now) ? now : suggested;
  }

  /// Saqlangan yo'lovchining tug'ilgan sanasi ([raw] — `dd.MM.yyyy` yoki ISO)
  /// slotning yosh toifasiga mos keladimi. Sana noma'lum bo'lsa — `true`
  /// (ro'yxatdan yashirilmaydi, tekshiruv formada bo'ladi).
  static bool fitsAgeType(
    String? raw,
    String ageType, {
    DateTime? firstFlight,
    DateTime? lastFlight,
    DateTime? today,
  }) {
    final birth = parseFlightDate(raw);
    if (birth == null) return true;
    final formatted = '${birth.day.toString().padLeft(2, '0')}.'
        '${birth.month.toString().padLeft(2, '0')}.${birth.year}';
    return fieldError(
          'birthdate',
          formatted,
          ageType: ageType,
          firstFlight: firstFlight,
          lastFlight: lastFlight,
          today: today,
        ) ==
        null;
  }

  /// Bola/chaqaloq bilan uchadigan hamroh uchish kuni shu yoshga to'lgan
  /// bo'lishi kerak (aviakompaniyalar "katta" = 12+ ni hamroh deb olmaydi).
  static const int accompanyingAdultAge = 18;

  /// Bola yoki chaqaloq bor bo'lsa, kamida bitta katta yo'lovchi uchish
  /// kuni 18 yoshga to'lgan bo'lishi kerak (№71). Qoida buzilsa — xato
  /// ko'rsatiladigan katta yo'lovchi indeksi (birinchisi), aks holda `null`.
  /// Tug'ilgan sanasi o'qilmaydigan katta yo'lovchi bo'lsa tekshirilmaydi
  /// (u baribir sana xatosini oladi).
  static int? accompanyingAdultIssue(
    List<PassengerModel> passengers, {
    DateTime? firstFlight,
    DateTime? today,
  }) {
    final hasMinor = passengers.any((p) =>
        p.age == PassengerConstants.ageChild ||
        p.age == PassengerConstants.ageInfant);
    if (!hasMinor) return null;
    final at = firstFlight ?? _dateOnly(today ?? DateTime.now());
    int? firstAdult;
    for (int i = 0; i < passengers.length; i++) {
      final p = passengers[i];
      if (p.age != PassengerConstants.ageAdult) continue;
      firstAdult ??= i;
      final birth = parseFormDate(p.birthdate);
      if (birth == null) return null;
      if (ageAt(birth, at) >= accompanyingAdultAge) return null;
    }
    return firstAdult ?? 0;
  }

  /// Pasport oxirgi reysdan keyin 6 oydan kam muddatda tugaydimi (№72).
  /// Ko'p davlatlar (Turkiya, BAA, Misr...) bunday pasport bilan kiritmaydi —
  /// bu faqat YUMSHOQ ogohlantirish uchun. Safar tugashidan oldin tugaydigan
  /// pasport bu yerda `false` — u [fieldError] da qat'iy xato.
  static bool passportExpiresSoon(
    String docexp, {
    DateTime? lastFlight,
    DateTime? today,
  }) {
    final expiry = parseFormDate(docexp);
    if (expiry == null) return false;
    final end = lastFlight ?? _dateOnly(today ?? DateTime.now());
    if (expiry.isBefore(end)) return false;
    return expiry.isBefore(DateTime(end.year, end.month + 6, end.day));
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

/// Ism maydonlari uchun formatter: yozish paytida katta harfga o'tkazadi,
/// urg'uli lotin harflarini asosiy harfga keltiradi, apostrof/raqamni
/// tashlaydi, bo'sh joylarni bittaga qisqartiradi. Kirill harflari qoladi —
/// tekshiruv lotincha yozishni so'raydi.
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
    return _normalizeEdit(newValue, PassengerRules.normalizeNameInput);
  }
}

/// Hujjat raqami formatteri (№69): yozish paytida faqat katta harf va bo'sh
/// joysiz ([PassengerRules.typingDocnum]); to'liq normallashtirish
/// ([PassengerRules.normalizeDocnum]) saqlashda.
class DocumentNumberFormatter extends TextInputFormatter {
  const DocumentNumberFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.composing.isValid && !newValue.composing.isCollapsed) {
      return newValue;
    }
    return _normalizeEdit(newValue, PassengerRules.typingDocnum);
  }
}

/// Matnni [normalize] qiladi va kursorni normallashgan matndagi mos joyga
/// qo'yadi.
TextEditingValue _normalizeEdit(
    TextEditingValue value, String Function(String?) normalize) {
  final normalized = normalize(value.text);
  if (normalized == value.text) return value;
  final cursorBase = value.selection.baseOffset.clamp(0, value.text.length);
  final beforeCursor = normalize(value.text.substring(0, cursorBase));
  return TextEditingValue(
    text: normalized,
    selection: TextSelection.collapsed(
        offset: beforeCursor.length.clamp(0, normalized.length)),
  );
}
