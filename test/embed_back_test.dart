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
    SdkEmbedBackHandler.reset();
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

  testWidgets('system back on Main closes embed with one press',
      (tester) async {
    await openEmbed(tester);

    await triggerSystemBack(tester);
    expect(MySafarSdk.isEmbedded, isFalse);
    expect(find.byType(MySafarEmbed), findsNothing);
  });

  testWidgets('system back from non-home tab goes to Main, then closes embed',
      (tester) async {
    await openEmbed(tester);

    for (final tab in [1, 2, 3]) {
      BottomNavBarPage.switchTo(tab);
      await tester.pumpAndSettle();
      expect(BottomNavBarPage.currentTabIndex.value, tab);

      await triggerSystemBack(tester);
      expect(MySafarSdk.isEmbedded, isTrue,
          reason: 'back on tab $tab must only return to Main');
      expect(BottomNavBarPage.currentTabIndex.value, 0);
    }

    await triggerSystemBack(tester);
    expect(MySafarSdk.isEmbedded, isFalse);
    expect(find.byType(MySafarEmbed), findsNothing);
  });

  testWidgets('duplicate back event from one gesture does not also exit',
      (tester) async {
    await openEmbed(tester);
    BottomNavBarPage.switchTo(2);
    await tester.pumpAndSettle();

    // PopScope + didPopRoute bitta gesture'da ikkalasi ham kelishi mumkin.
    SdkEmbedBackHandler.handleBack();
    SdkEmbedBackHandler.handleBack();
    await tester.pumpAndSettle();

    expect(BottomNavBarPage.currentTabIndex.value, 0);
    expect(MySafarSdk.isEmbedded, isTrue);
  });

  testWidgets('system back pops inner SDK route before exit', (tester) async {
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

  testWidgets(
      'system back respects PopScope(canPop: false) on inner route '
      '(payment page guard)', (tester) async {
    await openEmbed(tester);

    var guardCalls = 0;
    NavigationService.navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) guardCalls++;
          },
          child: const Scaffold(body: Text('Guarded Payment Page')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await triggerSystemBack(tester);

    expect(guardCalls, 1, reason: 'page guard must receive the back event');
    expect(find.text('Guarded Payment Page'), findsOneWidget,
        reason: 'guarded route must not be popped directly');
    expect(MySafarSdk.isEmbedded, isTrue);
  });

  testWidgets('SdkEmbedBackHandler.handleBack exits at Main', (tester) async {
    await openEmbed(tester);

    SdkEmbedBackHandler.handleBack();
    await tester.pumpAndSettle();
    expect(MySafarSdk.isEmbedded, isFalse);
  });

  testWidgets(
      'nested MaterialApp at root keeps frameworkHandlesBack true',
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
      isNotEmpty,
      reason: 'nested MaterialApp at SDK root must re-assert '
          'frameworkHandlesBack=true so the 3-button back stays registered',
    );
    expect(handlesBack, everyElement(isTrue));
    expect(MySafarSdk.isEmbedded, isTrue);
    expect(find.byType(MySafarEmbed), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
