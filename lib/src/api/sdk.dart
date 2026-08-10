import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:appmetrica_plugin/appmetrica_plugin.dart';
import 'package:flutter/foundation.dart'
    show VoidCallback, debugPrint, kDebugMode;
import 'package:flutter/services.dart'
    show DeviceOrientation, SystemChrome;
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:get_storage/get_storage.dart' show GetStorage;
import 'package:mysafar_sdk/src/core/config/response_config.dart'
    show NetworkErrorResponse, NetworkSuccessResponse;
import 'package:mysafar_sdk/src/core/config/sdk_storage.dart'
    show kMySafarStorageContainer, sdkStorage;
import 'package:mysafar_sdk/src/model/remote/profile/profile_model.dart'
    show ProfileModel;
import 'package:mysafar_sdk/src/service/account_service.dart'
    show AccountService;
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
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart'
    show AnalyticsService;
import 'package:mysafar_sdk/src/service/analytics/appmetrica_analytics.dart'
    show AppMetricaAnalytics;
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

  /// SDK'ni ishga tayyorlaydi. `runApp`dan oldin chaqirilishi shart.
  ///
  /// Firebase'ga bog'liq funksiyalar (Firestore remote config, Google auth)
  /// host app `Firebase.initializeApp`ni o'zi bajargan bo'lsagina ishlaydi.
  /// SDK ekranlari faqat vertical (portrait) da ishlaydi.
  static Future<void> lockPortrait() => SystemChrome.setPreferredOrientations(
        const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ],
      );

  /// Embed yopilganda host app orientation'larini qayta ochadi.
  static Future<void> restoreOrientations() =>
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);

  static Future<void> init({
    required MySafarConfig config,
    MySafarTokenStore? tokenStore,
    MySafarAnalytics? analytics,
    MySafarCallbacks callbacks = const MySafarCallbacks(),
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    await lockPortrait();

    _config = config;
    if (tokenStore != null) _tokens = tokenStore;
    if (analytics != null) {
      _analytics = analytics;
    } else {
      final apiKey = config.appMetricaApiKey.trim();
      if (apiKey.isNotEmpty && !apiKey.startsWith(r'$(')) {
        await AppMetrica.activate(
          AppMetricaConfig(apiKey, logs: kDebugMode),
        );
        _analytics = const AppMetricaAnalytics();
      }
    }
    _callbacks = callbacks;

    AppConfig.apply(config);

    // SDK o'z alohida konteynerida ishlaydi — host storage'iga tegilmaydi.
    await Future.wait([
      GetStorage.init(kMySafarStorageContainer),
      HiveService.init(),
    ]);

    // Storage tayyor bo'lgach til yuklanadi (izolyatsiyalangan — host'ning
    // lokalizatsiyasiga tegilmaydi).
    await SdkLocalization.init(
      startLocale: config.startLocale,
      persist: config.saveLocale,
    );

    await AnalyticsService().initGlobalEnvironment();
    await AnalyticsService().restoreUserProfile();
  }

  /// Host app deep-link'ni SDK'ga uzatadi (masalan
  /// `https://mysafar.uz/payment?billing_id=...`). SDK navigatori tayyor
  /// bo'lsa darhol ochadi, bo'lmasa pending saqlab keyin ochadi.
  static void handleLink(Uri uri) => DeepLinkGateway.handleLink(uri);

  // ── Tez ro'yxatdan o'tish (web-register) ─────────────────────────────────

  static const String _kRegisteredPhoneKey = 'web_registered_phone';
  static const String _kRegisteredEmailKey = 'web_registered_email';

  /// [ensureRegistered] orqali saqlangan host user telefoni (`998...`).
  /// Ro'yxatdan o'tilmagan bo'lsa `null`.
  static String? get registeredPhone =>
      sdkStorage().read<String>(_kRegisteredPhoneKey);

  /// [ensureRegistered] orqali saqlangan host user emaili.
  /// Berilmagan / sync qilinmagan bo'lsa `null`.
  static String? get registeredEmail =>
      sdkStorage().read<String>(_kRegisteredEmailKey);

  /// Host user'ini telefon raqami bilan MySafar backend'ida jim ro'yxatdan
  /// o'tkazadi (`/auth/web-register`) va tokenlarni saqlaydi.
  ///
  /// [email] berilsa, register'dan keyin (yoki sessiya allaqachon tirik
  /// bo'lsa) profilga `updateProfile` orqali yoziladi va ProfileCache'ga
  /// qo'yiladi — booking kontakt maydoni avtomatik to'ldiriladi.
  ///
  /// Idempotent: shu raqam bilan allaqachon ro'yxatdan o'tilgan va sessiya
  /// tirik bo'lsa hech narsa qilmaydi (email o'zgargan bo'lsa faqat email
  /// sync qilinadi). Raqam o'zgargan bo'lsa (host'da boshqa user kirgan) —
  /// eski sessiya/keshlar tozalanib, yangi raqam bilan qayta ro'yxatdan
  /// o'tiladi.
  static Future<bool> ensureRegistered(
    String phoneNumber, {
    String? email,
  }) async {
    // Normalizatsiya: "+998 90 123-45-67" ham, "998901234567" ham bitta
    // raqam — formatlash farqi qayta-registratsiyaga sabab bo'lmasin.
    // Backend ham raqamni +siz (998...) formatda kutadi.
    final phone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.isEmpty) return false;

    final store = sdkStorage();
    final registeredPhone = store.read<String>(_kRegisteredPhoneKey);
    final hostEmail = email?.trim();
    final hasEmail = hostEmail != null && hostEmail.isNotEmpty;

    var registered = false;

    if (registeredPhone == phone && tokens.isLoggedIn) {
      registered = true;
    } else {
      if (registeredPhone != null && registeredPhone != phone) {
        // Boshqa user — oldingi sessiya va PII keshlari qoldirilmaydi.
        await tokens.clear();
        await ProfileCache().clear();
        await TicketsCache().clear();
        await store.remove(_kRegisteredPhoneKey);
        await store.remove(_kRegisteredEmailKey);
      }

      final response = await AuthService().webRegister(phoneNumber: phone);
      if (response is NetworkSuccessResponse) {
        await store.write(_kRegisteredPhoneKey, phone);
        registered = true;
      } else {
        debugPrint('MySafarSdk.ensureRegistered failed: '
            '${(response as NetworkErrorResponse).getError()}');
        return false;
      }
    }

    if (registered && hasEmail) {
      await _ensureHostEmail(hostEmail);
    }

    return registered;
  }

  /// Host emailini profilga yozadi (idempotent). Muvaffaqiyatsizlik
  /// register'ni buzmaydi — faqat log.
  static Future<void> _ensureHostEmail(String email) async {
    final store = sdkStorage();
    final saved = store.read<String>(_kRegisteredEmailKey);
    if (saved == email) {
      await _mergeEmailIntoProfileCache(email);
      return;
    }

    final response = await AccountService()
        .updateProfile(ProfileModel(email: email).toFormData());
    if (response is NetworkSuccessResponse) {
      await store.write(_kRegisteredEmailKey, email);
      await _mergeEmailIntoProfileCache(email);
      return;
    }
    debugPrint('MySafarSdk._ensureHostEmail failed: '
        '${(response as NetworkErrorResponse).getError()}');
  }

  /// Booking/profil prefill uchun keshga email (va kerak bo'lsa telefon)
  /// qo'yiladi — profil sahifasi ochilmagan bo'lsa ham kontakt to'ldiriladi.
  static Future<void> _mergeEmailIntoProfileCache(String email) async {
    final cache = ProfileCache();
    final existing = Map<String, dynamic>.from(cache.read() ?? const {});
    if (existing['email'] == email) return;
    existing['email'] = email;
    final phone = registeredPhone;
    final cachedPhone = existing['phone_number']?.toString() ?? '';
    if (phone != null && cachedPhone.isEmpty) {
      existing['phone_number'] = phone;
    }
    await cache.write(existing);
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
