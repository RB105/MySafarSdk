import 'dart:ui' show Locale;

/// SDK'ning tashqi konfiguratsiyasi. Host app `MySafarSdk.init` orqali beradi —
/// ilgari native `MySafarChannel` (BuildConfig/xcconfig) dan o'qilgan qiymatlar
/// endi shu yerdan keladi.
class MySafarConfig {
  const MySafarConfig({
    required this.baseUrl,
    required this.skoteBaseUrl,
    this.partnerToken = '',
    this.myId,
    this.socialAuth,
    this.enableFirestoreConfig = false,
    this.startLocale,
    this.saveLocale = false,
  });

  /// Asosiy backend (masalan `https://api.mysafar.ru`).
  final String baseUrl;

  /// CMS/Skote backend (masalan `https://cms.mysafar.uz/api`).
  final String skoteBaseUrl;

  /// Partner-token auth uchun (`Authorization: Token ...`).
  final String partnerToken;

  /// MyID identifikatsiya sozlamalari. `null` bo'lsa identifikatsiya kirish
  /// nuqtalari ko'rsatilmaydi.
  final MySafarMyIdConfig? myId;

  /// Google/Telegram orqali kirish sozlamalari. `null` bo'lsa ijtimoiy tarmoq
  /// tugmalari yashiriladi (faqat telefon-OTP qoladi).
  final MySafarSocialAuthConfig? socialAuth;

  /// Firestore'dan recommendation endpointlarini sinxronlash. Host app
  /// Firebase'ni o'zi init qilgan bo'lishi shart.
  final bool enableFirestoreConfig;

  /// Boshlang'ich til. `null` bo'lsa saqlangan til yoki `uz` ishlatiladi.
  final Locale? startLocale;

  /// easy_localization tanlangan tilni saqlasinmi. Embed rejimda host'ning
  /// o'z easy_localization'i bilan to'qnashmaslik uchun default `false`.
  final bool saveLocale;
}

/// MyID SDK kirish ma'lumotlari (nomi `myid` paketidagi `MyIdConfig` bilan
/// to'qnashmasligi uchun `MySafar` prefiksi bilan).
class MySafarMyIdConfig {
  const MySafarMyIdConfig({
    required this.clientHash,
    required this.clientHashId,
  });

  final String clientHash;
  final String clientHashId;
}

class MySafarSocialAuthConfig {
  const MySafarSocialAuthConfig({this.google, this.telegram});

  final MySafarGoogleAuthConfig? google;
  final MySafarTelegramAuthConfig? telegram;
}

class MySafarGoogleAuthConfig {
  const MySafarGoogleAuthConfig({
    required this.serverClientIdAndroid,
    required this.serverClientIdIos,
  });

  final String serverClientIdAndroid;
  final String serverClientIdIos;
}

class MySafarTelegramAuthConfig {
  const MySafarTelegramAuthConfig({
    required this.clientId,
    required this.redirectUriAndroid,
    required this.redirectUriIos,
    this.redirectUriAndroidDebug,
  });

  final String clientId;
  final String redirectUriAndroid;
  final String redirectUriIos;

  /// Debug build'lardagi boshqa SHA-256 imzo uchun alohida redirect.
  /// `null` bo'lsa [redirectUriAndroid] ishlatiladi.
  final String? redirectUriAndroidDebug;
}
