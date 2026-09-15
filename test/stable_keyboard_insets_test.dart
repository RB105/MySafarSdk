import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/src/core/widgets/stable_keyboard_insets.dart';

void main() {
  const keyboard = 300.0;

  Future<List<double>> pumpForm(WidgetTester tester) async {
    final seen = <double>[];
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigatorKey,
      home: const Scaffold(body: Text('home')),
    ));
    navigatorKey.currentState!.push(MaterialPageRoute<void>(
      builder: (_) => StableKeyboardInsets(
        child: Builder(builder: (context) {
          seen.add(MediaQuery.viewInsetsOf(context).bottom);
          return const Scaffold(body: Text('form'));
        }),
      ),
    ));
    await tester.pumpAndSettle();
    return seen;
  }

  void setKeyboard(WidgetTester tester, double logical) {
    tester.view.viewInsets = FakeViewPadding(
      bottom: logical * tester.view.devicePixelRatio,
    );
  }

  testWidgets('live inset while the route is current', (tester) async {
    addTearDown(tester.view.reset);
    final seen = await pumpForm(tester);

    setKeyboard(tester, keyboard);
    await tester.pump();
    expect(seen.last, keyboard);

    setKeyboard(tester, 0);
    await tester.pump();
    expect(seen.last, 0);
  });

  testWidgets('inset frozen while the route pops', (tester) async {
    addTearDown(tester.view.reset);
    final seen = await pumpForm(tester);

    setKeyboard(tester, keyboard);
    await tester.pump();

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    // Klaviatura pop paytida yopiladi — ketayotgan sahifa joyida qolishi kerak.
    setKeyboard(tester, 120);
    await tester.pump(const Duration(milliseconds: 50));
    setKeyboard(tester, 0);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('form'), findsOneWidget);
    expect(seen.last, keyboard);

    await tester.pumpAndSettle();
    expect(find.text('form'), findsNothing);
  });

  testWidgets('bottom padding stays at viewPadding with keyboard open',
      (tester) async {
    addTearDown(tester.view.reset);
    tester.view.viewPadding = FakeViewPadding(
      bottom: 34 * tester.view.devicePixelRatio,
    );
    double? padding;
    await tester.pumpWidget(MaterialApp(
      home: StableKeyboardInsets(
        child: Builder(builder: (context) {
          padding = MediaQuery.paddingOf(context).bottom;
          return const SizedBox();
        }),
      ),
    ));

    tester.view.padding = FakeViewPadding.zero;
    setKeyboard(tester, keyboard);
    await tester.pump();
    expect(padding, 34);
  });
}
