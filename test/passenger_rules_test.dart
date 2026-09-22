import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/src/model/local/passenger_model.dart';
import 'package:mysafar_sdk/src/model/local/passenger_rules.dart';

void main() {
  final today = DateTime(2026, 9, 22);
  final depart = DateTime(2026, 10, 10);
  final ret = DateTime(2026, 10, 20);

  String? check(String field, String value, {String age = 'adt'}) =>
      PassengerRules.fieldError(
        field,
        value,
        ageType: age,
        firstFlight: depart,
        lastFlight: ret,
        today: today,
      );

  group('normalizeName', () {
    test('kirill lotinga, apostrof va bo\'sh joy tashlanadi', () {
      expect(PassengerRules.normalizeName('Иванов'), 'IVANOV');
      expect(PassengerRules.normalizeName("O'rinboyev"), 'ORINBOYEV');
      expect(PassengerRules.normalizeName('Oʻrinboyev'), 'ORINBOYEV');
      expect(PassengerRules.normalizeName("ERGASH O'G'LI"), 'ERGASHOGLI');
      expect(PassengerRules.normalizeName('Ғулом'), 'GULOM');
      expect(PassengerRules.normalizeName('Анна-Мария'), 'ANNA-MARIIA');
      expect(PassengerRules.normalizeName('ali2'), 'ALI');
    });

    test('formatter kursorni to\'g\'ri joyga qo\'yadi', () {
      const formatter = PassengerNameFormatter();
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: "o'g",
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      expect(result.text, 'OG');
      expect(result.selection.baseOffset, 2);
    });
  });

  group('sana va yosh', () {
    test('noto\'g\'ri format va mavjud bo\'lmagan sana', () {
      expect(check('birthdate', '12.03.19'), 'invalid_date_format');
      expect(check('birthdate', '31.02.2000'), 'invalid_date_format');
    });

    test('kelajakdagi tug\'ilgan kun', () {
      expect(check('birthdate', '01.01.2030'), 'birthdate_in_future');
    });

    test('yosh toifasi uchish kuniga ko\'ra', () {
      expect(check('birthdate', '10.10.2014'), isNull, reason: '12 ga to\'ldi');
      expect(check('birthdate', '11.10.2014'), 'passenger_age_mismatch_adult');
      expect(check('birthdate', '01.01.2020', age: 'chd'), isNull);
      expect(check('birthdate', '01.01.2010', age: 'chd'),
          'passenger_age_mismatch_child');
      expect(check('birthdate', '01.01.2026', age: 'inf'), isNull);
      // Qaytish kuni 2 yoshga to'ladi — chaqaloq sifatida o'tmaydi.
      expect(check('birthdate', '15.10.2024', age: 'inf'),
          'passenger_age_mismatch_infant');
    });

    test('pasport safar tugaguncha amal qilishi kerak', () {
      expect(check('docexp', '19.10.2026'), 'passport_expires_before_trip');
      expect(check('docexp', '20.10.2026'), isNull);
      expect(check('docexp', '01.01.2030'), isNull);
    });

    test('bo\'sh qiymat qoida xatosi emas (u "to\'ldirilmagan")', () {
      expect(check('docexp', ''), isNull);
      expect(check('firstname', ''), isNull);
    });
  });

  test('invalidFields forma tartibida qaytaradi', () {
    const passenger = PassengerModel(
      lastname: 'IVANOV',
      firstname: 'IVAN',
      birthdate: '01.01.2020',
      docexp: '01.01.2026',
      age: 'adt',
    );
    final issues = PassengerRules.invalidFields(
      passenger,
      firstFlight: depart,
      lastFlight: ret,
      today: today,
    );
    expect(issues.map((e) => e.$1), ['birthdate', 'docexp']);
  });

  test('reys sanasi dd.MM.yyyy va ISO', () {
    expect(PassengerRules.parseFlightDate('24.06.2026'), DateTime(2026, 6, 24));
    expect(PassengerRules.parseFlightDate('2026-06-24T10:30:00'),
        DateTime(2026, 6, 24));
    expect(PassengerRules.parseFlightDate(''), isNull);
  });
}
