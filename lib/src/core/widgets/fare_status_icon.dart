// Creator: Ravshanov Anzor
// Created: 24.09.2026

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';

/// Tarif sharti ikonkasi: bagaj / qo'l yuki / qaytarish / almashtirish.
///
/// Shart mavjud bo'lmasa ([positive] `false`) ikonka ustidan qizil chiziq
/// tortiladi — "mumkin emas" degani bir qarashda ko'rinadi. Chiziq ostiga fon
/// rangidagi kengroq chiziq chiziladi, shunda u to'ldirilgan ikonka ustida ham
/// ajralib turadi.
class FareStatusIcon extends StatelessWidget {
  const FareStatusIcon({
    super.key,
    this.asset,
    this.icon,
    required this.positive,
    this.size = 20,
    this.color,
    this.gapColor,
  }) : assert(asset != null || icon != null);

  /// SVG ikonka yo'li.
  final String? asset;

  /// SVG o'rniga Material ikonka.
  final IconData? icon;
  final bool positive;
  final double size;

  /// Ikonka rangi (berilmasa SVG'ning o'z ranglari qoladi).
  final Color? color;

  /// Chiziq ostidagi ajratuvchi rang — odatda karta foni.
  final Color? gapColor;

  @override
  Widget build(BuildContext context) {
    final Widget image = SizedBox(
      width: size,
      height: size,
      child: asset != null
          ? SvgPicture.asset(
              asset!,
              colorFilter: color == null
                  ? null
                  : ColorFilter.mode(color!, BlendMode.srcIn),
            )
          : Icon(icon, size: size, color: color),
    );
    if (positive) return image;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        foregroundPainter: _StrikePainter(
          color: color ?? ProjectTheme.error,
          gapColor: gapColor ?? context.color.primaryContainer,
        ),
        child: image,
      ),
    );
  }
}

class _StrikePainter extends CustomPainter {
  const _StrikePainter({required this.color, required this.gapColor});

  final Color color;
  final Color gapColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Pastki chapdan yuqori o'ngga — ikonka chetidan bir oz ichkarida.
    final inset = size.width * 0.06;
    final start = Offset(inset, size.height - inset);
    final end = Offset(size.width - inset, inset);
    final stroke = size.width * 0.09;

    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = gapColor
        ..strokeWidth = stroke * 2.4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = color
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_StrikePainter old) =>
      old.color != color || old.gapColor != gapColor;
}
