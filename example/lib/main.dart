import 'package:flutter/material.dart';
import 'package:mysafar_sdk/mysafar_sdk.dart';

/// To'liq app rejimi: SDK o'zi MaterialApp quradi.
///
/// Ishga tushirish:
///   flutter run --dart-define=PARTNER_TOKEN=xxx
///
/// Embed (host ichida) rejimini sinash uchun: lib/main_embed.dart
Future<void> main() async {
  await MySafarSdk.init(
    config: const MySafarConfig(
      baseUrl: String.fromEnvironment(
        'BASE_URL',
        defaultValue: 'https://api.mysafar.ru',
      ),
      
      skoteBaseUrl: String.fromEnvironment(
        'SKOTE_BASE_URL',
        defaultValue: 'https://cms.mysafar.uz/api',
      ),
      partnerToken: String.fromEnvironment('PARTNER_TOKEN'),
      // Firebase example'da init qilinmaydi — Firestore config, Google auth
      // va MyID o'chiq holda ishlashi tekshiriladi.
    ),
  );

  runApp(const MySafarApp());
}
