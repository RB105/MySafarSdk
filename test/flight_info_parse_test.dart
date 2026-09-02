import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightElement;

/// `/avia/get-flight-info` javobini `FlightElement` ga o'girish testi.
void main() {
  late Map<String, dynamic> body;

  setUpAll(() {
    body = jsonDecode(
      File('test/fixtures/flight_info_response.json').readAsStringSync(),
    ) as Map<String, dynamic>;
  });

  test('javob konverti kutilganidek', () {
    expect(body['success'], isTrue);
    expect(body['data']?['flight'], isA<Map<String, dynamic>>());
  });

  test('data.flight FlightElement ga xatosiz o\'giriladi', () {
    final flight =
        FlightElement.fromJson(body['data']['flight'] as Map<String, dynamic>);

    expect(flight.id, isNotEmpty);
    expect(flight.id, contains('TAS'));

    expect(flight.price, isNotNull);
    expect(flight.duration, 810);
    expect(flight.segmentsCount, 2);
    expect(flight.segments, isNotNull);
    expect(flight.segments!.length, 2);
    expect(flight.provider?.name, 'VTRIP');
  });

  test('qolgan joy soni o\'qiladi', () {
    final flight =
        FlightElement.fromJson(body['data']['flight'] as Map<String, dynamic>);
    expect(flight.getSeatCount(), 1);
  });
}
