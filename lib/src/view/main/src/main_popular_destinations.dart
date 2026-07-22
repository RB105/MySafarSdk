// ignore_for_file: deprecated_member_use
part of '../main_page.dart';

class MainPopularDestinations extends StatefulWidget {
  const MainPopularDestinations({super.key});

  @override
  State<MainPopularDestinations> createState() =>
      _MainPopularDestinationsState();
}

class _MainPopularDestinationsState extends State<MainPopularDestinations> {
  late final DestinationListCubit _cubit = DestinationListCubit(pageSize: 3);

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<DestinationListCubit, DestinationListState>(
        builder: (context, state) {
          switch (state) {
            case DestinationListLoadingState():
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: HotTicketsShimmer(),
              );
            case DestinationListSuccessState():
              final items = state.items.take(3).toList();
              if (items.isEmpty) return const SizedBox();

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            onTap: () {
                              HapticFeedback.selectionClick();
                              AnalyticsService()
                                  .trackButtonTap('home_destinations_all');
                              BottomNavBarPage.switchTo(2);
                            },
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
                      height: _HomeDestinationCard.height,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) =>
                            _HomeDestinationCard(item: items[index]),
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
}

class _HomeDestinationCard extends StatelessWidget {
  static const double height = 196;
  static const double width = 180;

  final DestinationListItem item;
  const _HomeDestinationCard({required this.item});

  String _lt(DestLocalizedText t) => t.byLang(dataLang());

  int _priceOf(AppCurrency currency) => switch (currency) {
        AppCurrency.uzs => item.priceUzs,
        AppCurrency.rub => item.priceRub,
        AppCurrency.usd => item.priceUsd,
      };

  @override
  Widget build(BuildContext context) {
    final currency = Provider.of<CurrencyProvider>(context).currency;
    final price = _priceOf(currency);
    final city = _lt(item.cityName);
    final code = item.arrivalAirport.trim().toUpperCase();

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            AnalyticsService().trackButtonTap('home_popular_destination');
            Navigator.of(context).pushNamed(
              DestinationDetailsPage.routeName,
              arguments: item,
            );
          },
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.image.isNotEmpty)
                    CachedNetworkImage(
                      cacheManager: AppCacheManager.instance,
                      imageUrl: item.image,
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 150),
                      placeholder: (_, __) =>
                          Container(color: const Color(0xFFE8ECF2)),
                      errorWidget: (_, __, ___) =>
                          Container(color: const Color(0xFF16244A)),
                    )
                  else
                    Container(color: const Color(0xFF16244A)),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 88,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.72),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (price > 0)
                    Positioned(
                      top: 10,
                      left: 10,
                      right: 10,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: _HomePriceBadge(
                          amount: price,
                          currency: currency,
                        ),
                      ),
                    ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                city,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (code.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            code,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomePriceBadge extends StatelessWidget {
  final int amount;
  final AppCurrency currency;

  const _HomePriceBadge({required this.amount, required this.currency});

  @override
  Widget build(BuildContext context) {
    final number = ElementFormatter.formatNumberWithSpaces(amount);
    final pricePart = '$number ${currency.label}';
    final template = "home_price_from".tr(namedArgs: {"price": '\u0001'});
    final parts = template.split('\u0001');
    final prefix = parts.isNotEmpty ? parts.first : '';
    final suffix = parts.length > 1 ? parts.last : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text.rich(
        TextSpan(
          children: [
            if (prefix.trim().isNotEmpty)
              TextSpan(
                text: prefix,
                style: TextStyle(
                  color: ProjectTheme.brandColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            TextSpan(
              text: pricePart,
              style: const TextStyle(
                color: Color(0xFF1A1D26),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            if (suffix.trim().isNotEmpty)
              TextSpan(
                text: suffix.startsWith(' ') ? suffix : ' $suffix',
                style: TextStyle(
                  color: ProjectTheme.brandColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
