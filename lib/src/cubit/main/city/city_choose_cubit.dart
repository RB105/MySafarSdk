// used in city choose widget
import 'package:equatable/equatable.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/model/remote/avia/airports_model.dart';
import 'package:mysafar_sdk/src/service/avia_service.dart';
import 'package:mysafar_sdk/src/service/geolacator/location_airport_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'city_choose_state.dart';

class CityChooseCubit extends Cubit<CityChooseStates> {
  CityChooseCubit() : super(CityChooseInitState());

  final AviaService _aviaService = AviaService();
  final LocationAirportService _locationService = LocationAirportService();

  // controllers
  TextEditingController controller = TextEditingController();

  /// Load nearby airport based on location (only for 'from' direction)
  Future<void> loadNearbyAirport({String? lang}) async {
    // Check if already cached
    final cachedAirport = _locationService.cachedNearbyAirport;
    if (cachedAirport != null) {
      emit(CityChooseInitState(nearbyAirport: cachedAirport, isLoadingNearby: false));
      return;
    }

    // If already attempted, don't try again
    if (_locationService.hasAttemptedLocation) {
      emit(CityChooseInitState(nearbyAirport: null, isLoadingNearby: false));
      return;
    }

    // Start loading
    emit(CityChooseInitState(nearbyAirport: null, isLoadingNearby: true));

    try {
      final nearbyAirport = await _locationService.getNearbyAirport(lang: lang);
      if (isClosed) return;
      emit(CityChooseInitState(nearbyAirport: nearbyAirport, isLoadingNearby: false));
    } catch (e) {
      debugPrint("Error loading nearby airport: $e");
      if (isClosed) return;
      emit(CityChooseInitState(nearbyAirport: null, isLoadingNearby: false));
    }
  }

  Future<void> getAirports({required String part, String? lang}) async {
    emit(CityChooseLoadingState());
    try {
      NetworkResponse response =
          await _aviaService.getAirports(part: part, lang: lang);
      if (isClosed) return;
      if (response is NetworkSuccessResponse) {
        emit(CityChooseSuccessState(response.data));
      } else if (response is NetworkErrorResponse) {
        emit(CityChooseErrorState(response.getError()));
      }
    } catch (e) {
      debugPrint("CityChooseCubit getAirports error: $e");
      if (isClosed) return;
      emit(CityChooseErrorState(e.toString()));
    }
  }

  /// Reset to initial state with nearby airport preserved
  void resetToInit() {
    final cachedAirport = _locationService.cachedNearbyAirport;
    emit(CityChooseInitState(nearbyAirport: cachedAirport, isLoadingNearby: false));
  }

  @override
  Future<void> close() {
    controller.dispose();
    return super.close();
  }
}
