part of 'destination_details_page.dart';

class _AviaCtaCard extends StatelessWidget {
  final DestinationDetailModel detail;
  final String Function(DestLocalizedText) lt;
  final int Function(AppCurrency) priceOf;
  final VoidCallback onSearch;

  const _AviaCtaCard({
    required this.detail,
    required this.lt,
    required this.priceOf,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final avia = detail.aviaBlock;
    final currency = Provider.of<CurrencyProvider>(context).currency;
    final price = priceOf(currency);
    final route = avia != null && avia.fromIata.isNotEmpty
        ? "${avia.fromIata} → ${avia.toIata}"
        : "TAS → ${detail.airportCode}";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2F6BFF), Color(0xFF16244A)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flight_takeoff_rounded,
                  size: 16, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                route,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "dest_cheap_flights".tr(),
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
          ),
          if (avia != null && !avia.description.isEmpty) ...[
            const SizedBox(height: 6),
            Text(
              lt(avia.description),
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13.5, height: 1.45),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onSearch,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "dest_search_tickets".tr(),
                          style: TextStyle(
                              color: ProjectTheme.brandColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded,
                            size: 16, color: ProjectTheme.brandColor),
                      ],
                    ),
                  ),
                ),
              ),
              if (price > 0)
                _priceFromLine(
                  context,
                  amount: price,
                  currency: currency,
                  boldColor: Colors.white,
                  greyColor: Colors.white70,
                  fontSize: 17,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Narx kartasi (web'dagi mobil sidebar): narx + asosiy faktlar + tugma.
class _PriceCard extends StatelessWidget {
  final DestinationDetailModel detail;
  final String Function(DestLocalizedText) lt;
  final int Function(AppCurrency) priceOf;
  final VoidCallback onSearch;

  const _PriceCard({
    required this.detail,
    required this.lt,
    required this.priceOf,
    required this.onSearch,
  });

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style:
                    context.textTheme.headlineSmall?.copyWith(fontSize: 13.5)),
          ),
          const SizedBox(width: 12),
          Text(value,
              style: context.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700, fontSize: 13.5)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = Provider.of<CurrencyProvider>(context).currency;
    final price = priceOf(currency);
    final hero = detail.hero;
    final q = detail.quickInfo;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.color.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: context.shadowDown,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("dest_price_title".tr(),
              style: context.textTheme.headlineSmall?.copyWith(fontSize: 13)),
          const SizedBox(height: 4),
          if (price > 0)
            _priceFromLine(
              context,
              amount: price,
              currency: currency,
              boldColor: context.textTheme.bodyMedium?.color ??
                  const Color(0xFF16244A),
              greyColor: context.textTheme.headlineSmall?.color ??
                  const Color(0xFF8E99B5),
              fontSize: 22,
            ),
          const SizedBox(height: 10),
          Divider(height: 1, thickness: 1, color: ProjectTheme.borderLight),
          const SizedBox(height: 6),
          if (detail.airportCode.isNotEmpty)
            _row(context, "dest_airport".tr(), detail.airportCode),
          if (hero != null && hero.rating > 0)
            _row(context, "★", hero.rating.toStringAsFixed(1)),
          if (q != null && q.flightDuration.isNotEmpty)
            _row(context, "dest_flight_duration".tr(), q.flightDuration),
          if (q != null && !q.bestSeason.isEmpty)
            _row(context, "dest_best_season".tr(), lt(q.bestSeason)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ProjectTheme.blueButtonStyle,
              onPressed: onSearch,
              child: Text(
                "dest_search_tickets".tr(),
                style: context.textTheme.bodyMedium?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kontakt kartasi: xabar + telefon + telegram (bosilganda ochiladi).
class _ContactCard extends StatelessWidget {
  final DestinationContact contact;
  final String Function(DestLocalizedText) lt;
  final void Function(String uri) onOpen;

  const _ContactCard({
    required this.contact,
    required this.lt,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final String telegramHandle = contact.telegram.replaceAll('@', '');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.color.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: context.shadowDown,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!contact.message.isEmpty)
            Text(
              lt(contact.message),
              style: context.textTheme.headlineSmall
                  ?.copyWith(fontSize: 13.5, height: 1.45),
            ),
          const SizedBox(height: 10),
          if (contact.phone.isNotEmpty)
            InkWell(
              onTap: () => onOpen("tel:${contact.phone.replaceAll(' ', '')}"),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.phone_rounded,
                        size: 17, color: ProjectTheme.brandColor),
                    const SizedBox(width: 8),
                    Text(
                      contact.phone,
                      style: context.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          if (telegramHandle.isNotEmpty)
            InkWell(
              onTap: () => onOpen("https://t.me/$telegramHandle"),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.send_rounded,
                        size: 17, color: ProjectTheme.brandColor),
                    const SizedBox(width: 8),
                    Text(
                      contact.telegram,
                      style: context.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
