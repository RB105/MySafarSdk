import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk_example/main_embed.dart';

void main() {
  testWidgets('Host app builds with MySafar entry button', (tester) async {
    await tester.pumpWidget(const HostApp());
    expect(find.byType(FilledButton), findsOneWidget);
  });
}
