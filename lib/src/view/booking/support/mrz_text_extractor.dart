import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:mrz_parser/mrz_parser.dart';

/// Skanerda tanlangan hujjat turi.
enum MrzExpectedDoc { passport, idCard }

/// OCR matndan MRZ qatorlarini ajratib [MRZParser] orqali parse qiladi.
///
/// 1-bosqich (strict): check-digitli [MRZParser] + TD3 OCR repair.
/// 2-bosqich (lenient): check-digitsiz maydon tiklash + scoring
/// (mobile-home [MrzLineExtractor] yondashuvi, [MrzExpectedDoc] filter bilan).
class MrzTextExtractor {
  MrzTextExtractor._();

  static const _td3Len = 44;
  static const _td2Len = 36;
  static const _td1Len = 30;
  static const _maxLenientLines = 20;

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
    // Xom qatorlar — ism qatorida bo'shliq → '<' (lenient) uchun kerak.
    return tryExtractFromLines(
      rawText.split(RegExp(r'[\r\n]+')),
      expected: expected,
    );
  }

  /// Bir necha kadr yig'ilgan qatorlardan MRZ parse qilish.
  static MRZResult? tryExtractFromLines(
    List<String> lines, {
    required MrzExpectedDoc expected,
  }) {
    final cleaned = _prepareLines(lines);

    // 1-bosqich: strict — TD3/TD1/TD2 + OCR repair.
    if (cleaned.isNotEmpty) {
      if (expected == MrzExpectedDoc.passport) {
        final td3 = _tryTd3Pairs(cleaned);
        if (td3 != null && _isPassportResult(td3)) return td3;
      } else {
        final td1 = _tryAllChunks(cleaned, 3, allowTd3: false, allowTd2: false);
        if (td1 != null && _isIdResult(td1)) return td1;

        final td2 = _tryAllChunks(cleaned, 2, allowTd3: false, allowTd2: true);
        if (td2 != null && _isIdResult(td2)) return td2;
      }
    }

    // 2-bosqich: lenient — check-digit ishlamasa ham maydonlarni tiklash.
    return _tryLenient(lines, expected: expected);
  }

  /// Tanlangan turga mos kelmaydigan, lekin boshqa formatdagi MRZ topilsa
  /// shu "boshqa" turni qaytaradi (xato xabar uchun).
  static MrzExpectedDoc? detectMismatch(
    List<String> lines, {
    required MrzExpectedDoc expected,
  }) {
    final cleaned = _prepareLines(lines);

    if (expected == MrzExpectedDoc.passport) {
      if (cleaned.isNotEmpty) {
        final td1 = _tryAllChunks(cleaned, 3, allowTd3: false, allowTd2: false);
        if (td1 != null && _isIdResult(td1)) return MrzExpectedDoc.idCard;
        final td2 = _tryAllChunks(cleaned, 2, allowTd3: false, allowTd2: true);
        if (td2 != null && _isIdResult(td2)) return MrzExpectedDoc.idCard;
      }
      if (_tryLenient(lines, expected: MrzExpectedDoc.idCard) != null) {
        return MrzExpectedDoc.idCard;
      }
      return null;
    }

    if (cleaned.isNotEmpty) {
      final td3 = _tryTd3Pairs(cleaned);
      if (td3 != null && _isPassportResult(td3)) {
        return MrzExpectedDoc.passport;
      }
    }
    if (_tryLenient(lines, expected: MrzExpectedDoc.passport) != null) {
      return MrzExpectedDoc.passport;
    }
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

  /// Block/line OCR dan yig'ish — bo'shliqni saqlaydi (lenient ism qatori uchun).
  static void accumulateRawLines(
    Iterable<String> rawLines,
    Set<String> into, {
    int max = 24,
  }) {
    for (final raw in rawLines) {
      final compact = _cleanForLenient(raw, spacesToFiller: false);
      if (compact.length < 12) continue;
      if (_noise.hasMatch(compact)) continue;
      into.remove(raw);
      into.add(raw);
    }
    while (into.length > max) {
      into.remove(into.first);
    }
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

  // ---------------------------------------------------------------------------
  // Lenient (mobile-home)
  // ---------------------------------------------------------------------------

  static MRZResult? _tryLenient(
    List<String> rawLines, {
    required MrzExpectedDoc expected,
  }) {
    final lines = <_MrzLine>[];
    for (final raw in rawLines) {
      final compact = _cleanForLenient(raw, spacesToFiller: false);
      if (compact.length < 12) continue;
      if (_noise.hasMatch(compact)) continue;
      lines.add(_MrzLine(
        compact: compact,
        spaced: _cleanForLenient(raw, spacesToFiller: true),
      ));
      if (lines.length >= _maxLenientLines) break;
    }
    if (lines.isEmpty) return null;

    final scorer = _BestResult();
    _searchLenient(lines, scorer, expected: expected);
    final best = scorer.best;
    if (best == null) return null;
    if (expected == MrzExpectedDoc.passport && !_isPassportResult(best)) {
      return null;
    }
    if (expected == MrzExpectedDoc.idCard && !_isIdResult(best)) {
      return null;
    }
    if (kDebugMode) {
      print(
        '[MRZ] LENIENT OK → ${best.surnames} ${best.givenNames} '
        'doc=${best.documentNumber} type=${best.documentType}',
      );
    }
    return best;
  }

  static void _searchLenient(
    List<_MrzLine> lines,
    _BestResult scorer, {
    required MrzExpectedDoc expected,
  }) {
    final n = lines.length;
    bool docChar(String s) => _startsWithDocCharLoose(s);

    if (expected == MrzExpectedDoc.passport) {
      for (var i = 0; i < n; i++) {
        final structural = docChar(lines[i].compact);
        if (!structural) continue;
        for (var j = 0; j < n; j++) {
          if (i == j) continue;
          for (final nameVar in [lines[i].spaced, lines[i].compact]) {
            if (scorer.consider(
              _lenientTd3(
                _fitLenient(nameVar, _td3Len),
                _fitLenient(lines[j].compact, _td3Len),
              ),
              structural: structural,
            )) {
              return;
            }
          }
        }
      }
      for (final line in lines) {
        final s = line.compact;
        final structural = docChar(s);
        if (!structural) continue;
        if (s.length >= _td3Len * 2 &&
            scorer.consider(
              _lenientTd3(
                _fitLenient(s.substring(0, _td3Len), _td3Len),
                _fitLenient(s.substring(_td3Len, _td3Len * 2), _td3Len),
              ),
              structural: structural,
            )) {
          return;
        }
      }
      return;
    }

    // ID: TD1, keyin TD2.
    if (n >= 3) {
      for (var i = 0; i < n; i++) {
        final docOk = docChar(lines[i].compact);
        if (!docOk) continue;
        for (var j = 0; j < n; j++) {
          if (j == i) continue;
          for (var k = 0; k < n; k++) {
            if (k == i || k == j) continue;
            final structural = docOk && !_hasDigit(lines[k].compact);
            if (!structural) continue;
            for (final nameVar in [lines[k].spaced, lines[k].compact]) {
              if (scorer.consider(
                _lenientTd1(
                  _fitLenient(lines[i].compact, _td1Len),
                  _fitLenient(lines[j].compact, _td1Len),
                  _fitLenient(nameVar, _td1Len),
                ),
                structural: structural,
              )) {
                return;
              }
            }
          }
        }
      }
    }

    for (var i = 0; i < n; i++) {
      final structural = docChar(lines[i].compact);
      if (!structural) continue;
      for (var j = 0; j < n; j++) {
        if (i == j) continue;
        for (final nameVar in [lines[i].spaced, lines[i].compact]) {
          if (scorer.consider(
            _lenientTd2(
              _fitLenient(nameVar, _td2Len),
              _fitLenient(lines[j].compact, _td2Len),
            ),
            structural: structural,
          )) {
            return;
          }
        }
      }
    }

    for (final line in lines) {
      final s = line.compact;
      final structural = docChar(s);
      if (!structural) continue;
      if (s.length >= _td1Len * 3 &&
          scorer.consider(
            _lenientTd1(
              _fitLenient(s.substring(0, _td1Len), _td1Len),
              _fitLenient(s.substring(_td1Len, _td1Len * 2), _td1Len),
              _fitLenient(s.substring(_td1Len * 2, _td1Len * 3), _td1Len),
            ),
            structural: structural,
          )) {
        return;
      }
      if (s.length >= _td2Len * 2 &&
          scorer.consider(
            _lenientTd2(
              _fitLenient(s.substring(0, _td2Len), _td2Len),
              _fitLenient(s.substring(_td2Len, _td2Len * 2), _td2Len),
            ),
            structural: structural,
          )) {
        return;
      }
    }
  }

  static String _fitLenient(String line, int target) {
    if (line.length == target) return line;
    if (line.length > target) return line.substring(0, target);
    return line.padRight(target, '<');
  }

  static bool _startsWithDocCharLoose(String s) =>
      s.isNotEmpty && 'PVIAC1'.contains(s[0]);

  static bool _hasDigit(String s) => s.contains(RegExp(r'[0-9]'));

  static String _cleanForLenient(String line, {required bool spacesToFiller}) {
    var s = line.trim().toUpperCase();
    s = s
        .replaceAll('«', '<')
        .replaceAll('»', '<')
        .replaceAll('‹', '<')
        .replaceAll('›', '<')
        .replaceAll('≤', '<')
        .replaceAll('≪', '<')
        .replaceAll('≫', '<')
        .replaceAll('|', 'I');
    if (spacesToFiller) {
      s = s.replaceAll(RegExp(r'\s'), '<');
    } else {
      s = s.replaceAll(RegExp(r'\s+'), '');
    }
    return s.replaceAll(RegExp(r'[^A-Z0-9<]'), '');
  }

  static MRZResult? _lenientTd1(String a, String b, String c) {
    if (a.length != _td1Len || b.length != _td1Len || c.length != _td1Len) {
      return null;
    }
    final String docNumRaw;
    final String opt1Raw;
    if (a[14] == '<') {
      final tmp = a.substring(15, 28).replaceAll(RegExp(r'<+$'), '');
      if (tmp.isEmpty) return null;
      docNumRaw = a.substring(5, 14) + tmp.substring(0, tmp.length - 1);
      opt1Raw = a.substring(15 + tmp.length, 30);
    } else {
      docNumRaw = a.substring(5, 14);
      opt1Raw = a.substring(15, 30);
    }
    return _buildLenientResult(
      docTypeRaw: a.substring(0, 2),
      countryRaw: a.substring(2, 5),
      namesRaw: c.substring(0, 30),
      docNumRaw: docNumRaw,
      nationalityRaw: b.substring(15, 18),
      birthRaw: b.substring(0, 6),
      sexRaw: b.substring(7, 8),
      expiryRaw: b.substring(8, 14),
      opt1Raw: opt1Raw,
      opt2Raw: b.substring(18, 29),
    );
  }

  static MRZResult? _lenientTd3(String a, String b) {
    if (a.length != _td3Len || b.length != _td3Len) return null;
    return _buildLenientResult(
      docTypeRaw: a.substring(0, 2),
      countryRaw: a.substring(2, 5),
      namesRaw: a.substring(5),
      docNumRaw: b.substring(0, 9),
      nationalityRaw: b.substring(10, 13),
      birthRaw: b.substring(13, 19),
      sexRaw: b.substring(20, 21),
      expiryRaw: b.substring(21, 27),
      opt1Raw: b.substring(28, 42),
    );
  }

  static MRZResult? _lenientTd2(String a, String b) {
    if (a.length != _td2Len || b.length != _td2Len) return null;
    return _buildLenientResult(
      docTypeRaw: a.substring(0, 2),
      countryRaw: a.substring(2, 5),
      namesRaw: a.substring(5),
      docNumRaw: b.substring(0, 9),
      nationalityRaw: b.substring(10, 13),
      birthRaw: b.substring(13, 19),
      sexRaw: b.substring(20, 21),
      expiryRaw: b.substring(21, 27),
      opt1Raw: b.substring(28, 35),
    );
  }

  static MRZResult? _buildLenientResult({
    required String docTypeRaw,
    required String countryRaw,
    required String namesRaw,
    required String docNumRaw,
    required String nationalityRaw,
    required String birthRaw,
    required String sexRaw,
    required String expiryRaw,
    required String opt1Raw,
    String opt2Raw = '',
  }) {
    try {
      final names = MRZFieldParser.parseNames(
        MRZFieldRecognitionDefectsFixer.fixNames(namesRaw),
      );
      return MRZResult(
        documentType: MRZFieldParser.parseDocumentType(
          MRZFieldRecognitionDefectsFixer.fixDocumentType(docTypeRaw),
        ),
        countryCode: MRZFieldParser.parseCountryCode(
          MRZFieldRecognitionDefectsFixer.fixCountryCode(countryRaw),
        ),
        surnames: names[0],
        givenNames: names[1],
        documentNumber: MRZFieldParser.parseDocumentNumber(docNumRaw),
        nationalityCountryCode: MRZFieldParser.parseNationality(
          MRZFieldRecognitionDefectsFixer.fixNationality(nationalityRaw),
        ),
        birthDate: MRZFieldParser.parseBirthDate(
          MRZFieldRecognitionDefectsFixer.fixDate(birthRaw),
        ),
        sex: MRZFieldParser.parseSex(
          MRZFieldRecognitionDefectsFixer.fixSex(sexRaw),
        ),
        expiryDate: MRZFieldParser.parseExpiryDate(
          MRZFieldRecognitionDefectsFixer.fixDate(expiryRaw),
        ),
        personalNumber: MRZFieldParser.parseOptionalData(opt1Raw),
        personalNumber2:
            opt2Raw.isEmpty ? null : MRZFieldParser.parseOptionalData(opt2Raw),
      );
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Strict TD3 / chunk (mavjud SDK mantiq)
  // ---------------------------------------------------------------------------

  /// TD3: 1-qator `P<...`, 2-qator hujjat raqami bilan boshlanadi (P< emas).
  static MRZResult? _tryTd3Pairs(List<String> lines) {
    final line1s = lines.where(_isTd3Line1).toList()
      ..sort((a, b) => _scoreTd3Line1(b).compareTo(_scoreTd3Line1(a)));

    final line2s = lines.where(_isTd3Line2).toList()
      ..sort((a, b) => _scoreTd3Line2(b).compareTo(_scoreTd3Line2(a)));

    if (kDebugMode) {
      print(
        '[MRZ] TD3 candidates: line1=${line1s.length} '
        'line2=${line2s.length}',
      );
    }

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
    final fillers = '<'.allMatches(line).length;
    return fillers >= 4;
  }

  static bool _isTd3Line2(String line) {
    if (line.startsWith('P<')) return false;
    if (line.length < 36 || line.length > 48) return false;
    if (!RegExp(r'^[A-Z0-9]{8,10}').hasMatch(line)) return false;
    if (!RegExp(r'\d{6}').hasMatch(line)) return false;
    if (!RegExp(r'[MF<]')
        .hasMatch(line.substring(0, line.length.clamp(0, 28)))) {
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
          if (kDebugMode) {
            print('[MRZ] TD3 OK L1=$l1');
            print('[MRZ] TD3 OK L2=$l2');
          }
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

    if (fixed.length == 43) {
      for (final repaired in _repairMissingDocPrefix(fixed)) {
        add(repaired);
      }
    }

    yield* seen;
  }

  static Iterable<String> _repairMissingDocPrefix(String truncated43) sync* {
    if (truncated43.length != 43) return;

    final docTail = truncated43.substring(0, 8);
    final checkChar = truncated43[8];
    final expectedCheck = int.tryParse(checkChar);
    if (expectedCheck == null) return;

    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    for (var i = 0; i < alphabet.length; i++) {
      final prefix = alphabet[i];
      final docNumber = '$prefix$docTail';
      if (_mrzCheckDigit(docNumber) == expectedCheck) {
        yield '$prefix$truncated43';
      }
    }
  }

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
    if (kDebugMode) {
      print(
        '[MRZ] FAIL expected=$expected mismatch=$mismatch '
        'lines=${cleaned.length}',
      );
    }
    if (mismatch != null) {
      if (kDebugMode) {
        print('[MRZ] sabab: noto\'g\'ri hujjat turi — $mismatch topildi');
      }
      return;
    }

    final line1s = cleaned.where(_isTd3Line1).toList();
    final line2s = cleaned.where(_isTd3Line2).toList();
    if (kDebugMode) {
      print('[MRZ] L1=${line1s.length} L2=${line2s.length}');
      if (expected == MrzExpectedDoc.passport &&
          (line1s.isEmpty || line2s.isEmpty)) {
        print('[MRZ] sabab: TD3 juft topilmadi');
      }
    }
  }
}

/// Nomzod natijalar ichidan eng ishonchlisini tanlaydi.
class _BestResult {
  MRZResult? best;
  int _bestScore = -1 << 30;

  bool consider(MRZResult? r, {required bool structural}) {
    if (r == null) return false;
    final score = _score(r, structural);
    if (score > _bestScore) {
      _bestScore = score;
      best = r;
    }
    return _isConfident(r, structural);
  }

  static int _score(MRZResult r, bool structural) {
    final surname = r.surnames.trim();
    final given = r.givenNames.trim();
    var s = 0;
    if (surname.isNotEmpty) s += 100;
    if (given.isNotEmpty) s += 25;
    if (structural) s += 60;
    if (surname.length <= 1) s -= 100;
    s += surname.length.clamp(0, 20);
    return s;
  }

  static bool _isConfident(MRZResult r, bool structural) =>
      structural &&
      r.surnames.trim().length >= 2 &&
      r.givenNames.trim().isNotEmpty;
}

class _MrzLine {
  const _MrzLine({required this.compact, required this.spaced});

  final String compact;
  final String spaced;
}
