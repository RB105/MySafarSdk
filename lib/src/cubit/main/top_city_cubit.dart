import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart'
    show NetworkResponse, NetworkSuccessResponse;
import 'package:mysafar_sdk/src/model/remote/avia/top_city_model.dart'
    show TopCityModel;
import 'package:mysafar_sdk/src/service/avia_service.dart' show AviaService;

part 'top_city_state.dart';

class TopCityCubit extends Cubit<TopCityState> {
  TopCityCubit() : super(TopCityInitState()) {
    getTopCities();
  }

  final AviaService _aviaService = AviaService();

  List<TopCityModel> topCities = [];
  Future<void> getTopCities() async {
    emit(TopCityLoadingState());
    final NetworkResponse response = await _aviaService.getTopCities();
    if (isClosed) return;
    if (response is NetworkSuccessResponse) {
      topCities = response.data;
      emit(TopCitySuccessState(topCities));
    } else {
      emit(TopCityInitState());
    }
  }
}
