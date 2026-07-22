import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:mysafar_sdk/src/core/constants/default_airports.dart'
    show DefaultAirports;
import 'package:mysafar_sdk/src/core/enum/currency.dart'
    show AppCurrency, AppCurrencyExtension;
import 'package:mysafar_sdk/src/core/tools/app_cache_manager.dart'
    show AppCacheManager;
import 'package:mysafar_sdk/src/core/tools/currency_provider.dart'
    show CurrencyProvider;
import 'package:mysafar_sdk/src/core/tools/formatters.dart' show ElementFormatter;
import 'package:mysafar_sdk/src/cubit/destinations/destination_detail_cubit.dart';
import 'package:mysafar_sdk/src/model/remote/avia/airports_model.dart'
    show AirPortsModel, Airports;
import 'package:mysafar_sdk/src/model/remote/destination/destination_detail_model.dart';
import 'package:mysafar_sdk/src/model/remote/destination/destination_list_model.dart'
    show DestinationListItem;
import 'package:mysafar_sdk/src/model/remote/fornex/pop_destinations.dart';
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart';
import 'package:mysafar_sdk/src/view/destinations/destinations_info_map_page.dart'
    show DestinationInfoMapWidget;
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/view/search/route_search_page.dart'
    show RouteSearchPage;
import 'package:provider/provider.dart' show Provider;
import 'package:url_launcher/url_launcher.dart' show launchUrl, LaunchMode;

part 'destination_details_sections.dart';
part 'destination_details_cards.dart';

class DestinationDetailsPage extends StatefulWidget {
  final PopDestinationsModel? destination;
  final DestinationListItem? listItem;

  const DestinationDetailsPage({super.key, this.destination, this.listItem})
      : assert(destination != null || listItem != null,
            'destination yoki listItem berilishi shart');

  static const routeName = '/destinationDetails';

  @override
  State<DestinationDetailsPage> createState() => _DestinationDetailsPageState();
}

class _DestinationDetailsPageState extends State<DestinationDetailsPage> {
  late final DestinationDetailCubit _cubit = DestinationDetailCubit(
    destination: widget.destination,
    listItem: widget.listItem,
  );

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  String _lt(DestLocalizedText text) => text.byLang(dataLang());

  String get _fallbackName {
    final item = widget.listItem;
    if (item != null) return item.cityName.byLang(dataLang());
    final n = widget.destination!.destination.name;
    return switch (dataLang()) {
      'ru' => n.ru,
      'en' => n.en,
      _ => n.uz,
    };
  }

  String get _fallbackImage {
    final item = widget.listItem;
    if (item != null) return item.image;
    final images = widget.destination!.images;
    return images.isNotEmpty ? images.first.image : '';
  }

  String get _fallbackAirportCode =>
      widget.listItem?.arrivalAirport ??
      widget.destination?.destination.aviationCode ??
      '';

  int _price(DestinationDetailModel? detail, AppCurrency currency) {
    final h = detail?.hero;
    final a = detail?.aviaBlock;
    return switch (currency) {
      AppCurrency.uzs => h?.priceUzs ?? a?.priceUzs ?? 0,
      AppCurrency.rub => h?.priceRub ?? a?.priceRub ?? 0,
      AppCurrency.usd => h?.priceUsd ?? a?.priceUsd ?? 0,
    };
  }

  void _searchTickets(DestinationDetailModel? detail) {
    HapticFeedback.lightImpact();
    AnalyticsService().trackButtonTap('destination_search_tickets');

    final String code = detail?.airportCode.isNotEmpty == true
        ? detail!.airportCode
        : _fallbackAirportCode;
    if (code.isEmpty) return;

    final String destName =
        detail != null ? _lt(detail.name) : _fallbackName;

    final String isoDate = detail?.aviaBlock?.date.isNotEmpty == true
        ? detail!.aviaBlock!.date
        : (detail?.hero?.date ?? '');
    final DateTime? cheapDate = DateTime.tryParse(isoDate);
    final DateTime? initialDate =
        (cheapDate != null && cheapDate.isAfter(DateTime.now()))
            ? cheapDate
            : null;

    final from = DefaultAirports.tashkent(lang: dataLang());
    final to = AirPortsModel(
      cityIataCode: code.toUpperCase(),
      cityName: destName,
      airports: [
        Airports(airportName: destName, airportIataCode: code.toUpperCase()),
      ],
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RouteSearchPage(
          from: from,
          to: to,
          initialDate: initialDate,
        ),
      ),
    );
  }

  Future<void> _openUri(String uri) async {
    try {
      await launchUrl(Uri.parse(uri), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<DestinationDetailCubit, DestinationDetailState>(
        listener: (context, state) {
          if (state is DestinationDetailRedirectMapState) {
            Navigator.of(context).pushReplacementNamed(
              DestinationInfoMapWidget.routeName,
              arguments: widget.destination,
            );
          }
        },
        builder: (context, state) {
          final DestinationDetailModel? detail =
              state is DestinationDetailSuccessState ? state.detail : null;

          if (detail == null) {
            final bool loading = state is! DestinationDetailErrorState;
            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: Column(
                children: [
                  _buildHero(context, null),
                  Expanded(
                    child: SafeArea(
                      top: false,
                      child: Center(
                        child: loading
                            ? const CircularProgressIndicator()
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("error_occurred".tr(),
                                      style: context.textTheme.bodyMedium),
                                  const SizedBox(height: 12),
                                  OutlinedButton(
                                    onPressed: _cubit.load,
                                    child: Text("retry".tr()),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return _buildContent(context, detail);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, DestinationDetailModel detail) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () => _cubit.load(refresh: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(child: _buildHero(context, detail)),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 28 + bottomInset),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _QuickInfoGrid(detail: detail, lt: _lt),
                  if (detail.about != null &&
                      !detail.about!.description.isEmpty) ...[
                    const SizedBox(height: 24),
                    _SectionTitle("dest_about_title".tr()),
                    const SizedBox(height: 8),
                    Text(
                      _lt(detail.about!.description),
                      style: context.textTheme.bodyMedium
                          ?.copyWith(height: 1.55, fontSize: 14.5),
                    ),
                    if (!detail.about!.visaNote.isEmpty) ...[
                      const SizedBox(height: 14),
                      _VisaNoteBox(text: _lt(detail.about!.visaNote)),
                    ],
                  ],
                  if (detail.attractions.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _SectionTitle("dest_attractions_title".tr()),
                    const SizedBox(height: 10),
                    for (int i = 0; i < detail.attractions.length; i++) ...[
                      _AttractionCard(
                        icon: detail.attractions[i].icon,
                        imageUrl: detail.attractions[i].previewImage,
                        name: _lt(detail.attractions[i].name),
                        description: _lt(detail.attractions[i].description),
                      ),
                      if (i < detail.attractions.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                  if (detail.gallery.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _SectionTitle("dest_gallery_title".tr()),
                    const SizedBox(height: 8),
                    _GalleryGrid(images: detail.gallery),
                  ],
                  const SizedBox(height: 20),
                  _AviaCtaCard(
                    detail: detail,
                    lt: _lt,
                    priceOf: (currency) => _price(detail, currency),
                    onSearch: () => _searchTickets(detail),
                  ),
                  const SizedBox(height: 16),
                  _PriceCard(
                    detail: detail,
                    lt: _lt,
                    priceOf: (currency) => _price(detail, currency),
                    onSearch: () => _searchTickets(detail),
                  ),
                  if (detail.contact != null) ...[
                    const SizedBox(height: 16),
                    _ContactCard(
                      contact: detail.contact!,
                      lt: _lt,
                      onOpen: _openUri,
                    ),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, DestinationDetailModel? detail) {
    final hero = detail?.hero;
    final String image = hero?.backgroundImage.isNotEmpty == true
        ? hero!.backgroundImage
        : _fallbackImage;
    final String name = detail != null ? _lt(detail.name) : _fallbackName;
    final String country = detail != null ? _lt(detail.country) : '';
    final String code = detail?.airportCode.isNotEmpty == true
        ? detail!.airportCode
        : _fallbackAirportCode;

    return SizedBox(
      height: 320,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (image.isNotEmpty)
            CachedNetworkImage(
              cacheManager: AppCacheManager.instance,
              imageUrl: image,
              fit: BoxFit.cover,
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
                colors: [
                  Color(0x33000000),
                  Color(0x14000000),
                  Color(0xB3000000)
                ],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: Colors.white.withAlpha(46),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (hero != null && !hero.badge.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: ProjectTheme.brandColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _lt(hero.badge),
                        style: const TextStyle(
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
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (country.isNotEmpty) ...[
                        const Icon(Icons.location_on_outlined,
                            size: 15, color: Colors.white70),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            country,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (code.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(56),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            code,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      if (hero != null && hero.rating > 0) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.star_rounded,
                            size: 17, color: Color(0xFFFFC107)),
                        const SizedBox(width: 2),
                        Text(
                          hero.rating.toStringAsFixed(1),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700),
                        ),
                        if (hero.reviewsDisplay.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text(
                            "· ${"dest_reviews".tr(namedArgs: {
                                  "count": hero.reviewsDisplay
                                })}",
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ],
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
