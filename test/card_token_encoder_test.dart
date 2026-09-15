import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/src/service/payment/card_token_encoder.dart';
import 'package:pointycastle/export.dart'
    show AEADParameters, AESEngine, GCMBlockCipher, KeyParameter;

/// Hujjatdagi test kaliti (5-bo'lim).
const _testKey =
    '0000000000000000000000000000000000000000000000000000000000000001';

Uint8List _hex(String hex) => Uint8List.fromList([
      for (int i = 0; i < hex.length; i += 2)
        int.parse(hex.substring(i, i + 2), radix: 16),
    ]);

/// MySafar tomonidagi ochish: base64url → IV(12) ‖ CT ‖ TAG(16) → JSON.
Map<String, dynamic> _decrypt(String token, String keyHex) {
  final padded = token.padRight((token.length + 3) ~/ 4 * 4, '=');
  final raw = base64Url.decode(padded);
  final iv = raw.sublist(0, 12);
  final cipher = GCMBlockCipher(AESEngine())
    ..init(
      false,
      AEADParameters(KeyParameter(_hex(keyHex)), 128, iv, Uint8List(0)),
    );
  final plain = cipher.process(Uint8List.fromList(raw.sublist(12)));
  return jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
}

void main() {
  final issuedAt = DateTime.utc(2025, 9, 15, 8);
  final payload = CardTokenEncoder.payload(
    cardNumber: '8600 1234-5678 9012',
    expire: '2805',
    trId: 'd2b3e4be-cbfd-444e-acff-99c9931f3d4f',
    issuedAt: issuedAt,
  );

  test('plaintext hujjatdagi maydonlar va tartibda', () {
    expect(payload.keys, ['card_number', 'expire', 'tr_id', 'iat']);
    expect(payload['card_number'], '8600123456789012');
    expect(payload['expire'], '2805');
    expect(payload['iat'], 1757923200);
  });

  test('token ochiladi va plaintext mos keladi', () {
    final token = CardTokenEncoder(_testKey).encrypt(payload);
    expect(_decrypt(token, _testKey), {
      'card_number': '8600123456789012',
      'expire': '2805',
      'tr_id': 'd2b3e4be-cbfd-444e-acff-99c9931f3d4f',
      'iat': 1757923200,
    });
  });

  test('base64url, padding yo\'q, IV(12) ‖ CT ‖ TAG(16)', () {
    final token = CardTokenEncoder(_testKey).encrypt(payload);
    expect(token, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
    final raw = base64Url.decode(token.padRight((token.length + 3) ~/ 4 * 4, '='));
    expect(raw.length, 12 + utf8.encode(jsonEncode(payload)).length + 16);
  });

  test('har token uchun yangi tasodifiy IV', () {
    final encoder = CardTokenEncoder(_testKey);
    final a = encoder.encrypt(payload);
    final b = encoder.encrypt(payload);
    expect(a, isNot(b));
    expect(a.substring(0, 16), isNot(b.substring(0, 16)));
  });

  test('boshqa kalit bilan ochilmaydi (auth tag)', () {
    final token = CardTokenEncoder(_testKey).encrypt(payload);
    expect(
      () => _decrypt(token, '00' * 31 + '02'),
      throwsA(anything),
    );
  });

  test('kalit tekshiruvi', () {
    expect(CardTokenEncoder.isValidKey(_testKey), isTrue);
    expect(CardTokenEncoder.isValidKey('abc'), isFalse);
    expect(CardTokenEncoder.isValidKey(null), isFalse);
    expect(() => CardTokenEncoder('xyz'), throwsArgumentError);
  });
}
