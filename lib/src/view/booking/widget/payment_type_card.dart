import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/model/local/payment_type.dart';


class PaymentTypeEntry {
  final PaymentType type;
  final bool isActive;

  const PaymentTypeEntry({required this.type, required this.isActive});
}

class PaymentTypeCard extends StatelessWidget {
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


    final isCenteredLayout = paymentType.id == PaymentConstants.mysafarpay;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: (context.width - 48) / 2,
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
          children: [
            Column(
              crossAxisAlignment: isCenteredLayout
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLogoArea(context, isCenteredLayout),
                const SizedBox(height: 12),
                Text(
                  paymentType.cardName ?? '',
                  maxLines: 1,
                  textAlign: isCenteredLayout ? TextAlign.center : TextAlign.start,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                if (paymentType.subtitle != null) ...[
                  const SizedBox(height: 2),
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
    if (paymentType.imageUrl != null && paymentType.imageUrl!.isNotEmpty) {
      return Container(
        height: 36,
        alignment: isCentered ? Alignment.center : Alignment.centerLeft,
        child: Image.network(
          paymentType.imageUrl!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _assetLogo(isCentered),
        ),
      );
    }

    if (paymentType.secondaryImagePath != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment:
            isCentered ? MainAxisAlignment.center : MainAxisAlignment.start,
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

    return Container(
      height: 36,
      alignment: isCentered ? Alignment.center : Alignment.centerLeft,
      child: _assetLogo(isCentered),
    );
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

