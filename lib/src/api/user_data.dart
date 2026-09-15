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
    this.uzsCards = const [],
    this.foreignCards = const [],
  });

  /// Host user emaili. `MySafarEmbed.email` berilmasa shu ishlatiladi
  /// (telefon bilan ro'yxatdan o'tgach profilga yoziladi).
  final String? email;

  /// So'mdagi (UZS) kartalar — UzCard / Humo.
  final List<MySafarUzsCard> uzsCards;

  /// Boshqa valyutadagi kartalar (USD va h.k.) — token orqali.
  final List<MySafarForeignCard> foreignCards;

  bool get hasEmail => email?.trim().isNotEmpty ?? false;

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
    );
  }

  MySafarUserData copyWith({
    String? email,
    List<MySafarUzsCard>? uzsCards,
    List<MySafarForeignCard>? foreignCards,
  }) {
    return MySafarUserData(
      email: email ?? this.email,
      uzsCards: uzsCards ?? this.uzsCards,
      foreignCards: foreignCards ?? this.foreignCards,
    );
  }

  @override
  String toString() => 'MySafarUserData(email: ${hasEmail ? '***' : null}, '
      'uzsCards: $uzsCards, foreignCards: $foreignCards)';
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

  /// Karta egasi (masalan `ALIYEV VALI`).
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

  bool get isValid =>
      cardNumberDigits.length == 16 && RegExp(r'^\d{4}$').hasMatch(expire);

  @override
  String toString() => 'MySafarUzsCard($displayMask)';
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

  /// Karta egasi.
  final String? owner;

  /// ISO 4217 valyuta kodi (`USD`, `EUR`, `RUB` ...). Default `USD`.
  final String currency;

  bool get isValid => cardToken.trim().isNotEmpty;

  @override
  String toString() => 'MySafarForeignCard($cardMask, $currency)';
}
