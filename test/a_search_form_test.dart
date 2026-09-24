import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/src/core/widgets/passenger_count_widget.dart';
import 'package:mysafar_sdk/src/cubit/main/datePicker/date_picker_cubit.dart'
    show MonthPriceParams;
import 'package:mysafar_sdk/src/cubit/search/route_search_cubit.dart'
    show RouteSearchCubit;
import 'package:mysafar_sdk/src/model/local/recom_req_model.dart'
    show RecommendationRequestBody;
import 'package:mysafar_sdk/src/model/remote/avia/airports_model.dart';

void main() {
  final tas = AirPortsModel(cityName: 'Tashkent', cityIataCode: 'TAS');
  final ist = AirPortsModel(cityName: 'Istanbul', cityIataCode: 'IST');

  group('RouteSearchCubit.initialState (№31)', () {
    test('oxirgi qidiruvsiz — standart qiymatlar', () {
      final s = RouteSearchCubit.initialState(from: tas, to: ist);
      expect([s.adt, s.chd, s.inf], [1, 0, 0]);
      expect(s.klass, 'e');
    });

    test('yo\'lovchilar va klass oxirgi qidiruvdan olinadi', () {
      final s = RouteSearchCubit.initialState(
        from: tas,
        to: ist,
        lastSearch: RecommendationRequestBody(
            adt: 2, chd: 1, inf: 1, klass: 'B'),
      );
      expect([s.adt, s.chd, s.inf], [2, 1, 1]);
      expect(s.klass, 'b');
    });

    test('noto\'g\'ri tarkib (chaqaloq > katta) standartga qaytadi', () {
      final s = RouteSearchCubit.initialState(
        from: tas,
        to: ist,
        lastSearch:
            RecommendationRequestBody(adt: 1, chd: 0, inf: 2, klass: 'x'),
      );
      expect([s.adt, s.chd, s.inf], [1, 0, 0]);
      expect(s.klass, 'e');
    });
  });

  test('MonthPriceParams.normalizeKlass (№39)', () {
    expect(MonthPriceParams.normalizeKlass(null), 'a');
    expect(MonthPriceParams.normalizeKlass(''), 'a');
    expect(MonthPriceParams.normalizeKlass(' E '), 'e');
  });

  group('PassengerCountWidget — chaqaloqlar ≤ kattalar (№13)', () {
    Future<Map<String, dynamic>?> pumpAndApply(
      WidgetTester tester,
      Map<String, dynamic> params,
      Future<void> Function() actions,
    ) async {
      Map<String, dynamic>? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PassengerCountWidget(params: params),
                ));
              },
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await actions();
      await tester.tap(find.text('apply'));
      await tester.pumpAndSettle();
      return result;
    }

    Finder button(String label) => find.bySemanticsLabel(label);

    testWidgets('1 katta bilan faqat 1 chaqaloq qo\'shiladi', (tester) async {
      final r = await pumpAndApply(tester, {}, () async {
        for (int i = 0; i < 3; i++) {
          await tester.tap(button('a11y_increase: under_2'));
          await tester.pump();
        }
      });
      expect(r?['inf'], 1);
      expect(r?['adt'], 1);
    });

    testWidgets('kattalar kamaytirilsa chaqaloqlar ham kamayadi',
        (tester) async {
      final r = await pumpAndApply(
          tester, {'adt': 2, 'chd': 0, 'inf': 2, 'klass': 'a'}, () async {
        await tester.tap(button('a11y_decrease: above_12'));
        await tester.pump();
      });
      expect(r?['adt'], 1);
      expect(r?['inf'], 1);
    });

    testWidgets('noto\'g\'ri boshlang\'ich params to\'g\'rilanadi',
        (tester) async {
      final r = await pumpAndApply(
          tester, {'adt': 1, 'chd': 0, 'inf': 3, 'klass': 'a'}, () async {});
      expect(r?['inf'], 1);
    });
  });
}
