import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:mysafar_sdk/src/core/styles/theme.dart';

/// Segment matni va (ixtiyoriy) jonli soni.
class GlassSegment {
  const GlassSegment({required this.label, this.count});

  final String label;

  /// `null` — badge ko'rsatilmaydi (masalan, ro'yxat hali kelmagan).
  final int? count;
}

/// Pastki navigatsiya panelidagi "liquid glass" uslubidagi segment
/// boshqaruvi: shisha kapsula, yorug' qirra, faqat tashqariga tushadigan
/// soya va tanlangan segment ostida suzuvchi "linza".
///
/// [TabController] bilan ishlaydi — linza va matn ranglari tab animatsiyasini
/// kuzatadi, shuning uchun `TabBarView`ni surganda ham barmoq ortidan yuradi.
class GlassSegmentedControl extends StatelessWidget {
  const GlassSegmentedControl({
    super.key,
    required this.controller,
    required this.segments,
    this.height = 52,
  }) : assert(segments.length > 1);

  final TabController controller;
  final List<GlassSegment> segments;
  final double height;

  static const double _padding = 5;
  static const double _blurSigma = 24;

  // Pastki navigatsiya paneli bilan bir xil ranglar.
  static const Color _activeLight = Color(0xFF1B2541);
  static const Color _inactiveLight = Color(0xFF7A849E);

  @override
  Widget build(BuildContext context) {
    assert(controller.length == segments.length);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double radius = height / 2;
    final Color tint = isDark
        ? const Color(0xFF2A2A2E).withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.62);
    final Color active = isDark ? Colors.white : _activeLight;
    final Color inactive = isDark
        ? ProjectTheme.secondaryTextDark.withValues(alpha: 0.75)
        : _inactiveLight;

    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _OuterShadowPainter(
          radius: radius,
          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(tint, Colors.white, isDark ? 0.04 : 0.25)!,
                    tint,
                  ],
                ),
              ),
              child: CustomPaint(
                foregroundPainter:
                    _GlassRimPainter(radius: radius, isDark: isDark),
                child: Padding(
                  padding: const EdgeInsets.all(_padding),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double itemWidth =
                          constraints.maxWidth / segments.length;
                      return AnimatedBuilder(
                        animation: controller.animation!,
                        builder: (context, _) {
                          final double position = controller.animation!.value;
                          return Stack(
                            children: [
                              Positioned(
                                left: itemWidth * position,
                                width: itemWidth,
                                top: 0,
                                bottom: 0,
                                child: _SelectionPill(
                                  radius: math.max(0, radius - _padding),
                                  isDark: isDark,
                                ),
                              ),
                              Positioned.fill(
                                child: Row(
                                  children: [
                                    for (int i = 0; i < segments.length; i++)
                                      Expanded(
                                        child: _SegmentItem(
                                          segment: segments[i],
                                          // 1 — to'liq tanlangan, 0 — tanlanmagan;
                                          // surish paytida oraliq qiymatlar.
                                          selectedness:
                                              (1 - (position - i).abs())
                                                  .clamp(0.0, 1.0),
                                          selected: controller.index == i,
                                          active: active,
                                          inactive: inactive,
                                          isDark: isDark,
                                          onTap: () {
                                            if (controller.index == i) return;
                                            HapticFeedback.selectionClick();
                                            controller.animateTo(i);
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tanlangan segment ostidagi suzuvchi shisha "linza".
class _SelectionPill extends StatelessWidget {
  const _SelectionPill({required this.radius, required this.isDark});

  final double radius;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: isDark
            ? Colors.white.withValues(alpha: 0.14)
            : const Color(0xFF1B2541).withValues(alpha: 0.07),
        border: Border.all(
          width: 0.8,
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.70),
        ),
      ),
    );
  }
}

class _SegmentItem extends StatefulWidget {
  const _SegmentItem({
    required this.segment,
    required this.selectedness,
    required this.selected,
    required this.active,
    required this.inactive,
    required this.isDark,
    required this.onTap,
  });

  final GlassSegment segment;
  final double selectedness;
  final bool selected;
  final Color active;
  final Color inactive;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_SegmentItem> createState() => _SegmentItemState();
}

class _SegmentItemState extends State<_SegmentItem> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final double t = widget.selectedness;
    final Color color = Color.lerp(widget.inactive, widget.active, t)!;
    final int? count = widget.segment.count;

    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.segment.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.segment.label,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'packages/mysafar_sdk/Gilroy',
                        fontSize: 14,
                        fontWeight: t > 0.5 ? FontWeight.w700 : FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 6),
                  _CountBadge(
                      count: count, color: color, isDark: widget.isDark),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.count,
    required this.color,
    required this.isDark,
  });

  final int count;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'packages/mysafar_sdk/Gilroy',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          height: 1.2,
        ),
      ),
    );
  }
}

/// Shisha qirrasidagi yorug' chiziq — tepada yorqin, pastga xiralashadi.
class _GlassRimPainter extends CustomPainter {
  const _GlassRimPainter({required this.radius, required this.isDark});

  final double radius;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 1;
    final Rect rect = (Offset.zero & size).deflate(stroke / 2);
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                Colors.white.withValues(alpha: 0.22),
                Colors.white.withValues(alpha: 0.05),
              ]
            : [
                Colors.white.withValues(alpha: 0.95),
                Colors.white.withValues(alpha: 0.35),
              ],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          rect, Radius.circular(math.max(0, radius - stroke / 2))),
      paint,
    );
  }

  @override
  bool shouldRepaint(_GlassRimPainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.isDark != isDark;
}

/// Faqat kapsula tashqarisiga tushadigan soya — shaffof shisha ortidan
/// qorayib ko'rinmasligi uchun.
class _OuterShadowPainter extends CustomPainter {
  const _OuterShadowPainter({
    required this.radius,
    required this.color,
    required this.blurRadius,
    required this.offset,
  });

  final double radius;
  final Color color;
  final double blurRadius;
  final Offset offset;

  @override
  void paint(Canvas canvas, Size size) {
    final RRect shape =
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final Rect bounds =
        (Offset.zero & size).inflate(blurRadius * 2 + offset.distance);

    canvas.save();
    canvas.clipPath(Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(bounds)
      ..addRRect(shape));
    canvas.drawRRect(
      shape.shift(offset),
      Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(
            BlurStyle.normal, Shadow.convertRadiusToSigma(blurRadius)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OuterShadowPainter oldDelegate) =>
      oldDelegate.radius != radius ||
      oldDelegate.color != color ||
      oldDelegate.blurRadius != blurRadius ||
      oldDelegate.offset != offset;
}
