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

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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
                                  style: context.textTheme.bodyMedium?.copyWith(
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
                    // Soya kesilmasin — yuqori/pastdan joy.
                    height: _HomeDestinationCard.height + 20,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) =>
                          _HomeDestinationCard(item: items[index]),
                    ),
                  ),
                ],
              );
            default:
              return const SizedBox();
          }
        },
      ),
    );
  }
}

/// Manzil kartasi — to'liq rasm, ustida narx yorlig'i va shahar nomi.
/// Yangi UI: radius 20, bosilganda kichrayadi, kodi hero'dagi kabi chipda.
class _HomeDestinationCard extends StatefulWidget {
  static const double height = 196;
  static const double width = 172;

  final DestinationListItem item;
  const _HomeDestinationCard({required this.item});

  @override
  State<_HomeDestinationCard> createState() => _HomeDestinationCardState();
}

class _HomeDestinationCardState extends State<_HomeDestinationCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  String _lt(DestLocalizedText t) => t.byLang(dataLang());

  int _priceOf(AppCurrency currency) => switch (currency) {
        AppCurrency.uzs => widget.item.priceUzs,
        AppCurrency.rub => widget.item.priceRub,
        AppCurrency.usd => widget.item.priceUsd,
      };

  void _open() {
    HapticFeedback.lightImpact();
    AnalyticsService().trackButtonTap('home_popular_destination');
    Navigator.of(context).pushNamed(
      DestinationDetailsPage.routeName,
      arguments: widget.item,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final currency = Provider.of<CurrencyProvider>(context).currency;
    final price = _priceOf(currency);
    final city = _lt(widget.item.cityName);
    final code = widget.item.arrivalAirport.trim().toUpperCase();
    const double w = _HomeDestinationCard.width;
    const double h = _HomeDestinationCard.height;

    return Semantics(
      button: true,
      label: city,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) {
          _setPressed(false);
          _open();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: context.shadowDown,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.item.image.isNotEmpty)
                    CachedNetworkImage(
                      cacheManager: AppCacheManager.instance,
                      imageUrl: widget.item.image,
                      fit: BoxFit.cover,
                      // Karta o'lchamida dekodlanadi (№43).
                      memCacheWidth: coverImageCacheSize(context, w, h).width,
                      memCacheHeight: coverImageCacheSize(context, w, h).height,
                      fadeInDuration: const Duration(milliseconds: 150),
                      placeholder: (_, __) => ColoredBox(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : ProjectTheme.swimmer200,
                      ),
                      errorWidget: (_, __, ___) =>
                          const ColoredBox(color: Color(0xFF16244A)),
                    )
                  else
                    const ColoredBox(color: Color(0xFF16244A)),
                  // Matn o'qilishi uchun pastki qorayish.
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 104,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00000000), Color(0xCC000000)],
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
                        child:
                            _HomePriceBadge(amount: price, currency: currency),
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
                            SvgPicture.asset(
                              Assets.iconsDestPinIcon,
                              width: 15,
                              height: 15,
                              colorFilter: const ColorFilter.mode(
                                  Colors.white, BlendMode.srcIn),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                city,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: "packages/mysafar_sdk/Gilroy",
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
                          const SizedBox(height: 6),
                          _HomeCodeChip(code: code),
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

/// Rasm ustidagi kichik aeroport kodi (masalan "IST") — manzil sahifasidagi
/// hero chiplari bilan bir xil.
class _HomeCodeChip extends StatelessWidget {
  final String code;

  const _HomeCodeChip({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        code,
        style: const TextStyle(
          fontFamily: "packages/mysafar_sdk/Gilroy",
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          height: 1.1,
        ),
      ),
    );
  }
}

/// Rasm ustidagi oq narx yorlig'i: "narxi 1 713 405 UZSdan".
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
    // Yorliq rasm ustida turadi — mavzudan qat'i nazar oq (har qanday
    // fotosurat ustida o'qiladi).
    final muted = TextStyle(
      fontFamily: "packages/mysafar_sdk/Gilroy",
      color: ProjectTheme.secondaryTextLight,
      fontSize: 11.5,
      fontWeight: FontWeight.w500,
    );

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
            if (prefix.trim().isNotEmpty) TextSpan(text: prefix, style: muted),
            TextSpan(
              text: pricePart,
              style: TextStyle(
                fontFamily: "packages/mysafar_sdk/Gilroy",
                color: ProjectTheme.brandColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            if (suffix.trim().isNotEmpty) TextSpan(text: suffix, style: muted),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
