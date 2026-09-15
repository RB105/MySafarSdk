import 'package:flutter/services.dart' show HapticFeedback;
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

/// Segment matni va (ixtiyoriy) jonli soni.
class AppSegment {
  const AppSegment({required this.label, this.count});

  final String label;

  /// `null` — badge ko'rsatilmaydi (masalan, ro'yxat hali kelmagan).
  final int? count;
}

/// Kapsula ko'rinishidagi segment tab panel — qidiruv sahifasidagi segment
/// tanlagich bilan bir xil yangi uslub: yumshoq trek ustida oq "pill"
/// (dark'da brend) suriladi, tanlangan matn brend rangda.
///
/// [TabController] bilan ishlaydi — pill va matn ranglari tab animatsiyasini
/// kuzatadi, shuning uchun `TabBarView`ni surganda ham barmoq ortidan yuradi.
class AppSegmentedTabBar extends StatelessWidget {
  const AppSegmentedTabBar({
    super.key,
    required this.controller,
    required this.segments,
    this.height = 48,
  }) : assert(segments.length > 1);

  final TabController controller;
  final List<AppSegment> segments;
  final double height;

  static const double _padding = 4;
  static const double _labelSize = 14;
  static const double _badgeSize = 11;
  static const double _itemHPadding = 6;
  static const double _badgeGap = 6;

  static TextStyle _labelStyle(double size) => TextStyle(
        fontFamily: 'packages/mysafar_sdk/Gilroy',
        fontSize: size,
        fontWeight: FontWeight.w700,
      );

  static TextStyle _badgeStyle(double size) => TextStyle(
        fontFamily: 'packages/mysafar_sdk/Gilroy',
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );

  /// Barcha segmentlar uchun bitta umumiy shrift masshtabi — eng uzun segment
  /// (masalan "To'lanmaganlar") sig'maganda hammasi birga kichrayadi, shunda
  /// yozuvlar bir xil o'lchamda qoladi.
  double _fitScale(BuildContext context, double itemWidth) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    double measure(String text, TextStyle style) => (TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
          textScaler: scaler,
        )..layout())
            .width;

    double widest = 0;
    for (final segment in segments) {
      double width =
          measure(segment.label, _labelStyle(_labelSize)) + _itemHPadding * 2;
      if (segment.count != null) {
        final double badge =
            measure('${segment.count}', _badgeStyle(_badgeSize)) + 12;
        width += _badgeGap + (badge < 20 ? 20 : badge);
      }
      if (width > widest) widest = width;
    }
    return widest <= itemWidth ? 1 : itemWidth / widest;
  }

  @override
  Widget build(BuildContext context) {
    assert(controller.length == segments.length);
    final bool isDark = context.isDarkMode;
    final Color brand = ProjectTheme.brandColor;
    final double radius = height / 2;
    // Sahifa foni (#EEF3FB) ustida ajralib turadigan yumshoq trek.
    final Color track =
        isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F2);
    final Color pill = isDark ? brand : Colors.white;
    final Color active = isDark ? Colors.white : brand;
    final Color inactive =
        isDark ? Colors.white.withValues(alpha: 0.67) : const Color(0xFF5B6B85);

    return Container(
      height: height,
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double itemWidth = constraints.maxWidth / segments.length;
          final double scale = _fitScale(context, itemWidth);
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
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: pill,
                        borderRadius: BorderRadius.circular(radius - _padding),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.24)
                                : const Color(0x260A2540),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
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
                                  (1 - (position - i).abs()).clamp(0.0, 1.0),
                              selected: controller.index == i,
                              scale: scale,
                              brand: brand,
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
    );
  }
}

class _SegmentItem extends StatelessWidget {
  const _SegmentItem({
    required this.segment,
    required this.selectedness,
    required this.selected,
    required this.scale,
    required this.brand,
    required this.active,
    required this.inactive,
    required this.isDark,
    required this.onTap,
  });

  final AppSegment segment;
  final double selectedness;
  final bool selected;
  final double scale;
  final Color brand;
  final Color active;
  final Color inactive;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double t = selectedness;
    final int? count = segment.count;
    // Badge: tanlanmagan — trek ustida neytral; tanlangan — oq pill ustida
    // brend tusi (dark'da brend pill ustida oq shaffof).
    final Color idleBadgeBg = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.65);
    final Color activeBadgeBg = isDark
        ? Colors.white.withValues(alpha: 0.24)
        : brand.withValues(alpha: 0.10);

    return Semantics(
      button: true,
      selected: selected,
      label: segment.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSegmentedTabBar._itemHPadding),
          // Masshtab umumiy (_fitScale); FittedBox — faqat yumaloqlash
          // xatolari uchun zaxira.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  segment.label,
                  maxLines: 1,
                  style: AppSegmentedTabBar._labelStyle(
                          AppSegmentedTabBar._labelSize * scale)
                      .copyWith(
                    fontWeight: t > 0.5 ? FontWeight.w700 : FontWeight.w600,
                    color: Color.lerp(inactive, active, t),
                  ),
                ),
                if (count != null) ...[
                  SizedBox(width: AppSegmentedTabBar._badgeGap * scale),
                  Container(
                    constraints: BoxConstraints(minWidth: 20 * scale),
                    padding: EdgeInsets.symmetric(
                        horizontal: 6 * scale, vertical: 2 * scale),
                    decoration: BoxDecoration(
                      color: Color.lerp(idleBadgeBg, activeBadgeBg, t),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$count',
                      textAlign: TextAlign.center,
                      style: AppSegmentedTabBar._badgeStyle(
                              AppSegmentedTabBar._badgeSize * scale)
                          .copyWith(
                        color: Color.lerp(inactive, active, t),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
