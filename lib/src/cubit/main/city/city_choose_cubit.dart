// used in city choose widget
import 'package:equatable/equatable.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/model/remote/avia/airports_model.dart';
import 'package:mysafar_sdk/src/service/avia/airport_local_search_service.dart';
import 'package:mysafar_sdk/src/service/avia_service.dart';
import 'package:mysafar_sdk/src/service/geolacator/location_airport_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'city_choose_state.dart';

class CityChooseCubit extends Cubit<CityChooseStates> {
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

  /// Load nearby airport based on location (only for 'from' direction)
  Future<void> loadNearbyAirport({String? lang}) async {
    final cachedAirport = _locationService.cachedNearbyAirport;
    if (cachedAirport != null) {
      emit(CityChooseInitState(
          nearbyAirport: cachedAirport, isLoadingNearby: false));
      return;
    }

    if (_locationService.hasAttemptedLocation) {
      emit(CityChooseInitState(nearbyAirport: null, isLoadingNearby: false));
      return;
    }

    emit(CityChooseInitState(nearbyAirport: null, isLoadingNearby: true));

    try {
      final nearbyAirport = await _locationService.getNearbyAirport(lang: lang);
      if (isClosed) return;
      emit(CityChooseInitState(
          nearbyAirport: nearbyAirport, isLoadingNearby: false));
    } catch (e) {
      debugPrint("Error loading nearby airport: $e");
      if (isClosed) return;
      emit(CityChooseInitState(nearbyAirport: null, isLoadingNearby: false));
    }
  }

  /// Qidiruv strategiyasi:
  /// 1) Har doim local JSON (1+ harf) — isolate’da, Loading emit qilinmaydi
  /// 2) Local bo'sh va so'rov ≥ 3 harf bo'lsa — API fallback (+ Loading)
  Future<void> getAirports({required String part, String? lang}) async {
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

      if (query.length < 3) {
        emit(CityChooseErrorState('nothingFound'.tr()));
        return;
      }

      // API faqat local topmaganda — loading shu yerda.
      emit(const CityChooseLoadingState());
      final apiLang = searchLang == 'uz' ? 'en' : searchLang;
      final NetworkResponse response =
          await _aviaService.getAirports(part: query, lang: apiLang);
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
    final cachedAirport = _locationService.cachedNearbyAirport;
    emit(CityChooseInitState(
        nearbyAirport: cachedAirport, isLoadingNearby: false));
  }

  @override
  Future<void> close() {
    controller.dispose();
    return super.close();
  }
}
