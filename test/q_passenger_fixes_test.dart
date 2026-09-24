import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/src/core/widgets/ticket_tariffs_widget.dart';
import 'package:mysafar_sdk/src/model/local/passenger_model.dart';
import 'package:mysafar_sdk/src/model/local/passenger_rules.dart';
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart';
import 'package:mysafar_sdk/src/model/remote/avia/ticket_tariff_model.dart';
import 'package:mysafar_sdk/src/model/remote/profile/users_model.dart';
import 'package:mysafar_sdk/src/view/booking/widget/booking_form_fields.dart';

/// Q guruhi: №61, №67–№73 (yo'lovchi formasi va bron oldi qoidalari).
void main() {
  group('№73 ism ichidagi bo\'sh joy', () {
    test('bitta bo\'sh joy saqlanadi, ortiqchasi qisqaradi, chetlari kesiladi',
        () {
      expect(PassengerRules.normalizeName('anna maria'), 'ANNA MARIA');
      expect(PassengerRules.normalizeName('  anna    maria  '), 'ANNA MARIA');
      expect(PassengerRules.normalizeName('anna - maria'), 'ANNA-MARIA');
      expect(PassengerRules.normalizeName('ali 2 vali'), 'ALI VALI');
      expect(PassengerRules.isLatinName('ANNA MARIA'), isTrue);
      expect(PassengerRules.isLatinName('ANNA  MARIA'), isFalse);
      expect(
          PassengerRules.fieldError('firstname', 'ANNA MARIA', ageType: 'adt'),
          isNull);
    });

    test('formatter yozish paytida oxirgi bo\'sh joyni saqlaydi', () {
      const formatter = PassengerNameFormatter();
      final typed = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: 'anna ',
          selection: TextSelection.collapsed(offset: 5),
        ),
      );
      expect(typed.text, 'ANNA ');
      expect(typed.selection.baseOffset, 5);
      final doubled = formatter.formatEditUpdate(
        typed,
        const TextEditingValue(
          text: 'ANNA  ',
          selection: TextSelection.collapsed(offset: 6),
        ),
      );
      expect(doubled.text, 'ANNA ');
    });
  });

  group('№69 hujjat raqami', () {
    test('kirill o\'xshash harflar, №, -, /, bo\'sh joy', () {
      expect(PassengerRules.normalizeDocnum('АА1234567'), 'AA1234567');
      expect(PassengerRules.normalizeDocnum('aa 123-45/67'), 'AA1234567');
      expect(PassengerRules.normalizeDocnum('№ ac1234567'), 'AC1234567');
      expect(PassengerRules.normalizeDocnum('ХМ.123'), 'XM123');
    });

    test('kirill seriyali guvohnoma o\'zgarmaydi va rad etilmaydi', () {
      final value = PassengerRules.normalizeDocnum('v-лю 123456');
      expect(value, 'V-ЛЮ123456');
      // O'xshash harfli guvohnoma ham kirillda qoladi (lotinga o'girilmaydi).
      expect(PassengerRules.normalizeDocnum('II-АВ 123456'), 'II-АВ123456');
      expect(PassengerRules.fieldError('docnum', 'II-АВ123456', ageType: 'inf'),
          isNull);
      expect(PassengerRules.fieldError('docnum', value, ageType: 'chd'),
          isNull);
    });

    test('lotin/kirill bo\'lmagan harf aniq xato beradi', () {
      expect(PassengerRules.fieldError('docnum', 'AĞ1234567', ageType: 'adt'),
          'docnum_latin_only');
      expect(PassengerRules.fieldError('docnum', 'AA1234567', ageType: 'adt'),
          isNull);
    });

    test('formatter', () {
      const formatter = DocumentNumberFormatter();
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: 'аа 12',
          selection: TextSelection.collapsed(offset: 5),
        ),
      );
      // Yozish paytida faqat katta harf va bo'sh joysiz; o'girish saqlashda.
      expect(result.text, 'АА12');
      expect(result.selection.baseOffset, 4);
      expect(PassengerRules.normalizeDocnum(result.text), 'AA12');
    });

    test('invalidFields hujjat raqamini ham tekshiradi', () {
      const p = PassengerModel(docnum: 'AĞ123');
      expect(
        PassengerRules.invalidFields(p).map((e) => e.$1),
        contains('docnum'),
      );
    });
  });

  group('№68 / №70 saqlangan yo\'lovchi va skaner', () {
    test('copyFromUser ISO sanani dd.MM.yyyy ga o\'giradi', () {
      final user = UsersModel.fromJson({
        'firstname': 'anna maria',
        'lastname': 'ivanova',
        'birthdate': '1990-03-12',
        'docexp': '2031-01-02T00:00:00',
        'docnum': 'аа 1234567',
        'gender': 'F',
        'citizen': 'UZ',
        'doctype': 'P',
      });
      final p = const PassengerModel().copyFromUser(user);
      expect(p.birthdate, '12.03.1990');
      expect(p.docexp, '02.01.2031');
      expect(p.docnum, 'AA1234567');
      expect(p.firstname, 'ANNA MARIA');
      expect(PassengerRules.invalidFields(p, today: DateTime(2026, 9, 1)),
          isEmpty);
    });

    test('hujjat turi fuqarolikdan olinadi (qo\'lda kiritish qoidasi)', () {
      final uz = const PassengerModel()
          .copyFromUser(UsersModel.fromJson({'citizen': 'UZ', 'doctype': 'P'}));
      expect(uz.doctype, PassengerConstants.docTypeId);
      final ru = const PassengerModel(citizen: 'UZ')
          .copyFromUser(UsersModel.fromJson({'citizen': 'RU', 'doctype': 'A'}));
      expect(ru.doctype, PassengerConstants.docTypePassport);
      // Skaner ham xuddi shunday.
      final scanned = const PassengerModel()
          .mergeScan(UsersModel.fromJson({'citizen': 'UZ', 'doctype': 'P'}));
      expect(scanned.doctype, PassengerConstants.docTypeId);
      expect(scanned.doctype,
          const PassengerModel().copyWithCitizen('UZ').doctype);
    });

    test('toFormDate', () {
      expect(PassengerRules.toFormDate('1990-03-12'), '12.03.1990');
      expect(PassengerRules.toFormDate('12.03.1990'), '12.03.1990');
      expect(PassengerRules.toFormDate(null), '');
      expect(PassengerRules.toFormDate('garbage'), 'garbage');
    });
  });

  group('№71 18+ hamroh', () {
    final flight = DateTime(2026, 10, 10);
    PassengerModel p(String age, String birth) =>
        PassengerModel(age: age, birthdate: birth);

    test('15 yoshli "katta" chaqaloq bilan — xato (katta yo\'lovchi indeksi)',
        () {
      expect(
        PassengerRules.accompanyingAdultIssue(
          [p('adt', '01.01.2011'), p('inf', '01.01.2026')],
          firstFlight: flight,
        ),
        0,
      );
    });

    test('kamida bitta 18+ bo\'lsa yoki bola yo\'q bo\'lsa — xato yo\'q', () {
      expect(
        PassengerRules.accompanyingAdultIssue(
          [
            p('adt', '01.01.2011'),
            p('adt', '01.01.1990'),
            p('chd', '01.01.2020')
          ],
          firstFlight: flight,
        ),
        isNull,
      );
      expect(
        PassengerRules.accompanyingAdultIssue([p('adt', '01.01.2011')],
            firstFlight: flight),
        isNull,
      );
      // 18 ga uchish kuni to'ladi.
      expect(
        PassengerRules.accompanyingAdultIssue(
          [p('adt', '10.10.2008'), p('chd', '01.01.2020')],
          firstFlight: flight,
        ),
        isNull,
      );
    });
  });

  group('№72 pasport 6 oylik ogohlantirish', () {
    final end = DateTime(2026, 10, 20);
    test('6 oydan kam — ogohlantirish, ko\'p — yo\'q', () {
      expect(PassengerRules.passportExpiresSoon('20.12.2026', lastFlight: end),
          isTrue);
      expect(PassengerRules.passportExpiresSoon('19.04.2027', lastFlight: end),
          isTrue);
      expect(PassengerRules.passportExpiresSoon('20.04.2027', lastFlight: end),
          isFalse);
      // Safardan oldin tugaydigan — qat'iy xato, bu yerda emas.
      expect(PassengerRules.passportExpiresSoon('01.10.2026', lastFlight: end),
          isFalse);
      expect(PassengerRules.passportExpiresSoon('', lastFlight: end), isFalse);
    });
  });

  group('№67 tavsiya tanlanganda seriya harflari qoladi', () {
    testWidgets('hujjat raqami', (tester) async {
      final controller = TextEditingController();
      final focus = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      String? changed;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BookingTextField(
            label: 'Doc',
            controller: controller,
            focusNode: focus,
            onChanged: (v) => changed = v,
            showError: false,
            inputFormatters: const [DocumentNumberFormatter()],
            suggestions: const ['AA1234567'],
          ),
        ),
      ));
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'AA');
      await tester.pumpAndSettle();
      await tester.tap(find.text('AA1234567'));
      await tester.pumpAndSettle();
      expect(controller.text, 'AA1234567');
      expect(changed, 'AA1234567');
    });
  });

  group('№61 tarifni barqaror kalit bo\'yicha topish', () {
    late Map<String, dynamic> flightJson;
    setUpAll(() {
      final body = jsonDecode(
        File('test/fixtures/flight_info_response.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      flightJson = body['data']['flight'] as Map<String, dynamic>;
    });

    FlightElement flight(String id, {String fare = 'Y'}) {
      final f = FlightElement.fromJson(
          jsonDecode(jsonEncode(flightJson)) as Map<String, dynamic>);
      f.id = id;
      for (final s in f.segments!) {
        s.fareCode = fare;
      }
      return f;
    }

    test('id o\'zgargan (bron tokeni) — kalit bo\'yicha topiladi', () {
      final tariffs = [
        FlightTariffModel(flight: flight('T1', fare: 'LITE')),
        FlightTariffModel(flight: flight('T2', fare: 'FLEX')),
      ];
      final validated = flight('BOOKING_TOKEN', fare: 'FLEX');
      expect(
          TariffPickerWidget.indexOfCurrent(tariffs, validated.id, validated),
          1);
      expect(TariffPickerWidget.indexOfCurrent(tariffs, 'T1', validated), 0);
    });

    test('mos kelmasa — hech qaysi tarif belgilanmaydi (1-tarif emas)', () {
      final tariffs = [
        FlightTariffModel(flight: flight('T1', fare: 'LITE')),
        FlightTariffModel(flight: flight('T2', fare: 'FLEX')),
      ];
      final other = flight('X', fare: 'PROMO');
      expect(TariffPickerWidget.indexOfCurrent(tariffs, 'X', other), -1);
      // Noaniq (ikkita mos) — ham belgilanmaydi.
      final dup = [
        FlightTariffModel(flight: flight('T1', fare: 'FLEX')),
        FlightTariffModel(flight: flight('T2', fare: 'FLEX')),
      ];
      expect(
          TariffPickerWidget.indexOfCurrent(
              dup, 'TOKEN', flight('TOKEN', fare: 'FLEX')),
          -1);
    });
  });
}
