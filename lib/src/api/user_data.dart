/// Host app foydalanuvchisiga tegishli ixtiyoriy ma'lumotlar — `MySafarSdk.init`
/// (yoki keyinroq [MySafarSdk.updateUserData]) orqali beriladi.
///
/// Hamma maydon ixtiyoriy: hech narsa berilmasa SDK odatdagidek ishlaydi.
///
/// Xavfsizlik: karta va pasport ma'lumotlari faqat xotirada (in-memory)
/// saqlanadi — diskka, keshga yoki analytics'ga yozilmaydi, `toString()` da
/// karta raqami va shaxsiy ma'lumotlar maskalanadi. Ilova qayta ishga tushsa
/// host ularni yana berishi kerak.
///
/// Xaridor ma'lumotlari ([firstName], [lastName], [birthDate], hujjat) berilsa
/// bron formasida birinchi katta yoshli yo'lovchi shular bilan oldindan
/// to'ldiriladi (foydalanuvchi o'zgartirishi mumkin).
class MySafarUserData {
  const MySafarUserData({
    this.email,
    this.uzsCards = const [],
    this.foreignCards = const [],
    this.firstName,
    this.lastName,
    this.middleName,
    this.birthDate,
    this.gender,
    this.citizenship,
    this.documentNumber,
    this.documentExpiry,
  });

  /// Host user emaili. `MySafarEmbed.email` berilmasa shu ishlatiladi
  /// (telefon bilan ro'yxatdan o'tgach profilga yoziladi).
  final String? email;

  /// So'mdagi (UZS) kartalar — UzCard / Humo.
  final List<MySafarUzsCard> uzsCards;

  /// Boshqa valyutadagi kartalar (USD va h.k.) — token orqali.
  final List<MySafarForeignCard> foreignCards;

  /// Ism — pasportdagidek lotincha (masalan `VALI`).
  final String? firstName;

  /// Familiya — pasportdagidek lotincha (masalan `ALIYEV`).
  final String? lastName;

  /// Otasining ismi (ixtiyoriy).
  final String? middleName;

  /// Tug'ilgan sana (faqat sana qismi ishlatiladi).
  final DateTime? birthDate;

  /// Jinsi. Berilmasa formada tanlanmagan holda turadi.
  final MySafarGender? gender;

  /// Fuqarolik — ISO 3166-1 alpha-2 kodi (`UZ`, `RU`, `KZ` ...).
  final String? citizenship;

  /// Pasport / ID-karta raqami (masalan `AA1234567`).
  final String? documentNumber;

  /// Hujjatning amal qilish muddati.
  final DateTime? documentExpiry;

  bool get hasEmail => email?.trim().isNotEmpty ?? false;

  /// Yo'lovchi formasini to'ldirish uchun biror maydon berilganmi.
  bool get hasPassengerData =>
      _filled(firstName) ||
      _filled(lastName) ||
      birthDate != null ||
      _filled(documentNumber);

  static bool _filled(String? value) => value?.trim().isNotEmpty ?? false;

  static String? _clean(String? value, {bool upper = false}) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return upper ? trimmed.toUpperCase() : trimmed;
  }

  bool get hasCards => uzsCards.isNotEmpty || foreignCards.isNotEmpty;

  /// Bo'sh emailni `null` ga, yaroqsiz kartalarni tashlab yuborilgan nusxasini
  /// qaytaradi. Ro'yxatlar o'zgarmas (unmodifiable) bo'ladi.
  MySafarUserData sanitized() {
    final trimmedEmail = email?.trim();
    return MySafarUserData(
      email:
          (trimmedEmail == null || trimmedEmail.isEmpty) ? null : trimmedEmail,
      uzsCards: List.unmodifiable(uzsCards.where((c) => c.isValid)),
      foreignCards: List.unmodifiable(foreignCards.where((c) => c.isValid)),
      firstName: _clean(firstName, upper: true),
      lastName: _clean(lastName, upper: true),
      middleName: _clean(middleName, upper: true),
      birthDate: birthDate,
      gender: gender,
      // Faqat 2 harfli kod qabul qilinadi — boshqasi jim tashlanadi.
      citizenship: switch (_clean(citizenship, upper: true)) {
        final String code when RegExp(r'^[A-Z]{2}$').hasMatch(code) => code,
        _ => null,
      },
      documentNumber:
          _clean(documentNumber, upper: true)?.replaceAll(RegExp(r'\s+'), ''),
      documentExpiry: documentExpiry,
    );
  }

  MySafarUserData copyWith({
    String? email,
    List<MySafarUzsCard>? uzsCards,
    List<MySafarForeignCard>? foreignCards,
    String? firstName,
    String? lastName,
    String? middleName,
    DateTime? birthDate,
    MySafarGender? gender,
    String? citizenship,
    String? documentNumber,
    DateTime? documentExpiry,
  }) {
    return MySafarUserData(
      email: email ?? this.email,
      uzsCards: uzsCards ?? this.uzsCards,
      foreignCards: foreignCards ?? this.foreignCards,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      citizenship: citizenship ?? this.citizenship,
      documentNumber: documentNumber ?? this.documentNumber,
      documentExpiry: documentExpiry ?? this.documentExpiry,
    );
  }

  @override
  String toString() => 'MySafarUserData(email: ${hasEmail ? '***' : null}, '
      'passenger: ${hasPassengerData ? '***' : null}, '
      'uzsCards: $uzsCards, foreignCards: $foreignCards)';
}

/// Yo'lovchi jinsi ([MySafarUserData.gender]).
enum MySafarGender { male, female }

/// So'mdagi (UZS) karta — UzCard / Humo.
class MySafarUzsCard {
  const MySafarUzsCard({
    required this.cardNumber,
    required this.expire,
    this.cardMask,
    this.owner,
    this.balance,
    this.cardLogoUrl,
  });

  /// To'liq karta raqami (16 raqam). Bo'shliq/tire bo'lsa ham qabul qilinadi.
  final String cardNumber;

  /// Amal qilish muddati `YYMM` formatida (masalan `2812` — 12/2028).
  /// Backend'ning `expire` parametri bilan bir xil format.
  final String expire;

  /// Ko'rsatish uchun maska (masalan `8600 **** **** 1234`). Berilmasa
  /// [cardNumber] dan hosil qilinadi — qarang [displayMask].
  final String? cardMask;

  /// Karta egasi (masalan `ALIYEV VALI` yoki maskalangan `ALIYEV V*****`).
  /// UI'da [displayOwner] ishlatiladi.
  final String? owner;

  /// Karta balansi so'mda (tiyinda emas). Masalan `1250000.50`.
  final num? balance;

  /// Karta (processing) logotipining to'liq URL'i — `https://...` (`.svg` yoki
  /// `.png`/`.jpg`). Kartalar ro'yxatida ko'rsatiladi; berilmasa yoki
  /// yuklanmasa karta raqamiga qarab SDK'dagi UzCard / Humo logotipi chiqadi.
  final String? cardLogoUrl;

  /// Faqat raqamlar (`8600123412341234`).
  String get cardNumberDigits => cardNumber.replaceAll(RegExp(r'\D'), '');

  /// Host bergan maska, bo'lmasa `8600 **** **** 1234`.
  String get displayMask {
    final mask = cardMask?.trim();
    if (mask != null && mask.isNotEmpty) return mask;
    final digits = cardNumberDigits;
    if (digits.length < 8) return '**** **** **** ****';
    return '${digits.substring(0, 4)} **** **** '
        '${digits.substring(digits.length - 4)}';
  }

  /// Ko'rsatish uchun egasi: maska yulduzchalari qisqartiriladi —
  /// `ABDIRAXMONOV R********` → `ABDIRAXMONOV R.`. Bo'sh bo'lsa `null`.
  String? get displayOwner => _compactMaskedName(owner);

  bool get isValid =>
      cardNumberDigits.length == 16 && RegExp(r'^\d{4}$').hasMatch(expire);

  @override
  String toString() => 'MySafarUzsCard($displayMask)';
}

/// Maskalangan ismdagi yulduzchalarni qisqartiradi: maskali so'z qolgan
/// harflari + `.` bo'ladi (`R********` → `R.`), faqat maskadan iborat so'z
/// tashlanadi. Maskasiz so'zlar o'zgarmaydi.
String? _compactMaskedName(String? name) {
  final words = (name ?? '').trim().split(RegExp(r'\s+'));
  final mask = RegExp(r'[*•]');
  final result = <String>[];
  for (final word in words) {
    if (!word.contains(mask)) {
      if (word.isNotEmpty) result.add(word);
      continue;
    }
    final visible = word.replaceAll(mask, '').replaceFirst(RegExp(r'\.+$'), '');
    if (visible.isNotEmpty) result.add('$visible.');
  }
  return result.isEmpty ? null : result.join(' ');
}

/// Boshqa valyutadagi karta (USD va h.k.). To'liq raqam o'rniga host
/// processing'i bergan token ishlatiladi.
class MySafarForeignCard {
  const MySafarForeignCard({
    required this.cardToken,
    required this.cardMask,
    this.owner,
    this.currency = 'USD',
  });

  /// Host processing'idagi karta tokeni.
  final String cardToken;

  /// Ko'rsatish uchun maska (masalan `4276 **** **** 1234`).
  final String cardMask;

  /// Karta egasi. UI'da [displayOwner] ishlatiladi.
  final String? owner;

  /// Ko'rsatish uchun egasi — qarang [MySafarUzsCard.displayOwner].
  String? get displayOwner => _compactMaskedName(owner);

  /// ISO 4217 valyuta kodi (`USD`, `EUR`, `RUB` ...). Default `USD`.
  final String currency;

  bool get isValid => cardToken.trim().isNotEmpty;

  @override
  String toString() => 'MySafarForeignCard($cardMask, $currency)';
}
