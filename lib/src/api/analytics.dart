/// Analytics chegarasi. SDK ichida hech qanday konkret analytics SDK yo'q —
/// host app o'zinikini (AppMetrica, Firebase Analytics, ...) shu interfeys
/// orqali ulaydi. Hamma metod default no-op, faqat keraklisi override qilinadi.
abstract class MySafarAnalytics {
  const MySafarAnalytics();

  /// Oddiy event ([name] + atributlar).
  Future<void> logEvent(String name, [Map<String, Object>? attributes]) async {}

  /// Barcha event/crash hisobotlariga biriktiriladigan global qiymat
  /// (masalan `app_version`, `lang`).
  Future<void> setEnvironmentValue(String key, String value) async {}

  /// Eventlarni foydalanuvchiga bog'lash. `null` — profil tozalash (logout).
  Future<void> setUserId(String? userId) async {}

  /// Foydalanuvchi profil atributlari (masalan `auth_provider`).
  Future<void> setUserAttributes(Map<String, Object> attributes) async {}

  /// To'lov muvaffaqiyatida daromad hisobotini yuborish (LTV dashboardlari).
  Future<void> trackRevenue({
    required num amount,
    required String currency,
    int quantity = 1,
    String? productId,
  }) async {}

  /// Deep-link orqali ochilish (attribution).
  void reportAppOpen(String link) {}
}

/// Default: hech narsa yubormaydi.
class NoopAnalytics extends MySafarAnalytics {
  const NoopAnalytics();
}
