import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart';
import 'package:mysafar_sdk/src/core/widgets/date_calendar_widget.dart';
import 'package:mysafar_sdk/src/core/widgets/sdk_dialog.dart';
import 'package:mysafar_sdk/src/cubit/search/route_search_cubit.dart'
    show RouteSearchState;
import 'package:mysafar_sdk/src/model/remote/avia/airports_model.dart';
import 'package:mysafar_sdk/src/view/destinations/cover_image_cache_size.dart';

void main() {
  final tas = AirPortsModel(cityName: 'Tashkent', cityIataCode: 'TAS');
  final ist = AirPortsModel(cityName: 'Istanbul', cityIataCode: 'IST');

  test('RouteSearchState.klassLabelKey — kalendar xulosasi uchun (№24)', () {
    String key(String k) =>
        RouteSearchState(from: tas, to: ist, klass: k).klassLabelKey;
    expect(key('e'), 'klass_e');
    expect(key('b'), 'klass_b');
    expect(key('f'), 'klass_f');
    expect(key('w'), 'klass_w');
    expect(key('a'), 'klass_a_short');
    expect(key('?'), 'klass_a_short');
  });

  test('citySheetClosed — sheet ochilmagan bo\'lsa darhol tugaydi', () async {
    await ProjectDialogs.citySheetClosed().timeout(
      const Duration(milliseconds: 50),
    );
  });

  group('DateCalendarWidget tasdiqlash tugmasi (№24)', () {
    Future<void> pump(WidgetTester tester, Widget child) async {
      await tester.pumpWidget(MaterialApp(home: child));
      await tester.pump();
    }

    testWidgets('confirmLabel va yo\'lovchilar xulosasi ko\'rinadi',
        (tester) async {
      int taps = 0;
      await pump(
        tester,
        DateCalendarWidget(
          type: 2,
          params: null,
          confirmLabel: 'SEARCH',
          passengerSummary: '1 pax',
          onPassengerSummaryTap: () async {
            taps++;
            return '2 pax';
          },
        ),
      );
      expect(find.text('SEARCH'), findsOneWidget);
      expect(find.text('1 pax'), findsOneWidget);
      await tester.tap(find.text('1 pax'));
      await tester.pump();
      expect(taps, 1);
      expect(find.text('2 pax'), findsOneWidget);
    });

    testWidgets('oddiy rejimda xulosa yo\'q', (tester) async {
      await pump(tester, const DateCalendarWidget(type: 2, params: null));
      expect(find.text('SEARCH'), findsNothing);
      expect(find.byIcon(Icons.person_outline_rounded), findsNothing);
    });
  });

  testWidgets('SdkDialogCloseButton — bosish maydoni ≥44 dp va nomi bor (№32)',
      (tester) async {
    int taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(child: SdkDialogCloseButton(onTap: () => taps++)),
      ),
    ));
    final size = tester.getSize(find.byType(SdkDialogCloseButton));
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
    // Ko'rinadigan doiradan tashqaridagi burchak ham bosiladi.
    final rect = tester.getRect(find.byType(SdkDialogCloseButton));
    await tester.tapAt(rect.topLeft + const Offset(2, 2));
    expect(taps, 1);
    expect(
      find.bySemanticsLabel(
          const DefaultMaterialLocalizations().closeButtonTooltip),
      findsOneWidget,
    );
  });

  testWidgets('coverImageCacheSize — faqat bitta tomon (№43)', (tester) async {
    late ({int? width, int? height}) tall, wide;
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(devicePixelRatio: 3),
      child: Builder(builder: (context) {
        tall = coverImageCacheSize(context, 170, 220);
        wide = coverImageCacheSize(context, 360, 128);
        return const SizedBox();
      }),
    ));
    expect(tall, (width: null, height: 660));
    expect(wide, (width: 1080, height: null));
  });
}
