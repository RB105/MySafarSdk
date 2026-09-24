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
///     --dart-define=MYSAFAR_PARTNER_TOKEN=xxx \
///     --dart-define=USER_PHONE=998... \
///     --dart-define=USER_EMAIL=...
Future<void> main() async {
  await MySafarSdk.init(
    // Unired init'i bilan bir xil config. URL/token bo'sh — debug'da SDK
    // ularni env.json dagi MYSAFAR_* qiymatlaridan to'ldiradi. Release'da
    // hech narsa to'ldirilmaydi: host haqiqiy qiymatlarni shu yerga beradi.
    config: const MySafarConfig(
      baseUrl: '',
      skoteBaseUrl: '',
      enableServicesTab: false,

      // brandColor berilmasa default #0057BE qoladi.
      // brandColor: Colors.green,
      // support: MySafarSupportConfig(
      //   phone: '+998 99 000 00 00',
      //   telegramUrl: 'https://t.me/nom0n0v',
      // ),
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
    // Host berishi mumkin: email, myid malumot, kartalar.
    userData: MySafarUserData(
      email: 'user@example.com',
      identification: MySafarUserIdentification(
        firstName: 'VALI',
        lastName: 'ALIYEV',
        middleName: 'VALIYEVICH',
        birthDate: '15.03.1990', // yoki 1990-03-15
        passSeries: 'AA1234567',
        passSeriesMask: 'AA*******',
        passExpiry: '15.03.2030',
        pinfl: '30103901234567',
        pinflMask: '30103********',
        address: 'Toshkent sh.',
        isResident: true,
      ),
    //   uzsCards: [
    //     MySafarUzsCard(
    //       cardNumber: '8600123412341234',
    //       expire: '2812', // YYMM
    //       cardMask: '8600 **** **** 1234',
    //       owner: 'ALIYEV VALI',
    //       balance: 1250000, // so'mda
    //       cardLogoUrl: 'https://example.com/logo/uzcard.svg', // to'liq URL
    //     ),
    //   ],
    //   foreignCards: [
    //     MySafarForeignCard(
    //       cardToken: 'host-processing-token',
    //       cardMask: '4276 **** **** 1234',
    //       owner: 'ALIYEV VALI',
    //       currency: 'USD',
    //     ),
    //   ],
    // ),
    // card_token kaliti: config'da `cardTokenSecret` (debug'da bo'sh bo'lsa
    // env.json dagi MYSAFAR_CARD_TOKEN_SECRET). Token serverda yaratilsa:
    // callbacks: MySafarCallbacks(
    //   onCreateCardToken: (request) => myBackend.createMySafarCardToken(
    //     cardNumber: request.card.cardNumberDigits,
    //     expire: request.card.expire, // YYMM
    //     trId: request.trId,
    //   ),
     ),
  );

  // Back diagnostikasi: tizim back'i Flutter'ga yetib keladimi.
  // Loglar `MySafarBack:` tegi bilan `flutter logs` da ko'rinadi.
  MySafarSdk.debugBackLogging = true;

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
                  // Host joriy temasi — har ochilishda beriladi:
                  //themeMode:  ThemeMode.dark // → faqat qorong'u
                  themeMode: ThemeMode.light, // → faqat yorug'
                  // null            → sistema temasi (terminal `b` ishlaydi)
                  // Production (Unired): ThemeMode.dark yoki .light
                  // themeMode: ThemeMode.dark,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
