import 'dart:typed_data';
import 'dart:ui' show Rect, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mysafar_sdk/src/view/booking/support/document_photo_processor.dart';

Uint8List _jpeg(int width, int height) =>
    Uint8List.fromList(img.encodeJpg(img.Image(width: width, height: height)));

void main() {
  test('katta kamera surati ramka atrofi bo\'yicha kesiladi va kichrayadi', () {
    // Portret 12 MP surat, ekranda 400x700 maydon, ramka markazda.
    const viewport = Size(400, 700);
    final frame = Rect.fromCenter(
      center: const Offset(200, 364),
      width: 360,
      height: 360 / 1.42,
    );
    final out = processDocumentPhotoBytes(DocumentPhotoJob(
      bytes: _jpeg(3000, 4000),
      frameLeft: frame.left,
      frameTop: frame.top,
      frameWidth: frame.width,
      frameHeight: frame.height,
      viewportWidth: viewport.width,
      viewportHeight: viewport.height,
    ));
    final result = img.decodeJpg(out!)!;

    expect(result.width, lessThanOrEqualTo(maxLongSide));
    expect(result.height, lessThanOrEqualTo(maxLongSide));
    // Hujjat enli (landshaft) bo'lak — balandlik to'liq surat balandligidan
    // ancha kichik, kenglik esa deyarli butun kenglik.
    expect(result.width, greaterThan(result.height));
    expect(result.width, greaterThan(2000));
  });

  test('ramkasiz (galereya) surat faqat kichraytiriladi', () {
    final out = processDocumentPhotoBytes(
      DocumentPhotoJob(bytes: _jpeg(4000, 3000)),
    );
    final result = img.decodeJpg(out!)!;
    expect(result.width, maxLongSide);
    expect(result.height, 1800);
  });

  test('kichik surat o\'lchami o\'zgarmaydi', () {
    final out = processDocumentPhotoBytes(
      DocumentPhotoJob(bytes: _jpeg(1200, 900)),
    );
    final result = img.decodeJpg(out!)!;
    expect(result.width, 1200);
    expect(result.height, 900);
  });

  test('rasm bo\'lmagan bayt — null (asl fayl yuboriladi)', () {
    expect(
      processDocumentPhotoBytes(
          DocumentPhotoJob(bytes: Uint8List.fromList([1, 2, 3]))),
      isNull,
    );
  });
}
