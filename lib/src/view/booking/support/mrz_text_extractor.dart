import 'package:mrz_parser/mrz_parser.dart';

/// Skanerda tanlangan hujjat turi.
enum MrzExpectedDoc { passport, idCard }

/// OCR matndan MRZ qatorlarini ajratib [MRZParser] orqali parse qiladi.
class MrzTextExtractor {
  MrzTextExtractor._();

  static final RegExp _mrzChar = RegExp(r'^[A-Z0-9<]+$');

  /// Pasport yuzasidagi oddiy matn (MRZ emas).
  static final RegExp _noise = RegExp(
    r'PASSPORT|PASPORT|RESPUBLIK|REPUBLIC|DATEOF|EXPIRY|AUTHOR|COUNTRY|'
    r'NATION|SURNAME|HOLDER|SIGNAT|TYPE|REGION|BERILGAN|MUDDAT|AMAL',
  );

  /// OCR natijasidan [MRZResult] olishga urinadi; topilmasa `null`.
  ///
  /// [expected]: qat'iy filter —
  /// passport → faqat TD3; idCard → faqat TD1/TD2.
  static MRZResult? tryExtract(
    String rawText, {
    required MrzExpectedDoc expected,
  }) {
    return tryExtractFromLines(
      extractCandidateLines(rawText),
      expected: expected,
    );
  }

  /// Bir necha kadr yig'ilgan qatorlardan MRZ parse qilish.
  static MRZResult? tryExtractFromLines(
    List<String> lines, {
    required MrzExpectedDoc expected,
  }) {
    final cleaned = _prepareLines(lines);
    if (cleaned.isEmpty) return null;

    if (expected == MrzExpectedDoc.passport) {
      final td3 = _tryTd3Pairs(cleaned);
      if (td3 != null && _isPassportResult(td3)) return td3;
      return null;
    }

    // ID: TD1 (3×30), keyin TD2 (2×36). TD3 qabul qilinmaydi.
    final td1 = _tryAllChunks(cleaned, 3, allowTd3: false, allowTd2: false);
    if (td1 != null && _isIdResult(td1)) return td1;

    final td2 = _tryAllChunks(cleaned, 2, allowTd3: false, allowTd2: true);
    if (td2 != null && _isIdResult(td2)) return td2;

    return null;
  }

  /// Tanlangan turga mos kelmaydigan, lekin boshqa formatdagi MRZ topilsa
  /// shu "boshqa" turni qaytaradi (xato xabar uchun).
  static MrzExpectedDoc? detectMismatch(
    List<String> lines, {
    required MrzExpectedDoc expected,
  }) {
    final cleaned = _prepareLines(lines);
    if (cleaned.isEmpty) return null;

    if (expected == MrzExpectedDoc.passport) {
      final td1 = _tryAllChunks(cleaned, 3, allowTd3: false, allowTd2: false);
      if (td1 != null && _isIdResult(td1)) return MrzExpectedDoc.idCard;
      final td2 = _tryAllChunks(cleaned, 2, allowTd3: false, allowTd2: true);
      if (td2 != null && _isIdResult(td2)) return MrzExpectedDoc.idCard;
      return null;
    }

    final td3 = _tryTd3Pairs(cleaned);
    if (td3 != null && _isPassportResult(td3)) return MrzExpectedDoc.passport;
    return null;
  }

  static List<String> _prepareLines(List<String> lines) {
    final cleaned = lines
        .map(_cleanLine)
        .where((l) => l.length >= 26)
        .where((l) => !_noise.hasMatch(l))
        .toList();
    if (cleaned.isEmpty) return const [];
    return _expandMergedLines(cleaned);
  }

  static bool _isPassportResult(MRZResult r) =>
      r.documentType.toUpperCase().startsWith('P');

  static bool _isIdResult(MRZResult r) {
    final t = r.documentType.toUpperCase();
    return t.startsWith('I') ||
        t.startsWith('A') ||
        t.startsWith('C') ||
        !t.startsWith('P');
  }

  /// OCR matnidan MRZ bo'lishi mumkin bo'lgan qatorlarni ajratadi.
  static List<String> extractCandidateLines(String rawText) {
    final result = <String>[];
    for (final line in rawText.split(RegExp(r'[\r\n]+'))) {
      final cleaned = _cleanLine(line);
      if (cleaned.length < 26) continue;
      if (!_mrzChar.hasMatch(cleaned)) continue;
      if (_noise.hasMatch(cleaned)) continue;
      if (!cleaned.contains('<') && !RegExp(r'^[PIACVFA]').hasMatch(cleaned)) {
        continue;
      }
      result.add(cleaned);
    }
    return result;
  }

  static String _cleanLine(String line) {
    return line
        .toUpperCase()
        .replaceAll(' ', '')
        .replaceAll(RegExp(r'[^A-Z0-9<]'), '');
  }

  static List<String> _expandMergedLines(List<String> lines) {
    final result = <String>[...lines];

    for (final line in lines) {
      if (line.length >= 80 && line.length <= 92) {
        final end = line.length < 88 ? line.length : 88;
        result.add(line.substring(0, 44));
        result.add(line.substring(44, end));
      }
      if (line.length >= 84 && line.length <= 96) {
        final end = line.length < 90 ? line.length : 90;
        result.add(line.substring(0, 30));
        result.add(line.substring(30, 60));
        result.add(line.substring(60, end));
      }
      if (line.length >= 64 && line.length <= 76) {
        final end = line.length < 72 ? line.length : 72;
        result.add(line.substring(0, 36));
        result.add(line.substring(36, end));
      }
    }

    return result.toSet().toList();
  }

  /// TD3: 1-qator `P<...`, 2-qator hujjat raqami bilan boshlanadi (P< emas).
  static MRZResult? _tryTd3Pairs(List<String> lines) {
    final line1s = lines
        .where(_isTd3Line1)
        .toList()
      ..sort((a, b) => _scoreTd3Line1(b).compareTo(_scoreTd3Line1(a)));

    final line2s = lines
        .where(_isTd3Line2)
        .toList()
      ..sort((a, b) => _scoreTd3Line2(b).compareTo(_scoreTd3Line2(a)));

    // ignore: avoid_print
    print(
      '[MRZ] TD3 candidates: line1=${line1s.length} '
      'line2=${line2s.length}',
    );
    for (final l in line1s.take(3)) {
      // ignore: avoid_print
      print('[MRZ]   L1(${l.length}): $l');
    }
    for (final l in line2s.take(3)) {
      // ignore: avoid_print
      print('[MRZ]   L2(${l.length}): $l');
    }

    // Avval to'liq 44 belgilik L2, keyin qisqaroqlari (check-digit repair).
    final fullL2 = line2s.where((l) => l.length == 44).toList();
    final shortL2 = line2s.where((l) => l.length != 44).toList();

    for (final l1 in line1s.take(5)) {
      for (final l2 in [...fullL2, ...shortL2].take(10)) {
        final result = _tryParseTd3(l1, l2);
        if (result != null) return result;
      }
    }
    return null;
  }

  static bool _isTd3Line1(String line) {
    if (!line.startsWith('P<') && !line.startsWith('P')) return false;
    if (line.length < 36 || line.length > 48) return false;
    // Ism qatorida ko'p '<' bo'ladi.
    final fillers = '<'.allMatches(line).length;
    return fillers >= 4;
  }

  static bool _isTd3Line2(String line) {
    if (line.startsWith('P<')) return false;
    if (line.length < 36 || line.length > 48) return false;
    // Hujjat raqami + check + nationality (masalan FA61584191UZB...)
    if (!RegExp(r'^[A-Z0-9]{8,10}').hasMatch(line)) return false;
    // Sana qismi: YYMMDD raqamlari.
    if (!RegExp(r'\d{6}').hasMatch(line)) return false;
    // Jins.
    if (!RegExp(r'[MF<]').hasMatch(line.substring(0, line.length.clamp(0, 28)))) {
      return false;
    }
    return true;
  }

  static int _scoreTd3Line1(String line) {
    var score = 0;
    if (line.startsWith('P<')) score += 20;
    if (line.length == 44) score += 30;
    score += 20 - (line.length - 44).abs().clamp(0, 20);
    score += '<'.allMatches(line).length;
    return score;
  }

  static int _scoreTd3Line2(String line) {
    var score = 0;
    // 1-usul: to'liq 44 belgi eng yuqori prioritet.
    if (line.length == 44) {
      score += 100;
    } else {
      score += 40 - (line.length - 44).abs().clamp(0, 40);
    }
    if (RegExp(r'UZB|0ZB|U2B').hasMatch(line)) score += 15;
    if (RegExp(r'[MF]').hasMatch(line)) score += 5;
    if (RegExp(r'^[A-Z]{1,2}\d').hasMatch(line)) score += 10;
    return score;
  }

  static MRZResult? _tryParseTd3(String line1, String line2) {
    for (final l1 in _line1Variants(line1)) {
      for (final l2 in _line2Variants(line2)) {
        final result = MRZParser.tryParse([l1, l2]);
        if (result != null) {
          // ignore: avoid_print
          print('[MRZ] TD3 OK L1=$l1');
          // ignore: avoid_print
          print('[MRZ] TD3 OK L2=$l2');
          return result;
        }
      }
    }
    return null;
  }

  static Iterable<String> _line1Variants(String line) sync* {
    final base = _fitLine(_fixCommonOcrErrors(line), 44);
    if (base.length == 44) {
      yield base;
      yield _fixTd3Line1(base);
    }
  }

  /// 2-qator variantlari:
  /// 1) to'liq 44 belgi (eng yaxshi)
  /// 2) 43 belgi → check digit orqali boshidagi 1 belgini tiklash
  static Iterable<String> _line2Variants(String line) sync* {
    final fixed = _fixCommonOcrErrors(line)
        .replaceFirst('0ZB', 'UZB')
        .replaceFirst('U2B', 'UZB')
        .replaceFirst('UZ8', 'UZB');

    final seen = <String>{};
    void add(String s) {
      final f = _fitLine(s, 44);
      if (f.length == 44) seen.add(f);
    }

    // --- Usul 1: to'liq / deyarli to'liq qator ---
    if (fixed.length == 44) {
      add(fixed);
      add(_fixTd3Line2(fixed));
      yield* seen;
      return;
    }

    if (fixed.length == 45) {
      add(fixed.substring(1));
      add(fixed.substring(0, 44));
    }

    if (fixed.length >= 40 && fixed.length < 44) {
      add(fixed);
      add(_fixTd3Line2(fixed));
    }

    // --- Usul 2: check digit bilan bosh belgini tiklash ---
    // OCR birinchi belgini tashlaganda: 43 belgi qoladi.
    // doc[0..8] + check[9] → truncated: doc[1..8] + check.
    if (fixed.length == 43) {
      for (final repaired in _repairMissingDocPrefix(fixed)) {
        add(repaired);
      }
    }

    yield* seen;
  }

  /// TD3 2-qator: yetishmayotgan hujjat raqami prefiksini check digit bilan topadi.
  ///
  /// truncated (43): [doc1..doc8][check][rest...]
  /// to'liq (44):    [prefix][doc1..doc8][check][rest...]
  /// shart: checkDigit(prefix + doc1..doc8) == check
  static Iterable<String> _repairMissingDocPrefix(String truncated43) sync* {
    if (truncated43.length != 43) return;

    final docTail = truncated43.substring(0, 8);
    final checkChar = truncated43[8];
    final expectedCheck = int.tryParse(checkChar);
    if (expectedCheck == null) return;

    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    for (var i = 0; i < alphabet.length; i++) {
      final prefix = alphabet[i];
      final docNumber = '$prefix$docTail'; // 9 belgi
      if (_mrzCheckDigit(docNumber) == expectedCheck) {
        yield '$prefix$truncated43'; // 44 belgi
      }
    }
  }

  /// ICAO 9303 check digit (mrz_parser bilan bir xil formula).
  static int _mrzCheckDigit(String input) {
    const weights = [7, 3, 1];
    var sum = 0;
    for (var i = 0; i < input.length; i++) {
      final c = input.codeUnitAt(i);
      final value = (c >= 65 && c <= 90)
          ? c - 65 + 10
          : (c >= 48 && c <= 57)
              ? c - 48
              : 0;
      sum += value * weights[i % 3];
    }
    return sum % 10;
  }

  static MRZResult? _tryAllChunks(
    List<String> lines,
    int len, {
    required bool allowTd3,
    required bool allowTd2,
  }) {
    final targetLen = len == 3 ? 30 : (allowTd3 ? 44 : 36);
    final scored = [...lines]..sort((a, b) {
        final da = (a.length - targetLen).abs();
        final db = (b.length - targetLen).abs();
        return da.compareTo(db);
      });

    for (final source in [scored, lines]) {
      for (var i = 0; i <= source.length - len; i++) {
        final chunk = source.sublist(i, i + len);
        final result = _tryParseChunk(
          chunk,
          allowTd3: allowTd3,
          allowTd2: allowTd2,
        );
        if (result != null) return result;
      }
    }
    return null;
  }

  static MRZResult? _tryParseChunk(
    List<String> chunk, {
    required bool allowTd3,
    required bool allowTd2,
  }) {
    final attempts = <List<String>>[];

    if (chunk.length == 3) {
      if (chunk.every((l) => l.length >= 26 && l.length <= 34)) {
        attempts.add(chunk.map((l) => _fitLine(l, 30)).toList());
      }
    } else if (chunk.length == 2) {
      if (_isTd3Line1(chunk[0]) && _isTd3Line1(chunk[1])) {
        return null;
      }
      final near44 = chunk.every((l) => l.length >= 38 && l.length <= 48);
      final near36 = chunk.every((l) => l.length >= 32 && l.length <= 40);

      if (allowTd3 && near44) {
        attempts.add(chunk.map((l) => _fitLine(l, 44)).toList());
      }
      if (allowTd2 && near36) {
        attempts.add(chunk.map((l) => _fitLine(l, 36)).toList());
      }
    }

    for (final normalized in attempts) {
      for (final variant in _ocrVariants(normalized)) {
        final result = MRZParser.tryParse(variant);
        if (result != null) return result;
      }
    }
    return null;
  }

  static String _fitLine(String line, int length) {
    if (line.length == length) return line;
    if (line.length > length) return line.substring(0, length);
    final maxPad = length >= 44 ? 4 : 3;
    if (length - line.length > maxPad) return line;
    return line.padRight(length, '<');
  }

  static Iterable<List<String>> _ocrVariants(List<String> lines) sync* {
    yield lines;
    yield lines.map(_fixCommonOcrErrors).toList();
    if (lines.length == 2) {
      yield [
        _fixCommonOcrErrors(_fixTd3Line1(lines[0])),
        _fixCommonOcrErrors(_fixTd3Line2(lines[1])),
      ];
    }
  }

  static String _fixCommonOcrErrors(String line) {
    return line
        .replaceAll('«', '<')
        .replaceAll('‹', '<')
        .replaceAll('›', '<')
        .replaceAll('>', '<')
        .replaceAll('|', 'I')
        .replaceAll('!', 'I')
        .replaceFirstMapped(RegExp(r'^[0OQ]'), (_) => 'P');
  }

  static String _fixTd3Line1(String line) {
    final buffer = StringBuffer();
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      buffer.write(ch == '<' ? '<' : _letterify(ch));
    }
    return buffer.toString();
  }

  static String _fixTd3Line2(String line) {
    final buffer = StringBuffer();
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '<') {
        buffer.write('<');
        continue;
      }
      final isLetterField = (i >= 10 && i <= 12) || i == 20;
      final isDigitField = (i <= 8) ||
          i == 9 ||
          (i >= 13 && i <= 19) ||
          (i >= 21 && i <= 27) ||
          i == 42 ||
          i == 43;
      if (isLetterField) {
        buffer.write(_letterify(ch));
      } else if (isDigitField) {
        buffer.write(_digitify(ch));
      } else {
        buffer.write(ch);
      }
    }
    return buffer.toString();
  }

  static String _letterify(String ch) {
    return switch (ch) {
      '0' => 'O',
      '1' => 'I',
      '2' => 'Z',
      '5' => 'S',
      '6' => 'G',
      '8' => 'B',
      _ => ch,
    };
  }

  static String _digitify(String ch) {
    return switch (ch) {
      'O' || 'Q' || 'D' => '0',
      'I' || 'L' => '1',
      'Z' => '2',
      'S' => '5',
      'G' => '6',
      'B' => '8',
      _ => ch,
    };
  }

  /// Debug: nima uchun parse muvaffaqiyatsiz bo'lganini console ga yozadi.
  static void debugWhyFailed(
    List<String> lines, {
    required MrzExpectedDoc expected,
  }) {
    final cleaned = _prepareLines(lines);
    final mismatch = detectMismatch(lines, expected: expected);
    // ignore: avoid_print
    print(
      '[MRZ] FAIL expected=$expected mismatch=$mismatch '
      'lines=${cleaned.length}',
    );
    if (mismatch != null) {
      // ignore: avoid_print
      print('[MRZ] sabab: noto\'g\'ri hujjat turi — $mismatch topildi');
      return;
    }

    final line1s = cleaned.where(_isTd3Line1).toList();
    final line2s = cleaned.where(_isTd3Line2).toList();
    // ignore: avoid_print
    print('[MRZ] L1=${line1s.length} L2=${line2s.length}');
    if (expected == MrzExpectedDoc.passport &&
        (line1s.isEmpty || line2s.isEmpty)) {
      // ignore: avoid_print
      print('[MRZ] sabab: TD3 juft topilmadi');
    }
  }
}
