import 'package:flutter_test/flutter_test.dart';
import 'package:mrz_parser/mrz_parser.dart';
import 'package:mysafar_sdk/src/model/remote/profile/users_model.dart';

MRZResult _scanResult({
  String documentType = 'P',
  String nationalityCountryCode = 'UZB',
  String countryCode = 'UZB',
  Sex sex = Sex.male,
  String documentNumber = 'FA1234567',
  String surnames = 'KARIMOV',
  String givenNames = 'JASUR',
}) {
  return MRZResult(
    documentType: documentType,
    countryCode: countryCode,
    surnames: surnames,
    givenNames: givenNames,
    documentNumber: documentNumber,
    nationalityCountryCode: nationalityCountryCode,
    birthDate: DateTime(1990, 6, 15),
    sex: sex,
    expiryDate: DateTime(2030, 3, 20),
    personalNumber: '',
  );
}

void main() {
  group('UsersModel.fromScan — citizen map', () {
    final cases = <String, String>{
      'UZB': 'UZ',
      'TUR': 'TR',
      'KAZ': 'KZ',
      'UKR': 'UA',
      'CHN': 'CN',
    };

    for (final entry in cases.entries) {
      test('${entry.key} → ${entry.value}', () {
        final user = UsersModel.fromScan(
          _scanResult(nationalityCountryCode: entry.key),
        );
        expect(user.citizen, entry.value);
      });
    }
  });

  group('UsersModel.fromScan — docnum', () {
    test('< va begona belgilar tozalanadi', () {
      final user = UsersModel.fromScan(
        _scanResult(documentNumber: 'fa12<<345-67'),
      );
      expect(user.docnum, 'FA1234567');
    });
  });

  group('UsersModel.fromScan — gender', () {
    test('male → M', () {
      expect(
        UsersModel.fromScan(_scanResult(sex: Sex.male)).gender,
        'M',
      );
    });

    test('female → F', () {
      expect(
        UsersModel.fromScan(_scanResult(sex: Sex.female)).gender,
        'F',
      );
    });

    test('none → null', () {
      expect(
        UsersModel.fromScan(_scanResult(sex: Sex.none)).gender,
        isNull,
      );
    });
  });

  group('UsersModel.fromScan — ism va hujjat', () {
    test('middlename har doim bo‘sh', () {
      final user = UsersModel.fromScan(
        _scanResult(givenNames: 'JASUR AKBAR'),
      );
      expect(user.middlename, '');
      expect(user.firstname, 'JASUR AKBAR');
      expect(user.lastname, 'KARIMOV');
    });

    test('doctype P → P', () {
      expect(
        UsersModel.fromScan(_scanResult(documentType: 'P')).doctype,
        'P',
      );
    });

    test('doctype I → A', () {
      expect(
        UsersModel.fromScan(_scanResult(documentType: 'I')).doctype,
        'A',
      );
    });

    test('sanalar dd.MM.yyyy', () {
      final user = UsersModel.fromScan(_scanResult());
      expect(user.birthdate, '15.06.1990');
      expect(user.docexp, '20.03.2030');
    });
  });
}
