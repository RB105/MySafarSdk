import 'dart:async' show unawaited;

import 'package:easy_localization/easy_localization.dart'
    show EasyLocalization;
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:get_storage/get_storage.dart' show GetStorage;
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

  static MySafarTokenStore get tokens => _tokens;
  static MySafarAnalytics get analytics => _analytics;
  static MySafarCallbacks get callbacks => _callbacks;

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
      GetStorage.init(),
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
}
