/// Host app foydalanuvchisiga tegishli ixtiyoriy ma'lumotlar — `MySafarSdk.init`
/// (yoki keyinroq [MySafarSdk.updateUserData]) orqali beriladi.
///
/// Hamma maydon ixtiyoriy: hech narsa berilmasa SDK odatdagidek ishlaydi.
///
/// Xavfsizlik: karta ma'lumotlari faqat xotirada (in-memory) saqlanadi —
/// diskka, keshga yoki analytics'ga yozilmaydi, `toString()` da karta raqami
/// maskalanadi. Ilova qayta ishga tushsa host ularni yana berishi kerak.
class MySafarUserData {
  const MySafarUserData({
    this.email,
    this.identification,
    this.uzsCards = const [],
    this.foreignCards = const [],
  });

  /// Host user emaili. `MySafarEmbed.email` berilmasa shu ishlatiladi
  /// (telefon bilan ro'yxatdan o'tgach profilga yoziladi).
  final String? email;

  /// Host MyID malumoti. Bersa bron da "Ozimning malumotim" chiqadi
  final MySafarUserIdentification? identification;

  /// So'mdagi (UZS) kartalar — UzCard / Humo.
  final List<MySafarUzsCard> uzsCards;

  /// Boshqa valyutadagi kartalar (USD va h.k.) — token orqali.
  final List<MySafarForeignCard> foreignCards;

  bool get hasEmail => email?.trim().isNotEmpty ?? false;

  bool get hasIdentification => identification?.hasUsefulData ?? false;

  bool get hasCards => uzsCards.isNotEmpty || foreignCards.isNotEmpty;

  /// Bo'sh emailni `null` ga, yaroqsiz kartalarni tashlab yuborilgan nusxasini
  /// qaytaradi. Ro'yxatlar o'zgarmas (unmodifiable) bo'ladi.
  MySafarUserData sanitized() {
    final trimmedEmail = email?.trim();
    final id = identification?.sanitized();
    return MySafarUserData(
      email:
          (trimmedEmail == null || trimmedEmail.isEmpty) ? null : trimmedEmail,
      identification: (id != null && id.hasUsefulData) ? id : null,
      uzsCards: List.unmodifiable(uzsCards.where((c) => c.isValid)),
      foreignCards: List.unmodifiable(foreignCards.where((c) => c.isValid)),
    );
  }

  MySafarUserData copyWith({
    String? email,
    MySafarUserIdentification? identification,
    List<MySafarUzsCard>? uzsCards,
    List<MySafarForeignCard>? foreignCards,
  }) {
    return MySafarUserData(
      email: email ?? this.email,
      identification: identification ?? this.identification,
      uzsCards: uzsCards ?? this.uzsCards,
      foreignCards: foreignCards ?? this.foreignCards,
    );
  }

  @override
  String toString() => 'MySafarUserData(email: ${hasEmail ? '***' : null}, '
      'identification: ${hasIdentification ? identification : null}, '
      'uzsCards: $uzsCards, foreignCards: $foreignCards)';
}

/// Host MyID dan olgan user malumoti.
/// init da userData.identification ga beriladi.
/// Forma ozi toldirilmaydi — user "Ozimning malumotim" ni bosib tasdiqlasa
/// shunda maydonlarga yoziladi.
///
/// Misol:
/// MySafarUserIdentification(
///   firstName: 'VALI',
///   lastName: 'ALIYEV',
///   middleName: 'VALIYEVICH',
///   address: 'Toshkent sh.',
///   pinfl: '30103901234567',       // 14 ta raqam
///   pinflMask: '30103********',    // ixtiyoriy, ui da shu chiqadi
///   passSeries: 'AA1234567',       // 2 harf + 7 raqam
///   passSeriesMask: 'AA*******',   // ixtiyoriy
///   passExpiry: '15.03.2030',      // pasport amal qilish muddati
///   birthDate: '15.03.1990',       // dd.MM.yyyy yoki 1990-03-15
///   isResident: true,
/// )
class MySafarUserIdentification {
  const MySafarUserIdentification({
    this.firstName,
    this.lastName,
    this.middleName,
    this.address,
    this.pinfl,
    this.pinflMask,
    this.passSeries,
    this.passSeriesMask,
    this.passExpiry,
    this.birthDate,
    this.isResident,
  });

  /// Ism, masalan VALI
  final String? firstName;

  /// Familiya, masalan ALIYEV
  final String? lastName;

  /// Otasini ismi, ixtiyoriy
  final String? middleName;

  /// Manzil. Formaga yozilmaydi, faqat tasdiqlashda korinadi
  final String? address;

  /// Pinfl toliq — 14 raqam
  final String? pinfl;

  /// Pinfl maskasi, berilmasa yuqoridagi toliq chiqadi
  final String? pinflMask;

  /// Pasport/id raqami, masalan AA1234567 — formadagi docnum ga ketadi
  final String? passSeries;

  /// Hujjat maskasi, berilmasa passSeries chiqadi
  final String? passSeriesMask;

  /// Pasport amal qilish muddati: 15.03.2030 yoki 2030-03-15.
  /// Formadagi docexp ga ketadi
  final String? passExpiry;

  /// Tugilgan kun: 15.03.1990 yoki 1990-03-15. Ichida dd.MM.yyyy ga otkaziladi
  final String? birthDate;

  /// true bolsa fuqarolik UZ qoyiladi
  final bool? isResident;

  /// Ui da korsatish: maska bolsa maska, yoq bolsa toliq
  String? get displayPinfl {
    final mask = pinflMask?.trim();
    if (mask != null && mask.isNotEmpty) return mask;
    final raw = pinfl?.trim();
    return (raw == null || raw.isEmpty) ? null : raw;
  }

  /// Ui da korsatish: maska bolsa maska, yoq bolsa toliq
  String? get displayPassSeries {
    final mask = passSeriesMask?.trim();
    if (mask != null && mask.isNotEmpty) return mask;
    final raw = passSeries?.trim();
    return (raw == null || raw.isEmpty) ? null : raw;
  }

  /// dd.MM.yyyy ga keltirilgan tugilgan sana
  String? get normalizedBirthDate => _normalizeDate(birthDate);

  /// dd.MM.yyyy ga keltirilgan pasport muddati
  String? get normalizedPassExpiry => _normalizeDate(passExpiry);

  /// Biror maydon toldirilganmi
  bool get hasUsefulData {
    bool filled(String? v) => v != null && v.trim().isNotEmpty;
    return filled(firstName) ||
        filled(lastName) ||
        filled(middleName) ||
        filled(passSeries) ||
        filled(passExpiry) ||
        filled(birthDate) ||
        filled(pinfl) ||
        filled(address);
  }

  MySafarUserIdentification sanitized() {
    String? clean(String? v) {
      final t = v?.trim();
      return (t == null || t.isEmpty) ? null : t;
    }

    return MySafarUserIdentification(
      firstName: clean(firstName),
      lastName: clean(lastName),
      middleName: clean(middleName),
      address: clean(address),
      pinfl: clean(pinfl),
      pinflMask: clean(pinflMask),
      passSeries: clean(passSeries),
      passSeriesMask: clean(passSeriesMask),
      passExpiry: clean(passExpiry),
      birthDate: clean(birthDate),
      isResident: isResident,
    );
  }

  factory MySafarUserIdentification.fromJson(Map<String, dynamic> json) {
    return MySafarUserIdentification(
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      middleName: json['middle_name']?.toString(),
      address: json['address']?.toString(),
      pinfl: json['pinfl']?.toString(),
      pinflMask: json['pinfl_mask']?.toString(),
      passSeries: json['pass_series']?.toString(),
      passSeriesMask: json['pass_series_mask']?.toString(),
      passExpiry: json['pass_expiry']?.toString(),
      birthDate: json['birth_date']?.toString(),
      isResident: json['is_resident'] is bool
          ? json['is_resident'] as bool
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'first_name': firstName,
        'last_name': lastName,
        'middle_name': middleName,
        'address': address,
        'pinfl': pinfl,
        'pinfl_mask': pinflMask,
        'pass_series': passSeries,
        'pass_series_mask': passSeriesMask,
        'pass_expiry': passExpiry,
        'birth_date': birthDate,
        'is_resident': isResident,
      };

  @override
  String toString() =>
      'MySafarUserIdentification(${lastName ?? ''} ${firstName ?? ''}, '
      'doc: ${displayPassSeries ?? '—'})';
}

String? _normalizeDate(String? raw) {
  final t = raw?.trim();
  if (t == null || t.isEmpty) return null;
  if (RegExp(r'^\d{2}\.\d{2}\.\d{4}$').hasMatch(t)) return t;
  final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(t);
  if (iso != null) return '${iso[3]}.${iso[2]}.${iso[1]}';
  return t;
}

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
    final visible =
        word.replaceAll(mask, '').replaceFirst(RegExp(r'\.+$'), '');
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
