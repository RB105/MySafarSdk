import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class AnimatedAirplanePainter extends CustomPainter {
  final double cloudOffset;
  final double planeOffset;
  final ui.Image cloudImage;
  final ui.Image planeImage;

  AnimatedAirplanePainter({
    required this.cloudOffset,
    required this.planeOffset,
    required this.cloudImage,
    required this.planeImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();

    double cloudScale = 0.6;
    double cloudWidth = cloudImage.width * cloudScale;
    double cloudHeight = cloudImage.height * cloudScale;
    double startX = -cloudWidth + cloudOffset;

    for (int i = 0; i < 3; i++) {
      canvas.drawImageRect(
        cloudImage,
        Rect.fromLTWH(0, 0, cloudImage.width.toDouble(), cloudImage.height.toDouble()),
        Rect.fromLTWH(startX + i * cloudWidth, 10, cloudWidth, cloudHeight),
        paint,
      );
    }


    double targetPlaneHeight = 120;
    double originalPlaneWidth = planeImage.width.toDouble();
    double originalPlaneHeight = planeImage.height.toDouble();


    double aspectRatio = originalPlaneWidth / originalPlaneHeight;
    double targetPlaneWidth = targetPlaneHeight * aspectRatio;

    double planeX = (size.width - targetPlaneWidth) / 2;
    double planeY = 40 + planeOffset;

    canvas.drawImageRect(
      planeImage,
      Rect.fromLTWH(0, 0, originalPlaneWidth, originalPlaneHeight),
      Rect.fromLTWH(planeX, planeY, targetPlaneWidth, targetPlaneHeight),
      paint,
    );
  }


  @override
  bool shouldRepaint(covariant AnimatedAirplanePainter oldDelegate) {
    return oldDelegate.cloudOffset != cloudOffset ||
        oldDelegate.planeOffset != planeOffset;
  }
}
