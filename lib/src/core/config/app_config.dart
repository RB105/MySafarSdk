import 'package:mysafar_sdk/src/api/config.dart' show MySafarConfig;

/// App-level konfiguratsiya. Ilgari native `MySafarChannel` platform kanalidan
/// o'qilardi; SDK'da qiymatlar `MySafarSdk.init` → [apply] orqali Dart
/// tomonidan beriladi. Static fieldlar saqlangan, shu sabab chaqiruvchi joylar
/// (Dio interceptorlar va h.k.) o'zgarmagan.
class AppConfig {
  AppConfig._();

  static String baseUrl = '';
  static String skoteBaseUrl = '';
  static String partnerToken = '';

  /// True once [baseUrl] has been successfully resolved.
  static bool get isLoaded => baseUrl.isNotEmpty;

  /// `MySafarSdk.init` chaqiradi.
  static void apply(MySafarConfig config) {
    baseUrl = config.baseUrl.trim();
    skoteBaseUrl = config.skoteBaseUrl.trim();
    partnerToken = config.partnerToken.trim();
  }

  /// Ilgari native kanaldan yuklardi; endi qiymatlar init'da tayyor bo'ladi.
  /// Interceptorlardagi himoya chaqiruvlari uchun imzo saqlangan.
  static Future<void> ensureLoaded() {
    assert(isLoaded,
        'AppConfig bo\'sh — MySafarSdk.init() runApp dan oldin chaqirilganini tekshiring.');
    return Future.value();
  }

  /// Whether the partner token is present and not an unresolved build
  /// placeholder such as `$(PARTNER_TOKEN)`.
  static bool get hasValidPartnerToken =>
      partnerToken.isNotEmpty && !partnerToken.startsWith(r'$(');
}
