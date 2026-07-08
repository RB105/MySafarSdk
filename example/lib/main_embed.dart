import 'package:flutter/material.dart';
import 'package:mysafar_sdk/mysafar_sdk.dart';

/// Embed rejimi: host app (Unired stsenariysi) SDK'ni oddiy route sifatida
/// push qiladi.
///
/// Ishga tushirish:
///   flutter run -t lib/main_embed.dart --dart-define=PARTNER_TOKEN=xxx
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
                builder: (_) => const MySafarEmbed(
                  // Host user'ining raqami — SDK bir marta jim ro'yxatdan
                  // o'tkazadi (--dart-define=USER_PHONE=998... bilan bering).
                  phoneNumber: String.fromEnvironment('USER_PHONE') == ''
                      ? null
                      : String.fromEnvironment('USER_PHONE'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
