import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:shimmer/shimmer.dart' show Shimmer;
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/tools/app_cache_manager.dart';
import 'package:mysafar_sdk/src/core/tools/project_assets.dart';
import 'package:mysafar_sdk/src/model/local/payment_type.dart';
import 'package:mysafar_sdk/src/view/booking/widget/booking_form_fields.dart'
    show BookingFormStyle;
import 'package:mysafar_sdk/src/view/booking/widget/support_widget.dart'
    show BookingCard;

class PaymentTypeEntry {
  final PaymentType type;
  final bool isActive;

  const PaymentTypeEntry({required this.type, required this.isActive});
}

class _BrandLogo {
  final String light;
  final String dark;

  const _BrandLogo({required this.light, required this.dark});

  /// Dark variant yo'q (bir xil rasm) — to'q fonda ko'rinmaydi, shuning uchun
  /// logotip plitkasi dark temada ham oq bo'ladi.
  bool get needsLightTile => light == dark;
}

const Map<String, _BrandLogo> _brandLogos = {
  PaymentConstants.mysafarpay: _BrandLogo(
    light: ProjectAssets.bookingLocalLight,
    dark: ProjectAssets.bookingLocalDark,
  ),
  PaymentConstants.payme: _BrandLogo(
    light: ProjectAssets.bookingPaymeLight,
    dark: ProjectAssets.bookingPaymeDark,
  ),
  PaymentConstants.paygine: _BrandLogo(
    light: ProjectAssets.bookingSbpLight,
    dark: ProjectAssets.bookingSbp,
  ),
  PaymentConstants.click: _BrandLogo(
    light: ProjectAssets.bookingClickLight,
    dark: ProjectAssets.bookingClickDark,
  ),
  PaymentConstants.visa: _BrandLogo(
    light: ProjectAssets.bookingVisaLight,
    dark: ProjectAssets.bookingVisaLight,
  ),
};

/// To'lov usullari — har biri alohida karta: katta logotip, nom, izoh va
/// radio. Tanlangan karta brend konturi va yengil fon bilan ajraladi.
/// Yuklanayotganda skeleton kartalar.
class PaymentMethodList extends StatelessWidget {
  static const double _gap = 10;

  final List<PaymentTypeEntry> items;
  final String? selectedType;
  final ValueChanged<String> onTypeSelected;
  final bool isLoading;
  final bool hasError;

  const PaymentMethodList({
    super.key,
    required this.items,
    required this.selectedType,
    required this.onTypeSelected,
    this.isLoading = false,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final rows = isLoading
        ? List<Widget>.generate(3, (_) => const _PaymentMethodSkeleton())
        : [
            for (final entry in items)
              PaymentMethodTile(
                paymentType: entry.type,
                isSelected: selectedType == entry.type.id,
                enabled: entry.isActive,
                hasError: hasError,
                onTap: () => onTypeSelected(entry.type.id),
              ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: _gap),
          rows[i],
        ],
      ],
    );
  }
}

class PaymentMethodTile extends StatelessWidget {
  static const double _logoWidth = 76;
  static const double _logoHeight = 52;
  static const double _radius = 20;
  static const double _borderWidth = 1.5;

  final PaymentType paymentType;
  final bool isSelected;
  final bool enabled;

  /// Usul tanlanmay "To'lovga o'tish" bosilgan — kartalar qizil konturlanadi.
  final bool hasError;
  final VoidCallback onTap;

  const PaymentMethodTile({
    super.key,
    required this.paymentType,
    required this.isSelected,
    required this.onTap,
    this.enabled = true,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final brand = ProjectTheme.brandColor;
    final cardColor =
        isDark ? ProjectTheme.cardColorDark : ProjectTheme.cardColorLight;
    final rawTitle = (paymentType.cardName?.trim() ?? '').tr();
    final subtitle = paymentType.subtitle?.trim().tr();
    final title = rawTitle.isNotEmpty ? rawTitle : (subtitle ?? '');
    final caption = rawTitle.isNotEmpty ? subtitle : null;

    // Kontur doim bir xil qalinlikda (shaffof) — tanlanganda layout siljimaydi.
    final Color borderColor = isSelected
        ? brand
        : hasError
            ? ProjectTheme.error.withValues(alpha: 0.7)
            : Colors.transparent;

    final tile = Semantics(
      button: true,
      selected: isSelected,
      enabled: enabled,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected
              ? Color.alphaBlend(
                  brand.withValues(alpha: isDark ? 0.16 : 0.05),
                  cardColor,
                )
              : cardColor,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: borderColor, width: _borderWidth),
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: brand.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(_radius),
            onTap: enabled
                ? () {
                    HapticFeedback.selectionClick();
                    onTap();
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: _logoWidth,
                    height: _logoHeight,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: !isDark
                          ? const Color(0xFFF1F4F9)
                          : (_brandLogoFor(paymentType)?.needsLightTile ??
                                  false)
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: _logoContent(isDark),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title.isNotEmpty)
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodyMedium?.copyWith(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        if (caption != null && caption.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            caption,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodySmall?.copyWith(
                              fontSize: 13,
                              height: 1.25,
                              fontWeight: FontWeight.w500,
                              color: BookingFormStyle.label(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _RadioIndicator(selected: isSelected),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return enabled ? tile : Opacity(opacity: 0.45, child: tile);
  }

  _BrandLogo? _brandLogoFor(PaymentType type) {
    final id = type.id.trim().toUpperCase();
    final direct = _brandLogos[id];
    if (direct != null) return direct;
    final base = PaymentConstants.paymentTypeByName(id);
    if (base == null) return null;
    return _brandLogos[base.id];
  }

  Widget _logoContent(bool isDark) {
    // Logotip tanlov holatiga bog'liq emas — faqat theme (light/dark).
    final local = _brandLogoFor(paymentType);
    if (local != null) {
      final asset = isDark ? local.dark : local.light;
      return Image.asset(
        asset,
        key: ValueKey('$asset-$isDark'),
        height: _logoHeight,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => _fallbackIcon(isDark),
      );
    }

    if (paymentType.imageUrl != null && paymentType.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        cacheManager: AppCacheManager.instance,
        cacheKey: paymentType.imageUrl,
        imageUrl: paymentType.imageUrl!,
        height: _logoHeight,
        fit: BoxFit.contain,
        memCacheHeight: 256,
        errorWidget: (_, __, ___) => _fallbackIcon(isDark),
      );
    }

    if (paymentType.secondaryImagePath != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(paymentType.imagePath, height: 24),
          const SizedBox(width: 6),
          Image.asset(paymentType.secondaryImagePath!, height: 24),
        ],
      );
    }

    if (paymentType.imagePath.isNotEmpty) {
      return Image.asset(
        paymentType.imagePath,
        height: _logoHeight,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => _fallbackIcon(isDark),
      );
    }

    return _fallbackIcon(isDark);
  }

  Widget _fallbackIcon(bool isDark) => Icon(
        Icons.credit_card_rounded,
        color: isDark ? Colors.white70 : const Color(0xFF8E8E92),
        size: 24,
      );
}

class _RadioIndicator extends StatelessWidget {
  final bool selected;

  const _RadioIndicator({required this.selected});

  @override
  Widget build(BuildContext context) {
    final brand = ProjectTheme.brandColor;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? brand : Colors.transparent,
        border: Border.all(
          color: selected
              ? brand
              : (context.isDarkMode
                  ? const Color(0xFF5B5B5B)
                  : const Color(0xFFC9CFD9)),
          width: 1.5,
        ),
      ),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: selected ? 1 : 0,
        child: Container(
          width: 9,
          height: 9,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodSkeleton extends StatelessWidget {
  const _PaymentMethodSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    Widget bar(double width, double height, double radius) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
          ),
        );

    return BookingCard(
      padding: const EdgeInsets.fromLTRB(
        12 + PaymentMethodTile._borderWidth,
        12 + PaymentMethodTile._borderWidth,
        16 + PaymentMethodTile._borderWidth,
        12 + PaymentMethodTile._borderWidth,
      ),
      child: Shimmer.fromColors(
        baseColor: isDark ? Colors.white12 : const Color(0xFFE9EDF3),
        highlightColor: isDark ? Colors.white24 : const Color(0xFFF7F9FC),
        child: Row(
          children: [
            bar(PaymentMethodTile._logoWidth, PaymentMethodTile._logoHeight,
                13),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(120, 15, 6),
                  const SizedBox(height: 7),
                  bar(80, 12, 6),
                ],
              ),
            ),
            const SizedBox(width: 12),
            bar(24, 24, 12),
          ],
        ),
      ),
    );
  }
}
