import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:mysafar_sdk/src/core/enum/currency.dart'
    show AppCurrency, AppCurrencyExtension;
import 'package:mysafar_sdk/src/core/tools/app_cache_manager.dart'
    show AppCacheManager;
import 'package:mysafar_sdk/src/core/tools/currency_provider.dart'
    show CurrencyProvider;
import 'package:mysafar_sdk/src/core/tools/formatters.dart' show ElementFormatter;
import 'package:mysafar_sdk/src/cubit/destinations/destination_list_cubit.dart';
import 'package:mysafar_sdk/src/model/remote/destination/destination_detail_model.dart'
    show DestLocalizedText;
import 'package:mysafar_sdk/src/model/remote/destination/destination_list_model.dart';
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart';
import 'package:mysafar_sdk/src/view/destinations/destination_details_page.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:provider/provider.dart' show Provider;
import 'package:shimmer/shimmer.dart';

/// Bottom bar "Yo'nalishlar" — 2 ustunli grid, rasm ustida narx badge.
class DestinationsListPage extends StatefulWidget {
  const DestinationsListPage({super.key});

  @override
  State<DestinationsListPage> createState() => _DestinationsListPageState();
}

class _DestinationsListPageState extends State<DestinationsListPage> {
  late final DestinationListCubit _cubit = DestinationListCubit(pageSize: 10);

  final ScrollController _scroll = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _searchCtrl.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      _cubit.loadNext();
    }
  }

  void _openDetails(DestinationListItem item) {
    HapticFeedback.lightImpact();
    AnalyticsService().trackButtonTap('destinations_tab_item');
    Navigator.of(context).pushNamed(
      DestinationDetailsPage.routeName,
      arguments: item,
    );
  }

  List<DestinationListItem> _filter(List<DestinationListItem> items) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((item) {
      final city = item.cityName.byLang(dataLang()).toLowerCase();
      final country = item.country.byLang(dataLang()).toLowerCase();
      final code = item.arrivalAirport.toLowerCase();
      return city.contains(q) || country.contains(q) || code.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                children: [
                  Text(
                    "destinations_tab".tr(),
                    textAlign: TextAlign.center,
                    style: context.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SearchField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "showcase_popular_title".tr(),
                      style: context.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Expanded(
              child: BlocProvider.value(
                value: _cubit,
                child: BlocBuilder<DestinationListCubit, DestinationListState>(
                  builder: (context, state) => _buildBody(context, state),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DestinationListState state) {
    if (state is DestinationListLoadingState) {
      return const _DestinationGridShimmer();
    }

    if (state is DestinationListErrorState) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("error_occurred".tr(), style: context.textTheme.bodyMedium),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _cubit.loadNext,
              child: Text("retry".tr()),
            ),
          ],
        ),
      );
    }

    final all = state is DestinationListSuccessState
        ? state.items
        : const <DestinationListItem>[];
    final items = _filter(all);
    final bool hasMore =
        state is DestinationListSuccessState && state.hasMore && _query.isEmpty;

    return RefreshIndicator(
      onRefresh: _cubit.refresh,
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
                Center(
                  child: Text(
                    "nothingFound".tr(),
                    style: context.textTheme.headlineMedium,
                  ),
                ),
              ],
            )
          : GridView.builder(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.92,
              ),
              itemCount: items.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= items.length) {
                  return const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                  );
                }
                return _DestinationGridCard(
                  item: items[index],
                  onTap: () => _openDetails(items[index]),
                );
              },
            ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: context.textTheme.bodyMedium?.copyWith(fontSize: 14.5),
      decoration: InputDecoration(
        hintText: "destinations_search_hint".tr(),
        hintStyle: context.textTheme.headlineMedium?.copyWith(
          fontSize: 14,
          color: const Color(0xFF9AA3B2),
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: Color(0xFF9AA3B2),
          size: 22,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1C2434) : const Color(0xFFF3F5F8),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: ProjectTheme.brandColor.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

class _DestinationGridCard extends StatelessWidget {
  final DestinationListItem item;
  final VoidCallback onTap;

  const _DestinationGridCard({required this.item, required this.onTap});

  String _lt(DestLocalizedText t) => t.byLang(dataLang());

  int _price(AppCurrency currency) => switch (currency) {
        AppCurrency.uzs => item.priceUzs,
        AppCurrency.rub => item.priceRub,
        AppCurrency.usd => item.priceUsd,
      };

  @override
  Widget build(BuildContext context) {
    final currency = Provider.of<CurrencyProvider>(context).currency;
    final price = _price(currency);
    final city = _lt(item.cityName);
    final code = item.arrivalAirport.trim().toUpperCase();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
                      child: _PriceBadge(amount: price, currency: currency),
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
    );
  }
}

class _PriceBadge extends StatelessWidget {
  final int amount;
  final AppCurrency currency;

  const _PriceBadge({required this.amount, required this.currency});

  @override
  Widget build(BuildContext context) {
    final number = ElementFormatter.formatNumberWithSpaces(amount);
    final pricePart = '$number ${currency.label}';
    final template =
        "home_price_from".tr(namedArgs: {"price": '\u0001'});
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

class _DestinationGridShimmer extends StatelessWidget {
  const _DestinationGridShimmer();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
