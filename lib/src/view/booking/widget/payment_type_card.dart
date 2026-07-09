import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/tools/app_cache_manager.dart';
import 'package:mysafar_sdk/src/model/local/payment_type.dart';


class PaymentTypeEntry {
  final PaymentType type;
  final bool isActive;

  const PaymentTypeEntry({required this.type, required this.isActive});
}

class PaymentTypeCard extends StatelessWidget {
  /// Barcha kartalar bir xil balandlikda bo'lishi uchun qat'iy balandlik
  /// (title bor/yo'qligidan qat'i nazar). Eng baland kontent (logo + title +
  /// subtitle) uchun yetarli, headroom bilan.
  static const double _cardHeight = 112;

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
    final isDark = context.themeProvider.isDark;
    final bgColor = isDark ? const Color(0xff1E1E1E) : Colors.white;
    final borderColor = isSelected
        ? const Color(0xff0057BE)
        : (isDark ? const Color(0xff3A3A3A) : const Color(0xffEAEBEE));


    // Title (cardName) bo'lmasa — logo va matn markazda; bo'lsa chapdan.
    final title = paymentType.cardName?.trim() ?? '';
    final isCenteredLayout = title.isEmpty;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: (context.width - 48) / 2,
        height: _cardHeight,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 30: 4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: isCenteredLayout
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
             mainAxisAlignment: isCenteredLayout
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                _buildLogoArea(context, isCenteredLayout),
                if (title.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    title,
                    maxLines: 1,
                    textAlign:
                        isCenteredLayout ? TextAlign.center : TextAlign.start,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
                if (paymentType.subtitle != null) ...[
                  SizedBox(height: title.isNotEmpty ? 2 : 12),
                  Text(
                    paymentType.subtitle!,
                    maxLines: 1,
                    textAlign: isCenteredLayout ? TextAlign.center : TextAlign.start,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: const Color(0xff8E8E92),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            Positioned(
              top: -4,
              right: -4,
              child: isSelected
                  ? const Icon(Icons.check_circle,
                      color: Color(0xff0057BE), size: 24)
                  : const Icon(Icons.chevron_right,
                      color: Color(0xffD0D5DD), size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoArea(BuildContext context, bool isCentered) {
    final isDark = context.themeProvider.isDark;
    final logo = _logoContent(isCentered);

    // Dark mode'da ko'p logotiplarning matn/qismi to'q rangda bo'lgani uchun
    // qorong'i karta foni ustida ko'rinmay qoladi. Shuning uchun dark mode'da
    // logo oq "chip" fon ustiga qo'yiladi — brend ranglari saqlanadi va logo
    // har doim aniq ko'rinadi.
    final decorated = isDark
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: logo,
          )
        : logo;

    return SizedBox(
      height: isDark ? 40 : 36,
      child: Align(
        alignment: isCentered ? Alignment.center : Alignment.centerLeft,
        child: decorated,
      ),
    );
  }

  Widget _logoContent(bool isCentered) {
    if (paymentType.imageUrl != null && paymentType.imageUrl!.isNotEmpty) {
      // Firebase'dan kelgan logo disk + xotirada keshlanadi (AppCacheManager) —
      // shu bilan har safar qayta yuklanmaydi.
      return CachedNetworkImage(
        cacheManager: AppCacheManager.instance,
        cacheKey: paymentType.imageUrl,
        imageUrl: paymentType.imageUrl!,
        height: 32,
        fit: BoxFit.contain,
        memCacheHeight: 128,
        errorWidget: (_, __, ___) => _assetLogo(isCentered),
      );
    }

    if (paymentType.secondaryImagePath != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(paymentType.imagePath, height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              width: 1.2,
              height: 24,
              color: const Color(0xffEAEBEE),
            ),
          ),
          Image.asset(paymentType.secondaryImagePath!, height: 32),
        ],
      );
    }

    return _assetLogo(isCentered);
  }

  Widget _assetLogo(bool isCentered) {
    return Image.asset(
      paymentType.imagePath,
      height: 32,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(Icons.credit_card, size: 32),
    );
  }
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

