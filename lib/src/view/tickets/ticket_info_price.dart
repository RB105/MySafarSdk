// ignore_for_file: unused_element
// part of ticket_info_page.dart

part of 'ticket_info_page.dart';

class _PriceFeatureCard extends StatelessWidget {
  final String priceLabel;
  final int seatCount;
  final bool withCBaggage;
  final String? cBaggage;
  final bool isRefund;
  final bool isBaggage;
  final String baggageLabel;
  final bool isExchangeable;
  final Widget tariffSection;

  const _PriceFeatureCard({
    required this.priceLabel,
    required this.seatCount,
    required this.withCBaggage,
    required this.cBaggage,
    required this.isRefund,
    required this.isBaggage,
    required this.baggageLabel,
    required this.isExchangeable,
    required this.tariffSection,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final brand = ProjectTheme.brandColor;
    final secondaryColor = isDark
        ? ProjectTheme.secondaryTextDark
        : ProjectTheme.secondaryTextLight;
    final dividerColor =
        isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(14);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.color.primaryContainer,
          borderRadius: BorderRadius.circular(22),
          boxShadow: context.shadowDown,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Price hero
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [brand, ProjectTheme.blueBg],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.confirmation_number_outlined,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "total_price".tr(),
                          style: context.textTheme.bodySmall?.copyWith(
                            color: secondaryColor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            priceLabel,
                            style: context.textTheme.displayMedium?.copyWith(
                              color: brand,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(height: 1, color: dividerColor),
              const SizedBox(height: 14),
              // Feature pills
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FeaturePill(
                    assetPath: Assets.ticketsSeatIcon,
                    label:
                        "seat_count".tr(namedArgs: {"count": "$seatCount"}),
                    accent: ProjectTheme.success,
                    isDark: isDark,
                  ),
                  _FeaturePill(
                    assetPath: withCBaggage
                        ? Assets.ticketsLuggageIcon
                        : Assets.ticketsLuggageNegativeIcon,
                    label: withCBaggage
                        ? "luggage_size".tr(namedArgs: {"count": cBaggage ?? ""})
                        : "no_luggage".tr(),
                    accent:
                        withCBaggage ? ProjectTheme.success : ProjectTheme.error,
                    isDark: isDark,
                  ),
                  _FeaturePill(
                    assetPath: isBaggage
                        ? Assets.ticketsBaggagePositiveIcon
                        : Assets.ticketsBaggageNegativeIcon,
                    label: baggageLabel,
                    accent:
                        isBaggage ? ProjectTheme.success : ProjectTheme.error,
                    isDark: isDark,
                  ),
                  _FeaturePill(
                    assetPath: isRefund
                        ? Assets.ticketsReturnSuccessIcon
                        : Assets.ticketsReturnIcon,
                    label: isRefund ? "refundable".tr() : "unrefundable".tr(),
                    accent: isRefund ? ProjectTheme.success : ProjectTheme.error,
                    isDark: isDark,
                  ),
                  _FeaturePill(
                    assetPath: isExchangeable
                        ? Assets.ticketsReplaceGreenIcon
                        : Assets.ticketsReplaceRedIcon,
                    label: isExchangeable
                        ? "exchangeable".tr()
                        : "unexchangeable".tr(),
                    accent: isExchangeable
                        ? ProjectTheme.success
                        : ProjectTheme.error,
                    isDark: isDark,
                  ),
                ],
              ),
              tariffSection,
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final String assetPath;
  final String label;
  final Color accent;
  final bool isDark;

  const _FeaturePill({
    required this.assetPath,
    required this.label,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? accent.withAlpha(45) : accent.withAlpha(22);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: SvgPicture.asset(assetPath),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _TariffPickerTile extends StatelessWidget {
  final VoidCallback onTap;

  const _TariffPickerTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final brand =
        isDark ? ProjectTheme.accentLight : ProjectTheme.brandColor;
    final bg = isDark ? brand.withAlpha(38) : brand.withAlpha(22);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: brand.withAlpha(isDark ? 80 : 45),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.style_outlined, color: brand, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "choose_other_tariff".tr(),
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: brand,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: brand, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  FLIGHT DIRECTION — BOARDING-PASS CARD + VERTICAL TIMELINE
// ════════════════════════════════════════════════════════════════════

