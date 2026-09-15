import 'dart:convert';
import 'dart:math' show Random;
import 'dart:typed_data';

import 'package:pointycastle/export.dart'
    show AEADParameters, AESEngine, GCMBlockCipher, KeyParameter;

/// MySafar to'lov sahifasi uchun `card_token` — "Unired → MySafar: karta
/// rekvizitlarini shifrlab uzatish" hujjati bo'yicha:
///
/// * AES-256-GCM, kalit 32 bayt (hex, 64 belgi), AAD yo'q;
/// * IV 12 bayt, har token uchun yangi tasodifiy;
/// * plaintext — UTF-8 JSON `{card_number, expire, tr_id, iat}`;
/// * token — `base64url(IV ‖ CIPHERTEXT ‖ TAG(16))`, padding'siz.
class CardTokenEncoder {
  CardTokenEncoder(String keyHex) : _key = _parseKey(keyHex);

  static const int ivLength = 12;
  static const int tagLengthBits = 128;

  final Uint8List _key;

  /// 64 belgili hex (32 bayt) kalitmi.
  static bool isValidKey(String? keyHex) =>
      keyHex != null && RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(keyHex.trim());

  /// Hujjatning 3-bo'limidagi plaintext. Maydonlar tartibi hujjatdagidek.
  /// [cardNumber] dan faqat raqamlar olinadi; [expire] — `YYMM`;
  /// `iat` — Unix soniya (UTC).
  static Map<String, Object> payload({
    required String cardNumber,
    required String expire,
    required String trId,
    required DateTime issuedAt,
  }) {
    return {
      'card_number': cardNumber.replaceAll(RegExp(r'\D'), ''),
      'expire': expire,
      'tr_id': trId,
      'iat': issuedAt.millisecondsSinceEpoch ~/ 1000,
    };
  }

  /// [payload] ni shifrlab token qaytaradi. [iv] faqat testlar uchun —
  /// odatda har chaqiriqda yangi tasodifiy IV yaratiladi.
  String encrypt(Map<String, Object> payload, {Uint8List? iv}) {
    final nonce = iv ?? _randomIv();
    if (nonce.length != ivLength) {
      throw ArgumentError.value(
          nonce.length, 'iv', 'IV 12 bayt bo\'lishi kerak');
    }
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(KeyParameter(_key), tagLengthBits, nonce, Uint8List(0)),
      );
    // GCM natijasi: CIPHERTEXT ‖ TAG(16).
    final sealed =
        cipher.process(Uint8List.fromList(utf8.encode(jsonEncode(payload))));
    final token = Uint8List(nonce.length + sealed.length)
      ..setAll(0, nonce)
      ..setAll(nonce.length, sealed);
    return base64Url.encode(token).replaceAll('=', '');
  }

  static Uint8List _parseKey(String keyHex) {
    final hex = keyHex.trim();
    if (!isValidKey(hex)) {
      throw ArgumentError(
          'card_token kaliti 64 belgili hex (32 bayt) bo\'lishi kerak');
    }
    return Uint8List.fromList([
      for (int i = 0; i < hex.length; i += 2)
        int.parse(hex.substring(i, i + 2), radix: 16),
    ]);
  }

  static Uint8List _randomIv() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(ivLength, (_) => random.nextInt(256)),
    );
  }
}
