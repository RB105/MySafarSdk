import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/src/cubit/tickets/flight_results_utils.dart';
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightElement, FlightPrice, FluffyUzs;

/// Qidiruv natijalari: manbalar orasidagi takroriy reyslar, saralash narxi
/// keshi va qayta hisoblash keshi (№20, №34).
void main() {
  Map<String, dynamic> segment({
    String carrier = 'HY',
    String number = '601',
    String depTime = '08:00',
    String arrTime = '11:30',
    int baggageWeight = 23,
    String fareCode = 'YOW',
  }) =>
      {
        'carrier': {'id': 1, 'code': carrier, 'title': carrier},
        'flight_number': number,
        'dep': {
          'date': '24.07.2026',
          'time': depTime,
          'airport': {'id': 1, 'code': 'TAS', 'title': 'Tashkent'},
        },
        'arr': {
          'date': '24.07.2026',
          'time': arrTime,
          'airport': {'id': 2, 'code': 'IST', 'title': 'Istanbul'},
        },
        'direction': 0,
        'seats': 9,
        'route_duration': 0,
        'fare_code': fareCode,
        'class': {'type_id': 1, 'name': 'Econom', 'service': 'Y'},
        'baggage': {'piece': 1, 'weight': baggageWeight},
        'cbaggage': {'piece': 1, 'weight': 8},
        'provider': {
          'gds': 1,
          'name': 'p',
          'supplier': {'id': 1, 'code': 'X', 'title': 'X'},
        },
        'refundBlock': <String, dynamic>{},
        'exchangeBlock': <String, dynamic>{},
      };

  FlightElement flight(
    String id,
    String price, {
    Map<String, dynamic>? seg,
    bool baggage = true,
  }) =>
      FlightElement.fromJson({
        'id': id,
        'duration': 210,
        'segments_count': 1,
        'is_baggage': baggage,
        'price': {
          'UZS': {'amount': price},
        },
        'segments': [seg ?? segment()],
        'segments_direction': [
          [0],
        ],
      });

  group('FlightElement.sortPrice', () {
    test('formatlangan narx bir marta o\'qiladi', () {
      final f = flight('a', '2 751 009');
      expect(f.sortPrice, 2751009);
    });

    test('narx yo\'q yoki 0 — ro\'yxat oxiriga (infinity)', () {
      expect(flight('a', '0').sortPrice, double.infinity);
      final f = flight('b', '100')..price = null;
      expect(f.sortPrice, double.infinity);
    });

    test('price obyekti almashtirilsa qayta hisoblanadi', () {
      final f = flight('a', '1 000');
      expect(f.sortPrice, 1000);
      f.price =
          FlightPrice(rub: null, usd: null, uzs: FluffyUzs(amount: '500'));
      expect(f.sortPrice, 500);
    });
  });

  group('FlightResultsUtils.mergeDedupe', () {
    test(
        'turli manbadagi aynan bir xil taklif — arzoni qoladi, o\'rni saqlanadi',
        () {
      final base = [
        flight('a', '3 000 000'),
        flight('b', '1 000 000', seg: segment(number: '999')),
      ];
      final extra = [flight('c', '2 500 000')];
      final merged = FlightResultsUtils.mergeDedupe(base, extra);
      expect(merged.map((f) => f.id), ['c', 'b']);
    });

    test('qimmatroq takror tashlanadi', () {
      final merged = FlightResultsUtils.mergeDedupe(
        [flight('a', '2 000 000')],
        [flight('c', '2 100 000')],
      );
      expect(merged.map((f) => f.id), ['a']);
    });

    test('shartlari farq qilsa (bagaj, vaqt, reys, tarif) — birlashtirilmaydi',
        () {
      final merged = FlightResultsUtils.mergeDedupe(
        [flight('a', '2 000 000')],
        [
          flight('b', '1 000 000', baggage: false),
          flight('c', '1 000 000', seg: segment(baggageWeight: 0)),
          flight('d', '1 000 000', seg: segment(depTime: '09:00')),
          flight('e', '1 000 000', seg: segment(number: '602')),
          flight('f', '1 000 000', seg: segment(fareCode: 'YFLEX')),
        ],
      );
      expect(merged.map((f) => f.id), ['a', 'b', 'c', 'd', 'e', 'f']);
    });

    test(
        'id bo\'yicha takror avvalgidek tashlanadi; kirish ro\'yxati o\'zgarmaydi',
        () {
      final base = [flight('a', '2 000 000')];
      final merged = FlightResultsUtils.mergeDedupe(
          base, [flight('a', '1 000 000', seg: segment(number: '1'))]);
      expect(merged.map((f) => f.id), ['a']);
      expect(identical(merged, base), isFalse);
      expect(base.length, 1);
    });
  });

  group('FlightResultsUtils.stableSort', () {
    test('kalit bo\'yicha, tenglarda kirish tartibi saqlanadi', () {
      final list = [
        flight('a', '300'),
        flight('b', '100'),
        flight('c', '300'),
        flight('d', '200'),
      ];
      int calls = 0;
      final sorted = FlightResultsUtils.stableSort(list, (f) {
        calls++;
        return f.sortPrice;
      });
      expect(sorted.map((f) => f.id), ['b', 'd', 'a', 'c']);
      // Kalit har bir reys uchun faqat bir marta hisoblanadi.
      expect(calls, list.length);
    });
  });

  group('ListResultMemo', () {
    test('o\'sha ro\'yxat va variant — qayta hisoblamaydi', () {
      final memo = ListResultMemo<int>();
      final src = [1, 2, 3];
      int computed = 0;
      int run(List<int> s, Object? v) => memo.get(s, v, () {
            computed++;
            return s.length;
          });

      expect(run(src, 0), 3);
      expect(run(src, 0), 3);
      expect(computed, 1);

      // Variant (masalan saralash rejimi) o'zgardi.
      run(src, 1);
      expect(computed, 2);

      // Teng, lekin BOSHQA ro'yxat obyekti (yangi manba natijasi).
      run([1, 2, 3], 1);
      expect(computed, 3);
    });
  });
}
