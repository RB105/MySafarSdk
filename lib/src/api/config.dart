import 'dart:ui' show Locale;

/// SDK'ning tashqi konfiguratsiyasi. Host app `MySafarSdk.init` orqali beradi —
/// ilgari native `MySafarChannel` (BuildConfig/xcconfig) dan o'qilgan qiymatlar
/// endi shu yerdan keladi.
class MySafarConfig {
  const MySafarConfig({
    required this.baseUrl,
    required this.skoteBaseUrl,
    this.partnerToken = '',
    this.appName,
    this.myId,
    this.socialAuth,
    this.enableVersionGate = false,
    this.enableServicesTab = false, // true edi false qilindi Xizmatlar bolimini berkitish uchun 
    this.enableShowcaseTour = false,
    this.enableFullProfile = false,
    this.startLocale,
    this.saveLocale = true,
  });

  /// Asosiy backend (masalan `https://api.mysafar.ru`).
  final String baseUrl;

  /// CMS/Skote backend (masalan `https://cms.mysafar.uz/api`).
  final String skoteBaseUrl;

  /// Partner-token auth uchun (`Authorization: Token ...`).
  final String partnerToken;

  /// UI'da ko'rinadigan brend nomi. `null` bo'lsa "MySafar" ishlatiladi —
  /// host app o'z nomini berishi mumkin (masalan home sarlavhasida).
  final String? appName;

  /// MyID identifikatsiya sozlamalari. `null` bo'lsa identifikatsiya kirish
  /// nuqtalari ko'rsatilmaydi.
  final MySafarMyIdConfig? myId;

  /// Google/Telegram orqali kirish sozlamalari. `null` bo'lsa ijtimoiy tarmoq
  /// tugmalari yashiriladi (faqat telefon-OTP qoladi).
  final MySafarSocialAuthConfig? socialAuth;

  /// Backend'dagi minimal versiya tekshiruvi (majburiy yangilash dialogi).
  /// Faqat MySafar app'ning o'zida ma'noga ega — SDK embed qilingan hostda
  /// versiya siyosati host'niki, shu sabab default o'chiq.
  final bool enableVersionGate;

  /// Pastki navigatsiyadagi "Xizmatlar" (visa, ban-check, destinations) tab'i.
  /// `false` bo'lsa tab ko'rsatilmaydi — host faqat avia oqimini xohlasa.
  final bool enableServicesTab;

  /// Bosh sahifadagi birinchi-ochilish showcase (tutorial) turi. Embed
  /// rejimda odatda keraksiz, shu sabab default o'chiq; MySafar app'ning o'zi
  /// `true` qiladi.
  final bool enableShowcaseTour;

  /// Profil sahifasining to'liq rejimi. Default o'chiq — embed'da faqat
  /// "Ma'lumotlarim" va "Qo'llab-quvvatlash" ko'rinadi; `true` bo'lsa
  /// arizalarim, cheklar, sozlamalar va hisobni o'chirish/chiqish ham chiqadi.
  final bool enableFullProfile;

  /// Boshlang'ich til. `null` bo'lsa saqlangan til yoki `uz` ishlatiladi.
  final Locale? startLocale;

  /// SDK ichida tanlangan til keyingi ochilishda eslab qolinsinmi. SDK'ning
  /// o'z izolyatsiyalangan storage'ida saqlanadi — host'ga ta'sir qilmaydi.
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
  const MySafarSocialAuthConfig({this.telegram});

  final MySafarTelegramAuthConfig? telegram;
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
