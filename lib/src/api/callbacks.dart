/// Host app'ga qaytadigan hook'lar. Hammasi ixtiyoriy — `null` bo'lsa SDK
/// o'zining default xatti-harakatida qoladi yoki qadam o'tkazib yuboriladi.
class MySafarCallbacks {
  const MySafarCallbacks({
    this.onAuthRequired,
    this.onLoggedIn,
    this.onLoggedOut,
    this.getPushToken,
    this.onRequestReview,
  });

  /// Token refresh uzil-kesil muvaffaqiyatsiz bo'ldi — host o'z login oqimini
  /// ko'rsatishi mumkin. `null` bo'lsa SDK ichki AuthPage'iga o'tadi.
  final void Function()? onAuthRequired;

  /// Foydalanuvchi SDK ichida muvaffaqiyatli login qildi.
  final void Function()? onLoggedIn;

  /// Foydalanuvchi SDK ichida logout qildi.
  final void Function()? onLoggedOut;

  /// Push registration token (masalan FCM) beradi — SDK login'dan keyin uni
  /// backend'ga ro'yxatdan o'tkazadi. `null` bo'lsa push ro'yxati o'tkaziladi.
  final Future<String?> Function()? getPushToken;

  /// SDK app-store baho so'ramoqchi bo'lganda chaqiriladi (host in_app_review
  /// bilan o'zi hal qiladi). `null` bo'lsa so'ralmaydi.
  final Future<void> Function()? onRequestReview;
}
