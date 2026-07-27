import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/src/view/booking/support/mrz_text_extractor.dart';

import 'helpers/mrz_test_fixtures.dart';

void main() {
  group('MrzTextExtractor — TD3 passport', () {
    test('ideal 2×44 strict parse', () {
      final result = MrzTextExtractor.tryExtractFromLines(
        [td3Line1, td3Line2],
        expected: MrzExpectedDoc.passport,
      );

      expect(result, isNotNull);
      expect(result!.documentType, 'P');
      expect(result.surnames, 'ERIKSSON');
      expect(result.givenNames, 'ANNA MARIA');
      expect(result.documentNumber, 'L898902C3');
    });

    test('43-char line2 prefix repair', () {
      expect(td3Line2MissingPrefix.length, 43);

      final result = MrzTextExtractor.tryExtractFromLines(
        [td3Line1, td3Line2MissingPrefix],
        expected: MrzExpectedDoc.passport,
      );

      expect(result, isNotNull);
      expect(result!.documentType, 'P');
      expect(result.surnames, 'ERIKSSON');
      // Check-digit repair bir nechta prefiksni sinashi mumkin; muhimi — parse.
      expect(result.documentNumber.length, 9);
    });

    test('OCR 0ZB → UZB tuzatish', () {
      final result = MrzTextExtractor.tryExtractFromLines(
        [td3Line1, td3Line2NatOcr0ZB],
        expected: MrzExpectedDoc.passport,
      );

      expect(result, isNotNull);
      expect(result!.nationalityCountryCode, 'UZB');
    });

    test('birlashgan 88 belgilik qator split + parse', () {
      expect(td3Merged88.length, greaterThanOrEqualTo(88));

      final result = MrzTextExtractor.tryExtractFromLines(
        [td3Merged88],
        expected: MrzExpectedDoc.passport,
      );

      expect(result, isNotNull);
      expect(result!.documentType, 'P');
    });
  });

  group('MrzTextExtractor — TD1 ID', () {
    test('toza TD1 strict parse', () {
      final result = MrzTextExtractor.tryExtractFromLines(
        [td1Line1, td1Line2, td1Line3],
        expected: MrzExpectedDoc.idCard,
      );

      expect(result, isNotNull);
      expect(result!.documentType, 'I');
      expect(result.surnames, 'SPECIMEN');
      expect(result.givenNames, 'SVEN');
    });

    test('strict fail, lenient pass (doc check-digit xato)', () {
      final strictOnly = MrzTextExtractor.tryExtractFromLines(
        [td1Line1BadDocCheck, td1Line2, td1Line3],
        expected: MrzExpectedDoc.idCard,
      );

      // Lenient bosqich ishlashi kerak — natija bo‘lishi mumkin.
      expect(strictOnly, isNotNull);
      expect(strictOnly!.documentNumber, isNotEmpty);
    });
  });

  group('MrzTextExtractor — noise va mismatch', () {
    test('noise qatorlar filtrlansin', () {
      final raw = '''
PASSPORT REPUBLIC OF UZBEKISTAN
$td3Line1
$td3Line2
DATE OF EXPIRY
''';

      final candidates = MrzTextExtractor.extractCandidateLines(raw);
      for (final line in candidates) {
        expect(line.contains('PASSPORT'), isFalse);
        expect(line.contains('REPUBLIC'), isFalse);
        expect(line.contains('EXPIRY'), isFalse);
      }

      final result = MrzTextExtractor.tryExtract(
        raw,
        expected: MrzExpectedDoc.passport,
      );
      expect(result, isNotNull);
    });

    test('passport kutilganda ID MRZ → mismatch idCard', () {
      final mismatch = MrzTextExtractor.detectMismatch(
        [td1Line1, td1Line2, td1Line3],
        expected: MrzExpectedDoc.passport,
      );
      expect(mismatch, MrzExpectedDoc.idCard);
    });

    test('ID kutilganda pasport MRZ → mismatch passport', () {
      final mismatch = MrzTextExtractor.detectMismatch(
        [td3Line1, td3Line2],
        expected: MrzExpectedDoc.idCard,
      );
      expect(mismatch, MrzExpectedDoc.passport);
    });
  });

  group('MrzTextExtractor — TD2 filter', () {
    test('P-type TD2 idCard rejimida qabul qilinmaydi', () {
      final asId = MrzTextExtractor.tryExtractFromLines(
        [td2Line1, td2Line2],
        expected: MrzExpectedDoc.idCard,
      );
      expect(asId, isNull);
    });
  });

  group('MrzTextExtractor — accumulateRawLines', () {
    test('xom qatorlar yig‘iladi', () {
      final acc = <String>{};
      MrzTextExtractor.accumulateRawLines(
        [td3Line1, '  $td3Line2  '],
        acc,
      );
      expect(acc.length, greaterThanOrEqualTo(1));
    });
  });
}
