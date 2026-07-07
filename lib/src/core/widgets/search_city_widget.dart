import 'dart:async' show Timer;
import 'dart:io' show Platform;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:mysafar_sdk/src/core/tools/app_cache_manager.dart' show AppCacheManager;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/styles/theme_notifier.dart' show ThemeNotifier;
import 'package:mysafar_sdk/src/core/tools/project_utils.dart';
import 'package:mysafar_sdk/src/cubit/main/city/city_choose_cubit.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/model/remote/avia/airports_model.dart';
import 'package:mysafar_sdk/src/model/remote/fornex/pop_destinations.dart';
import 'package:provider/provider.dart' show Provider;
import 'package:shimmer/shimmer.dart';

class SearchCityWidget extends StatefulWidget {
  final int directionType;

  const SearchCityWidget({super.key, required this.directionType});

  @override
  State<SearchCityWidget> createState() => _SearchCityWidgetState();
}

class _SearchCityWidgetState extends State<SearchCityWidget> {
  late String title;
  final GetStorage _getStorage = GetStorage();
  List<AirPortsModel> _recentSearches = [];

  /// Debounce timer for airport search to avoid a network request per keystroke.
  Timer? _searchDebounce;

  // Cache keys
  static const String _recentFromKey = 'recent_from_airports';
  static const String _recentToKey = 'recent_to_airports';

  String get _cacheKey =>
      widget.directionType == 0 ? _recentFromKey : _recentToKey;

  @override
  void initState() {
    title = getAppBarTitle(widget.directionType);
    _loadRecentSearches();
    super.initState();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _loadRecentSearches() {
    final cachedData = _getStorage.read(_cacheKey);
    if (cachedData != null && cachedData is List) {
      _recentSearches = cachedData
          .map((e) => AirPortsModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      setState(() {});
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
    _saveToRecentSearches(airport);
    Navigator.of(context).pop(airport);
  }

  String getAppBarTitle(int type) {
    if (type == 0) {
      return "choose_visit_dir".tr();
    } else {
      return "choose_return_dir".tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final langCode = context.locale.languageCode;
    final searchLang = langCode == "uz" ? "en" : langCode;

    return BlocProvider(
      create: (_) {
        final cubit = CityChooseCubit();
        if (widget.directionType == 0) {
          cubit.loadNearbyAirport(lang: searchLang);
        }
        return cubit;
      },
      child: BlocBuilder<CityChooseCubit, CityChooseStates>(
        builder: (BuildContext context, CityChooseStates state) {
          return Scaffold(
              appBar: AppBar(
                leading: SizedBox.fromSize(),
                centerTitle: true,
                title: Text(title, style: context.textTheme.bodyMedium),
                actions: [
                  IconButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                        );
                      },
                      icon: Icon(Icons.close))
                ],
              ),
              body: Padding(
                padding: context.k16horizontalPadding,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      context.szBoxHeight16,
                      SizedBox(
                          height: 56,
                          width: double.infinity,
                          child: TextFormField(
                            autofocus: true,
                            controller:
                                context.watch<CityChooseCubit>().controller,
                            keyboardType: TextInputType.name,
                            style: context.textTheme.bodyMedium,
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 16.0, horizontal: 16),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(12),
                                child: SvgPicture.asset(
                                  Assets.iconsSearchIcon,
                                ),
                              ),
                              suffixIcon: getLoadingWidget(state, context),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                      color: context.color.outline, width: 1)),
                              hintStyle: context.textTheme.headlineMedium,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                      color: context.color.outline, width: 1)),
                            ),
                            onChanged: (value) {
                              _searchDebounce?.cancel();
                              final cubit = context.read<CityChooseCubit>();
                              if (value.length > 2) {
                                final lang =
                                    context.locale.languageCode == "uz"
                                        ? "en"
                                        : context.locale.languageCode;
                                _searchDebounce = Timer(
                                    const Duration(milliseconds: 300), () {
                                  cubit.getAirports(part: value, lang: lang);
                                });
                              } else if (value.isEmpty) {
                                cubit.resetToInit();
                              }
                            },
                          )),
                      Builder(
                        builder: (context) {
                          switch (state) {
                            case CityChooseSuccessState():
                              return ListView.builder(
                                physics: NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.all(0.0),
                                shrinkWrap: true,
                                itemCount: state.airports.length,
                                itemBuilder: (context, index) {
                                  final city = state.airports[index];
                                  return Column(
                                    children: [
                                      ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        onTap: () {
                                          _onAirportSelected(
                                              state.airports[index]);
                                        },
                                        leading: SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: SvgPicture.asset(
                                            Assets.homeMapLocationPin,

                                          ),
                                        ),
                                        title: Text(
                                          state.airports[index].cityName ?? "",
                                          style: context.textTheme.bodyMedium,
                                        ),
                                        subtitle: Text(
                                          state.airports[index].cityIataCode ??
                                              "",
                                          style:
                                              context.textTheme.headlineMedium,
                                        ),
                                      ),
                                      Column(
                                        children: List.generate(
                                            city.airports?.length ?? 0,
                                            (i) => ListTile(
                                                  onTap: () {
                                                    final selectedAirport =
                                                        city.copyWith(
                                                            cityIataCode: city
                                                                .airports
                                                                ?.elementAt(i)
                                                                .airportIataCode);
                                                    _onAirportSelected(
                                                        selectedAirport);
                                                  },
                                                  contentPadding:
                                                      EdgeInsets.only(
                                                    left: 24.0,
                                                  ),
                                                  leading: SizedBox(
                                                    height: 24,
                                                    width: 24,
                                                    child: SvgPicture.asset(
                                                        Assets.iconsPlaneIcon),
                                                  ),
                                                  title: Text(
                                                    city.airports?[i]
                                                            .airportName ??
                                                        "",
                                                  ),
                                                  subtitle: Text(
                                                    city.airports?[i]
                                                            .airportIataCode ??
                                                        "",
                                                    style: context.textTheme
                                                        .headlineMedium,
                                                  ),
                                                )),
                                      )
                                    ],
                                  );
                                },
                              );
                            case CityChooseErrorState():
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: Text(state.error),
                                ),
                              );
                            case CityChooseInitState():
                              return _buildInitialContent(context, state);
                            default:
                              return _buildInitialContent(context, null);
                          }
                        },
                      ),
                      SizedBox(
                        height: context.height * 0.1,
                      )
                    ],
                  ),
                ),
              ));
        },
      ),
    );
  }

  Widget _buildInitialContent(
      BuildContext context, CityChooseInitState? initState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nearby airport section (only for 'from' direction)
        if (widget.directionType == 0) ...[
          _buildNearbyAirportSection(context, initState),
        ],
        // Recent searches
        if (_recentSearches.isNotEmpty) ...[
          Padding(
            padding: context.k16verticalPadding,
            child: Text("recent_searches".tr(),
                style: context.textTheme.displayMedium),
          ),
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: _recentSearches.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final airport = _recentSearches[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => _onAirportSelected(airport),
                leading: SizedBox(
                  height: 24,
                  width: 24,
                  child: SvgPicture.asset(Assets.homeMapLocationPin),
                ),
                title: Text(
                  airport.cityName ?? "",
                  style: context.textTheme.bodyMedium,
                ),
                subtitle: Text(
                  airport.cityIataCode ?? "",
                  style: context.textTheme.headlineMedium,
                ),
              );
            },
          ),
        ],
        // Popular destinations
        if (ProjectUtils.popularDestinations?.isNotEmpty ?? false) ...[
          Padding(
            padding: context.k16verticalPadding,
            child: Text("popular_city".tr(),
                style: context.textTheme.displayMedium),
          ),
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: ProjectUtils.popularDestinations?.length ?? 0,
            separatorBuilder: (context, index) => context.szBoxHeight8,
            itemBuilder: (context, index) {
              final destinations = ProjectUtils.popularDestinations;
              return InkWell(
                onTap: () {
                  final airport = AirPortsModel(
                    cityIataCode: destinations?[index].destination.aviationCode,
                    cityName: _getDestinationTitle(
                        destinations?[index].destination.name,
                        context.locale.languageCode),
                  );
                  _onAirportSelected(airport);
                },
                child: Row(children: [
                  SizedBox(
                    width: 58,
                    height: 58,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        cacheManager: AppCacheManager.instance,
                        cacheKey: destinations?[index].images[0].image,
                        imageUrl: "${destinations?[index].images[0].image}",
                        fit: BoxFit.cover,
                        memCacheWidth: 120,
                        memCacheHeight: 120,
                      ),
                    ),
                  ),
                  context.szBoxWidth8,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          _getDestinationTitle(
                              destinations?[index].destination.name,
                              context.locale.languageCode),
                          style: context.textTheme.bodyMedium),
                      Text(destinations?[index].destination.aviationCode ?? "",
                          style: context.textTheme.headlineMedium)
                    ],
                  )
                ]),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildNearbyAirportSection(
      BuildContext context, CityChooseInitState? state) {
    // Show shimmer while loading
    if (state?.isLoadingNearby == true) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: context.k16verticalPadding,
            child: Text("nearby_airport".tr(),
                style: context.textTheme.displayMedium),
          ),
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                height: 24,
                width: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              title: Container(
                height: 16,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              subtitle: Container(
                height: 12,
                width: 60,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Show nearby airport if found
    if (state?.nearbyAirport != null) {
      final airport = state!.nearbyAirport!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: context.k16verticalPadding,
            child: Text("nearby_airport".tr(),
                style: context.textTheme.displayMedium),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            onTap: () => _onAirportSelected(airport),
            leading: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: ProjectTheme.brandColor.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.my_location,
                color: ProjectTheme.brandColor,
                size: 20,
              ),
            ),
            title: Text(
              airport.cityName ?? "",
              style: context.textTheme.bodyMedium,
            ),
            subtitle: Text(
              airport.cityIataCode ?? "",
              style: context.textTheme.headlineMedium,
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: context.color.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const Divider(height: 1),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget getLoadingWidget(CityChooseStates state, BuildContext context) {
    switch (state) {
      case CityChooseLoadingState():
        if (Platform.isIOS) {
          return CupertinoActivityIndicator(
            radius: 10,
            color: Provider.of<ThemeNotifier>(context).isDark
                ? Colors.white
                : Colors.black,
          );
        }
        return Transform.scale(
          scale: 0.5,
          child: const CircularProgressIndicator(),
        );
      default:
        return SizedBox();
    }
  }

  String _getDestinationTitle(PopDestinationsText? name, String lang) {
    switch (lang) {
      case 'en':
        return name?.en ?? "";
      case 'ru':
        return name?.ru ?? "";
      default:
        return name?.uz ?? "";
    }
  }
}
