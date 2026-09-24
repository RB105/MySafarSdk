part of 'destination_details_page.dart';

/// Manzil sahifasining ranglari — yangi UI: tekis oq kartalar, yumshoq
/// hairline chiziqlar, xira kulrang yorliqlar va brend rangli tonal plitkalar.
class _DestTheme {
  final bool isDark;
  const _DestTheme(this.isDark);

  factory _DestTheme.of(BuildContext context) => _DestTheme(context.isDarkMode);

  Color get card =>
      isDark ? ProjectTheme.cardColorDark : ProjectTheme.cardColorLight;

  Color get text =>
      isDark ? ProjectTheme.textColorDark : ProjectTheme.textColorLight;

  Color get muted =>
      isDark ? ProjectTheme.secondaryTextDark : const Color(0xFF687290);

  Color get line =>
      isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE8ECF3);

  Color get tonal =>
      isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F4F9);

  Color get brandTonal =>
      ProjectTheme.brandColor.withValues(alpha: isDark ? 0.22 : 0.10);

  List<BoxShadow>? get shadow => isDark
      ? null
      : const [
          BoxShadow(
            color: Color(0x0F202A44),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ];
}

/// Barcha bo'limlar uchun bitta karta qobig'i (radius 20, tekis, soyasi yengil).
class _DestCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _DestCard(
      {required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    final t = _DestTheme.of(context);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: t.shadow,
      ),
      child: child,
    );
  }
}

/// Brend rangli tonal kvadrat ichidagi SVG — kartalardagi barcha ikonkalar
/// shu ko'rinishda (yangi UI).
class _DestIconTile extends StatelessWidget {
  final String asset;
  final double size;
  final double iconSize;

  const _DestIconTile(
    this.asset, {
    this.size = 36,
    this.iconSize = 19,
  });

  @override
  Widget build(BuildContext context) {
    final t = _DestTheme.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.brandTonal,
        borderRadius: BorderRadius.circular(size / 2.8),
      ),
      child: SvgPicture.asset(
        asset,
        width: iconSize,
        height: iconSize,
        colorFilter: ColorFilter.mode(ProjectTheme.brandColor, BlendMode.srcIn),
      ),
    );
  }
}

/// Bo'lim sarlavhasi: kichik ikonka + matn (16.5 w700).
class _SectionTitle extends StatelessWidget {
  final String text;
  final String? icon;

  const _SectionTitle(this.text, {this.icon});

  @override
  Widget build(BuildContext context) {
    final t = _DestTheme.of(context);
    return Row(
      children: [
        if (icon != null) ...[
          _DestIconTile(icon!, size: 30, iconSize: 17),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: "packages/mysafar_sdk/Gilroy",
              color: t.text,
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// Tezkor ma'lumotlar: bitta karta ichida 2 ustunli katak (hairline bilan
/// ajratilgan) — avvalgi 4 ta alohida soyali karta o'rniga.
class _QuickInfoCard extends StatelessWidget {
  final DestinationDetailModel detail;
  final String Function(DestLocalizedText) lt;

  const _QuickInfoCard({required this.detail, required this.lt});

  @override
  Widget build(BuildContext context) {
    final q = detail.quickInfo;
    if (q == null) return const SizedBox.shrink();

    final items = <(String, String, String)>[
      if (q.flightDuration.isNotEmpty)
        (
          Assets.iconsDestDurationIcon,
          "dest_flight_duration".tr(),
          q.flightDuration
        ),
      if (!q.bestSeason.isEmpty)
        (Assets.iconsDestSeasonIcon, "dest_best_season".tr(), lt(q.bestSeason)),
      if (!q.recommendedDuration.isEmpty)
        (
          Assets.iconsDestStayIcon,
          "dest_recommended_duration".tr(),
          lt(q.recommendedDuration)
        ),
      if (!q.visaRequirement.isEmpty)
        (Assets.iconsDestVisaIcon, "dest_visa".tr(), lt(q.visaRequirement)),
    ];
    if (items.isEmpty) return const SizedBox.shrink();

    final t = _DestTheme.of(context);

    Widget cell((String, String, String) item) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DestIconTile(item.$1),
              const SizedBox(height: 10),
              // Ruscha yorliqlar uzun ("Рекомендуемая длительность") —
              // bir qatorga sig'masa ikkinchi qatorga o'tadi.
              Text(
                item.$2,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: "packages/mysafar_sdk/Gilroy",
                  color: t.muted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.$3,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: "packages/mysafar_sdk/Gilroy",
                  color: t.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ],
          ),
        );

    return _DestCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i += 2) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: t.line),
            // Cheksiz balandlikdagi sliver ichida `stretch` ishlamaydi —
            // IntrinsicHeight qatorni eng baland katak bo'yicha cheklaydi.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: cell(items[i])),
                  if (i + 1 < items.length) ...[
                    VerticalDivider(width: 1, thickness: 1, color: t.line),
                    Expanded(child: cell(items[i + 1])),
                  ] else
                    const Expanded(child: SizedBox()),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Shahar haqida" kartasi — matn va (bo'lsa) viza eslatmasi.
class _AboutCard extends StatelessWidget {
  final String description;
  final String visaNote;

  const _AboutCard({required this.description, required this.visaNote});

  @override
  Widget build(BuildContext context) {
    final t = _DestTheme.of(context);
    return _DestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle("dest_about_title".tr(),
              icon: Assets.iconsDestInfoIcon),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontFamily: "packages/mysafar_sdk/Gilroy",
              color: t.text,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.6,
            ),
          ),
          if (visaNote.isNotEmpty) ...[
            const SizedBox(height: 14),
            _VisaNoteBox(text: visaNote),
          ],
        ],
      ),
    );
  }
}

/// "Viza haqida" — brend rangli tonal eslatma qutisi.
class _VisaNoteBox extends StatelessWidget {
  final String text;
  const _VisaNoteBox({required this.text});

  @override
  Widget build(BuildContext context) {
    final t = _DestTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.brandTonal,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                Assets.iconsDestVisaIcon,
                width: 17,
                height: 17,
                colorFilter:
                    ColorFilter.mode(ProjectTheme.brandColor, BlendMode.srcIn),
              ),
              const SizedBox(width: 7),
              Text(
                "dest_visa_about".tr(),
                style: TextStyle(
                  fontFamily: "packages/mysafar_sdk/Gilroy",
                  color: ProjectTheme.brandColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            text,
            style: TextStyle(
              fontFamily: "packages/mysafar_sdk/Gilroy",
              color: t.text,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

/// Diqqatga sazovor joylar — bitta karta ichidagi ro'yxat (hairline bilan).
class _AttractionsCard extends StatelessWidget {
  final List<DestinationAttraction> attractions;
  final String Function(DestLocalizedText) lt;

  const _AttractionsCard({required this.attractions, required this.lt});

  @override
  Widget build(BuildContext context) {
    final t = _DestTheme.of(context);
    return _DestCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (int i = 0; i < attractions.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.only(left: 82),
                child: Divider(height: 1, thickness: 1, color: t.line),
              ),
            _AttractionRow(
              icon: attractions[i].icon,
              imageUrl: attractions[i].previewImage,
              name: lt(attractions[i].name),
              description: lt(attractions[i].description),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bitta joy qatori: rasm (yoki emoji/ikonka) + nom + qisqa tavsif.
class _AttractionRow extends StatelessWidget {
  final String icon;
  final String imageUrl;
  final String name;
  final String description;

  const _AttractionRow({
    required this.icon,
    required this.imageUrl,
    required this.name,
    required this.description,
  });

  static const double _thumb = 54;

  @override
  Widget build(BuildContext context) {
    final t = _DestTheme.of(context);
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildThumb(context),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: "packages/mysafar_sdk/Gilroy",
                    color: t.text,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: "packages/mysafar_sdk/Gilroy",
                      color: t.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumb(BuildContext context) {
    if (imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CachedNetworkImage(
          cacheManager: AppCacheManager.instance,
          imageUrl: imageUrl,
          width: _thumb,
          height: _thumb,
          fit: BoxFit.cover,
          memCacheHeight: coverImageCacheSize(context, _thumb, _thumb).height,
          placeholder: (_, __) => _placeholder(context),
          errorWidget: (_, __, ___) => _placeholder(context),
        ),
      );
    }
    return _placeholder(context);
  }

  /// Rasm bo'lmasa — emoji, u ham bo'lmasa yangi UI ikonkasi.
  Widget _placeholder(BuildContext context) {
    final t = _DestTheme.of(context);
    return Container(
      width: _thumb,
      height: _thumb,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.brandTonal,
        borderRadius: BorderRadius.circular(14),
      ),
      child: icon.isNotEmpty
          ? Text(icon, style: const TextStyle(fontSize: 24))
          : SvgPicture.asset(
              Assets.iconsDestPlaceIcon,
              width: 22,
              height: 22,
              colorFilter:
                  ColorFilter.mode(ProjectTheme.brandColor, BlendMode.srcIn),
            ),
    );
  }
}

/// 2 ustunli galereya. GridView+shrinkWrap sliver ichida ortiqcha bo'sh joy
/// qoldirishi mumkin — Wrap + aniq kenglik/balandlik ishonchliroq.
class _GalleryGrid extends StatelessWidget {
  final List<String> images;
  const _GalleryGrid({required this.images});

  static const double _gap = 10;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();
    final t = _DestTheme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double cellW = (constraints.maxWidth - _gap) / 2;
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
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      cacheManager: AppCacheManager.instance,
                      imageUrl: url,
                      fit: BoxFit.cover,
                      width: cellW,
                      height: cellH,
                      memCacheWidth:
                          coverImageCacheSize(context, cellW, cellH).width,
                      memCacheHeight:
                          coverImageCacheSize(context, cellW, cellH).height,
                      placeholder: (_, __) => Container(color: t.tonal),
                      errorWidget: (_, __, ___) => Container(color: t.tonal),
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
    fontFamily: "packages/mysafar_sdk/Gilroy",
    color: greyColor,
    fontSize: fontSize * 0.68,
    fontWeight: FontWeight.w500,
  );

  return Text.rich(
    TextSpan(children: [
      if (prefix.isNotEmpty) TextSpan(text: prefix, style: grey),
      TextSpan(
        text: ElementFormatter.formatNumberWithSpaces(amount),
        style: TextStyle(
          fontFamily: "packages/mysafar_sdk/Gilroy",
          color: boldColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
        ),
      ),
      TextSpan(text: ' ${currency.label}$suffix', style: grey),
    ]),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}

/// Sahifa boshidagi rasm: gradient, orqaga tugmasi, shahar nomi va yorliqlar.
/// Pastki chekkasi yumaloq — kartalar rasm ustiga "varaq" bo'lib chiqadi.
class _DestHero extends StatelessWidget {
  final String image;
  final String name;
  final String country;
  final String code;
  final String badge;
  final double rating;
  final String reviews;

  const _DestHero({
    required this.image,
    required this.name,
    required this.country,
    required this.code,
    required this.badge,
    required this.rating,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _heroHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (image.isNotEmpty)
            CachedNetworkImage(
              cacheManager: AppCacheManager.instance,
              imageUrl: image,
              fit: BoxFit.cover,
              // Ekran kengligi × balandlik o'lchamida dekodlanadi (№43).
              memCacheWidth: coverImageCacheSize(
                      context, MediaQuery.sizeOf(context).width, _heroHeight)
                  .width,
              memCacheHeight: coverImageCacheSize(
                      context, MediaQuery.sizeOf(context).width, _heroHeight)
                  .height,
              placeholder: (_, __) => Container(color: const Color(0xFF16244A)),
              errorWidget: (_, __, ___) =>
                  Container(color: const Color(0xFF16244A)),
            )
          else
            Container(color: const Color(0xFF16244A)),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.45, 1],
                colors: [
                  Color(0x40000000),
                  Color(0x1A000000),
                  Color(0xCC000000),
                ],
              ),
            ),
          ),
          // Kontent "varag'i"ning yuqori burchaklari.
          Positioned(
            left: 0,
            right: 0,
            bottom: -1,
            child: Container(
              height: _heroCurve,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(_heroCurve)),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12 + _heroCurve),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    button: true,
                    label: MaterialLocalizations.of(context).backButtonTooltip,
                    excludeSemantics: true,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.28),
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.of(context).maybePop(),
                        // Bosish maydoni ≥44 dp (№32).
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(
                            child: SvgPicture.asset(
                              Assets.iconsScanBackIcon,
                              width: 22,
                              height: 22,
                              colorFilter: const ColorFilter.mode(
                                  Colors.white, BlendMode.srcIn),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (badge.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: ProjectTheme.brandColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: "packages/mysafar_sdk/Gilroy",
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: "packages/mysafar_sdk/Gilroy",
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Uzun mamlakat nomi + reyting bir qatorga sig'masa keyingi
                  // qatorga o'tadi (qirqilib qolmaydi).
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (country.isNotEmpty)
                        _HeroChip(
                            icon: Assets.iconsDestPinIcon, label: country),
                      if (code.isNotEmpty) _HeroChip(label: code),
                      if (rating > 0)
                        _HeroChip(
                          icon: Assets.iconsDestStarIcon,
                          iconColor: const Color(0xFFFFC107),
                          label: reviews.isEmpty
                              ? rating.toStringAsFixed(1)
                              : "${rating.toStringAsFixed(1)} · "
                                  "${"dest_reviews".tr(namedArgs: {
                                      "count": reviews
                                    })}",
                        ),
                    ],
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

/// Sahifa tanasi — sahifa va (golden testlardagi) oldindan ko'rish uchun
/// bitta joyda.
List<Widget> _destSlivers({
  required Widget hero,
  required DestinationDetailModel detail,
  required String Function(DestLocalizedText) lt,
  required void Function(String uri) onOpen,
}) {
  final about = detail.about;
  final bool hasAbout = about != null && !about.description.isEmpty;

  return [
    SliverToBoxAdapter(child: hero),
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _QuickInfoCard(detail: detail, lt: lt),
          if (hasAbout) ...[
            const SizedBox(height: 16),
            _AboutCard(
              description: lt(about.description),
              visaNote: about.visaNote.isEmpty ? '' : lt(about.visaNote),
            ),
          ],
          if (detail.attractions.isNotEmpty) ...[
            const SizedBox(height: 22),
            _SectionTitle("dest_attractions_title".tr(),
                icon: Assets.iconsDestPlaceIcon),
            const SizedBox(height: 12),
            _AttractionsCard(attractions: detail.attractions, lt: lt),
          ],
          if (detail.gallery.isNotEmpty) ...[
            const SizedBox(height: 22),
            _SectionTitle("dest_gallery_title".tr(),
                icon: Assets.iconsDestGalleryIcon),
            const SizedBox(height: 12),
            _GalleryGrid(images: detail.gallery),
          ],
          const SizedBox(height: 22),
          _AviaRouteCard(detail: detail, lt: lt),
          if (MySafarSdk.config.hasPartnerSupport) ...[
            const SizedBox(height: 16),
            _ContactCard(onOpen: onOpen),
          ],
        ]),
      ),
    ),
  ];
}
