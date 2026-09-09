import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/mysafar_sdk.dart';
import 'package:mysafar_sdk/src/core/router/android_system_back.dart';
import 'package:mysafar_sdk/src/core/router/navigation_service.dart';
import 'package:mysafar_sdk/src/core/router/sdk_embed_back_handler.dart';
import 'package:mysafar_sdk/src/view/navbar/bottom_nav_bar.dart';

/// Android 13+ (va Android 16 da MAJBURIY) tizim back'i Flutter'ga
/// `flutter/navigation`dagi `popRoute` orqali EMAS, `flutter/backgesture`
/// kanalidagi `startBackGesture` / `commitBackGesture` orqali keladi.
/// `embed_back_test.dart` faqat eski `popRoute` yo'lini sinaydi — bu fayl
/// haqiqiy qurilma yo'lini qoplaydi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Directory? createdTempDir;
  void addTearDownAll(Directory dir) => createdTempDir = dir;

  tearDownAll(() {
    try {
      createdTempDir?.deleteSync(recursive: true);
    } on FileSystemException {
      // Box hali ochiq bo'lsa — CI temp'ini o'zi tozalaydi.
    }
  });

  setUpAll(() async {
    const pathProviderChannel =
        MethodChannel('plugins.flutter.io/path_provider');
    // Alohida katalog: test fayllari parallel ishlaydi va umumiy temp
    // papkada Hive box lock'i to'qnashadi.
    final tempDir = Directory.systemTemp.createTempSync('mysafar_sdk_pb_test');
    addTearDownAll(tempDir);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      pathProviderChannel,
      (call) async => tempDir.path,
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

  /// `button: true` — 3 tugmali navigatsiya (touchOffset yo'q → isButtonEvent).
  /// `button: false` — chetdan tizim swipe'i (predictive back).
  Future<void> sendSystemBack(WidgetTester tester, {required bool button}) async {
    const codec = StandardMethodCodec();
    Future<void> send(String method, [Object? args]) {
      return tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/backgesture',
        codec.encodeMethodCall(MethodCall(method, args)),
        (_) {},
      );
    }

    await send('startBackGesture', <String, Object?>{
      'touchOffset': button ? null : <double>[0.0, 300.0],
      'progress': 0.0,
      'swipeEdge': 0,
    });
    await tester.pump();
    if (!button) {
      await send('updateBackGestureProgress', <String, Object?>{
        'touchOffset': <double>[220.0, 300.0],
        'progress': 0.9,
        'swipeEdge': 0,
      });
      await tester.pump();
    }
    await send('commitBackGesture');
    await tester.pump();
    await tester.pump(SdkEmbedBackHandler.rootBackLock);
    await tester.pumpAndSettle();
  }

  Future<void> openEmbed(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (hostContext) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => Navigator.of(hostContext).push(
                  MaterialPageRoute<void>(builder: (_) => const MySafarEmbed()),
                ),
                child: const Text('Open SDK'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Open SDK'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(MySafarSdk.isEmbedded, isTrue);
  }

  Future<void> pushInnerRoute(WidgetTester tester) async {
    NavigationService.navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Inner SDK Page')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Inner SDK Page'), findsOneWidget);
  }

  testWidgets('3-button back at SDK root does not leave the embed at once',
      (tester) async {
    await openEmbed(tester);

    await sendSystemBack(tester, button: true);
    expect(MySafarSdk.isEmbedded, isTrue,
        reason: 'first back at SDK root must only warn, not exit');

    await sendSystemBack(tester, button: true);
    expect(MySafarSdk.isEmbedded, isFalse,
        reason: 'second back within the double-back window returns to host');
    await tester.pumpAndSettle();
  });

  testWidgets('3-button back pops the inner SDK route', (tester) async {
    await openEmbed(tester);
    await pushInnerRoute(tester);

    await sendSystemBack(tester, button: true);

    expect(find.text('Inner SDK Page'), findsNothing);
    expect(MySafarSdk.isEmbedded, isTrue);
    await tester.pumpAndSettle();
  });

  testWidgets('system swipe back pops the inner SDK route', (tester) async {
    await openEmbed(tester);
    await pushInnerRoute(tester);

    await sendSystemBack(tester, button: false);

    expect(find.text('Inner SDK Page'), findsNothing);
    expect(MySafarSdk.isEmbedded, isTrue);
    await tester.pumpAndSettle();
  });

  testWidgets('3-button back from a non-home tab returns to Main',
      (tester) async {
    await openEmbed(tester);
    BottomNavBarPage.switchTo(3);
    await tester.pumpAndSettle();

    await sendSystemBack(tester, button: true);

    expect(BottomNavBarPage.currentTabIndex.value, 0);
    expect(MySafarSdk.isEmbedded, isTrue);
    await tester.pumpAndSettle();
  });

  testWidgets('embed keeps re-asserting frameworkHandlesBack while open',
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
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await openEmbed(tester);
    expect(handlesBack, isNotEmpty);
    expect(handlesBack, everyElement(isTrue),
        reason: 'the SDK must never hand back control while the embed is open');

    // Ichki stack root'ga qaytganda nested MaterialApp `canHandlePop: false`
    // yozmoqchi bo'ladi — SDK uni `true` ga aylantirishi shart, aks holda
    // Android 16 da OnBackInvokedCallback ro'yxatdan chiqadi.
    handlesBack.clear();
    final innerContext = NavigationService.navigatorKey.currentContext;
    expect(innerContext, isNotNull);
    const NavigationNotification(canHandlePop: false).dispatch(innerContext!);
    await tester.pump();

    expect(handlesBack, isNotEmpty);
    expect(handlesBack, everyElement(isTrue));

    await tester.pumpAndSettle();
  });

  testWidgets('embed asks its Android module to own the system back',
      (tester) async {
    final calls = <String>[];
    const channel = MethodChannel('mysafar_sdk/android_back');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async {
        calls.add(call.method);
        return true;
      },
    );
    // Productionda framework'ga `channelBuffers.push` orqali kiritiladi;
    // testda TestDefaultBinaryMessenger channelBuffers'ni chetlab o'tadi.
    AndroidSystemBack.dispatchToFramework = (name, message) {
      tester.binding.defaultBinaryMessenger
          .handlePlatformMessage(name, message, (_) {});
    };
    addTearDown(() {
      AndroidSystemBack.dispatchToFramework =
          AndroidSystemBack.pushToChannelBuffers;
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    await openEmbed(tester);
    await tester.pump();
    expect(calls, contains('enable'),
        reason: 'the SDK must register its own OnBackInvokedCallback, since '
            'Flutter only registers one inside a FlutterActivity host');

    // Native back event framework kanaliga qayta kiritiladi va odatdagi
    // SDK back oqimini ishga tushiradi.
    await pushInnerRoute(tester);
    await AndroidSystemBack.debugDispatchNativeBackEvent(
      const MethodCall('startBackGesture', <String, Object?>{
        'touchOffset': null,
        'progress': 0.0,
        'swipeEdge': 0,
      }),
    );
    await AndroidSystemBack.debugDispatchNativeBackEvent(
      const MethodCall('commitBackGesture'),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Inner SDK Page'), findsNothing,
        reason: 'a native back event must pop the inner SDK route');
    expect(MySafarSdk.isEmbedded, isTrue);
    await tester.pumpAndSettle();
  });
}
