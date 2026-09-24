import 'package:mysafar_sdk/src/view/destinations/cover_image_cache_size.dart';
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
import 'package:mysafar_sdk/src/core/tools/formatters.dart'
    show ElementFormatter;
import 'package:mysafar_sdk/src/cubit/destinations/destination_detail_cubit.dart';
import 'package:mysafar_sdk/src/model/remote/avia/airports_model.dart'
    show AirPortsModel, Airports;
import 'package:mysafar_sdk/src/model/remote/destination/destination_detail_model.dart';
import 'package:mysafar_sdk/src/model/remote/destination/destination_list_model.dart'
    show DestinationListItem;
import 'package:mysafar_sdk/src/model/remote/fornex/pop_destinations.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart';
import 'package:mysafar_sdk/src/view/destinations/destinations_info_map_page.dart'
    show DestinationInfoMapWidget;
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
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

/// Sahifa boshidagi rasm balandligi va kontent "varag'i"ning burchak radiusi.
const double _heroHeight = 300;
const double _heroCurve = 28;

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

    final String destName = detail != null ? _lt(detail.name) : _fallbackName;

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
        settings: const RouteSettings(name: '/routeSearch'),
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
          final bool failed = state is DestinationDetailErrorState;

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            // Narx va qidiruv tugmasi doim ko'rinadi — pastgacha scroll
            // qilish shart emas (avval ikkita takroriy CTA bor edi).
            bottomNavigationBar:
                detail == null ? null : _buildSearchBar(context, detail),
            body: detail == null
                ? Column(
                    children: [
                      _buildHero(context, null),
                      Expanded(
                        child: SafeArea(
                          top: false,
                          child: failed
                              ? _DestErrorView(onRetry: _cubit.load)
                              : const SingleChildScrollView(
                                  physics: NeverScrollableScrollPhysics(),
                                  child: _DestSkeleton(),
                                ),
                        ),
                      ),
                    ],
                  )
                : _buildContent(context, detail),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, DestinationDetailModel detail) {
    final currency = Provider.of<CurrencyProvider>(context).currency;
    return _DestSearchBar(
      price: _price(detail, currency),
      currency: currency,
      onSearch: () => _searchTickets(detail),
    );
  }

  Widget _buildContent(BuildContext context, DestinationDetailModel detail) {
    return AppRefreshIndicator(
      onRefresh: () => _cubit.load(refresh: true),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        slivers: _destSlivers(
          hero: _buildHero(context, detail),
          detail: detail,
          lt: _lt,
          onOpen: _openUri,
        ),
      ),
    );
  }

  /// Sahifa boshi: rasm + gradient + orqaga tugmasi va shahar nomi.
  Widget _buildHero(BuildContext context, DestinationDetailModel? detail) {
    final hero = detail?.hero;
    return _DestHero(
      image: hero?.backgroundImage.isNotEmpty == true
          ? hero!.backgroundImage
          : _fallbackImage,
      name: detail != null ? _lt(detail.name) : _fallbackName,
      country: detail != null ? _lt(detail.country) : '',
      code: detail?.airportCode.isNotEmpty == true
          ? detail!.airportCode
          : _fallbackAirportCode,
      badge: hero == null || hero.badge.isEmpty ? '' : _lt(hero.badge),
      rating: hero?.rating ?? 0,
      reviews: hero?.reviewsDisplay ?? '',
    );
  }
}

/// Rasm ustidagi yarim shaffof yorliq (mamlakat, IATA kodi, reyting).
class _HeroChip extends StatelessWidget {
  final String? icon;
  final String label;
  final Color? iconColor;

  const _HeroChip({required this.label, this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            SvgPicture.asset(
              icon!,
              width: 15,
              height: 15,
              colorFilter:
                  ColorFilter.mode(iconColor ?? Colors.white, BlendMode.srcIn),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: "packages/mysafar_sdk/Gilroy",
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
