import 'package:mysafar_sdk/src/api/user_data.dart' show MySafarUzsCard;

/// Host app'ga qaytadigan hook'lar. Hammasi ixtiyoriy — `null` bo'lsa SDK
/// o'zining default xatti-harakatida qoladi yoki qadam o'tkazib yuboriladi.
class MySafarCallbacks {
  const MySafarCallbacks({
    this.onAuthRequired,
    this.onLoggedIn,
    this.onLoggedOut,
    this.onRequestReview,
    this.onCreateCardToken,
  });

  /// Token refresh uzil-kesil muvaffaqiyatsiz bo'ldi — host o'z login oqimini
  /// ko'rsatishi mumkin. `null` bo'lsa SDK ichki AuthPage'iga o'tadi.
  final void Function()? onAuthRequired;

  /// Foydalanuvchi SDK ichida muvaffaqiyatli login qildi.
  final void Function()? onLoggedIn;

  /// Foydalanuvchi SDK ichida logout qildi.
  final void Function()? onLoggedOut;

  /// SDK app-store baho so'ramoqchi bo'lganda chaqiriladi (host in_app_review
  /// bilan o'zi hal qiladi). `null` bo'lsa so'ralmaydi.
  final Future<void> Function()? onRequestReview;

  /// Ixtiyoriy: `card_token` ni host o'zi (masalan o'z serverida) yaratmoqchi
  /// bo'lsa. Berilsa [MySafarConfig.cardTokenSecret] o'rniga shu ishlatiladi.
  /// Berilmasa SDK tokenni `cardTokenSecret` bilan o'zi yaratadi.
  ///
  /// Token "Unired → MySafar card_token" hujjati bo'yicha bo'lishi kerak
  /// (AES-256-GCM, `tr_id` ga bog'langan, 10 daqiqa). `null`, bo'sh qiymat yoki
  /// xato — SDK to'lov sahifasini oddiy rejimda ochadi.
  final Future<String?> Function(MySafarCardTokenRequest request)?
      onCreateCardToken;
}

/// [MySafarCallbacks.onCreateCardToken] ga beriladigan ma'lumot.
class MySafarCardTokenRequest {
  const MySafarCardTokenRequest({
    required this.card,
    required this.trId,
    required this.billingId,
  });

  /// Foydalanuvchi tanlagan karta (host `userData.uzsCards` da bergan).
  final MySafarUzsCard card;

  /// To'lov sahifasi URL'idagi `trid` — token ichidagi `tr_id` aynan shu
  /// bo'lishi shart.
  final String trId;

  /// Buyurtma (billing) ID — URL'dagi `billing_id`.
  final String billingId;

  @override
  String toString() =>
      'MySafarCardTokenRequest(card: $card, trId: $trId, billingId: $billingId)';
}
