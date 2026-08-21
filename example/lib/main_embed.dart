import 'package:flutter/material.dart';
import 'package:mysafar_sdk/mysafar_sdk.dart';

/// Embed rejimi: host app (Unired stsenariysi) SDK'ni oddiy route sifatida
/// push qiladi.
///
/// Ishga tushirish (local secretlar `env.json` dan):
///   cp env.json.example env.json   # bir marta
///   flutter run -t lib/main_embed.dart --dart-define-from-file=env.json
///
/// Yoki alohida:
///   flutter run -t lib/main_embed.dart \
///     --dart-define=PARTNER_TOKEN=xxx \
///     --dart-define=USER_PHONE=998... \
///     --dart-define=USER_EMAIL=...
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

      // MUHIM — terminal `b` bilan sinash uchun themeMode YOZMASLIK kerak!
      // themeMode: ThemeMode.dark  ← bu qator bo'lsa `b` ishlamaydi.
      // Production (Unired): themeMode: ThemeMode.dark yoki .light
      // brandColor berilmasa default #0057BE qoladi.
      // brandColor: Colors.green,
      // bottomBarStyle: MySafarBottomBarStyle(
      //   backgroundColorLight: Colors.amber,
      //   borderRadius: 0,
      //   backgroundColorDark: Colors.blue,
      // ),
      // homeHeaderStyle: MySafarHomeHeaderStyle(
      //   // logo .png va .svg formatni qabul qiladi
      //   // logo uchun .svg berilsa logo xira bolib qolmaydi
      //   logoAssetPath: 'packages/mysafar_sdk/assets/img/splash/logo.svg',
      //   logoBackgroundColor: Colors.amber,
      //   title: 'Asadulloh',
      //   description: 'bilan parvoz qiling',
      // ),
    ),
  );

  runApp(const HostApp());
}

/// Soddalashtirilgan "host app" — o'z MaterialApp'i va bitta ekrani bor.
class HostApp extends StatelessWidget {
  const HostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Host App',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const HostHomePage(),
    );
  }
}

class HostHomePage extends StatelessWidget {
  const HostHomePage({super.key});

  static const String _userPhone = String.fromEnvironment('USER_PHONE');
  static const String _userEmail = String.fromEnvironment('USER_EMAIL');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Host App')),
      body: Center(
        child: FilledButton.icon(
          icon: const Icon(Icons.flight_takeoff),
          label: const Text('MySafar — aviabilet'),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MySafarEmbed(
                  // Host user'ining raqami/emaili — SDK bir marta jim
                  // ro'yxatdan o'tkazadi va emailni profilga yozadi.
                  // Qiymatlar env.json / --dart-define orqali beriladi.
                  phoneNumber: _userPhone.isEmpty ? null : _userPhone,
                  email: _userEmail.isEmpty ? null : _userEmail,
                  // Host joriy tili — SDK shu tilda ochiladi.
                  locale: Localizations.localeOf(context),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
