import 'package:flutter/material.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/model/remote/avia/ticket_tariff_model.dart'
    show FlightTariffModel;
import 'package:mysafar_sdk/src/service/avia_service.dart';

part 'ticket_tariff_state.dart';

class TicketTariffCubit extends Cubit<TicketTariffState> {
  TicketTariffCubit(String tid) : super(TicketTariffInitState()) {
    //
    getTariffs(tid);
  }

  //
  final _aviaService = AviaService();

  Future<void> getTariffs(String tid) async {
    if (isClosed) return;
    emit(TicketTariffLoadingState());

    try {
      final response = await _aviaService.getTariff(tid);
      if (isClosed) return;

      if (response is NetworkSuccessResponse) {
        emit(TicketTariffSuccessState(response.data));
      } else {
        emit(TicketTariffInitState());
      }
    } catch (e) {
      debugPrint(e.toString());
      if (isClosed) return;
      emit(TicketTariffInitState());
    }
  }
}
