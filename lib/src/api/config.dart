import 'dart:ui' show Locale, Offset;

import 'package:flutter/material.dart' show Color, EdgeInsets, ThemeMode;

/// SDK'ning tashqi konfiguratsiyasi. Host app `MySafarSdk.init` orqali beradi —
/// ilgari native `MySafarChannel` (BuildConfig/xcconfig) dan o'qilgan qiymatlar
/// endi shu yerdan keladi.
class MySafarConfig {
  const MySafarConfig(
      {required this.baseUrl,
      required this.skoteBaseUrl,
      this.partnerToken = '',
      this.appMetricaApiKey = '',
      this.appName,
      this.myId,
      this.socialAuth,
      this.enableVersionGate = false,
      this.enableServicesTab =
          false, // true edi false qilindi Xizmatlar bolimini berkitish uchun
      this.enableShowcaseTour = false,
      this.enableFullProfile = false,
      this.startLocale,
      this.saveLocale = true,
      this.themeMode,
      this.brandColor,
      this.bottomBarStyle,
      this.homeHeaderStyle,
      this.support});

  /// Asosiy backend (masalan `https://api.mysafar.ru`).
  final String baseUrl;

  /// CMS/Skote backend (masalan `https://cms.mysafar.uz/api`).
  final String skoteBaseUrl;

  /// Partner-token auth uchun (`Authorization: Token ...`).
  final String partnerToken;

  /// AppMetrica API key. Berilsa SDK `init`da AppMetrica'ni yoqadi va
  /// eventlarni `MySafarSdk_*` prefiksi bilan yuboradi.
  final String appMetricaApiKey;

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

  /// Eski "Xizmatlar" tab'i — endi pastki navigatsiyada "Yo'nalishlar"
  /// ishlatiladi. Maydon saqlanadi, lekin nav bar'da qo'llanmaydi.
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

  /// Boshlang'ich tema (oq / qora fon). Host app o'z light/dark rejimini
  /// beradi — masalan Unired dark bo'lsa `ThemeMode.dark`.
  /// `null` bo'lsa `ThemeMode.system` (platform brightness). Foydalanuvchi
  /// Sozlamalardan o'zi tanlagan bo'lsa, o'sha tanlov saqlanadi.
  final ThemeMode? themeMode;

  /// Asosiy brend rangi (tugmalar, switch, focus va h.k.).
  /// `null` bo'lsa SDK default (`#0057BE`) ishlatiladi.
  final Color? brandColor;

  /// Pastki navbar paneli (Container) ko'rinishi. `null` bo'lsa
  /// [BottomNavBarPage] ichidagi default dizayn ishlatiladi.
  final MySafarBottomBarStyle? bottomBarStyle;

  /// Bosh sahifadagi slogan qismi ko'rinishi. `null` bo'lsa hozirgi
  /// lokalizatsiya matni (`home_slogan`) ishlatiladi.
  final MySafarHomeHeaderStyle? homeHeaderStyle;

  /// Qo'llab-quvvatlash telefoni va Telegram. `null` / bo'sh maydonlar
  /// MySafar defaultlariga tushadi.
  final MySafarSupportConfig? support;

  /// Support telefon (UI + `tel:`). Host bermasa default.
  String get supportPhone {
    final value = support?.phone?.trim();
    return (value != null && value.isNotEmpty)
        ? value
        : MySafarSupportConfig.defaultPhone;
  }

  /// Support Telegram URL. Host bermasa default.
  String get supportTelegramUrl {
    final value = support?.telegramUrl?.trim();
    if (value == null || value.isEmpty) {
      return MySafarSupportConfig.defaultTelegramUrl;
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final handle = value.replaceFirst(RegExp(r'^@'), '');
    return 'https://t.me/$handle';
  }
}

/// Qo'llab-quvvatlash kontaktlari — host `MySafarConfig.support` orqali beradi.
class MySafarSupportConfig {
  const MySafarSupportConfig({this.phone, this.telegramUrl});

  /// Default MySafar call-center raqami (ko'rsatish uchun bo'shliqli).
  static const String defaultPhone = '+998 55 512 00 08';

  /// Default MySafar Telegram bot.
  static const String defaultTelegramUrl =
      'https://t.me/My_Safar_call_center_bot';

  /// Qo'llab-quvvatlash telefoni. Masalan `+998 55 512 00 08` yoki
  /// `+998555120008`. `tel:` ochilganda bo'shliqlar olib tashlanadi.
  final String? phone;

  /// Telegram havolasi. To'liq URL (`https://t.me/...`) yoki `@username`
  /// / `username` — SDK `https://t.me/...` ga normalizatsiya qiladi.
  final String? telegramUrl;
}

/// Pastki navbar panelining tashqi ko'rinishi (faqat Container qatlami).
/// Barcha maydonlar ixtiyoriy — berilmaganlari SDK default qiymatini oladi.
class MySafarBottomBarStyle {
  const MySafarBottomBarStyle({
    // this.margin,
    this.padding,
    this.backgroundColorLight,
    this.backgroundColorDark,
    this.borderRadius,
    this.shadowOpacityLight,
    this.shadowOpacityDark,
    this.shadowBlurRadius,
    this.shadowOffset,
  });

  // /// 1 — panelning gorizontal margini (default: horizontal 14).
  // final EdgeInsets? margin;

  /// 2 — panel ichki padding (default: 6).
  final EdgeInsets? padding;

  /// 3 — panel foni (default: light/dark card rangi).
  final Color? backgroundColorLight;
  final Color? backgroundColorDark;

  /// 4 — burchak radiusi (default: 40).
  final double? borderRadius;

  /// 5 — soyа rangi opacity (light rejim, default: 0.12).
  final double? shadowOpacityLight;

  /// 5 — soyа rangi opacity (dark rejim, default: 0.45).
  final double? shadowOpacityDark;

  /// 6 — soyа blur radius (default: 24).
  final double? shadowBlurRadius;

  /// 7 — soyа offset (default: Offset(0, 8)).
  final Offset? shadowOffset;
}

/// Bosh sahifa slogan qismi uchun host tomonidan beriladigan ixtiyoriy style.
/// Barcha maydonlar ixtiyoriy:
/// - [logoAssetPath] berilsa matndan oldin ko'rsatiladi (PNG/JPG yoki SVG);
/// - [logoBackgroundColor] berilmasa theme card ranglari ishlatiladi;
/// - [title]/[description] bo'sh bo'lmasa ko'rsatiladi;
/// - ikkalasi ham bo'lsa orasiga `-` qo'yiladi.
class MySafarHomeHeaderStyle {
  const MySafarHomeHeaderStyle({
    this.logoAssetPath,
    this.logoBackgroundColor,
    this.title,
    this.description,
  });

  /// Host/SDK asset path'i. PNG/JPG yoki SVG bo'lishi mumkin
  /// (masalan `assets/unired_logo.png` yoki `packages/mysafar_sdk/assets/img/splash/logo.svg`).
  final String? logoAssetPath;

  /// Logo konteyner foni. `null` bo'lsa light/dark card ranglari
  /// (`cardColorLight` / `cardColorDark`) ishlatiladi.
  final Color? logoBackgroundColor;

  /// Header title qismi (masalan `UNIRED`).
  final String? title;

  /// Header description qismi (masalan `ishonchli sayohat qiling!`).
  final String? description;
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
