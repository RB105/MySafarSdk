import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:mysafar_sdk/src/api/config.dart' show MySafarConfig;

/// Faqat **debug** build'da: host bo'sh qoldirgan config maydonlarini
/// kompilyatsiya vaqtidagi `--dart-define` qiymatlari bilan to'ldiradi.
///
/// Kalit nomlari Unired `.env` bilan bir xil. Qiymatlar gitignore'dagi
/// `env.json`dan beriladi:
///   flutter run --dart-define-from-file=env.json
///
/// Release/profile build'da hech narsa qo'shilmaydi — barcha ma'lumot host
/// `MySafarSdk.init`ga bergan config'dan keladi. Repo public: token va
/// boshqa secretlar kodga yozilmaydi.
class DebugConfigDefaults {
  DebugConfigDefaults._();

  static const String baseUrlKey = 'MYSAFAR_BASE_URL';
  static const String skoteBaseUrlKey = 'MYSAFAR_SKOTE_BASE_URL';
  static const String partnerTokenKey = 'MYSAFAR_PARTNER_TOKEN';
  static const String appNameKey = 'MYSAFAR_APP_NAME';

  static const Map<String, String> _compileTimeEnv = {
    baseUrlKey: String.fromEnvironment(baseUrlKey),
    skoteBaseUrlKey: String.fromEnvironment(skoteBaseUrlKey),
    partnerTokenKey: String.fromEnvironment(partnerTokenKey),
    appNameKey: String.fromEnvironment(appNameKey),
  };

  /// [config]dagi bo'sh maydonlarni [env]dan to'ldiradi. Host bergan
  /// (bo'sh bo'lmagan) qiymat doim ustun. [isDebug] `false` bo'lsa [config]
  /// o'zgarishsiz qaytadi.
  static MySafarConfig apply(
    MySafarConfig config, {
    bool isDebug = kDebugMode,
    Map<String, String>? env,
  }) {
    if (!isDebug) return config;
    final values = env ?? _compileTimeEnv;

    String? fill(String? current, String key) {
      if ((current ?? '').trim().isNotEmpty) return null;
      final value = (values[key] ?? '').trim();
      return value.isEmpty ? null : value;
    }

    final baseUrl = fill(config.baseUrl, baseUrlKey);
    final skoteBaseUrl = fill(config.skoteBaseUrl, skoteBaseUrlKey);
    final partnerToken = fill(config.partnerToken, partnerTokenKey);
    final appName = fill(config.appName, appNameKey);

    if (baseUrl == null &&
        skoteBaseUrl == null &&
        partnerToken == null &&
        appName == null) {
      return config;
    }
    return config.copyWith(
      baseUrl: baseUrl,
      skoteBaseUrl: skoteBaseUrl,
      partnerToken: partnerToken,
      appName: appName,
    );
  }
}
