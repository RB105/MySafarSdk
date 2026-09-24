import 'package:mysafar_sdk/src/core/config/response_config.dart'
    show NetworkSuccessResponse;
import 'package:mysafar_sdk/src/model/remote/avia/airports_model.dart'
    show AirPortsModel;
import 'package:mysafar_sdk/src/model/remote/avia/ticket_date_price_model.dart';
import 'package:mysafar_sdk/src/service/avia_service.dart' show AviaService;
import 'package:flutter/material.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart' show Cubit;
import 'package:mysafar_sdk/src/core/config/network_request_scope.dart'
    show NetworkCancel;

part 'date_picker_state.dart';

class DatePickerCubit extends Cubit<DatePickerState> with NetworkCancel {
  final AirPortsModel? fromWhere;
  final AirPortsModel? toWhere;
  final int? flightType;

  /// Oylik narxlar so'rovi parametrlari — yo'nalish qidiruv sahifasidagi
  /// bilan AYNAN bir xil bo'lishi kerak (adt/chd/inf/klass/direct/baggage),
  /// aks holda AviaService keshi ishlamay, bir xil narxlar 2–3 marta
  /// so'raladi. Berilmasa — standart (1 katta, barcha klasslar).
  final MonthPriceParams priceParams;

  DatePickerCubit({
    this.fromWhere,
    this.toWhere,
    this.flightType,
    this.priceParams = const MonthPriceParams(),
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
      final response = await withNetworkCancel(
        () => _aviaService.getPriceByMonth(
          fromWhere?.cityIataCode ?? "",
          toWhere?.cityIataCode ?? "",
          adt: priceParams.adt,
          chd: priceParams.chd,
          inf: priceParams.inf,
          klass: MonthPriceParams.normalizeKlass(priceParams.klass),
          direct: priceParams.direct,
          baggage: priceParams.baggage,
        ),
      );
      if (isClosed) return;
      if (response is NetworkSuccessResponse) {
        emit(DatePickerFilledState(response.data));
      }
    } catch (e) {
      debugPrint("DatePickerState $e");
    }
  }
}

/// Oylik narxlar so'rovining yo'lovchi/klass/filtr parametrlari. Barcha
/// chaqiruvchilar klassni shu yerda bir xil ko'rinishga keltiradi
/// ([normalizeKlass]) — kesh kaliti mos kelishi uchun.
class MonthPriceParams {
  final int adt;
  final int chd;
  final int inf;
  final String klass;
  final bool direct;
  final bool baggage;

  const MonthPriceParams({
    this.adt = 1,
    this.chd = 0,
    this.inf = 0,
    this.klass = 'a',
    this.direct = false,
    this.baggage = false,
  });

  /// Klass kodi: bo'sh/null → `a` (barcha), kichik harf, bo'shliqsiz.
  static String normalizeKlass(String? klass) {
    final k = (klass ?? '').trim().toLowerCase();
    return k.isEmpty ? 'a' : k;
  }
}
