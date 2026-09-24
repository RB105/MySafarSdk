import 'package:mysafar_sdk/src/cubit/booking/passenger/passenger_draft_store.dart'
    show PassengerDraftStore;
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:appmetrica_plugin/appmetrica_plugin.dart';
import 'package:flutter/foundation.dart'
    show VoidCallback, debugPrint, kDebugMode;
import 'package:flutter/services.dart' show DeviceOrientation, SystemChrome;
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
import 'package:mysafar_sdk/src/api/user_data.dart';
import 'package:mysafar_sdk/src/core/config/app_config.dart' show AppConfig;
import 'package:mysafar_sdk/src/core/config/debug_config_defaults.dart'
    show DebugConfigDefaults;
import 'package:mysafar_sdk/src/service/cache/hive_service.dart'
    show HiveService;
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart'
    show AnalyticsService;
import 'package:mysafar_sdk/src/service/analytics/appmetrica_analytics.dart'
    show AppMetricaAnalytics;
import 'package:mysafar_sdk/src/service/deep_link_gateway.dart'
    show DeepLinkGateway;
import 'package:mysafar_sdk/src/service/payment/card_token_encoder.dart'
    show CardTokenEncoder;
import 'package:mysafar_sdk/src/service/avia/recent_search_cache.dart'
    show RecentSearchCache;
import 'package:mysafar_sdk/src/service/passenger/passenger_storage_service.dart'
    show PassengerStorageService;

/// SDK'ning markaziy kirish nuqtasi. Host app `runApp`dan oldin [init]ni
/// chaqiradi; SDK ichidagi kod config/token/analytics'ga shu holder orqali
/// murojaat qiladi.
class MySafarSdk {
  MySafarSdk._();

  static MySafarConfig? _config;
  static MySafarTokenStore _tokens = GetStorageTokenStore();
  static MySafarAnalytics _analytics = const NoopAnalytics();
  static MySafarCallbacks _callbacks = const MySafarCallbacks();
  static MySafarUserData _userData = const MySafarUserData();

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

  /// Host bergan foydalanuvchi ma'lumotlari (email, kartalar). Berilmagan
  /// bo'lsa bo'sh [MySafarUserData] — `null` tekshiruvi kerak emas.
  static MySafarUserData get userData => _userData;

  /// Kartalar/email o'zgarganda (yangi karta qo'shildi, balans yangilandi,
  /// boshqa user kirdi) host chaqiradi — oldingi qiymat to'liq almashtiriladi.
  /// Yaroqsiz kartalar (16 raqamsiz / `YYMM` bo'lmagan muddat / bo'sh token)
  /// jim tashlab yuboriladi.
  static void updateUserData(MySafarUserData userData) {
    _userData = userData.sanitized();
    _userDataUnbound = true;
    _warnIfCardTokenCallbackMissing();
    if (kDebugMode) {
      final dropped = userData.uzsCards.length +
          userData.foreignCards.length -
          _userData.uzsCards.length -
          _userData.foreignCards.length;
      if (dropped > 0) {
        debugPrint('MySafarSdk: $dropped ta yaroqsiz karta tashlab yuborildi.');
      }
    }
  }

  static void _warnIfCardTokenCallbackMissing() {
    final hasSecret = CardTokenEncoder.isValidKey(_config?.cardTokenSecret);
    if (kDebugMode &&
        _userData.uzsCards.isNotEmpty &&
        _callbacks.onCreateCardToken == null &&
        !hasSecret) {
      debugPrint(
        'MySafarSdk: uzsCards berilgan, lekin config.cardTokenSecret (yoki '
        'callbacks.onCreateCardToken) yo\'q — kartalar ro\'yxati ko\'rsatiladi, '
        'lekin card_token yaratilmaydi.',
      );
    }
  }

  /// [updateUserData] bilan berilgan, lekin hali hech bir telefon
  /// ([ensureRegistered]) bilan bog'lanmagan ma'lumot. Telefon almashganda
  /// shu `false` bo'lsa — [_userData] oldingi foydalanuvchiniki (host yangi
  /// user uchun [updateUserData] chaqirmagan) va o'chiriladi.
  static bool _userDataUnbound = false;

  /// Host user chiqib ketganda karta/email ma'lumotlarini, bron formasi
  /// qoralamasini va SDK'dagi barcha foydalanuvchiga tegishli keshlarni
  /// (saqlangan yo'lovchilar, avtoto'ldirish, so'nggi qidiruvlar, profil,
  /// biletlar, SDK sessiyasi) o'chiradi.
  static void clearUserData() {
    _userData = const MySafarUserData();
    _userDataUnbound = false;
    PassengerDraftStore.clear();
    // init'dan oldin storage ochilmagan — tozalanadigan disk ma'lumoti yo'q.
    if (isInitialized) clearUserScopedData().ignore();
  }

  /// №62: foydalanuvchiga tegishli BARCHA SDK ma'lumotini o'chiradigan
  /// yagona joy — telefon almashganda ([ensureRegistered]), SDK ichidagi
  /// "Chiqish" / "Hisobni o'chirish" va host [clearUserData] shu orqali.
  ///
  /// Tozalanadi: tokenlar ([clearTokens] bo'lsa), bron qoralamasi, saqlangan
  /// yo'lovchilar (`cached_users`), avtoto'ldirish ro'yxatlari, so'nggi
  /// qidiruvlar (reys + shaharlar), profil/biletlar keshi, web-register
  /// telefoni/emaili, analytics profil ID. Til va tema saqlanadi. Host
  /// bergan [userData] bu yerda o'chirilmaydi (u host'niki).
  static Future<void> clearUserScopedData({bool clearTokens = true}) async {
    PassengerDraftStore.clear();
    if (!isInitialized) return;
    Future<void> guard(Future<void> Function() step) async {
      try {
        await step();
      } catch (e) {
        debugPrint('MySafarSdk.clearUserScopedData: $e');
      }
    }

    if (clearTokens) await guard(tokens.clear);
    final store = sdkStorage();
    await guard(() => PassengerStorageService.clearUserScoped(store));
    for (final key in const [
      _kRegisteredPhoneKey,
      _kRegisteredEmailKey,
      'recent_from_airports',
      'recent_to_airports',
    ]) {
      await guard(() => store.remove(key));
    }
    await guard(ProfileCache().clear);
    await guard(TicketsCache().clear);
    await guard(RecentSearchCache().clear);
    await guard(AnalyticsService().clearUser);
  }

  /// SDK ekranlari faqat vertical (portrait) da ishlaydi. Faqat SDK ekranda
  /// turganda qo'llanadi (`MySafarEmbed` / `MySafarApp`) — [init] host'ning
  /// yo'nalishiga tegmaydi (№93).
  static Future<void> lockPortrait() => SystemChrome.setPreferredOrientations(
        const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ],
      );

  /// Embed yopilganda host'ning o'z yo'nalish siyosatiga qaytaradi:
  /// [MySafarConfig.hostOrientations] berilgan bo'lsa o'sha, aks holda bo'sh
  /// ro'yxat — ya'ni host'ning Info.plist / AndroidManifest'dagi default'i.
  /// Ilgari barcha yo'nalishlar yoqilardi va faqat-portret host buzilardi.
  static Future<void> restoreOrientations() =>
      SystemChrome.setPreferredOrientations(
          _config?.hostOrientations ?? const <DeviceOrientation>[]);

  static Future<void> init({
    required MySafarConfig config,
    MySafarTokenStore? tokenStore,
    MySafarAnalytics? analytics,
    MySafarCallbacks callbacks = const MySafarCallbacks(),
    MySafarUserData? userData,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    // №93: bu yerda yo'nalish qulflanmaydi — butun host portretga
    // o'tib qolardi. Portret faqat SDK ekranda turganda (embed/app).

    if (userData != null) updateUserData(userData);

    // Debug'da bo'sh maydonlar env.json (`MYSAFAR_*`) dan to'ldiriladi;
    // release'da config host bergan holicha qoladi.
    config = DebugConfigDefaults.apply(config);
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
    _warnIfCardTokenCallbackMissing();

    AppConfig.apply(config);
    if (kDebugMode && !AppConfig.hasValidPartnerToken) {
      debugPrint(
        'MySafarSdk: partnerToken yo\'q yoki yaroqsiz. Debug uchun '
        'env.json ga ${DebugConfigDefaults.partnerTokenKey} yozib '
        '`--dart-define-from-file=env.json` bilan ishga tushiring.',
      );
    }

    // SDK o'z alohida konteynerida ishlaydi — host storage'iga tegilmaydi.
    await Future.wait([
      GetStorage.init(kMySafarStorageContainer),
      HiveService.init(),
    ]);
    // №62: eski build'lar diskka yozgan pasport/tug'ilgan kun
    // avtoto'ldirish ro'yxatlari o'chiriladi.
    await PassengerStorageService.purgeSensitiveSuggestions();

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
  }) {
    // Normalizatsiya: "+998 90 123-45-67" ham, "998901234567" ham bitta
    // raqam — formatlash farqi qayta-registratsiyaga sabab bo'lmasin.
    // Backend ham raqamni +siz (998...) formatda kutadi.
    final phone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.isEmpty) return Future.value(false);

    // №92: bir vaqtda ikki chaqiruv (SDK ikki marta ochildi, token
    // yangilanishi + embed) bitta webRegister'ni baham ko'radi.
    final inFlight = _registering;
    if (inFlight != null && _registeringPhone == phone) {
      return inFlight.then((ok) async {
        final hostEmail = email?.trim();
        if (ok && hostEmail != null && hostEmail.isNotEmpty) {
          await _ensureHostEmail(hostEmail);
        }
        return ok;
      });
    }
    // Boshqa telefon uchun ro'yxatdan o'tish ketayotgan bo'lsa (masalan
    // sessiya tiklanishi eski raqam bilan) — tugashini kutamiz: ikkita
    // webRegister parallel ketsa oxirgisi tokenlarni yozib, B foydalanuvchi
    // A ning sessiyasida qolishi mumkin edi.
    if (inFlight != null) {
      return inFlight
          .catchError((_) => false)
          .then((_) => ensureRegistered(phoneNumber, email: email));
    }
    final future = _ensureRegistered(phone, email: email);
    _registering = future;
    _registeringPhone = phone;
    future.whenComplete(() {
      if (identical(_registering, future)) {
        _registering = null;
        _registeringPhone = null;
      }
    }).ignore();
    return future;
  }

  static Future<bool>? _registering;
  static String? _registeringPhone;

  static Future<bool> _ensureRegistered(
    String phone, {
    String? email,
    bool bindUserData = true,
  }) async {
    final store = sdkStorage();
    final registeredPhone = store.read<String>(_kRegisteredPhoneKey);
    final hostEmail = email?.trim();
    final hasEmail = hostEmail != null && hostEmail.isNotEmpty;

    var registered = false;

    if (registeredPhone == phone && tokens.isLoggedIn) {
      registered = true;
    } else {
      if (registeredPhone != null && registeredPhone != phone) {
        // №62: boshqa user — oldingi sessiya va BARCHA PII keshlari
        // (yo'lovchilar, avtoto'ldirish, qoralama, qidiruvlar) o'chiriladi.
        await clearUserScopedData();
        // Host yangi user uchun updateUserData chaqirmagan bo'lsa, xotiradagi
        // kartalar/pasport oldingi odamniki — ular ham o'chadi.
        if (!_userDataUnbound) _userData = const MySafarUserData();
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
    // Host bergan userData endi shu telefonga tegishli (faqat host o'zi
    // chaqirganda — jim sessiya tiklashda emas).
    if (bindUserData) _userDataUnbound = false;

    if (registered && hasEmail) {
      await _ensureHostEmail(hostEmail);
    }

    return registered;
  }

  /// №76: refresh token haqiqatan bekor bo'lganda (tokenlar allaqachon
  /// tozalangan) — saqlangan host telefoni bilan jim qayta ro'yxatdan
  /// o'tadi. Telefon yo'q bo'lsa (oddiy login) `false`. Tsikl bo'lmasligi
  /// uchun 60 soniyada ko'pi bilan bir marta urinadi.
  static Future<bool> reRegisterAfterSessionLoss() async {
    final phone = registeredPhone;
    if (phone == null || phone.isEmpty) return false;
    final now = DateTime.now();
    final last = _lastReRegisterAt;
    if (last != null && now.difference(last) < const Duration(seconds: 60)) {
      return false;
    }
    // Host hozir boshqa foydalanuvchini ro'yxatdan o'tkazayotgan bo'lsa —
    // eski raqam bilan tiklamaymiz (sessiyalar aralashmasin).
    if (_registering != null) return false;
    _lastReRegisterAt = now;
    final future = _ensureRegistered(
      phone,
      email: registeredEmail,
      bindUserData: false,
    );
    _registering = future;
    _registeringPhone = phone;
    try {
      final ok = await future;
      // Kutish paytida host boshqa telefonga o'tgan bo'lsa — natija eskirgan.
      return ok && registeredPhone == phone;
    } finally {
      if (identical(_registering, future)) {
        _registering = null;
        _registeringPhone = null;
      }
    }
  }

  static DateTime? _lastReRegisterAt;

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

  /// Android/iOS tizim back oqimini konsolga chiqaradi (`MySafarBack:` tegi).
  /// Host'da back tugmasi kutilgandek ishlamasa shuni yoqib, qurilmada
  /// bosib ko'ring: hech qanday log chiqmasa — event Flutter'ga umuman
  /// yetib kelmayapti (Android tomonidagi `OnBackInvokedCallback` muammosi);
  /// log chiqsa — muammo SDK navigatsiyasida.
  static bool debugBackLogging = false;

  /// [debugBackLogging] yoqilgan bo'lsa bitta qatorni chiqaradi.
  static void logBack(String message) {
    if (!debugBackLogging) return;
    debugPrint('MySafarBack: $message');
  }

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
