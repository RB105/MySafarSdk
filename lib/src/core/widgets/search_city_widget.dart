import 'dart:async' show Timer;
import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mysafar_sdk/src/core/config/sdk_storage.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/tools/project_utils.dart';
import 'package:mysafar_sdk/src/cubit/main/city/city_choose_cubit.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/model/remote/avia/airports_model.dart';
import 'package:mysafar_sdk/src/service/avia/airport_local_search_service.dart';

/// "Qayerdan? / Qayerga?" joy qidirish oynasi.
class SearchCityWidget extends StatefulWidget {
  final int directionType;

  /// Sheet'ning `DraggableScrollableSheet` controller'i — ro'yxat eng tepada
  /// bo'lganda pastga tortib yopish shu orqali ishlaydi.
  final ScrollController? scrollController;

  const SearchCityWidget({
    super.key,
    required this.directionType,
    this.scrollController,
  });

  @override
  State<SearchCityWidget> createState() => _SearchCityWidgetState();
}

class _SearchCityWidgetState extends State<SearchCityWidget> {
  final GetStorage _getStorage = sdkStorage();
  List<AirPortsModel> _recentSearches = [];

  /// Debounce timer for airport search.
  Timer? _searchDebounce;

  /// Ro'yxat surilganda qidiruv maydoni ostida chiziq ko'rsatiladi.
  final ValueNotifier<bool> _isScrolled = ValueNotifier(false);

  // Cache keys
  static const String _recentFromKey = 'recent_from_airports';
  static const String _recentToKey = 'recent_to_airports';

  static const double _hPadding = 16;
  static const double _iconSize = 24;
  static const double _iconGap = 12;

  bool get _isFrom => widget.directionType == 0;

  String get _cacheKey => _isFrom ? _recentFromKey : _recentToKey;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _isScrolled.dispose();
    super.dispose();
  }

  void _loadRecentSearches() {
    final cachedData = _getStorage.read(_cacheKey);
    if (cachedData != null && cachedData is List) {
      _recentSearches = cachedData
          .map((e) => AirPortsModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  void _saveToRecentSearches(AirPortsModel airport) {
    _recentSearches.removeWhere(
      (item) => item.cityIataCode == airport.cityIataCode,
    );

    _recentSearches.insert(0, airport);

    if (_recentSearches.length > 5) {
      _recentSearches = _recentSearches.sublist(0, 5);
    }

    _getStorage.write(
      _cacheKey,
      _recentSearches.map((e) => e.toJson()).toList(),
    );
  }

  void _onAirportSelected(AirPortsModel airport) {
    HapticFeedback.selectionClick();
    _saveToRecentSearches(airport);
    Navigator.of(context).pop(airport);
  }

  /// Local JSON search: uz / ru / en to'liq qo'llab-quvvatlanadi.
  String _searchLang(BuildContext context) {
    final code = context.locale.languageCode;
    return (code == 'uz' || code == 'ru' || code == 'en') ? code : 'en';
  }

  // ---------------------------------------------------------------------------
  // Colors
  // ---------------------------------------------------------------------------

  Color get _sheetColor => context.isDarkMode
      ? ProjectTheme.cardColorDark
      : ProjectTheme.cardColorLight;

  Color get _textColor => context.isDarkMode
      ? ProjectTheme.textColorDark
      : ProjectTheme.textColorLight;

  Color get _secondaryColor => context.isDarkMode
      ? ProjectTheme.secondaryTextDark
      : ProjectTheme.secondaryTextLight;

  Color get _hintColor => context.isDarkMode
      ? ProjectTheme.disabledTextDark
      : ProjectTheme.disabledTextLight;

  Color get _borderColor =>
      context.isDarkMode ? ProjectTheme.borderDark : ProjectTheme.borderLight;

  TextStyle get _titleStyle => context.textTheme.bodyMedium!.copyWith(
        color: _textColor,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.25,
      );

  TextStyle get _subtitleStyle => context.textTheme.bodyMedium!.copyWith(
        color: _textColor.withValues(alpha: 0.8),
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.25,
      );

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final lang = _searchLang(context);
        final cubit = CityChooseCubit();
        if (_isFrom) cubit.loadNearbyAirport(lang: lang);
        cubit.loadSuggestions(
          isFrom: _isFrom,
          lang: lang,
          popularCodes: _isFrom
              ? const []
              : (ProjectUtils.popularDestinations ?? const [])
                  .map((d) => d.destination.aviationCode),
          exclude: _recentSearches
              .map((e) => (e.cityIataCode ?? '').toUpperCase())
              .toSet(),
        );
        return cubit;
      },
      // TextField BlocBuilder tashqarisida — state o‘zgarganda klaviatura
      // qayta build bo‘lmaydi (qotishning asosiy UI sababi).
      child: Scaffold(
        backgroundColor: _sheetColor,
        body: Column(
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(_hPadding, 12, _hPadding, 12),
              child: Builder(builder: _buildSearchField),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _isScrolled,
              builder: (context, scrolled, _) => AnimatedOpacity(
                opacity: scrolled ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: Divider(height: 1, thickness: 1, color: _borderColor),
              ),
            ),
            Expanded(
              child: NotificationListener<ScrollUpdateNotification>(
                onNotification: (n) {
                  if (n.depth == 0) _isScrolled.value = n.metrics.pixels > 0;
                  return false;
                },
                child: BlocBuilder<CityChooseCubit, CityChooseStates>(
                  builder: (context, state) => ListView(
                    controller: widget.scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      _hPadding,
                      12,
                      _hPadding,
                      context.bottomPadding + 24,
                    ),
                    children: switch (state) {
                      CityChooseSuccessState() => _buildResults(context, state),
                      CityChooseErrorState() => [_buildEmpty(state.error)],
                      CityChooseInitState() => _buildInitial(context, state),
                      _ => _buildInitial(context, null),
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 52),
              child: Text(
                (_isFrom ? 'place_where_from' : 'place_where_to').tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelMedium?.copyWith(
                  color: _textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: _svg(Assets.iconsPlaceCloseIcon, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final cubit = context.read<CityChooseCubit>();
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _borderColor, width: 1),
    );

    return TextField(
      controller: cubit.controller,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.search,
      textAlignVertical: TextAlignVertical.center,
      cursorColor: _textColor,
      style: _titleStyle,
      decoration: InputDecoration(
        isDense: true,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        hintText: 'place_search_hint'.tr(),
        hintStyle: _titleStyle.copyWith(color: _hintColor),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 8),
          child: Text(
            (_isFrom ? 'from' : 'to').tr(),
            style: _titleStyle.copyWith(color: _secondaryColor),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0),
        suffixIcon: _buildSuffix(cubit),
        suffixIconConstraints:
            const BoxConstraints(minWidth: 44, minHeight: 44),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: _textColor, width: 1.5),
        ),
      ),
      onChanged: (value) {
        _searchDebounce?.cancel();
        final trimmed = value.trim();
        if (trimmed.isEmpty) {
          cubit.resetToInit();
          return;
        }
        final lang = _searchLang(context);
        _searchDebounce = Timer(
          const Duration(milliseconds: 350),
          () => cubit.getAirports(part: trimmed, lang: lang),
        );
      },
    );
  }

  Widget _buildSuffix(CityChooseCubit cubit) {
    return BlocBuilder<CityChooseCubit, CityChooseStates>(
      buildWhen: (prev, next) => prev.runtimeType != next.runtimeType,
      builder: (context, state) {
        if (state is CityChooseLoadingState) return _loader();
        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: cubit.controller,
          builder: (context, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              onPressed: () {
                _searchDebounce?.cancel();
                cubit.controller.clear();
                cubit.resetToInit();
              },
              icon:
                  _svg(Assets.iconsPlaceClearIcon, size: 20, color: _hintColor),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Initial content: current location, recent searches, suggested places
  // ---------------------------------------------------------------------------

  List<Widget> _buildInitial(BuildContext context, CityChooseInitState? state) {
    final suggestions = state?.suggestions ?? const <AirPortsModel>[];
    return [
      if (_isFrom) _buildCurrentLocation(context, state),
      if (_recentSearches.isNotEmpty) ...[
        _sectionTitle('recent_searches'.tr()),
        for (final airport in _recentSearches)
          _PlaceTile(
            icon: _svg(Assets.iconsPlaceRecentIcon),
            title: _nameWithCode(airport.cityName, airport.cityIataCode),
            subtitle: _typeWithCountry(
              _isCityGroup(airport)
                  ? 'place_type_city'.tr()
                  : 'place_type_airport'.tr(),
              airport.countryName,
            ),
            titleStyle: _titleStyle,
            subtitleStyle: _subtitleStyle,
            onTap: () => _onAirportSelected(airport),
          ),
      ],
      if (suggestions.isNotEmpty) ...[
        _sectionTitle('place_suggested'.tr()),
        for (final place in suggestions) _suggestionTile(place),
      ],
    ];
  }

  Widget _buildCurrentLocation(
      BuildContext context, CityChooseInitState? state) {
    final nearby = state?.nearbyAirport;
    final isLoading = state?.isLoadingNearby ?? false;

    final String subtitle;
    if (isLoading) {
      subtitle = 'determining_location'.tr();
    } else if (nearby != null) {
      subtitle = _nameWithCode(nearby.cityName, nearby.cityIataCode);
    } else if (state?.locationFailed ?? false) {
      subtitle = 'place_location_unavailable'.tr();
    } else {
      subtitle = 'place_use_current_location'.tr();
    }

    return _PlaceTile(
      icon: isLoading ? _loader() : _svg(Assets.iconsPlaceCurrentLocationIcon),
      title: 'place_current_location'.tr(),
      subtitle: subtitle,
      titleStyle: _titleStyle,
      subtitleStyle: _subtitleStyle,
      onTap: isLoading
          ? null
          : () async {
              final cubit = context.read<CityChooseCubit>();
              final airport =
                  await cubit.locateCurrentAirport(lang: _searchLang(context));
              if (airport != null && mounted) _onAirportSelected(airport);
            },
    );
  }

  Widget _suggestionTile(AirPortsModel place) {
    final isCity = _isCityGroup(place);
    return _PlaceTile(
      icon: _svg(
          isCity ? Assets.iconsPlaceCityIcon : Assets.iconsPlaceAirportIcon),
      title: _nameWithCode(place.cityName, place.cityIataCode),
      subtitle: _typeWithCountry(
        isCity ? 'place_type_city'.tr() : 'place_type_airport'.tr(),
        place.countryName,
      ),
      titleStyle: _titleStyle,
      subtitleStyle: _subtitleStyle,
      onTap: () => _onAirportSelected(place),
    );
  }

  Widget _countryTile(AirPortsModel source) {
    final name = source.countryName ?? '';
    final code = source.countryIataCode ?? '';
    if (name.isEmpty) return const SizedBox.shrink();
    return Builder(
      builder: (context) => _PlaceTile(
        icon: _svg(Assets.iconsPlaceCountryIcon),
        title: name,
        subtitle: 'place_type_country'.tr(),
        titleStyle: _titleStyle,
        subtitleStyle: _subtitleStyle,
        onTap: () {
          _searchDebounce?.cancel();
          final cubit = context.read<CityChooseCubit>();
          cubit.controller.value = TextEditingValue(
            text: name,
            selection: TextSelection.collapsed(offset: name.length),
          );
          cubit.getAirportsByCountry(
            country: code.isNotEmpty ? code : name,
            lang: _searchLang(context),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Search results
  // ---------------------------------------------------------------------------

  List<Widget> _buildResults(
      BuildContext context, CityChooseSuccessState state) {
    return [
      if (state.country == null)
        for (final country in _matchedCountries(context, state.airports))
          _countryTile(country),
      for (final city in state.airports) ..._resultGroup(city),
    ];
  }

  /// So'rov davlat nomiga mos kelsa — natijalar tepasida davlat qatori.
  List<AirPortsModel> _matchedCountries(
      BuildContext context, List<AirPortsModel> results) {
    final query = AirportLocalSearchService.normalize(
        context.read<CityChooseCubit>().controller.text);
    if (query.length < 2) return const [];
    final seen = <String>{};
    final matched = <AirPortsModel>[];
    for (final place in results) {
      final name = place.countryName ?? '';
      if (name.isEmpty || !seen.add(name)) continue;
      if (AirportLocalSearchService.normalize(name).startsWith(query)) {
        matched.add(place);
        if (matched.length == 2) break;
      }
    }
    return matched;
  }

  List<Widget> _resultGroup(AirPortsModel city) {
    final airports = city.airports ?? const <Airports>[];
    if (airports.isEmpty) {
      return [
        _PlaceTile(
          icon: _svg(Assets.iconsPlaceAirportIcon),
          title: _nameWithCode(city.cityName, city.cityIataCode),
          subtitle:
              _typeWithCountry('place_type_airport'.tr(), city.countryName),
          titleStyle: _titleStyle,
          subtitleStyle: _subtitleStyle,
          onTap: () => _onAirportSelected(city),
        ),
      ];
    }

    return [
      _PlaceTile(
        icon: _svg(Assets.iconsPlaceCityIcon),
        title: _nameWithCode(city.cityName, city.cityIataCode),
        subtitle: _typeWithCountry('place_type_city'.tr(), city.countryName),
        titleStyle: _titleStyle,
        subtitleStyle: _subtitleStyle,
        onTap: () => _onAirportSelected(city),
      ),
      for (final airport in airports)
        _PlaceTile(
          indent: 24,
          icon: _svg(Assets.iconsPlaceAirportIcon),
          title: _nameWithCode(airport.airportName, airport.airportIataCode),
          subtitle:
              _typeWithCountry('place_type_airport'.tr(), city.countryName),
          titleStyle: _titleStyle,
          subtitleStyle: _subtitleStyle,
          onTap: () => _onAirportSelected(
            city.copyWith(cityIataCode: airport.airportIataCode),
          ),
        ),
    ];
  }

  Widget _buildEmpty(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          _svg(Assets.iconsPlaceEmptySearchIcon, size: 40, color: _hintColor),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: _titleStyle.copyWith(color: _secondaryColor),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(
        text,
        style: context.textTheme.labelMedium?.copyWith(
          color: _textColor,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _svg(String asset, {double size = _iconSize, Color? color}) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color ?? _textColor, BlendMode.srcIn),
    );
  }

  Widget _loader() {
    return SizedBox.square(
      dimension: _iconSize,
      child: Center(
        child: Platform.isIOS
            ? CupertinoActivityIndicator(radius: 9, color: _textColor)
            : SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _textColor,
                ),
              ),
      ),
    );
  }

  /// Bir nechta aeroportli shahar (metro kod, masalan MOW) — "Shahar".
  bool _isCityGroup(AirPortsModel place) {
    final airports = place.airports ?? const <Airports>[];
    return airports.length > 1 &&
        !airports.any((a) => a.airportIataCode == place.cityIataCode);
  }

  String _nameWithCode(String? name, String? code) {
    final n = (name ?? '').trim();
    final c = (code ?? '').trim();
    if (n.isEmpty) return c;
    if (c.isEmpty) return n;
    return '$n ($c)';
  }

  String _typeWithCountry(String type, String? country) {
    final c = (country ?? '').trim();
    return c.isEmpty ? type : '$type · $c';
  }
}

class _PlaceTile extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;
  final VoidCallback? onTap;
  final double indent;

  const _PlaceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.onTap,
    this.indent = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.only(left: indent, top: 12, bottom: 12),
        child: Row(
          children: [
            SizedBox.square(
              dimension: _SearchCityWidgetState._iconSize,
              child: Center(child: icon),
            ),
            const SizedBox(width: _SearchCityWidgetState._iconGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: subtitleStyle,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
