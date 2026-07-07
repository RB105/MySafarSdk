import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart' show GetStorage;
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
import 'package:mysafar_sdk/src/core/router/navigation_service.dart';
import 'package:mysafar_sdk/src/core/tools/project_utils.dart' show ProjectUtils;

/// Analytics service for tracking events.
/// Centralized service for all analytics tracking in the SDK — konkret
/// provayder (AppMetrica va h.k.) host app tomonidan `MySafarSdk.init`ga
/// berilgan `MySafarAnalytics` implementatsiyasi orqali ulanadi.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

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
      final lang = GetStorage().read<String>('lang') ?? 'uz';
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
      await MySafarSdk.analytics.logEvent(eventName, attrs);
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
      if (userId != null && userId.isNotEmpty) {
        await MySafarSdk.analytics.setUserId(userId);
        // Sessiyalararo eslab qolamiz — keyingi launchda restoreUserProfile()
        // shu ID'ni qayta qo'yadi (aks holda qaytuvchi user'da profil_id bo'sh).
        await GetStorage().write(_kProfileIdKey, userId);
      }
      if (attributes != null && attributes.isNotEmpty) {
        await MySafarSdk.analytics.setUserAttributes(attributes);
      }
    } catch (e) {
      debugPrint('Analytics: setUser failed: $e');
    }
  }

  /// Logout'da chaqiriladi — profil ID'sini tozalaydi.
  Future<void> clearUser() async {
    try {
      await MySafarSdk.analytics.setUserId(null);
      await GetStorage().remove(_kProfileIdKey);
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
      final userId = GetStorage().read<String>(_kProfileIdKey);
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
  void trackTicketSearched({
    String? from,
    String? to,
    int? passengers,
    bool? roundTrip,
    String? travelClass,
  }) {
    unawaited(_reportEvent(_eventTicketSearched, {
      if (from != null) 'from': from,
      if (to != null) 'to': to,
      if (passengers != null) 'passengers': passengers,
      if (roundTrip != null) 'round_trip': roundTrip,
      if (travelClass != null) 'class': travelClass,
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

  // ─────────────────────────── Payment ───────────────────────────

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
