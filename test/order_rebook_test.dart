import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/src/model/remote/profile/confirmed_ticket_models.dart';
import 'package:mysafar_sdk/src/view/profile/src/order_rebook.dart';

String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}.'
    '${d.month.toString().padLeft(2, '0')}.${d.year}';

Map<String, dynamic> _segment(String from, String to, String date,
        {int direction = 0}) =>
    {
      'direction': direction,
      'dep': {
        'date': date,
        'city': {'code': from, 'title': from},
        'airport': {'code': '${from}A'},
      },
      'arr': {
        'city': {'code': to, 'title': to},
      },
      'parameters_for_each_passenger': [
        {
          'flight_class': {'code': 'B'}
        }
      ],
    };

Book _book({
  required List<Map<String, dynamic>> segments,
  List<Map<String, dynamic>>? passengers,
}) =>
    Book.fromJson({
      'flight': {'segments': segments},
      'passengers': passengers ??
          [
            {
              'age': 'inf',
              'name': {'first': 'Ali', 'last': 'Valiyev'},
              'birthdate': '2025-03-01',
              'gender': 'M',
              'citizenship': 'uz',
              'document': {'num': 'XS1234567', 'expire': '2035-01-02'},
            },
            {
              'age': 'adt',
              'name': {'first': 'Anna', 'last': 'Ivanova'},
              'birthdate': '1990-03-12',
              'gender': 'F',
              'citizenship': 'RU',
              'email': 'a@b.uz',
              'phone': '+998 90 123-45-67',
              'document': {'num': 'AA1234567', 'expire': '2031-06-30'},
            },
          ],
    });

void main() {
  final soon = DateTime.now().add(const Duration(days: 10));
  final back = DateTime.now().add(const Duration(days: 17));

  test('round trip: one search segment per direction, class and counts', () {
    final book = _book(segments: [
      _segment('TAS', 'IST', _date(soon)),
      _segment('IST', 'LON', _date(soon)),
      _segment('LON', 'TAS', _date(back), direction: 1),
    ]);
    final req = OrderRebook.requestFor(book)!;
    expect(req.adt, 1);
    expect(req.inf, 1);
    expect(req.chd, 0);
    expect(req.klass, 'b');
    expect(req.segments!.length, 2);
    expect(req.segments![0].from!.cityIataCode, 'TAS');
    expect(req.segments![0].to!.cityIataCode, 'LON');
    expect(req.segments![0].date, _date(soon));
    expect(req.segments![1].from!.cityIataCode, 'LON');
    expect(req.segments![1].to!.cityIataCode, 'TAS');
    expect(req.flight_Type, 1);
  });

  test('passengers are ordered adults first and converted to form format', () {
    final list = OrderRebook.passengersFor(_book(segments: [
      _segment('TAS', 'IST', _date(soon)),
    ]));
    expect(list.map((p) => p.age), ['adt', 'inf']);
    final adult = list.first;
    expect(adult.firstname, 'ANNA');
    expect(adult.lastname, 'IVANOVA');
    expect(adult.birthdate, '12.03.1990');
    expect(adult.docexp, '30.06.2031');
    expect(adult.docnum, 'AA1234567');
    expect(adult.gender, 'F');
    expect(adult.citizen, 'RU');
    expect(adult.doctype, 'P');
    expect(list.last.citizen, 'UZ');
  });

  test('masked document number is left empty', () {
    final list = OrderRebook.passengersFor(_book(
      segments: [_segment('TAS', 'IST', _date(soon))],
      passengers: [
        {
          'age': 'adt',
          'document': {'num': 'AA***4567'},
        }
      ],
    ));
    expect(list.single.docnum, '');
  });

  test('no request without an adult or with an unreadable date', () {
    expect(
      OrderRebook.requestFor(_book(
        segments: [_segment('TAS', 'IST', _date(soon))],
        passengers: [
          {'age': 'chd'}
        ],
      )),
      isNull,
    );
    expect(
      OrderRebook.requestFor(_book(segments: [_segment('TAS', 'IST', '')])),
      isNull,
    );
  });
}
