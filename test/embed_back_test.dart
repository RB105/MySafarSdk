import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/mysafar_sdk.dart';
import 'package:mysafar_sdk/src/core/router/navigation_service.dart';
import 'package:mysafar_sdk/src/core/router/sdk_embed_back_handler.dart';
import 'package:mysafar_sdk/src/view/navbar/bottom_nav_bar.dart';

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

  setUp(() {
    SdkEmbedBackHandler.resetDoubleBack();
    BottomNavBarPage.currentTabIndex.value = 0;
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
    // Root-back lock (PopScope + didPopRoute dedupe) ochilsin.
    await tester.pump(SdkEmbedBackHandler.rootBackLock);
    await tester.pumpAndSettle();
  }

  testWidgets('system back on Main requires two presses to close embed',
      (tester) async {
    await openEmbed(tester);

    await triggerSystemBack(tester);
    expect(MySafarSdk.isEmbedded, isTrue);
    expect(find.byType(MySafarEmbed), findsOneWidget);

    await triggerSystemBack(tester);
    expect(MySafarSdk.isEmbedded, isFalse);
    expect(find.byType(MySafarEmbed), findsNothing);
  });

  testWidgets('system back from non-home tab switches to Main once',
      (tester) async {
    await openEmbed(tester);

    BottomNavBarPage.switchTo(3);
    await tester.pumpAndSettle();
    expect(BottomNavBarPage.currentTabIndex.value, 3);

    await triggerSystemBack(tester);

    expect(MySafarSdk.isEmbedded, isTrue);
    expect(BottomNavBarPage.currentTabIndex.value, 0);
  });

  testWidgets('system back pops inner SDK route before double-back exit',
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
    expect(MySafarSdk.isEmbedded, isTrue);

    await triggerSystemBack(tester);
    expect(MySafarSdk.isEmbedded, isFalse);
    expect(find.byType(MySafarEmbed), findsNothing);
  });

  testWidgets('SdkEmbedBackHandler.handleBack double-back exits at Main',
      (tester) async {
    await openEmbed(tester);

    SdkEmbedBackHandler.handleBack();
    await tester.pump(SdkEmbedBackHandler.rootBackLock);
    await tester.pumpAndSettle();
    expect(MySafarSdk.isEmbedded, isTrue);

    SdkEmbedBackHandler.handleBack();
    await tester.pumpAndSettle();
    expect(MySafarSdk.isEmbedded, isFalse);
  });

  testWidgets(
      'nested MaterialApp at root does not set frameworkHandlesBack false',
      (tester) async {
    final handlesBack = <bool>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
          handlesBack.add(call.arguments as bool);
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await openEmbed(tester);
    handlesBack.clear();

    final innerContext = NavigationService.navigatorKey.currentContext;
    expect(innerContext, isNotNull);
    const NavigationNotification(canHandlePop: false).dispatch(innerContext!);
    await tester.pump();

    expect(
      handlesBack,
      isEmpty,
      reason: 'nested MaterialApp must swallow the notification, not tell '
          'Android that Flutter cannot handle back (API 36 back-to-home)',
    );
    expect(MySafarSdk.isEmbedded, isTrue);
    expect(find.byType(MySafarEmbed), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
