import 'package:mysafar_sdk/src/core/config/response_config.dart'
    show NetworkSuccessResponse;
import 'package:mysafar_sdk/src/model/remote/avia/airports_model.dart'
    show AirPortsModel;
import 'package:mysafar_sdk/src/model/remote/avia/ticket_date_price_model.dart';
import 'package:mysafar_sdk/src/service/avia_service.dart' show AviaService;
import 'package:flutter/material.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart' show Cubit;

part 'date_picker_state.dart';

class DatePickerCubit extends Cubit<DatePickerState> {
  final AirPortsModel? fromWhere;
  final AirPortsModel? toWhere;
  final int? flightType;

  DatePickerCubit({
    this.fromWhere,
    this.toWhere,
    this.flightType,
  }) : super(DatePickerInitState()) {
    if (flightType != 2) {
      getPricesByDate();
    }
  }

  // instance
  final AviaService _aviaService = AviaService();

  /// get prices by date
  Future<void> getPricesByDate() async {
    if (fromWhere == null || toWhere == null) {
      debugPrint("$fromWhere and $toWhere");
      return;
    }
    try {
      final response = await _aviaService.getPriceByMonth(
          fromWhere?.cityIataCode ?? "", toWhere?.cityIataCode ?? "");
      if (isClosed) return;
      if (response is NetworkSuccessResponse) {
        emit(DatePickerFilledState(response.data));
      }
    } catch (e) {
      debugPrint("DatePickerState $e");
    }
  }
}
