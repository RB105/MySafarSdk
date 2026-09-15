import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/src/view/booking/widget/booking_form_fields.dart';

void main() {
  // Kichik ekran + ochiq klaviatura: maydon ostida tavsiyalarga joy yetmaydi.
  Future<FocusNode> pumpFieldAboveKeyboard(
    WidgetTester tester, {
    required double top,
  }) async {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.reset);

    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Padding(
            padding: EdgeInsets.only(top: top, left: 16, right: 16),
            child: BookingTextField(
              label: 'Familiya',
              controller: TextEditingController(),
              focusNode: focusNode,
              onChanged: (_) {},
              showError: false,
              suggestions: const ['ALIYEV', 'ALIMOV', 'ALIQULOV'],
            ),
          ),
        ),
      ),
    );
    return focusNode;
  }

  testWidgets('pastda joy kam bo\'lsa tavsiyalar overflow bermaydi va tepaga '
      'ochiladi', (tester) async {
    await pumpFieldAboveKeyboard(tester, top: 230);

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'AL');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('ALIQULOV'), findsOneWidget);

    final fieldTop = tester.getRect(find.byType(TextField)).top;
    final optionBottom = tester.getRect(find.text('ALIQULOV')).bottom;
    expect(optionBottom, lessThanOrEqualTo(fieldTop));
  });

  testWidgets('pastda joy yetarli bo\'lsa tavsiyalar maydon ostida ochiladi',
      (tester) async {
    await pumpFieldAboveKeyboard(tester, top: 16);

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'AL');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final fieldBottom = tester.getRect(find.byType(TextField)).bottom;
    final optionTop = tester.getRect(find.text('ALIYEV')).top;
    expect(optionTop, greaterThanOrEqualTo(fieldBottom));
  });
}
