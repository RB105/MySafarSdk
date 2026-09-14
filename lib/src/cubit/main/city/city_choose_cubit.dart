// used in city choose widget
import 'package:dio/dio.dart' show CancelToken;
import 'package:equatable/equatable.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/model/remote/avia/airports_model.dart';
import 'package:mysafar_sdk/src/model/remote/avia/top_city_model.dart';
import 'package:mysafar_sdk/src/service/avia/airport_local_search_service.dart';
import 'package:mysafar_sdk/src/service/avia_service.dart';
import 'package:mysafar_sdk/src/service/geolacator/location_airport_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysafar_sdk/src/core/config/network_request_scope.dart'
    show NetworkCancel, NetworkRequestScope;

part 'city_choose_state.dart';

class CityChooseCubit extends Cubit<CityChooseStates> with NetworkCancel {
  CityChooseCubit({
    AirportLocalSearchService? localSearch,
    AviaService? aviaService,
  })  : _localSearch = localSearch ?? AirportLocalSearchService(),
        _aviaService = aviaService ?? AviaService(),
        super(CityChooseInitState()) {
    // JSON + index ni ochilishda background’da tayyorlab qo‘yamiz.
    _localSearch.ensureLoaded();
  }

  final AirportLocalSearchService _localSearch;
  final AviaService _aviaService;
  final LocationAirportService _locationService = LocationAirportService();

  TextEditingController controller = TextEditingController();

  /// Eng so‘nggi so‘rov — eski natija kelib qolmasin.
  int _searchSeq = 0;

  // Boshlang'ich (qidiruvsiz) holat ma'lumotlari — qidiruvdan qaytganda
  // yo'qolmasligi uchun cubit ichida saqlanadi.
  AirPortsModel? _nearby;
  bool _loadingNearby = false;
  bool _locationFailed = false;
  List<AirPortsModel> _suggestions = const [];
  Future<AirPortsModel?>? _nearbyRequest;

  CityChooseInitState get _initState => CityChooseInitState(
        nearbyAirport: _nearby,
        isLoadingNearby: _loadingNearby,
        locationFailed: _locationFailed,
        suggestions: _suggestions,
      );

  /// Faqat boshlang'ich holat ko'rinib turganda yangilaydi — qidiruv
  /// natijalari ustiga yozib yubormaslik uchun.
  void _refreshInit() {
    if (isClosed || state is! CityChooseInitState) return;
    emit(_initState);
  }

  /// Yaqin aeroportni **jim** yuklaydi: keshdan yoki ruxsat allaqachon
  /// berilgan bo'lsa. Ruxsat so'rovi faqat foydalanuvchi bosganda
  /// ([locateCurrentAirport]).
  Future<void> loadNearbyAirport({String? lang}) async {
    _nearby = _locationService.cachedNearbyAirport;
    if (_nearby != null) {
      _refreshInit();
      return;
    }
    if (_locationService.hasAttemptedLocation) return;
    if (!await _locationService.canLocateSilently() || isClosed) return;
    await _resolveNearby(lang: lang);
  }

  /// "Joriy joylashuv" bosilganda: kerak bo'lsa ruxsat so'raydi va
  /// aniqlangan aeroportni qaytaradi (topilmasa — `null`).
  Future<AirPortsModel?> locateCurrentAirport({String? lang}) async {
    final airport = _nearby ?? await _resolveNearby(lang: lang, force: true);
    if (airport == null && !isClosed) {
      _locationFailed = true;
      _refreshInit();
    }
    return airport;
  }

  Future<AirPortsModel?> _resolveNearby({String? lang, bool force = false}) {
    return _nearbyRequest ??= () async {
      _loadingNearby = true;
      _locationFailed = false;
      _refreshInit();
      AirPortsModel? airport;
      try {
        airport =
            await _locationService.getNearbyAirport(lang: lang, force: force);
      } catch (e) {
        debugPrint("Error loading nearby airport: $e");
      }
      _nearbyRequest = null;
      if (isClosed) return airport;
      _nearby = airport;
      _loadingNearby = false;
      _refreshInit();
      return airport;
    }();
  }

  static const int _maxSuggestions = 6;

  /// Tavsiyalar so'rovi alohida token bilan — qidiruv yozilganda
  /// (`refreshNetworkCancel`) bekor bo'lib ketmasin.
  final CancelToken _suggestionsCancel = CancelToken();

  /// "Tavsiya etilgan joylar" — faqat serverdan kelgan ma'lumotdan:
  /// [popularCodes] (mashhur yo'nalishlar) va top yo'nalishlar API
  /// (`from_iata` / `to_iata`). Ma'lumot bo'lmasa bo'lim ko'rsatilmaydi —
  /// statik (hardcode) ro'yxat yo'q.
  Future<void> loadSuggestions({
    required bool isFrom,
    required String lang,
    Iterable<String> popularCodes = const [],
    Set<String> exclude = const {},
  }) async {
    final codes = <String>[...popularCodes];
    try {
      final response = await NetworkRequestScope.run(
        _suggestionsCancel,
        () => _aviaService.getTopCities(),
      );
      if (response is NetworkSuccessResponse &&
          response.data is List<TopCityModel>) {
        final routes = List<TopCityModel>.of(response.data)
          ..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
        codes.addAll(routes.map((r) => (isFrom ? r.fromIata : r.toIata) ?? ''));
      }
    } catch (e) {
      debugPrint("CityChooseCubit top cities error: $e");
    }
    if (isClosed) return;

    final unique = codes
        .map((c) => c.trim().toUpperCase())
        .where((c) => c.length == 3 && !exclude.contains(c))
        .toSet()
        .take(_maxSuggestions);
    final found = await Future.wait(unique.map((c) => _suggestionFor(c, lang)));
    if (isClosed) return;
    _suggestions = found.whereType<AirPortsModel>().toList(growable: false);
    _refreshInit();
  }

  Future<AirPortsModel?> _suggestionFor(String code, String lang) async {
    final iata = code.trim().toUpperCase();
    if (iata.length != 3) return null;
    try {
      final groups =
          await _localSearch.search(query: iata, lang: lang, limit: 3);
      for (final group in groups) {
        if (group.cityIataCode?.toUpperCase() == iata) return group;
        final isChild = group.airports
                ?.any((a) => a.airportIataCode?.toUpperCase() == iata) ??
            false;
        if (isChild) return group.copyWith(cityIataCode: iata, airports: []);
      }
    } catch (e) {
      debugPrint("CityChooseCubit suggestion $iata error: $e");
    }
    return null;
  }

  /// Davlat qatori bosilganda — shu davlatdagi barcha shahar/aeroportlar.
  /// [country] — ISO kod (`UZ`) yoki davlat nomi.
  Future<void> getAirportsByCountry({
    required String country,
    String? lang,
  }) async {
    refreshNetworkCancel();
    final seq = ++_searchSeq;
    try {
      final results = await _localSearch.searchByCountry(
        country: country,
        lang: lang ?? 'en',
      );
      if (isClosed || seq != _searchSeq) return;
      emit(results.isEmpty
          ? CityChooseErrorState('nothingFound'.tr())
          : CityChooseSuccessState(results, country: country));
    } catch (e) {
      debugPrint("CityChooseCubit getAirportsByCountry error: $e");
      if (isClosed || seq != _searchSeq) return;
      emit(CityChooseErrorState(e.toString()));
    }
  }

  /// Qidiruv strategiyasi:
  /// 1) Har doim local JSON (1+ harf) — isolate’da, Loading emit qilinmaydi
  /// 2) Local bo'sh va so'rov ≥ 3 harf bo'lsa — API fallback (+ Loading)
  Future<void> getAirports({required String part, String? lang}) async {
    refreshNetworkCancel();
    final query = part.trim();
    if (query.isEmpty) {
      resetToInit();
      return;
    }

    final searchLang = lang ?? 'en';
    final seq = ++_searchSeq;

    try {
      final localResults = await _localSearch.search(
        query: query,
        lang: searchLang,
      );
      if (isClosed || seq != _searchSeq) return;

      if (localResults.isNotEmpty) {
        emit(CityChooseSuccessState(localResults));
        return;
      }

      final localByCountry = await _localSearch.searchByCountry(
        country: query,
        lang: searchLang,
      );
      if (isClosed || seq != _searchSeq) return;

      if (localByCountry.isNotEmpty) {
        emit(CityChooseSuccessState(localByCountry));
        return;
      }

      if (query.length < 3) {
        emit(CityChooseErrorState('nothingFound'.tr()));
        return;
      }

      // API faqat local topmaganda — loading shu yerda.
      emit(const CityChooseLoadingState());
      final apiLang = searchLang == 'uz' ? 'en' : searchLang;
      final NetworkResponse response = await withNetworkCancel(
        () => _aviaService.getAirports(part: query, lang: apiLang),
      );
      if (isClosed || seq != _searchSeq) return;

      if (response is NetworkSuccessResponse) {
        final data = response.data;
        if (data is List<AirPortsModel> && data.isNotEmpty) {
          emit(CityChooseSuccessState(data));
        } else {
          emit(CityChooseErrorState('nothingFound'.tr()));
        }
      } else if (response is NetworkErrorResponse) {
        emit(CityChooseErrorState(response.getError()));
      }
    } catch (e) {
      debugPrint("CityChooseCubit getAirports error: $e");
      if (isClosed || seq != _searchSeq) return;
      emit(CityChooseErrorState(e.toString()));
    }
  }

  void resetToInit() {
    _searchSeq++;
    _nearby ??= _locationService.cachedNearbyAirport;
    emit(_initState);
  }

  @override
  Future<void> close() {
    if (!_suggestionsCancel.isCancelled) _suggestionsCancel.cancel('closed');
    controller.dispose();
    return super.close();
  }
}
