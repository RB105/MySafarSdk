import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:mysafar_sdk/src/view/destinations/destination_map_constants.dart';

/// Google Maps marker yaratish uchun service
class MarkerService {
  /// Connection pooling/qayta foydalanish uchun yagona Dio instansi
  static final Dio _dio = Dio();

  /// Bir marta yaratilgan placeholder markerni keshlash
  static BitmapDescriptor? _cachedPlaceholder;

  /// Image markerlarni URL bo'yicha keshlash (qayta yuklash/codec ishini oldini olish)
  static final Map<String, BitmapDescriptor> _imageMarkerCache = {};

  /// Oq placeholder marker yaratish
  static Future<BitmapDescriptor> createPlaceholderMarker() async {
    if (_cachedPlaceholder != null) {
      return _cachedPlaceholder!;
    }
    const double size = DestinationMapConstants.placeholderMarkerSize;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final Paint backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final RRect roundedRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size, size),
      const Radius.circular(8),
    );

    canvas.drawRRect(roundedRect, backgroundPaint);

    final picture = recorder.endRecording();
    final ui.Image img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      return BitmapDescriptor.defaultMarker;
    }

    final placeholder = BitmapDescriptor.bytes(byteData.buffer.asUint8List());
    _cachedPlaceholder = placeholder;
    return placeholder;
  }

  static Future<BitmapDescriptor?> createImageMarker(String imageUrl) async {
    final cached = _imageMarkerCache[imageUrl];
    if (cached != null) {
      return cached;
    }
    try {
      final response = await _dio.get<List<int>>(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode != 200) {
        return null;
      }

      final data = response.data;
      if (data == null || data.isEmpty) {
        return null;
      }

      final imageBytes = Uint8List.fromList(data);
      final marker = await _processImageToMarker(imageBytes);
      _imageMarkerCache[imageUrl] = marker;
      return marker;
    } catch (e) {
      debugPrint('Marker rasm yuklanmadi: $e');
      return null;
    }
  }

  static Future<BitmapDescriptor> _processImageToMarker(
      Uint8List imageBytes) async {
    const double size = DestinationMapConstants.imageMarkerSize;
    const double borderRadius = DestinationMapConstants.markerBorderRadius;
    const double innerMargin = DestinationMapConstants.markerInnerMargin;

    final codec = await ui.instantiateImageCodec(
      imageBytes,
      targetWidth: size.toInt(),
    );
    final frame = await codec.getNextFrame();
    final ui.Image image = frame.image;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    // Oq border
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final RRect outerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size, size),
      Radius.circular(borderRadius),
    );
    canvas.drawRRect(outerRect, borderPaint);

    // Ichki rasm
    final Rect innerRect = Rect.fromLTWH(
      innerMargin,
      innerMargin,
      size - innerMargin * 2,
      size - innerMargin * 2,
    );

    final RRect roundedInnerRect = RRect.fromRectAndRadius(
      innerRect,
      Radius.circular(borderRadius - 4),
    );
    canvas.clipRRect(roundedInnerRect);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      innerRect,
      Paint(),
    );

    final ui.Image finalImage =
        await recorder.endRecording().toImage(size.toInt(), size.toInt());

    final ByteData? byteData = await finalImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (byteData == null) {
      return BitmapDescriptor.defaultMarker;
    }

    return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }
}
