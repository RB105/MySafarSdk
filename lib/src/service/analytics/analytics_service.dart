import 'dart:async' show unawaited;
import 'dart:convert' show base64Url, jsonDecode, utf8;

import 'package:flutter/foundation.dart';
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
import 'package:mysafar_sdk/src/core/router/navigation_service.dart';
import 'package:mysafar_sdk/src/core/tools/project_utils.dart'
    show ProjectUtils;
import 'package:mysafar_sdk/src/core/config/sdk_storage.dart';
import 'package:mysafar_sdk/src/model/local/recom_req_model.dart'
    show RecommendationRequestBody;

/// Analytics service for tracking events.
/// Centralized service for all analytics tracking in the SDK — konkret
/// provayder (AppMetrica va h.k.) host app tomonidan `MySafarSdk.init`ga
/// berilgan `MySafarAnalytics` implementatsiyasi orqali ulanadi.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  static const String _eventPrefix = 'mysafarsdk_';

  // Event names
  static const String _eventUserRegistered = 'user_registered';
  static const String _eventUserLoggedIn = 'user_logged_in';
  static const String _eventTicketSearched = 'ticket_searched';
  static const String _eventBookingCreated = 'booking_created';
  static const String _eventPaymentFailed = 'payment_failed';
  static const String _eventTransactionPaid = 'transaction_paid';
  static const String _eventApiError = 'api_error';
  static const String _eventButtonTap = 'button_tap';
  static const String _eventScreenView = 'screen_view';
  static const String _eventResultsShown = 'results_shown';
  static const String _eventNoResults = 'no_results';
  static const String _eventBookingFailed = 'booking_failed';
  static const String _eventFlightSelected = 'flight_selected';
  static const String _eventPassengerFormStarted = 'passenger_form_started';
  static const String _eventPassengerFormCompleted = 'passenger_form_completed';
  static const String _eventPaymentStarted = 'payment_started';

  // Voronka route nomlari (import sikli bo'lmasligi uchun literal; sahifa
  // `routeName`lari bilan bir xil — test tekshiradi).
  static const String passengerInfoRoute = '/passengerInformation';
  static const String bookingConfirmRoute = '/bookingConfirm';

  /// Bitta qidiruv bir necha joydan (forma + router) yozilsa takrorlanmasin.
  static const Duration _searchDedupWindow = Duration(seconds: 3);
  static DateTime? _lastSearchTrackedAt;

  /// Analytics profil ID'si sessiyalararo saqlanmaydi — uni har app ochilishida
  /// qayta qo'yish uchun oxirgi qiymatni shu kalit ostida saqlaymiz.
  static const String _kProfileIdKey = 'analytics_profile_id';

  /// Ilova versiyasi cache'i — native kanaldan bir marta o'qiladi va barcha
  /// keyingi eventlarda qayta ishlatiladi.
  static String _appVersion = '';
  static int _appBuild = 0;
  static bool _versionLoaded = false;

  /// Ilova versiyasi/build'ini bir marta yuklab cache'laydi. Birinchi eventdan
  /// oldin chaqiriladi, shu sabab har bir event versiya bilan ketadi.
  Future<void> _ensureVersionLoaded() async {
    if (_versionLoaded) return;
    try {
      _appVersion = await ProjectUtils.getVersionName();
      _appBuild = await ProjectUtils.getVersionCode();
    } catch (e) {
      debugPrint('Analytics: failed to load app version: $e');
    } finally {
      _versionLoaded = true;
    }
  }

  /// Global "app environment" qiymatlarini o'rnatadi — bular BARCHA event VA
  /// crash/error hisobotlariga avtomatik biriktiriladi. SDK init'idan keyin
  /// bir marta chaqiriladi.
  Future<void> initGlobalEnvironment() async {
    try {
      await _ensureVersionLoaded();
      final lang = sdkStorage().read<String>('lang') ?? 'uz';
      final analytics = MySafarSdk.analytics;
      await analytics.setEnvironmentValue('app_version', _appVersion);
      await analytics.setEnvironmentValue('app_build', '$_appBuild');
      await analytics.setEnvironmentValue('lang', lang);
      await analytics.setEnvironmentValue(
          'flavor', kReleaseMode ? 'prod' : 'debug');
    } catch (e) {
      debugPrint('Analytics: initGlobalEnvironment failed: $e');
    }
  }

  /// Generic method to report event with error handling.
  ///
  /// Har bir eventga avtomatik `app_version`, `app_build` va `timestamp`
  /// atributlari qo'shiladi — atribut bermagan eventlar ham to'liq ketadi.
  Future<void> _reportEvent(String eventName,
      [Map<String, Object>? attributes]) async {
    try {
      await _ensureVersionLoaded();
      final attrs = <String, Object>{
        'app_version': _appVersion,
        'app_build': _appBuild,
        'timestamp': DateTime.now().toIso8601String(),
        ...?attributes,
      };
      await MySafarSdk.analytics.logEvent('$_eventPrefix$eventName', attrs);
    } catch (e, stackTrace) {
      debugPrint('Analytics Error: Failed to report event "$eventName"');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
    }
  }

  // ─────────────────────────── User profile ───────────────────────────

  /// Eventlarni foydalanuvchiga bog'laydi: [userId] orqali analytics profil
  /// ID'sini o'rnatadi va [attributes] orqali profil atributlarini yuboradi
  /// (masalan `auth_provider`, `lang`).
  Future<void> setUser({
    String? userId,
    Map<String, Object>? attributes,
  }) async {
    try {
      // №97: profil ID faqat backend account ID — telefon raqami (PII)
      // hech qachon profil ID bo'lmaydi (aks holda bir odam ikki profil).
      if (userId != null && userId.isNotEmpty && !looksLikePhone(userId)) {
        await MySafarSdk.analytics.setUserId(userId);
        // Sessiyalararo eslab qolamiz — keyingi launchda restoreUserProfile()
        // shu ID'ni qayta qo'yadi (aks holda qaytuvchi user'da profil_id bo'sh).
        await sdkStorage().write(_kProfileIdKey, userId);
      }
      if (attributes != null && attributes.isNotEmpty) {
        await MySafarSdk.analytics.setUserAttributes(attributes);
      }
    } catch (e) {
      debugPrint('Analytics: setUser failed: $e');
    }
  }

  /// Telefon raqamiga o'xshash ID (eski build'lar profil ID sifatida
  /// telefonni yozgan) — bunday qiymat profil ID sifatida ishlatilmaydi.
  @visibleForTesting
  static bool looksLikePhone(String id) =>
      RegExp(r'^\+?\d{11,15}$').hasMatch(id.trim());

  /// JWT access token payload'idan backend foydalanuvchi ID'si (`user_id`).
  /// Topilmasa `null`.
  @visibleForTesting
  static String? userIdFromJwt(String? token) {
    if (token == null) return null;
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      if (payload is! Map) return null;
      final id = payload['user_id'] ?? payload['id'];
      final text = id?.toString().trim() ?? '';
      return text.isEmpty ? null : text;
    } catch (_) {
      return null;
    }
  }

  /// Login/ro'yxatdan o'tishdan keyin: access token'dagi backend ID bilan
  /// profilni bog'laydi (profil sahifasi ochilmasa ham). ID topilmasa faqat
  /// [attributes] yuboriladi — profil ID keyin `ProfileCubit` orqali qo'yiladi.
  Future<void> bindUserFromToken(String? accessToken,
      {Map<String, Object>? attributes}) {
    return setUser(userId: userIdFromJwt(accessToken), attributes: attributes);
  }

  /// Logout'da chaqiriladi — profil ID'sini tozalaydi.
  Future<void> clearUser() async {
    try {
      await MySafarSdk.analytics.setUserId(null);
      await sdkStorage().remove(_kProfileIdKey);
    } catch (e) {
      debugPrint('Analytics: clearUser failed: $e');
    }
  }

  /// Har app ochilishida chaqiriladi. Analytics profil ID'si sessiyalararo
  /// saqlanmasligi mumkin, shu sabab oxirgi saqlangan ID'ni qayta qo'yadi —
  /// bu bilan qaytib kelgan (allaqachon login qilgan) foydalanuvchining barcha
  /// eventlari ham real profilga bog'lanadi.
  Future<void> restoreUserProfile() async {
    try {
      final userId = sdkStorage().read<String>(_kProfileIdKey);
      if (userId != null && looksLikePhone(userId)) {
        // Eski build telefonni profil ID qilib saqlagan — tashlaymiz,
        // backend ID token/profil yuklanganda qo'yiladi.
        await sdkStorage().remove(_kProfileIdKey);
        return;
      }
      if (userId != null && userId.isNotEmpty) {
        await MySafarSdk.analytics.setUserId(userId);
        debugPrint('Analytics: profile ID restored ($userId)');
      }
    } catch (e) {
      debugPrint('Analytics: restoreUserProfile failed: $e');
    }
  }

  // ─────────────────────────── Revenue ───────────────────────────

  /// To'lov muvaffaqiyatli bo'lganda revenue hisobotini yuboradi — shu orqali
  /// LTV / daromad dashboard'lari ishlaydi. [amount] — to'langan summa (butun
  /// valyuta birligida), [currency] — ISO kod (masalan "UZS").
  Future<void> trackRevenue({
    required num amount,
    required String currency,
    String? orderId,
  }) async {
    if (amount <= 0 || currency.isEmpty) return;
    try {
      await MySafarSdk.analytics.trackRevenue(
        amount: amount,
        currency: currency,
        quantity: 1,
        productId: orderId,
      );
      debugPrint('Analytics: revenue $amount $currency reported');
    } catch (e) {
      debugPrint('Analytics: revenue report failed: $e');
    }
  }

  // ─────────────────────────── Screen view ───────────────────────────

  /// Ekran ko'rsatilishini kuzatadi. Navigatsiya observer'idan (har push/pop/
  /// replace'da) avtomatik chaqiriladi.
  ///
  /// SDK qayta ochilganda (embed) birinchi ekran "takror" deb tashlanmasligi
  /// uchun `NavigationService.resetScreenTracking()` chaqiriladi.
  void trackScreenView(String screen) {
    if (screen.isEmpty) return;
    unawaited(_reportEvent(_eventScreenView, {'screen': screen}));
  }

  // ─────────────────────────── Auth ───────────────────────────

  /// Track user registration via phone
  Future<void> trackUserRegisteredPhone({
    required String phoneNumber,
  }) async {
    await _reportEvent(_eventUserRegistered, {
      'method': 'phone',
      'has_phone': phoneNumber.isNotEmpty,
    });
  }

  /// Jim (web-register) sessiya ochildi. `user_registered` faqat backend
  /// yangi hisob yaratilganini aytganda ([isNewUser]) yuboriladi — har
  /// yashirin webRegister ro'yxatdan o'tish emas (№97).
  Future<void> trackWebRegister({required bool isNewUser}) async {
    await _reportEvent(
      isNewUser ? _eventUserRegistered : _eventUserLoggedIn,
      const {'method': 'web_register'},
    );
  }

  /// webRegister javobidan "yangi hisob" belgisini o'qiydi (backend
  /// `created` / `is_new` / `is_new_user` / `registered` dan birini
  /// yuborsa). Belgi bo'lmasa `false` — ya'ni `user_logged_in`.
  static bool isNewUserResponse(Object? data) {
    if (data is! Map) return false;
    for (final key in const ['created', 'is_new', 'is_new_user', 'new_user']) {
      if (data[key] == true) return true;
    }
    return false;
  }

  /// Track user login via phone OTP
  Future<void> trackUserLoggedInPhone({
    required String phoneNumber,
  }) async {
    await _reportEvent(_eventUserLoggedIn, {
      'method': 'phone_otp',
      'has_phone': phoneNumber.isNotEmpty,
    });
  }

  /// Track user login via Google
  Future<void> trackUserLoggedInGoogle({
    required String email,
  }) async {
    await _reportEvent(_eventUserLoggedIn, {
      'method': 'google',
      'has_email': email.isNotEmpty,
    });
  }

  // ─────────────────────────── Funnel ───────────────────────────
  // Kanonik voronka: ticket_searched → booking_created → transaction_paid.
  // Har bosqich uchun BITTA nom. Eski build'lardagi `payment_completed` endi
  // yozilmaydi — to'lov muvaffaqiyati faqat `transaction_paid` bilan ketadi.

  /// Voronka 1-bosqichi: foydalanuvchi chipta qidirdi.
  ///
  /// Natijalar sahifasiga har qanday yo'l bilan kirilganda router ham
  /// chaqiradi; [_searchDedupWindow] ichidagi ikkinchi chaqiruv tashlanadi
  /// (masalan forma + router bir qidiruvni ikki marta yozmasin).
  void trackTicketSearched({
    String? from,
    String? to,
    int? passengers,
    bool? roundTrip,
    String? travelClass,
    String? source,
  }) {
    final now = DateTime.now();
    final last = _lastSearchTrackedAt;
    if (last != null && now.difference(last) < _searchDedupWindow) return;
    _lastSearchTrackedAt = now;
    unawaited(_reportEvent(_eventTicketSearched, {
      if (source != null) 'source': source,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
      if (passengers != null) 'passengers': passengers,
      if (roundTrip != null) 'round_trip': roundTrip,
      if (travelClass != null) 'class': travelClass,
    }));
  }

  /// [trackTicketSearched] ning qidiruv tanasidan chaqiriladigan shakli —
  /// natijalar sahifasi ichidagi qayta qidiruvlar (sana lentasi, "qayta
  /// qidirish", filtrdan keyin) ham `ticket_searched` bo'lib yozilsin (№97).
  void trackTicketSearchedFor(RecommendationRequestBody body,
      {required String source}) {
    try {
      final segments = body.segments ?? const [];
      trackTicketSearched(
        from: segments.isEmpty ? null : segments.first.from?.cityIataCode,
        to: segments.isEmpty ? null : segments.first.to?.cityIataCode,
        passengers: body.adt + body.chd + body.inf,
        roundTrip: body.flight_Type == 1,
        travelClass: body.klass,
        source: source,
      );
    } catch (_) {
      // Analitika qidiruvni hech qachon to'xtatmasin.
    }
  }

  /// Hamma manba xato berdi (reys ko'rsatilmadi) — `no_results`
  /// `reason: error` bilan (№97). Bo'sh javobdan farqlash uchun.
  void trackSearchFailed({String? errorType, int? passengers}) {
    unawaited(_reportEvent(_eventNoResults, {
      'count': 0,
      'reason': 'error',
      if (errorType != null) 'error_type': errorType,
      if (passengers != null) 'passengers': passengers,
    }));
  }

  /// Voronka 2-bosqichi: booking yaratildi (to'lovdan oldingi qadam).
  Future<void> trackBookingCreated({
    String? tid,
    String? billingNumber,
    int? passengers,
    num? amount,
    String? currency,
  }) async {
    await _reportEvent(_eventBookingCreated, {
      if (tid != null) 'tid': tid,
      if (billingNumber != null) 'billing_number': billingNumber,
      if (passengers != null) 'passengers': passengers,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
    });
  }

  /// Qidiruv natijalari chiqdi ([count] > 0) yoki natija yo'q ([count] == 0
  /// bo'lsa `no_results`). Natijalar sahifasi (tickets cubit) qidiruv
  /// yakunlanganda BIR MARTA chaqiradi.
  void trackSearchResults({
    required int count,
    String? from,
    String? to,
    int? passengers,
    bool? roundTrip,
  }) {
    unawaited(_reportEvent(count > 0 ? _eventResultsShown : _eventNoResults, {
      'count': count,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
      if (passengers != null) 'passengers': passengers,
      if (roundTrip != null) 'round_trip': roundTrip,
    }));
  }

  /// Bron yaratilmadi (booking-create xatosi).
  void trackBookingFailed({
    String? tid,
    int? passengers,
    Object? error,
  }) {
    unawaited(_reportEvent(_eventBookingFailed, {
      if (tid != null) 'tid': tid,
      if (passengers != null) 'passengers': passengers,
      'message': _shortMessage(error),
    }));
  }

  /// Voronka: foydalanuvchi natijalardan reysni tanladi (tafsilot ochildi).
  void trackFlightSelected({
    String? source,
    String? from,
    String? to,
    String? airline,
    num? amount,
    String? currency,
  }) {
    unawaited(_reportEvent(_eventFlightSelected, {
      if (source != null) 'source': source,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
      if (airline != null) 'airline': airline,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
    }));
  }

  /// Bitta forma sessiyasida `passenger_form_completed` bir marta ketadi:
  /// forma submit'i (bron'dan oldin) ham, route fallback'i ham shu bayroq
  /// orqali o'tadi. `passenger_form_started` qayta ochadi.
  static bool _formCompletedSent = false;

  /// Voronka: yo'lovchi ma'lumotlari formasi ochildi.
  void trackPassengerFormStarted({int? passengers, String? source}) {
    _formCompletedSent = false;
    unawaited(_reportEvent(_eventPassengerFormStarted, {
      if (passengers != null) 'passengers': passengers,
      if (source != null) 'source': source,
    }));
  }

  /// Voronka: yo'lovchi formasi to'ldirilib, keyingi qadamga (bron/to'lov)
  /// o'tildi. Forma validatsiyadan o'tib bron so'rovi yuborilayotganda
  /// chaqiriladi (bron xatosi "formani tashlab ketdi" bo'lib ko'rinmasin).
  void trackPassengerFormCompleted({int? passengers, String? source}) {
    if (_formCompletedSent) return;
    _formCompletedSent = true;
    unawaited(_reportEvent(_eventPassengerFormCompleted, {
      if (passengers != null) 'passengers': passengers,
      if (source != null) 'source': source,
    }));
  }

  /// Navigatsiyadan voronka eventlari (route observer har push'da chaqiradi):
  /// yo'lovchi sahifasi ochilsa — `passenger_form_started`; undan to'g'ridan
  /// bron/to'lov sahifasiga o'tilsa — `passenger_form_completed`. Sahifa
  /// ichidagi kodga bog'lanmaydi, shuning uchun oqim refaktorida ham ishlaydi.
  void trackRouteFunnel(String? name, String? previousName) {
    final event = funnelEventForPush(name, previousName);
    if (event == null) return;
    if (event == _eventPassengerFormStarted) {
      _formCompletedSent = false;
    } else if (event == _eventPassengerFormCompleted) {
      // Submit'da allaqachon yozilgan bo'lsa takrorlanmaydi.
      if (_formCompletedSent) return;
      _formCompletedSent = true;
    }
    unawaited(_reportEvent(event, const {'source': 'route'}));
  }

  /// [trackRouteFunnel] mantig'i (test uchun sof funksiya).
  @visibleForTesting
  static String? funnelEventForPush(String? name, String? previousName) {
    if (name == passengerInfoRoute) return _eventPassengerFormStarted;
    if (previousName == passengerInfoRoute && name == bookingConfirmRoute) {
      return _eventPassengerFormCompleted;
    }
    return null;
  }

  // ─────────────────────────── Payment ───────────────────────────

  /// Voronka: foydalanuvchi "To'lash"ni bosdi (to'lov so'rovi yuborilyapti).
  void trackPaymentStarted({
    String? trId,
    String? paymentMethod,
    num? amount,
    String? currency,
  }) {
    unawaited(_reportEvent(_eventPaymentStarted, {
      if (trId != null) 'tr_id': trId,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
    }));
  }

  /// Track paid transaction with tr_id, amount and billing number
  Future<void> trackTransactionPaid({
    required String trId,
    required String billingNumber,
    num? amount,
    String? currency,
  }) async {
    await _reportEvent(_eventTransactionPaid, {
      'tr_id': trId,
      'billing_number': billingNumber,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
    });
  }

  /// Track failed payment
  Future<void> trackPaymentFailed({
    required String trId,
    required String errorMessage,
    String? billingId,
    String? paymentMethod,
  }) async {
    await _reportEvent(_eventPaymentFailed, {
      'tr_id': trId,
      'billing_id': billingId ?? '',
      'has_error_message': errorMessage.isNotEmpty,
      'message': _shortMessage(errorMessage),
      'payment_method': paymentMethod ?? '',
    });
  }

  /// API so'rovida yuz bergan xatolikni kuzatadi.
  ///
  /// Foydalanuvchi qaysi ekranda turganini ([NavigationService.currentRouteName])
  /// avtomatik qo'shadi, shu bilan birga endpoint, HTTP metodi, status kodi va
  /// xato turi/xabarini yuboradi.
  Future<void> trackApiError({
    required String endpoint,
    required String method,
    String? errorType,
    int? statusCode,
    Object? error,
  }) async {
    await _reportEvent(_eventApiError, {
      'screen': NavigationService.currentRouteName,
      'endpoint': endpoint,
      'method': method.toUpperCase(),
      'status_code': statusCode ?? 0,
      'error_type': errorType ?? 'unknown',
      'message': _shortMessage(error),
    });
  }

  /// Tugma bosilganini kuzatadi (funnel / drop-off tahlili uchun).
  ///
  /// Foydalanuvchi qaysi ekranda ([NavigationService.currentRouteName]) qaysi
  /// tugmani bosgani yoziladi. Shu eventlar ketma-ketligidan foydalanuvchi
  /// qaysi bosqichgacha borib ilovadan chiqib ketganini aniqlash mumkin.
  ///
  /// UI callback ichida chaqirish uchun `void` — javobni kutmaydi.
  void trackButtonTap(String button, {Map<String, Object>? extra}) {
    final attributes = <String, Object>{
      'screen': NavigationService.currentRouteName,
      'button': button,
      if (extra != null) ...extra,
    };
    unawaited(_reportEvent(_eventButtonTap, attributes));
  }

  /// Xato obyektini analytics atributiga sig'adigan qisqa matnga aylantiradi.
  String _shortMessage(Object? error) {
    if (error == null) return '';
    final text = error.toString();
    const maxLength = 300;
    return text.length > maxLength ? text.substring(0, maxLength) : text;
  }
}
