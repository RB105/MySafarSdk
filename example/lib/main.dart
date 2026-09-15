import 'package:flutter/material.dart';
import 'package:mysafar_sdk/mysafar_sdk.dart';

/// To'liq app rejimi: SDK o'zi MaterialApp quradi.
///
/// Ishga tushirish (Unired konfiguratsiyasi local `env.json` dan):
///   cp env.json.example env.json   # bir marta, MYSAFAR_* ni to'ldiring
///   flutter run --dart-define-from-file=env.json
///
/// Embed (host ichida) rejimini sinash uchun: lib/main_embed.dart
Future<void> main() async {
  await MySafarSdk.init(
    // Unired init'i bilan bir xil config. URL/token bo'sh — debug'da SDK
    // ularni env.json dagi MYSAFAR_* qiymatlaridan to'ldiradi. Release'da
    // hech narsa to'ldirilmaydi: host haqiqiy qiymatlarni shu yerga beradi.
    // Firebase example'da init qilinmaydi — Firestore config, Google auth
    // va MyID o'chiq holda ishlashi tekshiriladi.
    config: const MySafarConfig(
      baseUrl: '',
      skoteBaseUrl: '',
      enableServicesTab: false,
    ),
  );

  runApp(const MySafarApp());
}
