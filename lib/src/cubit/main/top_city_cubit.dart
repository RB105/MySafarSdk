import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart'
    show NetworkResponse, NetworkSuccessResponse;
import 'package:mysafar_sdk/src/model/remote/avia/top_city_model.dart'
    show TopCityModel;
import 'package:mysafar_sdk/src/service/avia_service.dart' show AviaService;
import 'package:mysafar_sdk/src/core/config/network_request_scope.dart'
    show NetworkCancel;

part 'top_city_state.dart';

class TopCityCubit extends Cubit<TopCityState> with NetworkCancel {
  TopCityCubit() : super(TopCityInitState()) {
    getTopCities();
  }

  final AviaService _aviaService = AviaService();

  List<TopCityModel> topCities = [];
  Future<void> getTopCities() async {
    emit(TopCityLoadingState());
    final NetworkResponse response = await withNetworkCancel(_aviaService.getTopCities);
    if (isClosed) return;
    if (response is NetworkSuccessResponse) {
      topCities = response.data;
      emit(TopCitySuccessState(topCities));
    } else {
      emit(TopCityInitState());
    }
  }
}
