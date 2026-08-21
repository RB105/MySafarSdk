import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/mysafar_sdk.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    const pathProviderChannel =
        MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      pathProviderChannel,
      (call) async => Directory.systemTemp.path,
    );
    await MySafarSdk.init(
      config: const MySafarConfig(
        baseUrl: 'https://api.example.com',
        skoteBaseUrl: 'https://cms.example.com/api',
        appName: 'Unired',
        enableServicesTab: false,
      ),
    );
  });

  testWidgets('MySafarEmbed host route ichida quriladi (qora ekran smoke)',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MySafarEmbed()),
    );
    // FutureBuilder + birinchi frame'lar
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    // Ichki nested MaterialApp qurilgan bo'lishi kerak
    expect(find.byType(MaterialApp), findsNWidgets(2));
  });

  testWidgets('MySafarEmbed locale host tiliga sync qiladi', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MySafarEmbed(locale: Locale('ru'))),
    );
    // rootBundle (til JSON) real async — fake timer bilan yetmaydi.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(SdkLocalization.locale.languageCode, 'ru');
  });
}
