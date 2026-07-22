// ignore_for_file: deprecated_member_use

part of '../main_page.dart';

class BookedTicketPaymentBanner extends StatelessWidget {
  const BookedTicketPaymentBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(
        TicketedBookingSearchPage.routeName,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.color.primaryContainer,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x24000000),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: Image.asset(
                'packages/mysafar_sdk/assets/img/home/icons/search_ticket_ic.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                "booked_ticket_payment_banner".tr(),
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: context.color.outline,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceTypeCell extends StatelessWidget {
  final int type;
  final bool isActive;

  const ServiceTypeCell({
    super.key,
    required this.type,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isActive ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 600),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 44, child: Image.asset(_getAsset())),
          const SizedBox(height: 4),
          Text(
            _getTitle(),
            style: isActive
                ? context.textTheme.headlineSmall
                ?.copyWith(color: ProjectTheme.brandColor)
                : context.textTheme.headlineSmall,
          )
        ],
      ),
    );
  }

  String _getAsset() {
    switch (type) {
      case 0:
        return isActive
            ? Assets.iconsIconPlaneActive
            : Assets.iconsIconPlaneDeactive;
      case 1:
        return isActive
            ? Assets.iconsIconTrainActive
            : Assets.iconsIconTrainDeactive;
      case 2:
        return isActive
            ? Assets.iconsIconHotelActive
            : Assets.iconsIconHotelDeactive;
      default:
        return "";
    }
  }

  String _getTitle() {
    switch (type) {
      case 0:
        return "flights_tickets".tr();
      case 1:
        return "train_tickets".tr();
      case 2:
        return "hotels".tr();
      default:
        return "";
    }
  }
}

class MainHotTickets extends StatefulWidget {
  const MainHotTickets({super.key});

  @override
  State<MainHotTickets> createState() => _MainHotTicketsState();
}

class _MainHotTicketsState extends State<MainHotTickets> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HotTicketsCubit(),
      child: BlocBuilder<HotTicketsCubit, HotTicketsState>(
        builder: (context, state) {
          switch (state) {
            case HotTicketsLoadingState():
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: HotTicketsShimmer(),
              );
            case HotTicketsSuccessState():
              if (state.flights.isEmpty) return const SizedBox();

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "home_popular_directions".tr(),
                            style: context.textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 19,
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    AllHotTicketsPage(flights: state.flights),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 4),
                              child: Row(
                                children: [
                                  Text(
                                    "all".tr(),
                                    style:
                                        context.textTheme.bodyMedium?.copyWith(
                                      color: ProjectTheme.brandColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: ProjectTheme.brandColor,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: _HomeHotTicketCard.height,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        itemCount: state.flights.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) =>
                            _HomeHotTicketCard(flight: state.flights[index]),
                      ),
                    ),
                  ],
                ),
              );
            default:
              return SizedBox();
          }
        },
      ),
    );
  }
}

/// Bosh sahifadagi "Eng ommabop yo'nalishlar" kartasi (Figma): tepada manzil
/// rasmi + "Ommabop" belgisi, pastda shahar nomi va "narxi … dan" qatori.
/// Rasmlar Pexels servisidan (cache + fallback bilan) keladi.
class _HomeHotTicketCard extends StatelessWidget {
  /// Gorizontal ro'yxat balandligi — rasm (128) + matn bloki.
  static const double height = 232;
  static const double width = 236;

  final HotTicket flight;
  const _HomeHotTicketCard({required this.flight});

  @override
  Widget build(BuildContext context) {
    final destCity =
        flight.ticket.segments.last.arr?.city?.title ?? flight.route.toCity;

    return Container(
      width: width,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.color.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: context.shadowDown,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => PassengerInformationPage(
                element: flight.ticket.getFlightElement(),
                adt: 1,
                chd: 0,
                inf: 0,
              ),
            ));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Manzil rasmi + "Ommabop" belgisi.
              SizedBox(
                height: 128,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DestinationImageCarousel(
                      key: ValueKey('hot-$destCity'),
                      query: destCity,
                      fallbackAsset: "packages/mysafar_sdk/assets/img/tickets/ticket_bg.png",
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "home_popular_badge".tr(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: ProjectTheme.brandColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Nomi va narxi.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        destCity,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.displayLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "home_price_label".tr(),
                            style: context.textTheme.headlineSmall
                                ?.copyWith(fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          _priceLine(context),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "6 400 000 so'mdan" — raqam qalin, valyuta va qo'shimcha kulrang.
  /// Shablon: "home_price_from" = "{price}dan" / "от {price}" / "from {price}".
  Widget _priceLine(BuildContext context) {
    return Consumer<CurrencyProvider>(
      builder: (context, provider, _) {
        final price = provider.getHotTicketPrice(flight.ticket.price);

        // Narxni raqam va valyuta so'ziga ajratamiz ("6 400 000" + " so'm").
        String number = price;
        String currency = '';
        final lastSpace = price.lastIndexOf(' ');
        if (lastSpace > 0 &&
            !RegExp(r'\d').hasMatch(price.substring(lastSpace + 1))) {
          number = price.substring(0, lastSpace);
          currency = ' ${price.substring(lastSpace + 1)}';
        }

        // Tarjima shablonini {price} bo'yicha ikkiga bo'lamiz.
        final parts = "home_price_from"
            .tr(namedArgs: {"price": "\u0001"}).split('\u0001');
        final prefix = parts.isNotEmpty ? parts.first : '';
        final suffix = parts.length > 1 ? parts.last : '';
        final grey =
            context.textTheme.headlineSmall?.copyWith(fontSize: 13.5);

        return Text.rich(
          TextSpan(children: [
            if (prefix.isNotEmpty) TextSpan(text: prefix, style: grey),
            TextSpan(
              text: number,
              style: context.textTheme.labelMedium?.copyWith(fontSize: 17),
            ),
            TextSpan(text: '$currency$suffix', style: grey),
          ]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

/// "So'ngi qidiruvlar" — serverdagi qidiruv tarixi (Figma: oq karta ichida
/// ro'yxat: yo'nalish, sana(lar), o'ngda yo'lovchilar soni). Tarix bo'sh yoki
/// xato bo'lsa bo'lim butunlay yashirinadi.
class RecentSearchesWidget extends StatefulWidget {
  const RecentSearchesWidget({super.key});

  @override
  State<RecentSearchesWidget> createState() => _RecentSearchesWidgetState();
}

class _RecentSearchesWidgetState extends State<RecentSearchesWidget> {
  List<RecommendationRequestBody> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
    // Yangi qidiruv qo'shilganda (foydalanuvchi qaytib kelganda) yangilanadi.
    RecentSearchCache().revision.addListener(_load);
  }

  @override
  void dispose() {
    RecentSearchCache().revision.removeListener(_load);
    super.dispose();
  }

  DateTime? _parseDotDate(String? d) {
    if (d == null) return null;
    final p = d.split('.');
    if (p.length != 3) return null;
    try {
      return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
    } catch (_) {
      return null;
    }
  }

  /// Lokal Hive keshdan o'qiydi (kesh allaqachon takrorlanmas holatda saqlaydi).
  void _load() {
    final list = RecentSearchCache().read();
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final visible = <RecommendationRequestBody>[];

    for (final p in list) {
      final s = p.segments;
      if (s == null || s.isEmpty) continue;
      // O'tib ketgan sanadagi qidiruvni ko'rsatmaymiz.
      final date = _parseDotDate(s.first.date);
      if (date == null || date.isBefore(startOfDay)) continue;
      visible.add(p);
      if (visible.length >= 3) break;
    }

    if (!mounted) return;
    setState(() => _items = visible);
  }

  String _dates(RecommendationRequestBody p) {
    final s = p.segments!;
    final start = ElementFormatter.formatDate(s.first.date ?? '');
    if (s.length > 1) {
      return '$start - ${ElementFormatter.formatDate(s.last.date ?? '')}';
    }
    return start;
  }

  void _repeatSearch(RecommendationRequestBody p) {
    HapticFeedback.selectionClick();
    ProjectUtils.setRecommendationParams(p);
    Navigator.of(context)
        .pushNamed(RecommendationsTicketPage.routeName, arguments: p);
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();

    // Konteyner ekran chetlariga yopishadi (yon padding yo'q); sarlavha ham
    // konteyner ICHIDA joylashadi.
    return Container(
      margin: const EdgeInsets.only(top: 20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.color.primaryContainer,
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: context.shadowDown,
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              "home_recent_searches".tr(),
              style: context.textTheme.displayLarge
                  ?.copyWith(fontWeight: FontWeight.w800, fontSize: 19),
            ),
          ),
          for (int i = 0; i < _items.length; i++) ...[
            if (i > 0)
              Divider(
                  height: 1,
                  thickness: 1,
                  indent: 14,
                  endIndent: 14,
                  color: context.color.outline.withOpacity(0.3)),
            _row(context, _items[i]),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, RecommendationRequestBody p) {
    final s = p.segments!;
    final title =
        '${s.first.from?.cityName ?? s.first.from?.cityIataCode ?? ''} - ${s.first.to?.cityName ?? s.first.to?.cityIataCode ?? ''}';
    final pax = p.adt + p.chd + p.inf;

    return InkWell(
      onTap: () => _repeatSearch(p),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.displayMedium
                        ?.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _dates(p),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.headlineSmall
                        ?.copyWith(fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('$pax',
                style:
                    context.textTheme.headlineMedium?.copyWith(fontSize: 14)),
            const SizedBox(width: 4),
            Icon(Icons.people_alt_outlined,
                size: 18, color: ProjectTheme.secondaryTextLight),
          ],
        ),
      ),
    );
  }
}

/// "24/7 yordam" kartasi (Figma) — bosilganda qo'llab-quvvatlash menyusi.
class HomeSupportBanner extends StatelessWidget {
  const HomeSupportBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.themeProvider.isDark;

    // Konteyner ekran chetlariga yopishadi (yon padding/yumaloq burchak yo'q).
    return Container(
      margin: const EdgeInsets.only(top: 20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.color.primaryContainer,
        borderRadius: BorderRadius.circular(32),
        boxShadow: context.shadowDown,
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
            onTap: () => ProjectDialogs.showSupportMenu(context),
            child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : ProjectTheme.swimmer200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Image.asset(
                    'packages/mysafar_sdk/assets/img/home/icons/support_ic.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "home_support_title".tr(),
                        style: context.textTheme.displayLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "home_support_desc".tr(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.headlineMedium
                            ?.copyWith(fontSize: 13.5),
                      ),
                    ],
                  ),
                ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right_rounded,
                      size: 24, color: ProjectTheme.secondaryTextLight),
                ],
              ),
            ),
          ),
        ),
      );
  }
}

/// Qaynoq chipta kartasi — rasm foni, narx, aviakompaniya va sana/vaqt paneli.
/// "Barcha qaynoq chiptalar" sahifasida ishlatiladi. Balandlikni o'rovchi
/// (ro'yxat) belgilaydi.
class HotTicketCard extends StatelessWidget {
  final HotTicket flight;

  const HotTicketCard({super.key, required this.flight});

  @override
  Widget build(BuildContext context) {
    final destCity =
        flight.ticket.segments.last.arr?.city?.title ?? flight.route.toCity;
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => PassengerInformationPage(
            element: flight.ticket.getFlightElement(),
            adt: 1,
            chd: 0,
            inf: 0,
          ),
        ));
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DestinationImageCarousel(
              key: ValueKey(flight.ticket.id),
              query: destCity,
              fallbackAsset: "packages/mysafar_sdk/assets/img/tickets/ticket_bg.png",
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xB3000000),
                    const Color(0x4D000000),
                    ProjectTheme.brandColor.withOpacity(0.45),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(children: [
                      Text(
                        "${flight.ticket.segments.first.segmentClass?.name?.toUpperCase() ?? ""} - ${"class".tr()}",
                        style: context.textTheme.displaySmall
                            ?.copyWith(color: Colors.white, fontSize: 12),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: ClipOval(
                          child: CachedNetworkImage(
                            cacheManager: AppCacheManager.instance,
                            cacheKey:
                                flight.ticket.provider.supplier.code ?? "",
                            memCacheWidth: 88,
                            memCacheHeight: 88,
                            errorWidget: (context, url, error) =>
                                const SizedBox(),
                            imageUrl: ProjectAssets.getSegmentProviderImg(
                              flight.ticket.provider.supplier.code ?? "",
                            ),
                          ),
                        ),
                      ),
                      context.szBoxWidth4,
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 80),
                        child: Text(
                          flight.ticket.provider.supplier.title ?? "",
                          style: context.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Consumer<CurrencyProvider>(
                      builder: (context, provider, _) => Text(
                        provider.getHotTicketPrice(flight.ticket.price),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.displayMedium
                            ?.copyWith(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      flight.ticket.getCityTitle(),
                      style: context.textTheme.headlineSmall
                          ?.copyWith(color: Colors.white, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    constraints: const BoxConstraints(
                      minHeight: 60,
                      maxHeight: 70,
                    ),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.color.primaryContainer,
                      borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 44,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: ProjectTheme.blueBgLight,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: ProjectTheme.blueBgLight,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6.0,
                                          vertical: 1.0,
                                        ),
                                        child: Text(
                                          ElementFormatter.getMonth(
                                              flight.route.fromDate),
                                          style: context.textTheme.displaySmall
                                              ?.copyWith(
                                            fontSize: 11,
                                            color: ProjectTheme.brandColor,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 44,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                const BorderRadius.only(
                                              bottomLeft: Radius.circular(6),
                                              bottomRight: Radius.circular(6),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              flight.ticket.segments[0].dep
                                                      ?.getFlightDay() ??
                                                  "",
                                              style: context
                                                  .textTheme.displayMedium
                                                  ?.copyWith(
                                                      color: Colors.black,
                                                      fontSize: 14),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "${flight.ticket.segments[0].dep?.time} - ${flight.ticket.segments[0].arr?.time}",
                                  style: context.textTheme.displaySmall
                                      ?.copyWith(fontSize: 12),
                                ),
                                Text(
                                  "${flight.route.fromCity} - ${flight.route.toCity}",
                                  style: context.textTheme.headlineSmall
                                      ?.copyWith(fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ElementFormatter.formatDuration(
                                    flight.ticket.duration),
                                style: context.textTheme.displaySmall
                                    ?.copyWith(fontSize: 12),
                              ),
                              Text(
                                flight.ticket.getTransferInfo(),
                                style: context.textTheme.headlineSmall
                                    ?.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PopularDestinationsWidget extends StatefulWidget {
  const PopularDestinationsWidget({super.key});

  @override
  State<PopularDestinationsWidget> createState() =>
      _PopularDestinationsWidgetState();
}

class _PopularDestinationsWidgetState extends State<PopularDestinationsWidget> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PopularDestinationCubit(),
      child: BlocBuilder<PopularDestinationCubit, PopularDestinationState>(
        builder: (context, state) {
          switch (state) {
            case PopularDestinationLoadingState():
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    context.szBoxHeight8,
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
                      child: Text(
                        "popular_city".tr(),
                        style: context.textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.w800, fontSize: 19),
                      ),
                    ),
                    SizedBox(
                      height: _PopularDestinationCard.totalHeight,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 5,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (context, index) => RepaintBoundary(
                          child: Shimmer.fromColors(
                            baseColor: Colors.grey.shade200,
                            highlightColor: Colors.grey.shade300,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: _PopularDestinationCard.cardWidth,
                                  height: _PopularDestinationCard.windowHeight,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                        _PopularDestinationCard.windowRadius),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  width: 90,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            case PopularDestinationSuccessState():
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    context.szBoxHeight8,
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
                      child: Text(
                        "popular_city".tr(),
                        style: context.textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.w800, fontSize: 19),
                      ),
                    ),
                    SizedBox(
                      height: _PopularDestinationCard.totalHeight,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.zero,
                        physics: const BouncingScrollPhysics(),
                        itemCount: state.destinations.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final destination = state.destinations[index];
                          return _PopularDestinationCard(
                            imageUrl: destination.images.isNotEmpty
                                ? destination.images[0].image
                                : '',
                            name: _getName(destination.name, dataLang()),
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                DestinationInfoMapWidget.routeName,
                                arguments: destination,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            default:
              return const SizedBox();
          }
        },
      ),
    );
  }

  String _getName(PopDestinationsText name, String lang) {
    switch (lang) {
      case 'ru':
        return name.ru;
      case 'en':
        return name.en;
      default:
        return name.uz;
    }
  }
}


/// Mashhur manzil kartasi — rasm samolyot oynasi shaklida (vertikal oval),
/// atrofida ranglari almashib aylanib turadigan gradient chegara, nomi esa
/// ostida joylashadi (2 qator, sig'masa "..." bilan qisqaradi).
class _PopularDestinationCard extends StatefulWidget {
  static const double cardWidth = 100;
  static const double windowHeight = 150;
  static const double windowRadius = 68;
  static const double borderWidth = 3.5;

  static const double totalHeight = windowHeight + 10 + 42;

  final String imageUrl;
  final String name;
  final VoidCallback onTap;

  const _PopularDestinationCard({
    required this.imageUrl,
    required this.name,
    required this.onTap,
  });

  @override
  State<_PopularDestinationCard> createState() =>
      _PopularDestinationCardState();
}

class _PopularDestinationCardState extends State<_PopularDestinationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Chegara ranglari perimetr bo'ylab uzluksiz aylanadi.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double w = _PopularDestinationCard.cardWidth;
    const double h = _PopularDestinationCard.windowHeight;
    const double r = _PopularDestinationCard.windowRadius;
    const double bw = _PopularDestinationCard.borderWidth;

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: w,
              height: h,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => CustomPaint(
                  painter: _RotatingBorderPainter(
                    rotation: _controller.value,
                    radius: r,
                    strokeWidth: bw,
                  ),
                  child: child,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(bw),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(r - bw),
                    child: CachedNetworkImage(
                      cacheManager: AppCacheManager.instance,
                      imageUrl: widget.imageUrl,
                      fit: BoxFit.cover,
                      width: w,
                      height: h,
                      memCacheWidth: 340,
                      memCacheHeight: 440,
                      fadeInDuration: const Duration(milliseconds: 200),
                      placeholder: (_, __) =>
                          Container(color: Colors.grey.shade200),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartaning ovalsimon chegarasini SweepGradient bilan chizadi va
/// [rotation] (0..1) bo'yicha ranglarni perimetr atrofida aylantiradi.
class _RotatingBorderPainter extends CustomPainter {
  final double rotation;
  final double radius;
  final double strokeWidth;

  const _RotatingBorderPainter({
    required this.rotation,
    required this.radius,
    required this.strokeWidth,
  });

  static const double _twoPi = 6.283185307179586;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final RRect rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(radius - strokeWidth / 2),
    );
    // Birinchi va oxirgi rang bir xil — halqa uzluksiz ko'rinadi.
    final SweepGradient gradient = SweepGradient(
      colors: const [
        Color(0xFF00A8FF),
        Color(0xFF9A3BFF),
        Color(0xFFFF3D77),
        Color(0xFFFFB020),
        Color(0xFF00E0C6),
        Color(0xFF00A8FF),
      ],
      transform: GradientRotation(rotation * _twoPi),
    );
    final Paint paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _RotatingBorderPainter oldDelegate) =>
      oldDelegate.rotation != rotation ||
      oldDelegate.radius != radius ||
      oldDelegate.strokeWidth != strokeWidth;
}


class HotTicketsShimmer extends StatelessWidget {
  const HotTicketsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: context.k16verticalPadding,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: 24,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: List.generate(5, (index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    width: 280,
                    height: 120,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class AnimatedGradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isSmart;

  const AnimatedGradientButton({
    super.key,
    required this.onPressed,
    required this.isSmart,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: !isSmart
                ? [const Color(0xFF00A8FF), const Color(0xFF0057BE)]
                : [const Color(0xFF9A3BFF), const Color(0xFF7A1BDF)],
          ),
        ),
        child: Shimmer.fromColors(
          baseColor: Colors.white,
          highlightColor: Colors.white.withAlpha(50),
          period: const Duration(seconds: 2),
          child: Row(
            children: [
              Text(
                  isSmart
                      ? "gradient_button_regular_title".tr()
                      : "gradient_button_smart_title".tr(),
                  style: context.textTheme.displayMedium
                      ?.copyWith(color: Colors.white)),
              context.szBoxWidth4,
              SizedBox(
                  width: 12,
                  height: 12,
                  child: SvgPicture.asset(
                    isSmart
                        ? Assets.iconsSearchWhiteIcon
                        : Assets.iconsStarsIcon,
                    colorFilter:
                    ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ))
            ],
          ),
        ),
      ),
    );
  }
}

class PassengerCount extends StatefulWidget {
  final Map<String, dynamic> params;
  final void Function(Map<String, dynamic> params) callback;

  const PassengerCount({
    super.key,
    required this.params,
    required this.callback,
  });

  @override
  State<PassengerCount> createState() => _PassengerCount();
}

class _PassengerCount extends State<PassengerCount> {
  int adt = 1;
  int chd = 0;
  int inf = 0;

  String klass = 'a';

  @override
  void initState() {
    if (widget.params.isNotEmpty) {
      final params = widget.params;
      adt = params['adt'];
      chd = params['chd'] ?? 0;
      inf = params['inf'] ?? 0;
      klass = params['klass'] ?? "a";
    }
    super.initState();
  }

  bool get isMax => adt + chd + inf == 9;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: context.k16horizontalPadding,
          child: Column(
            children: [
              getPassengerCounter(
                  type: 0,
                  title: "above_12".tr(),
                  remove: () {
                    if (adt > 1) {
                      setState(() {
                        HapticFeedback.lightImpact();
                        adt--;
                      });
                    }
                  },
                  add: () {
                    if (isMax) {
                      return;
                    }
                    setState(() {
                      HapticFeedback.lightImpact();
                      adt++;
                    });
                  }),
              context.szBoxHeight16,
              getPassengerCounter(
                  type: 1,
                  title: "between_2_12".tr(),
                  remove: () {
                    if (chd > 0) {
                      setState(() {
                        HapticFeedback.lightImpact();
                        chd--;
                      });
                    }
                  },
                  add: () {
                    if (isMax) {
                      return;
                    }
                    setState(() {
                      HapticFeedback.lightImpact();
                      chd++;
                    });
                  }),
              context.szBoxHeight16,
              getPassengerCounter(
                  type: 2,
                  title: "under_2".tr(),
                  remove: () {
                    if (inf > 0) {
                      setState(() {
                        HapticFeedback.lightImpact();
                        inf--;
                      });
                    }
                  },
                  add: () {
                    if (isMax) {
                      return;
                    }
                    setState(() {
                      HapticFeedback.lightImpact();
                      inf++;
                    });
                  }),
              context.szBoxHeight16,
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "show_age_feedback_subtitle".tr(),
                  style: context.textTheme.titleMedium,
                ),
              ),
              context.szBoxHeight8,
              Divider(
                thickness: 1,
                color: ProjectTheme.borderLight,
              ),
              context.szBoxHeight16,
              getKlass(
                'e',
                'klass_e'.tr(),
                    (type) => setState(() => klass = type),
              ),
              context.szBoxHeight12,
              getKlass(
                'b',
                'klass_b'.tr(),
                    (type) => setState(() => klass = type),
              ),
              context.szBoxHeight12,
              getKlass(
                'a',
                'klass_a'.tr(),
                    (type) => setState(() => klass = type),
              ),
              context.szBoxHeight12,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                          style: context.disabledButtonStyle,
                          onPressed: () {
                            setState(() {
                              adt = 1;
                              chd = 0;
                              inf = 0;
                              klass = 'a';
                            });
                          },
                          child: Text(
                            "reset".tr(),
                            style: context.textTheme.bodyMedium,
                          )),
                    ),
                  ),
                  context.szBoxWidth12,
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                          style: ProjectTheme.blueButtonStyle,
                          onPressed: () {
                            widget.callback({
                              "adt": adt,
                              "chd": chd,
                              "inf": inf,
                              "klass": klass
                            });
                          },
                          child: Text("apply".tr())),
                    ),
                  )
                ],
              ),
              context.szBoxHeight12
            ],
          ),
        ),
      ],
    );
  }

  InkWell getKlass(String type, String title,
      void Function(String type) callback) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () {
        HapticFeedback.lightImpact();
        callback(type);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: context.textTheme.titleMedium,
          ),
          SizedBox(
            width: 24,
            height: 24,
            child: SvgPicture.asset(type == klass
                ? Assets.homeRadioButtonActive
                : Assets.homeRadioButtonDeactive),
          )
        ],
      ),
    );
  }

  /// Type :
  ///
  /// 0 for adt
  ///
  /// 1 for chd
  ///
  /// 2 for inf
  Widget getPassengerCounter({required int type,
    required String title,
    required void Function() remove,
    required void Function() add}) {
    return Row(
      children: [
        Expanded(
            flex: 6,
            child: Text(
              title,
              style: context.textTheme.titleMedium?.copyWith(fontSize: 18),
            )),
        Expanded(
            flex: 5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AnimatedOpacity(
                  opacity: getOpacity(type),
                  duration: const Duration(milliseconds: 500),
                  child: InkWell(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () => remove(),
                    child: SizedBox(
                      height: 36,
                      width: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                  blurRadius: 8.0,
                                  offset: Offset(0, 2),
                                  color: ProjectTheme.shadowDropLight)
                            ],
                            color: ProjectTheme.brandColor,
                            borderRadius: BorderRadius.circular(16)),
                        child: Icon(
                          Icons.remove,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                Text(getCount(type)),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: isMax ? 0.4 : 1.0,
                  child: InkWell(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () => add(),
                    child: SizedBox(
                      height: 36,
                      width: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                  blurRadius: 8.0,
                                  offset: Offset(0, 2),
                                  color: ProjectTheme.shadowDropLight)
                            ],
                            color: ProjectTheme.brandColor,
                            borderRadius: BorderRadius.circular(16)),
                        child: Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ))
      ],
    );
  }

  double getOpacity(int type) {
    if (type == 0 && adt > 1) {
      return 1.0;
    } else if (type == 1 && chd > 0) {
      return 1.0;
    } else if (type == 2 && inf > 0) {
      return 1.0;
    }
    return 0.4;
  }

  String getCount(int type) {
    if (type == 0) {
      return "$adt";
    } else if (type == 1) {
      return "$chd";
    } else {
      return "$inf";
    }
  }
}

class SmartSearchWidget extends StatefulWidget {
  const SmartSearchWidget({super.key});

  @override
  State<SmartSearchWidget> createState() => _SmartSearchWidgetState();
}

class _SmartSearchWidgetState extends State<SmartSearchWidget> {
  final List<String> texts = [
    'ai_search_hint_1'.tr(),
    'ai_search_hint_2'.tr(),
    'ai_search_hint_3'.tr(),
    'ai_search_hint_4'.tr(),
  ];

  final _controller = TextEditingController();
  final AudioRecorder _recorder = AudioRecorder();
  late AiSearchCubit _aiSearchCubit;

  bool _isRecording = false;
  String? _filePath;

  // Animatsion hint — faqat shu qiymat o'zgaradi; ValueListenableBuilder orqali
  // faqat placeholder matn qayta chiziladi (butun forma/TextFormField emas).
  final ValueNotifier<String> _animatedText = ValueNotifier<String>('');
  int textIndex = 0;
  int charIndex = 0;
  Timer? _typingTimer;
  // Matn to'liq yozilgach 2s pauza uchun qolgan "tick" sonini saqlaydi
  // (har tick 60ms => ~33 tick ≈ 2s).
  int _pauseTicks = 0;

  @override
  void initState() {
    super.initState();
    _aiSearchCubit = AiSearchCubit();
    _startTyping();
    _initPermissions();
  }

  Future<void> _initPermissions() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      debugPrint("Microphone permission denied");
    }
  }

  Future<void> _startRecording() async {
    final dir = await getTemporaryDirectory();
    _filePath =
    '${dir.path}/audio_${DateTime
        .now()
        .millisecondsSinceEpoch}.wav';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _filePath!,
    );

    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stop();

    if (_filePath != null) {
      final file = await MultipartFile.fromFile(
        _filePath!,
        filename: 'speech.wav',
      );

      final formData = FormData.fromMap({
        'audio': file,
      });

      setState(() {
        _isRecording = false;
      });
      _aiSearchCubit.searchAiVoice(formData);

      debugPrint("✅ Audio recorded and sent: $_filePath");
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _animatedText.dispose();
    _controller.dispose();
    _aiSearchCubit.close();
    _recorder.dispose();
    super.dispose();
  }

  void _startTyping() {
    _typingTimer?.cancel();
    // 60ms'lik tick'lar bilan harf-harf yozish; matn tugagach 2s pauza
    // (pauza ham tick'lar orqali hisoblanadi, alohida Future kerak emas).
    _typingTimer = Timer.periodic(const Duration(milliseconds: 60), (_) {
      if (!mounted) return;
      if (_pauseTicks > 0) {
        _pauseTicks--;
        if (_pauseTicks == 0) {
          textIndex = (textIndex + 1) % texts.length;
          charIndex = 0;
          _animatedText.value = '';
        }
        return;
      }
      if (charIndex < texts[textIndex].length) {
        _animatedText.value += texts[textIndex][charIndex];
        charIndex++;
      } else {
        // ~2s pauza (33 * 60ms ≈ 1980ms).
        _pauseTicks = 33;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _aiSearchCubit,
      child: BlocConsumer<AiSearchCubit, AiSearchState>(
        listener: (context, state) {
          switch (state) {
            case AiSearchLoadingState():
              ProjectDialogs.showAiSearchLoader(context);
              break;
            case AiSearchErrorState():
              ProjectDialogs.dismissCurrentDialog();
              showToastMessage(state.error);
              break;
            case AiSearchSuccessState():
              ProjectDialogs.dismissCurrentDialog();
              ProjectUtils.setRecommendationParams(state.body);
              Navigator.of(context).pushNamed(
                  RecommendationsTicketPage.routeName,
                  arguments: state.body);
              break;
            default:
              break;
          }
        },
        builder: (context, state) =>
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                context.szBoxHeight12,
                Text(
                  "smart_search_widget_subtitle".tr(),
                  maxLines: 3,
                  textAlign: TextAlign.start,
                  style: context.textTheme.titleSmall,
                ),
                context.szBoxHeight12,
                Stack(
                  children: [
                    TextFormField(
                      controller: _controller,
                      style: context.textTheme.bodyMedium,
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                      onTapOutside: (event) => FocusScope.of(context).unfocus(),
                      onFieldSubmitted: (value) {
                        if (value.isNotEmpty) {
                          BlocProvider.of<AiSearchCubit>(context)
                              .searchAiChat(value);
                        }
                      },
                      onChanged: (value) {
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        fillColor: context.backgroundColor,
                        filled: true,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.fromLTRB(
                            16, 12, 48, 12),
                      ),
                    ),
                    // Animatsion placeholder — maydon bo'sh bo'lsa ko'rinadi.
                    // Faqat shu matn har tick'da qayta chiziladi.
                    Positioned(
                      left: 16,
                      top: 12,
                      right: 48,
                      child: IgnorePointer(
                        child: ValueListenableBuilder<String>(
                          valueListenable: _animatedText,
                          builder: (context, txt, _) => _controller.text.isEmpty
                              ? Text(
                                  txt,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    color: context.disabledTextColor,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    _controller.text.isEmpty
                        ? Positioned(
                      right: 16,
                      top: 12,
                      child: GestureDetector(
                        onTap: () async {
                          if (_isRecording) {
                            await _stopRecording();
                          } else {
                            await _startRecording();
                          }
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: _isRecording ? 72 : 0,
                              height: _isRecording ? 72 : 0,
                              decoration: BoxDecoration(
                                color:
                                ProjectTheme.brandColor.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                            ),
                            _isRecording
                                ? SvgPicture.asset(
                              Assets.homeSendIcon,)
                                : Icon(
                              Icons.mic_none_rounded,
                              color: ProjectTheme.brandColor,
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                    )
                        : const SizedBox(),
                  ],
                ),
                context.szBoxHeight12,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                            style: context.disabledButtonStyle,
                            onPressed: () {
                              _controller.clear();
                            },
                            child: Text(
                              "reset".tr(),
                              style: context.textTheme.bodyMedium,
                            )),
                      ),
                    ),
                    context.szBoxWidth12,
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                            style: ProjectTheme.blueButtonStyle,
                            onPressed: () {
                              if (_controller.text.isNotEmpty) {
                                BlocProvider.of<AiSearchCubit>(context)
                                    .searchAiChat(_controller.text);
                              }
                            },
                            child: Text("search_tickets_button".tr())),
                      ),
                    )
                  ],
                ),
              ],
            ),
      ),
    );
  }
}

/// Manzil nomi bo'yicha Pexels'dan olingan 3 ta rasmni avto-almashinuvchi
/// karusel qilib ko'rsatadi (1 → 2 → 3 → 1 ...).
///
/// Javob kelguncha [fallbackAsset] (hozirgi ko'rinish) turadi; rasmlar
/// yuklangach o'shalar chiqadi. Natijalar [PexelsService] orqali cache'lanadi.
class DestinationImageCarousel extends StatefulWidget {
  final String query;
  final String fallbackAsset;

  const DestinationImageCarousel({
    super.key,
    required this.query,
    required this.fallbackAsset,
  });

  @override
  State<DestinationImageCarousel> createState() =>
      _DestinationImageCarouselState();
}

class _DestinationImageCarouselState extends State<DestinationImageCarousel> {
  List<String> _images = const [];
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Avval cache (darhol), bo'lmasa tarmoqdan yuklaymiz.
    final cached = PexelsService.instance.readCache(widget.query);
    if (cached != null && cached.isNotEmpty) {
      _images = cached;
      _startRotation();
    } else {
      _loadImages();
    }
  }

  Future<void> _loadImages() async {
    final imgs = await PexelsService.instance.getImages(widget.query, perPage: 3);
    if (!mounted || imgs.isEmpty) return;
    setState(() => _images = imgs);
    _precache(imgs);
    _startRotation();
  }

  void _precache(List<String> imgs) {
    for (final url in imgs) {
      precacheImage(CachedNetworkImageProvider(url), context)
          .catchError((_) {});
    }
  }

  void _startRotation() {
    _timer?.cancel();
    if (_images.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _images.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _fallback() => Image.asset(
        widget.fallbackAsset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );

  @override
  Widget build(BuildContext context) {
    if (_images.isEmpty) {
      // Javob kelguncha — hozirgi ko'rinish
      return _fallback();
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      child: CachedNetworkImage(
        cacheManager: AppCacheManager.instance,
        key: ValueKey(_images[_index]),
        imageUrl: _images[_index],
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        memCacheWidth: 800,
        memCacheHeight: 600,
        fadeInDuration: const Duration(milliseconds: 300),
        placeholder: (_, __) => _fallback(),
        errorWidget: (_, __, ___) => _fallback(),
      ),
    );
  }
}
