// ignore_for_file: unused_element
// part of ticket_info_page.dart

part of 'ticket_info_page.dart';

/// Tafsilot sheet'i uchun umumiy sokin ranglar (bron sahifasi bilan bir xil).
Color _tiMuted(BuildContext context) => context.isDarkMode
    ? ProjectTheme.secondaryTextDark
    : const Color(0xFF5B6475);

Color _tiTonal(BuildContext context) => context.isDarkMode
    ? Colors.white.withValues(alpha: 0.06)
    : const Color(0xFFF1F4F9);

Color _tiText(BuildContext context) => context.isDarkMode
    ? ProjectTheme.textColorDark
    : ProjectTheme.textColorLight;

/// Oddiy oq karta — soyasiz, radius 20.
class _TiCard extends StatelessWidget {
  final Widget child;

  const _TiCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.color.primaryContainer,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// "Tarif qoidalari": joylar, qo'l yuki, bagaj, qaytarish, almashtirish —
/// ikki ustunli sokin ro'yxat. Narx bu yerda takrorlanmaydi (pastdagi
/// tugmada bor). Ostida (bo'lsa) "Boshqa tarifni tanlash" qatori.
class _FareRulesCard extends StatelessWidget {
  final int seatCount;
  final bool withCBaggage;
  final String? cBaggage;
  final bool isRefund;
  final bool isBaggage;
  final String baggageLabel;
  final bool isExchangeable;
  final Widget tariffSection;

  const _FareRulesCard({
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
    final rules = <(String, String, bool)>[
      (
        Assets.ticketsSeatIcon,
        "seat_count".tr(namedArgs: {"count": "$seatCount"}),
        true,
      ),
      (
        withCBaggage
            ? Assets.ticketsLuggageIcon
            : Assets.ticketsLuggageNegativeIcon,
        withCBaggage
            ? "luggage_size".tr(namedArgs: {"count": cBaggage ?? ""})
            : "no_luggage".tr(),
        withCBaggage,
      ),
      (
        isBaggage
            ? Assets.ticketsBaggagePositiveIcon
            : Assets.ticketsBaggageNegativeIcon,
        baggageLabel,
        isBaggage,
      ),
      (
        isRefund ? Assets.ticketsReturnSuccessIcon : Assets.ticketsReturnIcon,
        isRefund ? "refundable".tr() : "unrefundable".tr(),
        isRefund,
      ),
      (
        isExchangeable
            ? Assets.ticketsReplaceGreenIcon
            : Assets.ticketsReplaceRedIcon,
        isExchangeable ? "exchangeable".tr() : "unexchangeable".tr(),
        isExchangeable,
      ),
    ];

    return _TiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              "filter_tariff_title".tr(),
              style: context.textTheme.bodyLarge
                  ?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const gap = 12.0;
                final itemWidth = (constraints.maxWidth - gap) / 2;
                return Wrap(
                  spacing: gap,
                  children: [
                    for (final (icon, label, positive) in rules)
                      SizedBox(
                        width: itemWidth,
                        child: _FareRuleItem(
                          iconAsset: icon,
                          label: label,
                          positive: positive,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          tariffSection,
        ],
      ),
    );
  }
}

class _FareRuleItem extends StatelessWidget {
  final String iconAsset;
  final String label;
  final bool positive;

  const _FareRuleItem({
    required this.iconAsset,
    required this.label,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: SvgPicture.asset(iconAsset),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium?.copyWith(
                fontSize: 13.5,
                height: 1.3,
                fontWeight: FontWeight.w600,
                // Salbiy shart ham o'qiladi, lekin e'tiborni tortmaydi —
                // rang ma'nosini ikonka beradi.
                color: positive ? _tiText(context) : _tiMuted(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartaning pastki qatori — "Boshqa tarifni tanlash" ›.
class _TariffPickerTile extends StatelessWidget {
  final VoidCallback onTap;

  const _TariffPickerTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final Color accent = isDark ? Colors.white : ProjectTheme.brandColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(
          height: 1,
          thickness: 1,
          indent: 16,
          endIndent: 16,
          color: context.color.outline.withValues(alpha: 0.6),
        ),
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "choose_other_tariff".tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                ),
                SvgPicture.asset(
                  Assets.iconsBookingChevronRightIcon,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Tariflar yuklanayotganda karta ostidagi ixcham shimmer qator.
class _TariffPickerSkeleton extends StatelessWidget {
  const _TariffPickerSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Shimmer.fromColors(
        baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
        child: Container(
          height: 20,
          margin: const EdgeInsets.only(right: 140),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}
