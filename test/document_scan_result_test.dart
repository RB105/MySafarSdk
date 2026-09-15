import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/src/model/local/passenger_model.dart';
import 'package:mysafar_sdk/src/service/passenger/document_scan_service.dart';

void main() {
  group('DocumentScanResult.fromJson', () {
    test('to\'liq javob — sanalar dd.MM.yyyy, maydonlar tozalangan', () {
      final result = DocumentScanResult.fromJson({
        'passenger': {
          'lastname': 'ISROILOV',
          'firstname': 'SUXROBJON',
          'middlename': "ERGASH O'G'LI",
          'birthdate': '2002-02-01',
          'docnum': 'AE4212442',
          'docexp': '2035-09-14',
          'gender': 'M',
          'citizen': 'UZ',
          'doctype': 'A',
        },
        'source': {'lastname': 'vision'},
        'warnings': [],
        'mrz_used': false,
      });

      final p = result.passenger;
      expect(result.isEmpty, isFalse);
      expect(result.missingFields, isEmpty);
      expect(p.lastname, 'ISROILOV');
      expect(p.firstname, 'SUXROBJON');
      expect(p.middlename, "ERGASH O'G'LI");
      expect(p.birthdate, '01.02.2002');
      expect(p.docexp, '14.09.2035');
      expect(p.docnum, 'AE4212442');
      expect(p.gender, 'M');
      expect(p.citizen, 'UZ');
      expect(p.doctype, 'A');
    });

    test('hech narsa tanilmagan — isEmpty, null maydonlar bo\'sh', () {
      final result = DocumentScanResult.fromJson({
        'passenger': {
          'lastname': '',
          'firstname': '',
          'middlename': '',
          'birthdate': null,
          'docnum': '',
          'docexp': null,
          'gender': null,
          'citizen': null,
          'doctype': 'A',
        },
        'warnings': [
          {
            'code': 'missing_fields',
            'fields': ['firstname', 'lastname', 'docnum'],
          }
        ],
        'mrz_used': false,
      });

      expect(result.isEmpty, isTrue);
      expect(result.missingFields, ['firstname', 'lastname', 'docnum']);
      expect(result.passenger.birthdate, '');
      expect(result.passenger.gender, isNull);
      expect(result.passenger.citizen, isNull);
    });

    test('alpha-3 fuqarolik ISO alpha-2 ga, kichik harflar kattaga', () {
      final result = DocumentScanResult.fromJson({
        'passenger': {
          'lastname': 'yilmaz',
          'docnum': 'u 1234567',
          'citizen': 'tur',
          'gender': 'f',
          'doctype': 'P',
        },
      });
      expect(result.passenger.citizen, 'TR');
      expect(result.passenger.gender, 'F');
      expect(result.passenger.lastname, 'YILMAZ');
      expect(result.passenger.docnum, 'U1234567');
      expect(result.passenger.doctype, 'P');
    });
  });

  group('DocumentScanResult.fromJson — fuqarolik alpha-3 → alpha-2', () {
    const cases = {
      'UZB': 'UZ',
      'TUR': 'TR',
      'KAZ': 'KZ',
      'UKR': 'UA',
      'CHN': 'CN',
      'RU': 'RU',
    };
    for (final entry in cases.entries) {
      test('${entry.key} → ${entry.value}', () {
        final result = DocumentScanResult.fromJson({
          'passenger': {'citizen': entry.key},
        });
        expect(result.passenger.citizen, entry.value);
      });
    }
  });

  group('PassengerModel.mergeScan', () {
    test('faqat tanilgan maydonlar yoziladi', () {
      const current = PassengerModel(
        firstname: 'ALI',
        lastname: 'VALIYEV',
        birthdate: '10.10.1990',
        docnum: 'AA0000000',
        gender: 'M',
        citizen: 'KZ',
      );
      final scan = DocumentScanResult.fromJson({
        'passenger': {
          'lastname': 'ISROILOV',
          'firstname': '',
          'birthdate': null,
          'docnum': 'AE4212442',
          'docexp': '2035-09-14',
          'gender': null,
          'citizen': 'UZ',
        },
      }).passenger;

      final merged = current.mergeScan(scan);
      expect(merged.lastname, 'ISROILOV');
      expect(merged.firstname, 'ALI');
      expect(merged.birthdate, '10.10.1990');
      expect(merged.docnum, 'AE4212442');
      expect(merged.docexp, '14.09.2035');
      expect(merged.gender, 'M');
      expect(merged.citizen, 'UZ');
    });
  });
}
