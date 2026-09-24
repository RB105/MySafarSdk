import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/core/enum/currency.dart';
import 'package:mysafar_sdk/src/cubit/booking/create/booking_gate.dart';
import 'package:mysafar_sdk/src/cubit/booking/create/booking_passenger_saver.dart';
import 'package:mysafar_sdk/src/cubit/booking/passenger/passenger_cubit.dart';
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart';
import 'package:mysafar_sdk/src/model/remote/profile/confirmed_ticket_models.dart';
import 'package:mysafar_sdk/src/service/passenger/passenger_storage_service.dart';
import 'package:mysafar_sdk/src/view/booking/widget/booking_flight_summary_card.dart';

/// X guruhi: №22 (bron oqimi yordamchilari), №36 (fondagi reys tekshiruvi
/// bo'yicha qaror), №23 (reys kartasi modeli).
void main() {
  late Map<String, dynamic> flightJson;

  setUpAll(() {
    final body = jsonDecode(
      File('test/fixtures/flight_info_response.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    flightJson = body['data']['flight'] as Map<String, dynamic>;
  });

  FlightElement flight({String? id, String? uzs, String? usd}) {
    final f = FlightElement.fromJson(
        jsonDecode(jsonEncode(flightJson)) as Map<String, dynamic>);
    if (id != null) f.id = id;
    f.price = FlightPrice(
      uzs: FluffyUzs(amount: uzs ?? '1 000 000'),
      usd: usd == null ? null : FluffyRub(amount: usd),
      rub: null,
    );
    return f;
  }

  group('FlightValidation (№36)', () {
    test('muvaffaqiyatli javob — tekshirilgan element', () async {
      final validated = flight(id: 'NEW');
      final v = FlightValidation.fromResponse(
          'OLD', Future.value(NetworkSuccessResponse(data: validated)));
      final r = await v.result;
      expect(r, isA<FlightValidationPassed>());
      expect((r as FlightValidationPassed).element.id, 'NEW');
    });

    test('xato javob — Failed (xabar va tur bilan)', () async {
      final v = FlightValidation.fromResponse(
        'OLD',
        Future.value(const NetworkErrorResponse(
            error: 'sold out', errorType: ErrorType.other)),
      );
      final r = await v.result;
      expect(r, isA<FlightValidationFailed>());
      expect((r as FlightValidationFailed).errorType, ErrorType.other);
    });

    test('istisno (exception) ham Failed ga aylanadi', () async {
      final v = FlightValidation.fromResponse(
          'OLD', Future<NetworkResponse>.error(StateError('boom')));
      expect(await v.result, isA<FlightValidationFailed>());
    });

    test('tarif tanlangan bo\'lsa muvaffaqiyatda tanlangan element qoladi',
        () async {
      final tariff = flight(id: 'TARIFF');
      final v = FlightValidation.fromResponse('OLD',
              Future.value(NetworkSuccessResponse(data: flight(id: 'NEW'))))
          .keeping(tariff);
      final r = await v.result as FlightValidationPassed;
      expect(identical(r.element, tariff), isTrue);
    });

    test('qayta urinish shu id bilan yangi so\'rov yuboradi', () async {
      final calls = <String>[];
      final v = FlightValidation.fromResponse(
        'OLD',
        Future.value(const NetworkErrorResponse(error: 'x')),
        fetch: (id) async {
          calls.add(id);
          return NetworkSuccessResponse(data: flight(id: 'NEW'));
        },
      );
      expect(v.canRetry, isTrue);
      expect(await v.result, isA<FlightValidationFailed>());
      final again = await v.retry().result;
      expect(calls, ['OLD']);
      expect(again, isA<FlightValidationPassed>());
    });

    test('fetch berilmasa qayta urinib bo\'lmaydi', () {
      final v = FlightValidation.fromResponse(
          'OLD', Future.value(const NetworkErrorResponse(error: 'x')));
      expect(v.canRetry, isFalse);
    });
  });

  group('BookingGate.decide (№36)', () {
    test('narx o\'zgarmagan — davom etiladi (yangi id bilan)', () {
      final d = BookingGate.decide(
        shown: flight(id: 'OLD', uzs: '1 000 000'),
        result: FlightValidationPassed(flight(id: 'NEW', uzs: '1000000')),
        currency: AppCurrency.uzs,
      );
      expect(d, isA<BookingGateProceed>());
      expect((d as BookingGateProceed).element.id, 'NEW');
    });

    test('narx o\'zgargan — eski → yangi, tasdiq kerak', () {
      final d = BookingGate.decide(
        shown: flight(uzs: '1 000 000'),
        result: FlightValidationPassed(flight(id: 'NEW', uzs: '1 250 000')),
        currency: AppCurrency.uzs,
      );
      expect(d, isA<BookingGatePriceChanged>());
      final c = d as BookingGatePriceChanged;
      expect(c.oldPrice, 1000000);
      expect(c.newPrice, 1250000);
      expect(c.currencyLabel, 'UZS');
      expect(c.element.id, 'NEW');
    });

    test('narx tushgani ham ko\'rsatiladi', () {
      final d = BookingGate.decide(
        shown: flight(uzs: '1 000 000'),
        result: FlightValidationPassed(flight(uzs: '900 000')),
        currency: AppCurrency.uzs,
      );
      expect(d, isA<BookingGatePriceChanged>());
    });

    test('USD tanlangan — USD da taqqoslanadi', () {
      final d = BookingGate.decide(
        shown: flight(uzs: '1 000 000', usd: '80'),
        result: FlightValidationPassed(flight(uzs: '1 000 000', usd: '85')),
        currency: AppCurrency.usd,
      );
      final c = d as BookingGatePriceChanged;
      expect(c.currencyLabel, 'USD');
      expect(c.newPrice, 85);
    });

    test('USD bir tomonda yo\'q — UZS da taqqoslanadi', () {
      final same = BookingGate.decide(
        shown: flight(uzs: '1 000 000', usd: '80'),
        result: FlightValidationPassed(flight(uzs: '1 000 000')),
        currency: AppCurrency.usd,
      );
      expect(same, isA<BookingGateProceed>());
    });

    test('tekshiruv xatosi — bron qilinmaydi', () {
      const failure = FlightValidationFailed(message: 'x');
      final d = BookingGate.decide(
        shown: flight(),
        result: failure,
        currency: AppCurrency.uzs,
      );
      expect(d, isA<BookingGateFailed>());
      expect(identical((d as BookingGateFailed).failure, failure), isTrue);
    });
  });

  group('BookingGate.bookedPriceIncrease (№22)', () {
    final shown = FlightPrice(
      uzs: FluffyUzs(amount: '1 000 000'),
      rub: FluffyRub(amount: '7000'),
      usd: null,
    );
    test('oshgan narx aniqlanadi', () {
      final r = BookingGate.bookedPriceIncrease(shown, '1 100 000', null);
      expect(r?.oldPrice, 1000000);
      expect(r?.newPrice, 1100000);
      expect(r?.currencyLabel, 'UZS');
    });
    test('RUB bron RUB narx bilan taqqoslanadi', () {
      expect(BookingGate.bookedPriceIncrease(shown, 7500, 643)?.currencyLabel,
          'RUB');
      expect(BookingGate.bookedPriceIncrease(shown, 6900, 643), isNull);
    });
    test('tushgan / teng / narxsiz — null', () {
      expect(BookingGate.bookedPriceIncrease(shown, '1 000 000', 860), isNull);
      expect(BookingGate.bookedPriceIncrease(null, '5', null), isNull);
      expect(BookingGate.bookedPriceIncrease(shown, null, null), isNull);
    });
  });

  test('BookingPassengerSaver.toApiDate', () {
    expect(BookingPassengerSaver.toApiDate('05.03.1990'), '1990-03-05');
    expect(BookingPassengerSaver.toApiDate(' 1990-03-05 '), '1990-03-05');
    expect(BookingPassengerSaver.toApiDate('5/3/1990'), isNull);
  });

  test('PassengerCubit.updateFlight tekshirilgan token va narxni oladi', () {
    final cubit = PassengerCubit(
      adultCount: 1,
      childCount: 0,
      infantCount: 0,
      trId: 'OLD',
      price: null,
      storageService: _FakeStorage(),
    );
    final validated = flight(id: 'NEW', uzs: '2 000 000');
    cubit.updateFlight(trId: validated.id, price: validated.price);
    expect(cubit.trId, 'NEW');
    expect(cubit.price?.uzs?.amount, '2 000 000');
    cubit.close();
  });

  group('BookingFlightSummary (№23)', () {
    test('reysdan — yo\'nalishlar va qoidalar', () {
      final f = flight();
      final s = BookingFlightSummary.fromFlight(f, passengerCount: 2);
      expect(s.passengerCount, 2);
      expect(s.legs, isNotEmpty);
      expect(s.legs.first.from, isNotEmpty);
      expect(s.legs.first.date, f.segments!.first.dep.date);
      expect(s.isRefundable, f.isRefund ?? false);
      expect(s.isExchangeable, f.isExchangeable());
      expect(s.baggage?.included, f.isBaggage != false);
      expect(s.cabinBaggage?.included, f.withCBaggage());
    });

    test('buyurtmadan — borish-qaytish, yo\'lovchilar, bagaj', () {
      ConfirmedTicketArr arr(String city, String date, String time) =>
          ConfirmedTicketArr(
            city: ConfirmedTicketCarrier(title: city),
            date: date,
            time: time,
          );
      final book = Book(
        flight: BookFlight(segments: [
          ConfirmedTicketSegment(
            dep: arr('Toshkent', '12.07.2026', '08:00:00'),
            arr: arr('Istanbul', '12.07.2026', '11:30:00'),
            direction: 0,
            baggage: CbaggageClass(piece: 1, weight: 23),
            cbaggage: CbaggageClass(piece: 1, weight: 8),
            isRefund: false,
            isChange: true,
          ),
          ConfirmedTicketSegment(
            dep: arr('Istanbul', '20.07.2026', '13:00'),
            arr: arr('Toshkent', '20.07.2026', '19:45'),
            direction: 1,
            baggage: CbaggageClass(piece: 1, weight: 20),
            cbaggage: CbaggageClass(piece: 1, weight: 0),
            isRefund: true,
            isChange: true,
          ),
        ]),
        passengers: [Passenger(), Passenger(), Passenger()],
      );

      final s = BookingFlightSummary.fromOrder(book);
      expect(s.legs, hasLength(2));
      expect(s.legs[0].from, 'Toshkent');
      expect(s.legs[0].to, 'Istanbul');
      expect(s.legs[0].depTime, '08:00:00');
      expect(s.legs[1].from, 'Istanbul');
      expect(s.legs[1].transfers, 0);
      expect(s.passengerCount, 3);
      expect(s.baggage?.included, isTrue);
      expect(s.baggage?.weight, 20);
      // Bir segmentda og'irlik yo'q — faqat bo'lak soni.
      expect(s.cabinBaggage?.included, isTrue);
      expect(s.cabinBaggage?.weight, 0);
      expect(s.isRefundable, isFalse);
      expect(s.isExchangeable, isTrue);
    });

    test('buyurtmada ma\'lumot yo\'q — bo\'sh / noma\'lum qoidalar', () {
      final s = BookingFlightSummary.fromOrder(null);
      expect(s.isEmpty, isTrue);
      expect(s.baggage, isNull);
      expect(s.isRefundable, isNull);
      expect(s.isExchangeable, isNull);
    });

    test('bagajsiz segment — "bagajsiz"', () {
      final s = BookingFlightSummary.fromOrder(Book(
        flight: BookFlight(segments: [
          ConfirmedTicketSegment(
            direction: 0,
            baggage: CbaggageClass(piece: 0, weight: 0),
          ),
        ]),
      ));
      expect(s.baggage?.included, isFalse);
    });
  });
}

/// Diskka yozmaydigan soxta saqlash xizmati (GetStorage test muhitida yo'q).
class _FakeStorage implements PassengerStorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
