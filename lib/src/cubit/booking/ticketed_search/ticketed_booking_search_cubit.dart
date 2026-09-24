import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/model/remote/profile/confirmed_ticket_models.dart';
import 'package:mysafar_sdk/src/service/booking_service.dart';
import 'package:mysafar_sdk/src/core/config/network_request_scope.dart'
    show NetworkCancel;

part 'ticketed_booking_search_state.dart';

class TicketedBookingSearchCubit extends Cubit<TicketedBookingSearchState> with NetworkCancel {
  TicketedBookingSearchCubit() : super(TicketedBookingSearchInitial());

  final _bookingService = BookingService();

  Future<void> searchTicket(String billingId) async {
    emit(TicketedBookingSearchLoading());
    final NetworkResponse response;
    try {
      response = await withNetworkCancel(
        () => _bookingService.getTicketedBookingInfo(billingId: billingId),
      );
    } catch (_) {
      // Kutilmagan xato — sahifa yuklanishda qotib qolmasin.
      if (!isClosed) {
        emit(TicketedBookingSearchError(error: 'error_other'.tr()));
      }
      return;
    }
    if (isClosed) return;

    if (response is NetworkSuccessResponse) {
      try {
        final data = response.data;
        if (data is! Map) throw const FormatException('ticket data');
        final ticket =
            ConfirmedTicketsModel.fromJson(Map<String, dynamic>.from(data));
        emit(TicketedBookingSearchSuccess(ticket));
      } catch (_) {
        // Tarjima qilingan matn (№87) — avval o'zbekcha qattiq yozilgan edi.
        emit(TicketedBookingSearchError(error: 'order_data_read_error'.tr()));
      }
    } else if (response is NetworkErrorResponse) {
      emit(TicketedBookingSearchError(
          error: response.getError(), errorType: response.errorType));
    } else {
      emit(TicketedBookingSearchError(error: 'error_other'.tr()));
    }
  }

  void reset() => emit(TicketedBookingSearchInitial());
}
