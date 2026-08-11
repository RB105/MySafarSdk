import 'dart:convert' show base64, utf8;

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

  /// Bekor qilingan (leaked) partner token(lar)ining base64 ko'rinishi.
  /// Xom holda saqlanmaydi: (1) tarix-scrub bu faylni buzmasligi uchun,
  /// (2) qayta nusxa-ko'chirishni qiyinlashtirish uchun. Har bir partner o'z
  /// tokenini berishi shart — bu token backend'da bekor qilingan.
  static const Set<String> _revokedPartnerTokensB64 = {
    'NGRiNzM5ZDNmMmIxNzk3MDk3MjE4OWE5YjEzM2MyOGU0MzQ3NDQ4MA==',
  };

  static bool _isRevokedPartnerToken(String token) =>
      _revokedPartnerTokensB64.contains(base64.encode(utf8.encode(token)));

  /// Whether the partner token is present, is not an unresolved build
  /// placeholder such as `$(PARTNER_TOKEN)`, and is not a known revoked token.
  /// Revoked bo'lsa `false` — Dio interceptor so'rovni rad etadi, shu sabab
  /// hech bir partner umumiy/sizib chiqqan token bilan ishlay olmaydi.
  static bool get hasValidPartnerToken =>
      partnerToken.isNotEmpty &&
      !partnerToken.startsWith(r'$(') &&
      !_isRevokedPartnerToken(partnerToken);
}
