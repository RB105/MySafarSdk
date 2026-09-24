import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/mysafar_sdk.dart';
import 'package:mysafar_sdk/src/cubit/booking/passenger/passenger_cubit.dart';
import 'package:mysafar_sdk/src/cubit/booking/passenger/passenger_draft_store.dart';
import 'package:mysafar_sdk/src/model/local/passenger_model.dart';
import 'package:mysafar_sdk/src/model/local/passenger_rules.dart';
import 'package:mysafar_sdk/src/view/booking/widget/booking_form_fields.dart';

void main() {
  group('email format', () {
    test('valid', () {
      expect(PassengerCubit.isValidEmail('a@b.uz'), isTrue);
      expect(PassengerCubit.isValidEmail(' vali.aliyev+1@mail.co.uk '), isTrue);
      expect(PassengerCubit.isValidEmail('ivan@почта.рф'), isTrue);
    });
    test('invalid', () {
      for (final v in ['', 'a', 'a@', 'a@b', 'a@b.', '@b.uz', 'a b@c.uz']) {
        expect(PassengerCubit.isValidEmail(v), isFalse, reason: v);
      }
    });
  });

  group('birthdate picker start', () {
    final flight = DateTime(2026, 10, 15);
    final today = DateTime(2026, 9, 24);

    test('matches age category', () {
      for (final age in [
        PassengerConstants.ageAdult,
        PassengerConstants.ageChild,
        PassengerConstants.ageInfant,
      ]) {
        final d = PassengerRules.suggestedBirthdate(age,
            firstFlight: flight, today: today);
        final formatted = '${d.day.toString().padLeft(2, '0')}.'
            '${d.month.toString().padLeft(2, '0')}.${d.year}';
        expect(
          PassengerRules.fieldError('birthdate', formatted,
              ageType: age, firstFlight: flight, today: today),
          isNull,
          reason: '$age → $formatted',
        );
      }
    });

    test('never in the future', () {
      final d = PassengerRules.suggestedBirthdate(PassengerConstants.ageInfant,
          firstFlight: DateTime(2027, 12, 1), today: today);
      expect(d.isAfter(today), isFalse);
    });
  });

  test('saved passenger age filter accepts ISO and form dates', () {
    final flight = DateTime(2026, 10, 15);
    expect(
        PassengerRules.fitsAgeType('1990-03-12', PassengerConstants.ageAdult,
            firstFlight: flight),
        isTrue);
    expect(
        PassengerRules.fitsAgeType('12.03.1990', PassengerConstants.ageChild,
            firstFlight: flight),
        isFalse);
    expect(
        PassengerRules.fitsAgeType('01.01.2020', PassengerConstants.ageChild,
            firstFlight: flight),
        isTrue);
    expect(
        PassengerRules.fitsAgeType('', PassengerConstants.ageInfant,
            firstFlight: flight),
        isTrue);
  });

  group('prefill from host user data', () {
    final data = MySafarUserData(
      firstName: ' vali ',
      lastName: 'aliyev',
      birthDate: DateTime(1990, 3, 5),
      gender: MySafarGender.female,
      citizenship: 'kz',
      documentNumber: 'aa 1234567',
      documentExpiry: DateTime(2031, 1, 2),
    ).sanitized();

    test('fills empty fields, citizenship replaces default', () {
      final base = const PassengerModel(gender: '')
          .copyWithCitizen(PassengerCubit.defaultCitizen);
      final p = PassengerCubit.prefillFromUserData(base, data);
      expect(p.firstname, 'VALI');
      expect(p.lastname, 'ALIYEV');
      expect(p.birthdate, '05.03.1990');
      expect(p.gender, PassengerConstants.genderFemale);
      expect(p.citizen, 'KZ');
      expect(p.docnum, 'AA1234567');
      expect(p.docexp, '02.01.2031');
    });

    test('does not overwrite entered values', () {
      const base = PassengerModel(firstname: 'ALI', gender: 'M', citizen: 'RU');
      final p = PassengerCubit.prefillFromUserData(base, data);
      expect(p.firstname, 'ALI');
      expect(p.gender, 'M');
      expect(p.citizen, 'RU');
    });

    test('empty user data changes nothing', () {
      const base = PassengerModel(gender: '');
      final p =
          PassengerCubit.prefillFromUserData(base, const MySafarUserData());
      expect(p.toJson(), base.toJson());
    });
  });

  test('user data sanitizes and masks passenger fields', () {
    final data = const MySafarUserData(
      firstName: '  ',
      lastName: 'aliyev',
      citizenship: 'Uzbekistan',
      documentNumber: 'aa 123',
    ).sanitized();
    expect(data.firstName, isNull);
    expect(data.lastName, 'ALIYEV');
    expect(data.citizenship, isNull);
    expect(data.documentNumber, 'AA123');
    expect(data.hasPassengerData, isTrue);
    expect(data.toString(), isNot(contains('ALIYEV')));
    expect(data.toString(), isNot(contains('AA123')));
  });

  test('draft store keeps one composition and clears', () {
    final key = PassengerDraftStore.keyFor(1, 0, 0);
    PassengerDraftStore.write(
      key,
      const PassengerDraft(
        passengers: [PassengerModel(firstname: 'VALI')],
        email: 'a@b.uz',
        phone: '998901234567',
        saveToProfile: {0},
      ),
    );
    expect(PassengerDraftStore.read(key)?.passengers.first.firstname, 'VALI');
    PassengerDraftStore.write(
      PassengerDraftStore.keyFor(2, 0, 0),
      const PassengerDraft(
          passengers: [], email: '', phone: '', saveToProfile: {}),
    );
    expect(PassengerDraftStore.read(key), isNull);
    MySafarSdk.clearUserData();
    expect(PassengerDraftStore.read(PassengerDraftStore.keyFor(2, 0, 0)),
        isNull);
  });

  // Katta tizim shriftida maydonlar kesilmasligi (№32).
  testWidgets('fields grow with large text scale', (tester) async {
    final controller = TextEditingController(text: 'ALIYEV');
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Scaffold(
          body: Column(children: [
            BookingTextField(
              label: 'Familiya',
              controller: controller,
              focusNode: focus,
              onChanged: (_) {},
              showError: false,
            ),
            BookingChoiceField<String>(
              label: 'Jinsi',
              value: '',
              options: const [('M', 'Erkak'), ('F', 'Ayol')],
              onChanged: (_) {},
              errorText: 'Jins tanlanmadi',
            ),
          ]),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.text('Jins tanlanmadi'), findsOneWidget);
    expect(tester.getSize(find.byType(TextField)).height,
        greaterThan(BookingFormStyle.fieldHeight - 30));
  });

  test('bron yaratilgach eski cubit qoralamani qayta yozmaydi', () {
    PassengerDraftStore.clear();
    final key = PassengerDraftStore.keyFor(1, 0, 0);
    const draft = PassengerDraft(
      passengers: [],
      email: 'a@b.uz',
      phone: '',
      saveToProfile: {},
    );
    final oldGeneration = PassengerDraftStore.generation;
    PassengerDraftStore.write(key, draft, generation: oldGeneration);
    expect(PassengerDraftStore.read(key), isNotNull);

    PassengerDraftStore.markBooked();
    expect(PassengerDraftStore.read(key), isNull);

    PassengerDraftStore.write(key, draft, generation: oldGeneration);
    expect(PassengerDraftStore.read(key), isNull);

    PassengerDraftStore.write(key, draft,
        generation: PassengerDraftStore.generation);
    expect(PassengerDraftStore.read(key), isNotNull);
    PassengerDraftStore.clear();
  });
}
