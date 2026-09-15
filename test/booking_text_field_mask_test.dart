import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:mysafar_sdk/src/view/booking/widget/booking_form_fields.dart';

void main() {
  Future<(TextEditingController, FocusNode)> pumpDateField(
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    final formatter = MaskTextInputFormatter(
      type: MaskAutoCompletionType.lazy,
      mask: '##.##.####',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookingTextField(
            label: 'Tug\'ilgan sana',
            controller: controller,
            focusNode: focusNode,
            onChanged: (_) {},
            showError: false,
            keyboardType: TextInputType.number,
            inputFormatters: [formatter],
          ),
        ),
      ),
    );
    return (controller, focusNode);
  }

  Future<void> backspace(WidgetTester tester, TextEditingController c) async {
    final text = c.text;
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: text.substring(0, text.length - 1),
        selection: TextSelection.collapsed(offset: text.length - 1),
      ),
    );
    await tester.pump();
  }

  testWidgets(
      'koddan to\'ldirilgan sanada backspace faqat bitta belgini o\'chiradi',
      (tester) async {
    final (controller, focusNode) = await pumpDateField(tester);

    // Skaner / saqlangan yo'lovchi / kalendar — matn koddan o'rnatiladi.
    controller.text = '01.02.2002';
    await tester.pump();

    await tester.showKeyboard(find.byType(TextField));
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '01.02.2002',
        selection: TextSelection.collapsed(offset: 10),
      ),
    );
    await tester.pump();

    await backspace(tester, controller);
    expect(controller.text, '01.02.200');

    await backspace(tester, controller);
    expect(controller.text, '01.02.20');

    focusNode.dispose();
    controller.dispose();
  });

  testWidgets('matn koddan tozalansa, yangidan yozish ishlaydi',
      (tester) async {
    final (controller, focusNode) = await pumpDateField(tester);

    controller.text = '01.02.2002';
    await tester.pump();
    controller.clear();
    await tester.pump();

    await tester.enterText(find.byType(TextField), '15061990');
    await tester.pump();
    expect(controller.text, '15.06.1990');

    focusNode.dispose();
    controller.dispose();
  });
}
