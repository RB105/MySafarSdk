part of 'destination_details_page.dart';

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.textTheme.displayLarge
          ?.copyWith(fontWeight: FontWeight.w800, fontSize: 21),
    );
  }
}

/// 2×2 tezkor ma'lumot kartalari (web'dagi kabi).
class _QuickInfoGrid extends StatelessWidget {
  final DestinationDetailModel detail;
  final String Function(DestLocalizedText) lt;

  const _QuickInfoGrid({required this.detail, required this.lt});

  @override
  Widget build(BuildContext context) {
    final q = detail.quickInfo;
    if (q == null) return const SizedBox.shrink();

    final items = <(IconData, String, String)>[
      if (q.flightDuration.isNotEmpty)
        (Icons.schedule_rounded, "dest_flight_duration".tr(), q.flightDuration),
      if (!q.bestSeason.isEmpty)
        (
          Icons.calendar_month_rounded,
          "dest_best_season".tr(),
          lt(q.bestSeason)
        ),
      if (!q.recommendedDuration.isEmpty)
        (
          Icons.place_outlined,
          "dest_recommended_duration".tr(),
          lt(q.recommendedDuration)
        ),
      if (!q.visaRequirement.isEmpty)
        (Icons.verified_user_outlined, "dest_visa".tr(), lt(q.visaRequirement)),
    ];
    if (items.isEmpty) return const SizedBox.shrink();

    Widget card((IconData, String, String) item) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.color.primaryContainer,
            borderRadius: BorderRadius.circular(16),
            boxShadow: context.shadowDown,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.$1, size: 20, color: ProjectTheme.brandColor),
              const SizedBox(height: 8),
              Text(item.$2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.headlineSmall
                      ?.copyWith(fontSize: 12.5)),
              const SizedBox(height: 3),
              Text(item.$3,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700, fontSize: 13.5)),
            ],
          ),
        );

    return Column(
      children: [
        for (int i = 0; i < items.length; i += 2)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
            // Balandligi cheklanmagan (sliver) kontekstda `stretch` to'g'ridan-
            // to'g'ri ishlatilsa cheksiz balandlik xatosi beradi — IntrinsicHeight
            // qatorni eng baland karta bo'yicha cheklab beradi.
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: card(items[i])),
                  const SizedBox(width: 12),
                  Expanded(
                    child: i + 1 < items.length
                        ? card(items[i + 1])
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// "Viza haqida" och ko'k eslatma qutisi.
class _VisaNoteBox extends StatelessWidget {
  final String text;
  const _VisaNoteBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ProjectTheme.brandColor.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_outlined,
                  size: 16, color: ProjectTheme.brandColor),
              const SizedBox(width: 6),
              Text(
                "dest_visa_about".tr(),
                style: TextStyle(
                  color: ProjectTheme.brandColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: context.textTheme.bodyMedium
                ?.copyWith(height: 1.5, fontSize: 13.5),
          ),
        ],
      ),
    );
  }
}

/// Diqqatga sazovor joy kartasi: rasm (yoki emoji) + nom + tavsif.
/// [onTap] null bo'lsa (`detail` bo'sh) bosib ochilmaydi.
class _AttractionCard extends StatelessWidget {
  final String icon;
  final String imageUrl;
  final String name;
  final String description;
  final VoidCallback? onTap;

  const _AttractionCard({
    required this.icon,
    required this.name,
    required this.description,
    this.imageUrl = '',
  }) : onTap = null;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.color.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.shadowDown,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _thumb(context),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: context.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: context.textTheme.headlineSmall
                      ?.copyWith(fontSize: 13, height: 1.45),
                ),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                size: 22, color: context.color.outline),
          ],
        ],
      ),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      ),
    );
  }

  /// detail.hero.image yoki gallery photo; bo'lmasa emoji.
  Widget _thumb(BuildContext context) {
    const double size = 56;
    if (imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          cacheManager: AppCacheManager.instance,
          imageUrl: imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: size,
            height: size,
            color: ProjectTheme.brandColor.withAlpha(14),
          ),
          errorWidget: (_, __, ___) => _emojiThumb(size),
        ),
      );
    }
    return _emojiThumb(size);
  }

  Widget _emojiThumb(double size) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ProjectTheme.brandColor.withAlpha(14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        icon.isNotEmpty ? icon : '📍',
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}

/// 2 ustunli galereya. GridView+shrinkWrap sliver ichida ortiqcha
/// bo'sh joy qoldirishi mumkin — Wrap + aniq kenglik/balandlik ishonchliroq.
class _GalleryGrid extends StatelessWidget {
  final List<String> images;
  const _GalleryGrid({required this.images});

  static const double _gap = 10;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double cellW = (constraints.maxWidth - _gap) / 2;
        // Webdagi ~1.35 aspect — balandlik aniq hisoblanadi, ortiqcha joy yo'q.
        final double cellH = cellW / 1.35;
        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (final url in images)
              if (url.trim().isNotEmpty)
                SizedBox(
                  width: cellW,
                  height: cellH,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(
                      cacheManager: AppCacheManager.instance,
                      imageUrl: url,
                      fit: BoxFit.cover,
                      width: cellW,
                      height: cellH,
                      placeholder: (_, __) =>
                          Container(color: const Color(0x14202A44)),
                      errorWidget: (_, __, ___) =>
                          Container(color: const Color(0x14202A44)),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

/// Narxni "narxi 2 505 529 UZSdan" ko'rinishida quruvchi umumiy yordamchi.
Widget _priceFromLine(
  BuildContext context, {
  required int amount,
  required AppCurrency currency,
  required Color boldColor,
  required Color greyColor,
  double fontSize = 20,
}) {
  final parts =
      "home_price_from".tr(namedArgs: {"price": "\u0001"}).split('\u0001');
  final prefix = parts.isNotEmpty ? parts.first : '';
  final suffix = parts.length > 1 ? parts.last : '';
  final grey = TextStyle(
      color: greyColor, fontSize: fontSize * 0.68, fontWeight: FontWeight.w500);

  return Text.rich(
    TextSpan(children: [
      TextSpan(text: "${"home_price_label".tr()} ", style: grey),
      if (prefix.isNotEmpty) TextSpan(text: prefix, style: grey),
      TextSpan(
        text: ElementFormatter.formatNumberWithSpaces(amount),
        style: TextStyle(
            color: boldColor, fontSize: fontSize, fontWeight: FontWeight.w800),
      ),
      TextSpan(text: ' ${currency.label}$suffix', style: grey),
    ]),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}

/// Ko'k gradientli "Arzon aviachiptalar" CTA kartasi (web'dagi kabi).
