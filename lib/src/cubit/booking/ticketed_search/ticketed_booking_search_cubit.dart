import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/model/remote/profile/confirmed_ticket_models.dart';
import 'package:mysafar_sdk/src/service/booking_service.dart';

part 'ticketed_booking_search_state.dart';

class TicketedBookingSearchCubit extends Cubit<TicketedBookingSearchState> {
  TicketedBookingSearchCubit() : super(TicketedBookingSearchInitial());

  final _bookingService = BookingService();

  Future<void> searchTicket(String billingId) async {
    emit(TicketedBookingSearchLoading());
    final response =
        await _bookingService.getTicketedBookingInfo(billingId: billingId);
    if (isClosed) return;

    if (response is NetworkSuccessResponse) {
      try {
        final ticket = ConfirmedTicketsModel.fromJson(
            response.data as Map<String, dynamic>);
        emit(TicketedBookingSearchSuccess(ticket));
      } catch (_) {
        emit(TicketedBookingSearchError(error: "Ma'lumotni o'qishda xatolik"));
      }
    } else if (response is NetworkErrorResponse) {
      emit(TicketedBookingSearchError(
          error: response.getError(), errorType: response.errorType));
    }
  }

  void reset() => emit(TicketedBookingSearchInitial());
}
