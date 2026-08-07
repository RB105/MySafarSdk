import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/styles/theme_notifier.dart';
import 'package:mysafar_sdk/src/core/tools/app_cache_manager.dart';
import 'package:mysafar_sdk/src/core/tools/project_assets.dart';
import 'package:mysafar_sdk/src/model/local/payment_type.dart';


class PaymentTypeEntry {
  final PaymentType type;
  final bool isActive;

  const PaymentTypeEntry({required this.type, required this.isActive});
}

class _BrandLogo {
  final String light;
  final String dark;
  final double height;

  const _BrandLogo({
    required this.light,
    required this.dark,
    this.height = 24,
  });
}

class PaymentTypeCard extends StatelessWidget {
  static const double _cardHeight = 90;
  static const Color _brand = Color(0xFF0057BE);

  static const Map<String, _BrandLogo> _brandLogos = {
    PaymentConstants.mysafarpay: _BrandLogo(
      light: ProjectAssets.bookingLocalLight,
      dark: ProjectAssets.bookingLocalDark,
    ),
    PaymentConstants.payme: _BrandLogo(
      light: ProjectAssets.bookingPaymeLight,
      dark: ProjectAssets.bookingPaymeDark,
      height: 22,
    ),
    PaymentConstants.paygine: _BrandLogo(
      light: ProjectAssets.bookingSbpLight,
      dark: ProjectAssets.bookingSbp,
      height: 26,
    ),
    PaymentConstants.click: _BrandLogo(
      light: ProjectAssets.bookingClickLight,
      dark: ProjectAssets.bookingClickDark,
      height: 22,
    ),
    PaymentConstants.visa: _BrandLogo(
      light: ProjectAssets.bookingVisaLight,
      dark: ProjectAssets.bookingVisaLight,
      height: 20,
    ),
  };

  final PaymentType paymentType;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  const PaymentTypeCard({
    super.key,
    required this.paymentType,
    required this.isSelected,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // ThemeNotifier + MaterialApp temasi birga yangilansin (light: oq karta, dark: kulrang).
    return Consumer<ThemeNotifier>(
      builder: (context, _, __) => _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rawTitle = (paymentType.cardName?.trim() ?? '').tr();
    final subtitle = paymentType.subtitle?.trim().tr();
    final primary = rawTitle.isNotEmpty ? rawTitle : (subtitle ?? '');
    final secondary = rawTitle.isNotEmpty ? subtitle : null;
    final primaryColor = isDark ? Colors.white : const Color(0xFF1C1C1C);
    final secondaryColor =
        isDark ? const Color(0xFF9A9DA3) : const Color(0xFF8E8E92);

    final card = InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: (context.width - 48) / 2,
        height: _cardHeight,
        padding: const EdgeInsets.all(12),
        decoration: _cardDecoration(isDark),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ClipRect(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  SizedBox(
                    height: 24,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: _logoContent(isDark),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (primary.isNotEmpty)
                    Text(
                      primary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        height: 1.0,
                        color: primaryColor,
                      ),
                    ),
                  if (secondary != null && secondary.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        secondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: secondaryColor,
                          fontSize: 11,
                          height: 1.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
                ),
              ),
            ),
            Positioned(
              top: -2,
              right: -2,
              child: _buildSelectionBadge(isDark),
            ),
          ],
        ),
      ),
    );

    return enabled ? card : Opacity(opacity: 0.45, child: card);
  }

  BoxDecoration _cardDecoration(bool isDark) {
    final baseCard = isDark ? const Color(0xFF242426) : Colors.white;
    return BoxDecoration(
      color: isSelected
          ? Color.alphaBlend(_brand.withAlpha(isDark ? 34 : 14), baseCard)
          : baseCard,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: isSelected
            ? _brand
            : (isDark ? const Color(0xFF38383A) : const Color(0xFFEAEBEE)),
        width: isSelected ? 1.5 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(isDark ? 40 : 8),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Widget _buildSelectionBadge(bool isDark) {
    if (isSelected) {
      return Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: _brand,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 13),
      );
    }
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? const Color(0xFF4A4A4C) : const Color(0xFFD0D5DD),
          width: 1.5,
        ),
      ),
    );
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
        height: local.height,
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
        height: 24,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Container(
              width: 1.2,
              height: 18,
              color: isDark ? const Color(0xFF4A4A4C) : const Color(0xFFEAEBEE),
            ),
          ),
          Image.asset(paymentType.secondaryImagePath!, height: 24),
        ],
      );
    }

    if (paymentType.imagePath.isNotEmpty) {
      return Image.asset(
        paymentType.imagePath,
        height: 32,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => _fallbackIcon(isDark),
      );
    }

    return _fallbackIcon(isDark);
  }

  Widget _fallbackIcon(bool isDark) => Icon(
        Icons.credit_card,
        color: isDark ? Colors.white70 : const Color(0xFF8E8E92),
        size: 24,
      );
}

class PaymentTypesGrid extends StatelessWidget {
  final List<PaymentTypeEntry> items;
  final String? selectedType;
  final ValueChanged<String> onTypeSelected;
  final bool isLoading;

  const PaymentTypesGrid({
    super.key,
    required this.items,
    required this.selectedType,
    required this.onTypeSelected,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((entry) {
        return PaymentTypeCard(
          paymentType: entry.type,
          isSelected: selectedType == entry.type.id,
          enabled: entry.isActive,
          onTap: () => onTypeSelected(entry.type.id),
        );
      }).toList(),
    );
  }
}

