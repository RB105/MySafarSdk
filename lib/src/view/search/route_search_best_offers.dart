// ignore_for_file: deprecated_member_use
// part of route_search_page.dart — "Eng yaxshi takliflar" bo'limi

part of 'route_search_page.dart';

/// "Eng yaxshi takliflar" — mysafar.uz mobil ko'rinishidagi gorizontal
/// taklif kartalari. Ma'lumot: oylik kalendardagi eng arzon kunga yuborilgan
/// qidiruv natijalari (cubit'da yuklanadi).
class _BestOffersSection extends StatelessWidget {
  final List<FlightElement> offers;
  final bool loading;
  final DateTime? date;
  final ValueChanged<FlightElement> onTap;

  const _BestOffersSection({
    required this.offers,
    required this.loading,
    required this.date,
    required this.onTap,
  });

  static const double _cardHeight = 152;

  @override
  Widget build(BuildContext context) {
    if (!loading && offers.isEmpty) return const SizedBox.shrink();

    final double cardWidth = MediaQuery.of(context).size.width * 0.79;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _WebSectionTitle("best_offers_title".tr()),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: _cardHeight,
          child: loading
              ? _OffersShimmer(cardWidth: cardWidth)
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: offers.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) => SizedBox(
                    width: cardWidth,
                    child: _OfferCard(
                      flight: offers[i],
                      cheapest: i == 0,
                      date: date,
                      onTap: () => onTap(offers[i]),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Bitta taklif kartasi.
class _OfferCard extends StatelessWidget {
  final FlightElement flight;
  final bool cheapest;
  final DateTime? date;
  final VoidCallback onTap;

  const _OfferCard({
    required this.flight,
    required this.cheapest,
    required this.date,
    required this.onTap,
  });

  List<FlightSegment> get _segments =>
      (flight.segments ?? const <FlightSegment>[])
          .where((s) => s.direction == 0)
          .toList();

  String _priceText(AppCurrency currency) {
    final p = flight.price;
    final String? raw = switch (currency) {
      AppCurrency.uzs => p?.uzs?.amount,
      AppCurrency.rub => p?.rub?.amount,
      AppCurrency.usd => p?.usd?.amount,
    };
    final v = double.tryParse(raw ?? '');
    if (v == null) return '—';
    return ElementFormatter.formatNumberWithSpaces(v);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = Provider.of<CurrencyProvider>(context).currency;
    final segs = _segments;
    if (segs.isEmpty) return const SizedBox.shrink();

    final dep = segs.first.dep;
    final arr = segs.last.arr;
    final int transfers = flight.getTransferCount(0);

    return Material(
      color: isDark ? ProjectTheme.cardColorDark : Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: cheapest
              ? _Web.switchOn
              : (isDark ? ProjectTheme.borderDark : const Color(0xFFE7EDF6)),
          width: cheapest ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _badgeRow(context, isDark, dep),
              const SizedBox(height: 10),
              _timesRow(context, isDark, dep, arr, transfers),
              const Spacer(),
              _footer(context, isDark, currency),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badgeRow(BuildContext context, bool isDark, Arr dep) {
    final String carrierCode =
        (_segments.first.carrier.code).toUpperCase();
    return Row(
      children: [
        Flexible(child: _badge(context, isDark, dep)),
        const SizedBox(width: 8),
        _CarrierLogo(code: carrierCode),
        const SizedBox(width: 6),
        Text(
          date == null
              ? ''
              : "${date!.day} ${ElementFormatter.formatMonth(date!.month).toLowerCase()}",
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF8C99B3),
          ),
        ),
      ],
    );
  }

  Widget _badge(BuildContext context, bool isDark, Arr dep) {
    final int hour = int.tryParse((dep.time ?? '').split(':').first) ?? 12;
    final (String label, Color dot) = cheapest
        ? ("ticket_chip_cheapest".tr(), Colors.white)
        : hour < 6
            ? ("flight_badge_night".tr(), const Color(0xFF6366F1))
            : hour < 12
                ? ("flight_badge_morning".tr(), const Color(0xFFE89400))
                : ("flight_badge_day".tr(), const Color(0xFF0F3DEA));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cheapest
            ? _Web.switchOn
            : (isDark ? Colors.white.withAlpha(20) : const Color(0xFFF4F6FA)),
        borderRadius: BorderRadius.circular(6),
        boxShadow: cheapest
            ? const [
                BoxShadow(
                  color: Color(0x4D15A05A),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                height: 1.2,
                fontWeight: cheapest ? FontWeight.w700 : FontWeight.w600,
                color: cheapest
                    ? Colors.white
                    : (isDark
                        ? ProjectTheme.secondaryTextDark
                        : const Color(0xFF5D6B82)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timesRow(
    BuildContext context,
    bool isDark,
    Arr dep,
    Arr arr,
    int transfers,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _timeColumn(isDark, dep, CrossAxisAlignment.start),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ElementFormatter.formatDuration(flight.getDirDuration(0)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF93A3C4),
                  ),
                ),
                const SizedBox(height: 3),
                _FlightLine(isDark: isDark),
                const SizedBox(height: 3),
                Text(
                  transfers == 0
                      ? "only_direct".tr()
                      : "transfer_count"
                          .tr(namedArgs: {"count": "$transfers"}),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: transfers == 0
                        ? _Web.switchOn
                        : const Color(0xFF93A3C4),
                  ),
                ),
              ],
            ),
          ),
        ),
        _timeColumn(isDark, arr, CrossAxisAlignment.end),
      ],
    );
  }

  Widget _timeColumn(bool isDark, Arr point, CrossAxisAlignment align) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: align,
      children: [
        Text(
          point.time ?? '',
          style: TextStyle(
            fontSize: 19,
            height: 1,
            fontWeight: FontWeight.w700,
            color: isDark ? ProjectTheme.textColorDark : _Web.toggleText,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          point.airport?.code ?? '',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF93A3C4),
          ),
        ),
      ],
    );
  }

  Widget _footer(BuildContext context, bool isDark, AppCurrency currency) {
    return Column(
      children: [
        Divider(
          height: 1,
          thickness: 1,
          color: isDark ? ProjectTheme.borderDark : const Color(0xFFF1F5F9),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: _priceText(currency),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? ProjectTheme.textColorDark
                            : _Web.toggleText,
                      ),
                    ),
                    TextSpan(
                      text: " ${currency.label}",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF93A3C4),
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color:
                    isDark ? _Web.blue.withAlpha(50) : const Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                size: 15,
                color: _Web.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Aviakompaniya logotipi — mahalliy asset, topilmasa umumiy ikonka.
class _CarrierLogo extends StatelessWidget {
  final String code;

  const _CarrierLogo({required this.code});

  @override
  Widget build(BuildContext context) {
    if (code.isEmpty) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.asset(
        'assets/img/tickets/airlines/$code.png',
        width: 18,
        height: 18,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.flight_takeoff_rounded,
          size: 15,
          color: Color(0xFF93A3C4),
        ),
      ),
    );
  }
}

/// Jo'nash va kelish orasidagi chiziq: nuqta — samolyot — nuqta.
class _FlightLine extends StatelessWidget {
  final bool isDark;

  const _FlightLine({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final Color line =
        isDark ? ProjectTheme.borderDark : const Color(0xFFDDE5F2);
    return Row(
      children: [
        _dot(line),
        Expanded(child: Container(height: 1, color: line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Transform.rotate(
            angle: math.pi / 2,
            child: const Icon(Icons.flight_rounded, size: 12, color: _Web.blue),
          ),
        ),
        Expanded(child: Container(height: 1, color: line)),
        _dot(line),
      ],
    );
  }

  Widget _dot(Color c) => Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
}

/// Takliflar yuklanayotgandagi skelet kartalar.
class _OffersShimmer extends StatelessWidget {
  final double cardWidth;

  const _OffersShimmer({required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, __) => Container(
          width: cardWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
