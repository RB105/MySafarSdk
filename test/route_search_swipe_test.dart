// Yo'nalish sahifasi: chapga/o'ngga surish "Bir tomonlama" va
// "Multi marshrut" rejimlarini almashtiradi.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/mysafar_sdk.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/styles/theme_notifier.dart';
import 'package:mysafar_sdk/src/core/tools/currency_provider.dart';
import 'package:mysafar_sdk/src/model/remote/avia/airports_model.dart';
import 'package:mysafar_sdk/src/view/search/route_search_page.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final tmp = Directory.systemTemp.createTempSync('pp');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => tmp.path);
  setUpAll(() async {
    await MySafarSdk.init(
      config: const MySafarConfig(
        baseUrl: 'https://api.example.com',
        skoteBaseUrl: 'https://cms.example.com/api',
        appName: 'Unired',
      ),
    );
  });
  for (final dark in [false, true]) {
    testWidgets('surish rejimni almashtiradi (dark=$dark)', (tester) async {
      tester.view.physicalSize = const Size(1080, 1500);
      tester.view.devicePixelRatio = 2.7;
      tester.view.padding = const FakeViewPadding(top: 90);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeNotifier>(
              create: (_) => ThemeNotifier(
                  initialMode: dark ? ThemeMode.dark : ThemeMode.light)),
          ChangeNotifierProvider<CurrencyProvider>(
              create: (_) => CurrencyProvider()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ProjectTheme.light,
          darkTheme: ProjectTheme.dark,
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          home: RouteSearchPage(
            from: AirPortsModel(cityName: 'Toshkent', cityIataCode: 'TAS'),
            to: AirPortsModel(cityName: 'Dubay', cityIataCode: 'DXB'),
          ),
        ),
      ));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Toshkent (TAS)'), findsOneWidget);
      // Chapga surish — "Multi marshrut".
      await tester.fling(
          find.text('Toshkent (TAS)').first, const Offset(-250, 0), 1200);
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      // Multi marshrutda 2 ta yo'nalish: ikkinchisi Dubaydan boshlanadi.
      expect(find.text('Dubay (DXB)'), findsNWidgets(2));
      // O'ngga surish — qaytib "Bir tomonlama".
      await tester.flingFrom(
          const Offset(200, 330), const Offset(250, 0), 1200);
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('Dubay (DXB)'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });
  }
}
