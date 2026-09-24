import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/src/cubit/tickets/flight_results_utils.dart';
import 'package:mysafar_sdk/src/model/local/recom_req_model.dart';
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart';

/// R guruhi: reys bo'yicha xavfsiz parse (№77), AI sana (№78), faqat
/// USD/RUB narxli reyslar saralashi (№82), "Yangi reyslar" (№86).
void main() {
  late Map<String, dynamic> flightJson;

  setUpAll(() {
    final body = jsonDecode(
      File('test/fixtures/flight_info_response.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    flightJson = body['data']['flight'] as Map<String, dynamic>;
  });

  /// Real fixture'dan chuqur nusxa.
  Map<String, dynamic> cloneFlight(String id) {
    final copy =
        jsonDecode(jsonEncode(flightJson)) as Map<String, dynamic>;
    copy['id'] = id;
    return copy;
  }

  group('№77 reys bo\'yicha xavfsiz parse', () {
    test('int maydonlarda "" / satr — reys yo\'qolmaydi', () {
      final json = cloneFlight('A')
        ..['duration'] = ''
        ..['segments_count'] = '2';
      final seg = (json['segments'] as List).first as Map<String, dynamic>;
      seg['direction'] = '';
      seg['route_duration'] = '810';
      final f = FlightElement.fromJson(json);
      expect(f.duration, isNull);
      expect(f.segmentsCount, 2);
      expect(f.segments!.first.direction, 0);
      expect(f.segments!.first.routeDuration, 810);
    });

    test('Baggage/RefundBlock/Provider null — qulamaydi', () {
      final json = cloneFlight('B')..['provider'] = null;
      for (final s in (json['segments'] as List).cast<Map<String, dynamic>>()) {
        s['baggage'] = null;
        s['cbaggage'] = null;
        s['provider'] = null;
        s['refundBlock'] = null;
        s['exchangeBlock'] = null;
      }
      final f = FlightElement.fromJson(json);
      expect(f.segments!.first.baggage.weight, 0);
      expect(f.segments!.first.refundBlock, isNull);
      expect(f.segments!.first.provider.name, '');
      expect(f.provider?.name, '');
    });

    test('bitta buzuq reys — faqat o\'sha tashlanadi, qolganlari qoladi', () {
      final broken = cloneFlight('BROKEN')
        ..['price'] = {
          'UZS': {'amount': '1', 'passengers_amounts_details': 5},
        };
      final body = {
        'success': true,
        'data': {
          // inclusion_carriers null, segments_comments bor, predefined yo'q.
          'search': {
            'inclusion_carriers': null,
            'exclusion_carriers': null,
            'adt': '1',
            'chd': null,
            'segments': null,
          },
          'segments_comments': {'x': 'y'},
          'predefined_airlines': null,
          'flights': [
            cloneFlight('OK1'),
            broken,
            'not a map',
            cloneFlight('OK2')..['duration'] = '',
          ],
        },
      };
      final model = GetRecommendationResModel.fromJson(body);
      final ids = model.recommedations!.flights.map((f) => f.id).toList();
      expect(ids, ['OK1', 'OK2']);
      expect(model.recommedations!.predefinedAirlines, isEmpty);
      expect(model.recommedations!.search.inclusionCarriers, isEmpty);
      expect(model.recommedations!.search.adt, 1);
    });
  });

  group('№78 AI/ovozli qidiruv sanasi', () {
    test('dd.MM.yyyy va ISO yyyy-MM-dd o\'qiladi', () {
      expect(RecommendationRequestBody.parseSegmentDate('30.09.2026'),
          DateTime(2026, 9, 30));
      expect(RecommendationRequestBody.parseSegmentDate('2026-09-30'),
          DateTime(2026, 9, 30));
      expect(RecommendationRequestBody.parseSegmentDate('30-09-2026'),
          DateTime(2026, 9, 30));
      expect(RecommendationRequestBody.parseSegmentDate('2026-09-30T10:00:00'),
          DateTime(2026, 9, 30));
    });

    test('bo\'sh / yaroqsiz sana — null (istisno yo\'q)', () {
      expect(RecommendationRequestBody.parseSegmentDate(''), isNull);
      expect(RecommendationRequestBody.parseSegmentDate(null), isNull);
      expect(RecommendationRequestBody.parseSegmentDate('31.02.2026'), isNull);
      expect(RecommendationRequestBody.parseSegmentDate('ertaga'), isNull);
    });

    test('fromJson: ISO sana dd.MM.yyyy ga keltiriladi', () {
      final body = RecommendationRequestBody.fromJson({
        'adt': 1,
        'chd': 0,
        'inf': 0,
        'segments': [
          {'from': 'TAS', 'to': 'IST', 'date': '2026-09-30'},
        ],
      });
      expect(body.segments!.first.date, '30.09.2026');
      expect(body.segments!.first.getDateTime, DateTime(2026, 9, 30));
      expect(body.hasValidDates, isTrue);
      expect(body.flight_Type, 0);
    });

    test('sanasiz javob — hasValidDates false, params qulamaydi', () {
      final body = RecommendationRequestBody.fromJson({
        'adt': '2',
        'chd': null,
        'inf': 0,
        'segments': [
          {'from': 'TAS', 'to': 'IST', 'date': ''},
        ],
      });
      expect(body.adt, 2);
      expect(body.chd, 0);
      expect(body.hasValidDates, isFalse);
      expect(body.segments!.first.getDateTime, isNull);
      expect(() => body.params, returnsNormally);
    });

    test('ko\'p segmentli qidiruv faqat haqiqiy borib-kelishda 1', () {
      RecommendationRequestBody make(List<List<String>> legs) =>
          RecommendationRequestBody.fromJson({
            'adt': 1,
            'chd': 0,
            'inf': 0,
            'segments': [
              for (final l in legs)
                {'from': l[0], 'to': l[1], 'date': '01.10.2026'},
            ],
          });
      expect(
          make([
            ['TAS', 'IST'],
            ['IST', 'TAS'],
          ]).flight_Type,
          1);
      expect(
          make([
            ['TAS', 'IST'],
            ['IST', 'DXB'],
          ]).flight_Type,
          2);
      expect(
          make([
            ['TAS', 'IST'],
            ['IST', 'DXB'],
            ['DXB', 'TAS'],
          ]).flight_Type,
          2);
    });
  });

  group('№82 faqat USD/RUB narxli reyslar', () {
    FlightElement priced(String id, {String? uzs, String? usd, String? rub}) {
      final f = FlightElement.fromJson(cloneFlight(id));
      f.price = FlightPrice(
        uzs: uzs == null ? FluffyUzs(amount: '0') : FluffyUzs(amount: uzs),
        usd: usd == null ? null : FluffyRub(amount: usd),
        rub: rub == null ? null : FluffyRub(amount: rub),
      );
      return f;
    }

    test('USD soni UZS bilan solishtirilmaydi — oxiriga', () {
      final usdOnly = priced('USD', usd: '250');
      final rubOnly = priced('RUB', rub: '19 870');
      final uzs = priced('UZS', uzs: '3 000 000');
      expect(usdOnly.hasUzsSortPrice, isFalse);
      expect(uzs.hasUzsSortPrice, isTrue);
      expect(usdOnly.sortPrice, greaterThan(uzs.sortPrice));
      expect(rubOnly.sortPrice, greaterThan(usdOnly.sortPrice));

      final sorted = FlightResultsUtils.stableSort(
          [rubOnly, usdOnly, uzs], (f) => f.sortPrice);
      expect(sorted.map((f) => f.id), ['UZS', 'USD', 'RUB']);
    });

    test('narx umuman yo\'q — hali ham infinity', () {
      expect(priced('X').sortPrice, double.infinity);
    });

    test('mergeDedupe: UZS narxli dublikat USD-lini almashtiradi', () {
      final a = priced('A', usd: '100');
      final b = priced('B', uzs: '2 000 000');
      final merged = FlightResultsUtils.mergeDedupe([a], [b]);
      expect(merged.map((f) => f.id), ['B']);
    });
  });

  group('№86 "Yangi reyslar" va barqaror karta', () {
    FlightElement f(String id, String uzs) {
      final e = FlightElement.fromJson(cloneFlight(id));
      e.price = FlightPrice(uzs: FluffyUzs(amount: uzs), usd: null, rub: null);
      return e;
    }

    test('faqat takror/arzonroq dublikat — yangi reys emas', () {
      final prev = [f('A', '2 000 000')];
      // B — A ning arzonroq dublikati (bir xil segmentlar).
      final merged = FlightResultsUtils.mergeDedupe(prev, [f('B', '1 900 000')]);
      expect(merged.map((e) => e.id), ['B']);
      expect(FlightResultsUtils.hasNewFlights(prev, merged), isFalse);
      expect(FlightResultsUtils.replacedIds(prev, merged), {'B': 'A'});
    });

    test('bir xil ro\'yxat (yangi obyekt) — yangi reys yo\'q', () {
      final prev = [f('A', '1')];
      expect(FlightResultsUtils.hasNewFlights(prev, [...prev]), isFalse);
    });

    test('haqiqiy yangi reys — true', () {
      final prev = [f('A', '1')];
      final other = cloneFlight('C');
      (other['segments'] as List).first['flight_number'] = '9999';
      final c = FlightElement.fromJson(other);
      expect(FlightResultsUtils.hasNewFlights(prev, [...prev, c]), isTrue);
    });
  });
}
