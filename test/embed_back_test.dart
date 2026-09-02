import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/mysafar_sdk.dart';
import 'package:mysafar_sdk/src/core/router/navigation_service.dart';
import 'package:mysafar_sdk/src/core/router/sdk_embed_back_handler.dart';

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

  Future<void> openEmbed(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (hostContext) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(hostContext).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MySafarEmbed(),
                      ),
                    );
                  },
                  child: const Text('Open SDK'),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Open SDK'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 2));
    expect(MySafarSdk.isEmbedded, isTrue);
  }

  Future<void> triggerSystemBack(WidgetTester tester) async {
    final handled = await tester.binding.handlePopRoute();
    expect(handled, isTrue);
    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets('system back at embed root closes embed, not host app',
      (tester) async {
    await openEmbed(tester);

    await triggerSystemBack(tester);

    expect(MySafarSdk.isEmbedded, isFalse);
    expect(find.byType(MySafarEmbed), findsNothing);
  });

  testWidgets('system back pops inner SDK route before closing embed',
      (tester) async {
    await openEmbed(tester);

    NavigationService.navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Inner SDK Page')),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      NavigationService.navigatorKey.currentState!.canPop(),
      isTrue,
      reason: 'inner route push should make SDK navigator poppable',
    );
    expect(find.text('Inner SDK Page'), findsOneWidget);

    await triggerSystemBack(tester);

    expect(MySafarSdk.isEmbedded, isTrue);
    expect(find.text('Inner SDK Page'), findsNothing);

    await triggerSystemBack(tester);

    expect(MySafarSdk.isEmbedded, isFalse);
    expect(find.byType(MySafarEmbed), findsNothing);
  });

  testWidgets('SdkEmbedBackHandler.handleBack mirrors exitEmbed at root',
      (tester) async {
    await openEmbed(tester);

    SdkEmbedBackHandler.handleBack();
    await tester.pumpAndSettle();

    expect(MySafarSdk.isEmbedded, isFalse);
  });
}
