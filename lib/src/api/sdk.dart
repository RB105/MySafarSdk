import 'dart:async' show unawaited;

import 'package:easy_localization/easy_localization.dart'
    show EasyLocalization;
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:flutter/foundation.dart' show VoidCallback, debugPrint;
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:get_storage/get_storage.dart' show GetStorage;
import 'package:mysafar_sdk/src/core/config/response_config.dart'
    show NetworkErrorResponse, NetworkSuccessResponse;
import 'package:mysafar_sdk/src/core/config/sdk_storage.dart'
    show kMySafarStorageContainer, sdkStorage;
import 'package:mysafar_sdk/src/service/auth_service.dart' show AuthService;
import 'package:mysafar_sdk/src/service/profile/profile_cache.dart'
    show ProfileCache;
import 'package:mysafar_sdk/src/service/profile/tickets_cache.dart'
    show TicketsCache;
import 'package:mysafar_sdk/src/api/analytics.dart';
import 'package:mysafar_sdk/src/api/callbacks.dart';
import 'package:mysafar_sdk/src/api/config.dart';
import 'package:mysafar_sdk/src/api/token_store.dart';
import 'package:mysafar_sdk/src/core/config/app_config.dart' show AppConfig;
import 'package:mysafar_sdk/src/service/cache/hive_service.dart'
    show HiveService;
import 'package:mysafar_sdk/src/service/config/remote_config_service.dart'
    show RemoteConfigService;
import 'package:mysafar_sdk/src/service/deep_link_gateway.dart'
    show DeepLinkGateway;

/// SDK'ning markaziy kirish nuqtasi. Host app `runApp`dan oldin [init]ni
/// chaqiradi; SDK ichidagi kod config/token/analytics'ga shu holder orqali
/// murojaat qiladi.
class MySafarSdk {
  MySafarSdk._();

  static MySafarConfig? _config;
  static MySafarTokenStore _tokens = GetStorageTokenStore();
  static MySafarAnalytics _analytics = const NoopAnalytics();
  static MySafarCallbacks _callbacks = const MySafarCallbacks();

  static bool get isInitialized => _config != null;

  static MySafarConfig get config {
    final c = _config;
    assert(c != null,
        'MySafarSdk.init() chaqirilmagan — runApp dan oldin init qiling.');
    return c!;
  }

  /// UI'da ko'rinadigan brend nomi (host bergan bo'lsa o'shaniki).
  static String get brandName => config.appName ?? 'MySafar';

  /// [text] ichidagi "MySafar"/"Mysafar" so'zini host brendi bilan almashtiradi
  /// (appName berilmagan bo'lsa matn o'zgarmaydi). Tarjima satrlari uchun.
  static String brandify(String text) {
    if (config.appName == null) return text;
    return text.replaceAll(RegExp('mysafar', caseSensitive: false), brandName);
  }

  static MySafarTokenStore get tokens => _tokens;
  static MySafarAnalytics get analytics => _analytics;
  static MySafarCallbacks get callbacks => _callbacks;

  /// Host app Firebase'ni init qilganmi. Firestore'ga tayanuvchi ixtiyoriy
  /// funksiyalar (remote config, news, payment turlari) shu tekshiruvdan
  /// o'tmasa kesh/fallback rejimida ishlaydi.
  static bool get isFirebaseAvailable => Firebase.apps.isNotEmpty;

  /// SDK'ni ishga tayyorlaydi. `runApp`dan oldin chaqirilishi shart.
  ///
  /// Firebase'ga bog'liq funksiyalar (Firestore remote config, Google auth)
  /// host app `Firebase.initializeApp`ni o'zi bajargan bo'lsagina ishlaydi.
  static Future<void> init({
    required MySafarConfig config,
    MySafarTokenStore? tokenStore,
    MySafarAnalytics? analytics,
    MySafarCallbacks callbacks = const MySafarCallbacks(),
  }) async {
    WidgetsFlutterBinding.ensureInitialized();

    _config = config;
    if (tokenStore != null) _tokens = tokenStore;
    if (analytics != null) _analytics = analytics;
    _callbacks = callbacks;

    AppConfig.apply(config);

    await Future.wait([
      EasyLocalization.ensureInitialized(),
      // SDK o'z alohida konteynerida ishlaydi — host storage'iga tegilmaydi.
      GetStorage.init(kMySafarStorageContainer),
      HiveService.init(),
    ]);

    // Firestore'dan recommendation endpointlarini fon rejimida yangilaymiz
    // (bloklamaydi — birinchi qidiruv kesh yoki fallback bilan ishlaydi).
    if (config.enableFirestoreConfig) {
      unawaited(RemoteConfigService.instance.sync());
    }
  }

  /// Host app deep-link'ni SDK'ga uzatadi (masalan
  /// `https://mysafar.uz/payment?billing_id=...`). SDK navigatori tayyor
  /// bo'lsa darhol ochadi, bo'lmasa pending saqlab keyin ochadi.
  static void handleLink(Uri uri) => DeepLinkGateway.handleLink(uri);

  // ── Tez ro'yxatdan o'tish (web-register) ─────────────────────────────────

  static const String _kRegisteredPhoneKey = 'web_registered_phone';

  /// Host user'ini telefon raqami bilan MySafar backend'ida jim ro'yxatdan
  /// o'tkazadi (`/auth/web-register`) va tokenlarni saqlaydi.
  ///
  /// Idempotent: shu raqam bilan allaqachon ro'yxatdan o'tilgan va sessiya
  /// tirik bo'lsa hech narsa qilmaydi. Raqam o'zgargan bo'lsa (host'da boshqa
  /// user kirgan) — eski sessiya/keshlar tozalanib, yangi raqam bilan qayta
  /// ro'yxatdan o'tiladi.
  static Future<bool> ensureRegistered(String phoneNumber) async {
    final phone = phoneNumber.trim();
    if (phone.isEmpty) return false;

    final store = sdkStorage();
    final registeredPhone = store.read<String>(_kRegisteredPhoneKey);

    if (registeredPhone == phone && tokens.isLoggedIn) return true;

    if (registeredPhone != null && registeredPhone != phone) {
      // Boshqa user — oldingi sessiya va PII keshlari qoldirilmaydi.
      await tokens.clear();
      await ProfileCache().clear();
      await TicketsCache().clear();
      await store.remove(_kRegisteredPhoneKey);
    }

    final response = await AuthService().webRegister(phoneNumber: phone);
    if (response is NetworkSuccessResponse) {
      await store.write(_kRegisteredPhoneKey, phone);
      return true;
    }
    debugPrint('MySafarSdk.ensureRegistered failed: '
        '${(response as NetworkErrorResponse).getError()}');
    return false;
  }

  // ── Embed rejimi ─────────────────────────────────────────────────────────

  static VoidCallback? _embedExit;

  /// Hozir `MySafarEmbed` ichida ishlayapmizmi (host'ga qaytish tugmasi shu
  /// bayroqqa qarab ko'rsatiladi).
  static bool get isEmbedded => _embedExit != null;

  /// Embed'dan chiqib host ekraniga qaytadi. `MySafarEmbed` o'rnatadi.
  static void exitEmbed() => _embedExit?.call();

  // MySafarEmbed uchun ichki API.
  static void attachEmbedExit(VoidCallback onExit) => _embedExit = onExit;
  static void detachEmbedExit() => _embedExit = null;
}
