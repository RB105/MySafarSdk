// ignore_for_file: use_build_context_synchronously

part of 'booking_confirm_states.dart';

class BookingConfirmCubit extends Cubit<BookingConfirmStates> {
  BookingConfirmCubit(String billingId) : super(BookingConfirmInitState()) {
    if (billingId.isNotEmpty) {
      getTicketStatus(billingId: billingId);
    }
  }

  // instance
  BookingService bookingService = BookingService();

  Future<void> confirmBooking({
    required Map<String, dynamic> params,
  }) async {
    emit(BookingConfirmLoadingState());
    final NetworkResponse response =
        await bookingService.confirmBooking(params: params);
    if (isClosed) return;
    if (response is NetworkSuccessResponse) {
      emit(BookingConfirmSuccessState(response.data));
    } else if (response is NetworkErrorResponse) {
      emit(BookingConfirmErrorState(response.getError()));
    }
  }

  Future<void> getCardInfo({
    required String cardNumber,
  }) async {
    emit(BookingConfirmCardInfoLoadingState());
    final NetworkResponse response =
        await bookingService.getCardInfo(cardNumber: cardNumber);
    if (isClosed) return;
    if (response is NetworkSuccessResponse) {
      emit(BookingConfirmCardInfoSuccessState(response.data));
    } else if (response is NetworkErrorResponse) {
      emit(BookingConfirmErrorState(response.getError()));
    }
  }

  Future<void> otpPaymont({
    required String trId,
    required int otpCode,
    required String otpToken,
  }) async {
    emit(BookingConfirmLoadingState());
    final NetworkResponse response = await bookingService.confirmPayment(
      trId: trId,
      otpToken: otpToken,
      otp: otpCode,
    );
    if (isClosed) return;
    if (response is NetworkSuccessResponse) {
      emit(BookingConfirmOtpSuccessState(response.data));
    } else if (response is NetworkErrorResponse) {
      emit(BookingConfirmErrorState(response.getError()));
    }
  }

  Future<void> getTicketStatus({
    required String billingId,
  }) async {
    final NetworkResponse response =
        await bookingService.getTicketStatus(billingId: billingId);
    if (isClosed) return;
    if (response is NetworkSuccessResponse) {
      emit(BookingConfirmChangeAmountSuccessState(response.data));
    }
  }
}
