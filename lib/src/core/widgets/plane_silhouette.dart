// Creator: Ravshanov Anzor
// Created: 24.09.2026

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Tepadan qaragan yo'lovchi laynerining vektor silueti: fyuzelyaj, orqaga
/// qiya qanotlar, ikki dvigatel, dum qanotlari va kabina oynasi.
///
/// Bitta chizma — ikki joyda: bron sahifasidagi marshrut yoyi uchida
/// (`RouteArcHero`) va chipta tafsiloti headeridagi yoy ustida. Shakl
/// 100×100 koordinatada chiziladi (burni (50,0) da), keyin [size] ga
/// keltiriladi va [angle] bo'yicha buriladi.
///
/// [angle] — harakat yo'nalishining burchagi (radian, `Tangent.angle`
/// bilan bir xil: 0 — o'ngga, soat miliga teskari musbat). Burun shu
/// tomonga qaraydi.
///
/// [shadeColor] — dvigatel/dum uchun tanaga aralashtiriladigan rang va
/// kabina oynasi rangi; odatda fon rangi. [shadow] — samolyot ostidagi
/// yumshoq soya (fon rangida), bir xil rangli fon ustida keraksiz.
void drawPlaneSilhouette(
  Canvas canvas, {
  required Offset position,
  required double angle,
  required double size,
  required Color color,
  required Color shadeColor,
  bool shadow = true,
}) {
  final body = Paint()..color = color;
  // Dvigatel va dum — tanadan biroz to'qroq (fon rangiga aralashtirilgan),
  // aks holda oq qanot ustida ko'rinmay qolardi.
  final shade = Paint()..color = Color.lerp(color, shadeColor, 0.4)!;
  final glass = Paint()..color = shadeColor.withValues(alpha: 0.75);

  // Fyuzelyaj: yumaloq burun, bir tekis tana, dumga qarab toraygan.
  final fuselage = Path()
    ..moveTo(50, 0)
    ..cubicTo(57, 0, 58, 16, 58, 32)
    ..lineTo(58, 70)
    ..cubicTo(58, 84, 56, 93, 53, 100)
    ..lineTo(47, 100)
    ..cubicTo(44, 93, 42, 84, 42, 70)
    ..lineTo(42, 32)
    ..cubicTo(42, 16, 43, 0, 50, 0)
    ..close();

  // Qanotlar: ildizi keng, uchiga qarab toraygan, orqaga qiya.
  final wings = Path()
    ..moveTo(58, 36)
    ..lineTo(97, 68)
    ..lineTo(98, 76)
    ..lineTo(58, 63)
    ..close()
    ..moveTo(42, 36)
    ..lineTo(3, 68)
    ..lineTo(2, 76)
    ..lineTo(42, 63)
    ..close();

  // Dum qanotlari (gorizontal stabilizator).
  final tail = Path()
    ..moveTo(55, 84)
    ..lineTo(75, 96)
    ..lineTo(75, 100)
    ..lineTo(53, 96)
    ..close()
    ..moveTo(45, 84)
    ..lineTo(25, 96)
    ..lineTo(25, 100)
    ..lineTo(47, 96)
    ..close();

  canvas.save();
  canvas.translate(position.dx, position.dy);
  // `angle` — yo'nalishning soat miliga teskari burchagi; samolyot burni
  // yuqoriga qaragani uchun yana 90° buriladi.
  canvas.rotate(-angle + math.pi / 2);
  final scale = size / 100;
  canvas.scale(scale, scale);
  canvas.translate(-50, -50);

  if (shadow) {
    // Yumshoq soya — samolyot chiziq va fon ustida "ko'tarilib" turadi.
    canvas.drawPath(
      Path()
        ..addPath(fuselage, Offset.zero)
        ..addPath(wings, Offset.zero),
      Paint()
        ..color = shadeColor.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
  }

  canvas.drawPath(wings, body);
  canvas.drawPath(tail, body);
  canvas.drawPath(fuselage, body);

  // Dvigatellar — qanot oldiga chiqib turadigan ikki gondola.
  for (final cx in const [29.0, 71.0]) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, 52), width: 9, height: 20),
        const Radius.circular(4.5),
      ),
      shade,
    );
  }

  // Kabina oynasi — burun yaqinidagi yoysimon shisha.
  canvas.drawPath(
    Path()
      ..moveTo(45, 12)
      ..quadraticBezierTo(50, 7, 55, 12)
      ..lineTo(55, 17)
      ..quadraticBezierTo(50, 14, 45, 17)
      ..close(),
    glass,
  );

  // Vertikal dum — tepadan ingichka chiziq bo'lib ko'rinadi.
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(48.5, 72, 3, 24),
      const Radius.circular(1.5),
    ),
    shade,
  );

  canvas.restore();
}

/// [drawPlaneSilhouette] ning widget ko'rinishi — [size]×[size] kvadrat,
/// samolyot markazda, burni [angle] tomonga.
class PlaneSilhouette extends StatelessWidget {
  const PlaneSilhouette({
    super.key,
    required this.size,
    required this.color,
    required this.shadeColor,
    this.angle = 0,
    this.shadow = false,
  });

  final double size;
  final Color color;
  final Color shadeColor;

  /// Yo'nalish burchagi, radian: 0 — o'ngga, `math.pi` — chapga.
  final double angle;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PlanePainter(
          color: color,
          shadeColor: shadeColor,
          angle: angle,
          shadow: shadow,
        ),
      ),
    );
  }
}

class _PlanePainter extends CustomPainter {
  const _PlanePainter({
    required this.color,
    required this.shadeColor,
    required this.angle,
    required this.shadow,
  });

  final Color color;
  final Color shadeColor;
  final double angle;
  final bool shadow;

  @override
  void paint(Canvas canvas, Size size) {
    drawPlaneSilhouette(
      canvas,
      position: size.center(Offset.zero),
      angle: angle,
      size: math.min(size.width, size.height),
      color: color,
      shadeColor: shadeColor,
      shadow: shadow,
    );
  }

  @override
  bool shouldRepaint(_PlanePainter old) =>
      old.color != color ||
      old.shadeColor != shadeColor ||
      old.angle != angle ||
      old.shadow != shadow;
}
