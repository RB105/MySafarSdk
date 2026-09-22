import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Rect, Size;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Skaner surati serverga (`/v1/document/scan`) yuborilishidan oldin
/// tayyorlanadi: EXIF burilishi to'g'rilanadi, hujjat ramkasi atrofi (zaxira
/// chegara bilan) kesiladi va uzun tomoni [maxLongSide] gacha kichraytiriladi.
///
/// Maqsad — tiniq, lekin og'ir bo'lmagan rasm: kamera 4K (~8 MP) oladi,
/// hujjatdan tashqari joy tashlanadi, matn piksellari saqlanadi.
/// Har qanday xatoda asl fayl yo'li qaytadi — skaner baribir ishlaydi.
Future<String> prepareDocumentPhoto(
  String path, {
  Rect? frame,
  Size? viewport,
}) async {
  try {
    final bytes = await File(path).readAsBytes();
    final job = DocumentPhotoJob(
      bytes: bytes,
      frameLeft: frame?.left,
      frameTop: frame?.top,
      frameWidth: frame?.width,
      frameHeight: frame?.height,
      viewportWidth: viewport?.width,
      viewportHeight: viewport?.height,
    );
    final processed = await compute(processDocumentPhotoBytes, job);
    if (processed == null) return path;
    final out = File(
      '${Directory.systemTemp.path}/mysafar_doc_'
      '${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await out.writeAsBytes(processed, flush: true);
    return out.path;
  } catch (e) {
    debugPrint('Document photo processing failed: $e');
    return path;
  }
}

/// Isolate'ga yuboriladigan ish (faqat oddiy qiymatlar).
class DocumentPhotoJob {
  const DocumentPhotoJob({
    required this.bytes,
    this.frameLeft,
    this.frameTop,
    this.frameWidth,
    this.frameHeight,
    this.viewportWidth,
    this.viewportHeight,
  });

  final Uint8List bytes;

  /// Ramka va kamera maydoni — ekran (logical px) koordinatalarida.
  final double? frameLeft;
  final double? frameTop;
  final double? frameWidth;
  final double? frameHeight;
  final double? viewportWidth;
  final double? viewportHeight;

  bool get hasFrame =>
      frameLeft != null &&
      frameTop != null &&
      (frameWidth ?? 0) > 0 &&
      (frameHeight ?? 0) > 0 &&
      (viewportWidth ?? 0) > 0 &&
      (viewportHeight ?? 0) > 0;
}

/// Uzun tomon chegarasi: pasport sahifasi ~2100 px bo'ladi — MRZ va mayda
/// matn server OCR'i uchun yetarlicha tiniq, fayl esa ~1 MB atrofida.
const int maxLongSide = 2400;
const int _jpegQuality = 92;

/// Ramkaga qo'shiladigan zaxira (kamera preview va surat nisbati biroz farq
/// qilishi mumkin — hujjat chetlari kesilib qolmasin).
const double _marginX = 0.10;
const double _marginY = 0.25;

@visibleForTesting
Uint8List? processDocumentPhotoBytes(DocumentPhotoJob job) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(job.bytes);
  } catch (_) {
    // Rasm emas yoki buzilgan fayl.
    return null;
  }
  if (decoded == null) return null;
  var image = img.bakeOrientation(decoded);

  if (job.hasFrame) {
    final crop = _cropRect(
      imageWidth: image.width,
      imageHeight: image.height,
      job: job,
    );
    if (crop != null) {
      image = img.copyCrop(
        image,
        x: crop.$1,
        y: crop.$2,
        width: crop.$3,
        height: crop.$4,
      );
    }
  }

  final longSide = math.max(image.width, image.height);
  if (longSide > maxLongSide) {
    final landscape = image.width >= image.height;
    image = img.copyResize(
      image,
      width: landscape ? maxLongSide : null,
      height: landscape ? null : maxLongSide,
      interpolation: img.Interpolation.average,
    );
  }

  return Uint8List.fromList(img.encodeJpg(image, quality: _jpegQuality));
}

/// Ekrandagi ramkani suratdagi to'rtburchakka o'giradi. Kamera ko'rinishi
/// maydonni "cover" qilib to'ldiradi (markazdan kesiladi) — shu hisobga
/// olinadi. Natija: (x, y, width, height) yoki kesish ma'nosiz bo'lsa `null`.
(int, int, int, int)? _cropRect({
  required int imageWidth,
  required int imageHeight,
  required DocumentPhotoJob job,
}) {
  final vw = job.viewportWidth!;
  final vh = job.viewportHeight!;
  final scale = math.max(vw / imageWidth, vh / imageHeight);
  final offsetX = (imageWidth * scale - vw) / 2;
  final offsetY = (imageHeight * scale - vh) / 2;

  final fw = job.frameWidth!;
  final fh = job.frameHeight!;
  var left = (job.frameLeft! - fw * _marginX + offsetX) / scale;
  var top = (job.frameTop! - fh * _marginY + offsetY) / scale;
  var right = (job.frameLeft! + fw * (1 + _marginX) + offsetX) / scale;
  var bottom = (job.frameTop! + fh * (1 + _marginY) + offsetY) / scale;

  left = left.clamp(0, imageWidth.toDouble());
  right = right.clamp(0, imageWidth.toDouble());
  top = top.clamp(0, imageHeight.toDouble());
  bottom = bottom.clamp(0, imageHeight.toDouble());

  final width = (right - left).round();
  final height = (bottom - top).round();
  // Hisob noto'g'ri chiqsa (juda kichik bo'lak) — kesmaymiz.
  if (width < imageWidth * 0.4 || height < 100) return null;
  return (left.round(), top.round(), width, height);
}
