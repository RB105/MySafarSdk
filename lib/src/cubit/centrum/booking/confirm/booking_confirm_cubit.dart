// ignore_for_file: use_build_context_synchronously

part of 'booking_confirm_states.dart';

class CentrumBookingConfirmCubit extends Cubit<CentrumBookingConfirmStates> {
  CentrumBookingConfirmCubit(String bilingId) : super(CentrumBookingConfirmInitState()){
  if (bilingId != '0') {
    getTicketStatus(billingId: bilingId);
  }
  }

  // instance
  BookingService bookingService = BookingService();

  Future<void> confirmBooking({
    required Map<String, dynamic> params,
  }) async {
    emit(CentrumBookingConfirmLoadingState());
    final NetworkResponse response =
        await bookingService.centrumConfirmBooking(params: params);
    if (isClosed) return;
    if (response is NetworkSuccessResponse) {
      emit(CentrumBookingConfirmSuccessState(response.data));
    } else if (response is NetworkErrorResponse) {
      emit(CentrumBookingConfirmErrorState(response.getError()));
    }
  }

  Future<void> getCardInfo({
    required String cardNumber,
  }) async {
    emit(CentrumBookingConfirmCardInfoLoadingState());
    final NetworkResponse response =
        await bookingService.getCardInfo(cardNumber: cardNumber);
    if (isClosed) return;
    if (response is NetworkSuccessResponse) {
      emit(CentrumBookingConfirmCardInfoSuccessState(response.data));
    } else if (response is NetworkErrorResponse) {
      emit(CentrumBookingConfirmErrorState(response.getError()));
    }
  }

  Future<void> otpPaymont({
    required String trId,
    required int otpCode,
  }) async {
    emit(CentrumBookingConfirmLoadingState());
    final NetworkResponse response = await bookingService.centrumConfirmPayment(
      trId: trId,
      otp: otpCode,
    );
    if (isClosed) return;
    if (response is NetworkSuccessResponse) {
      emit(CentrumBookingConfirmOtpSuccessState(response.data));
    } else if (response is NetworkErrorResponse) {
      emit(CentrumBookingConfirmErrorState(response.getError()));
    }
  }
  Future<void> getTicketStatus({
    required String billingId,
  }) async {
    final NetworkResponse response =
        await bookingService.getTicketStatus(billingId: billingId);
    if (isClosed) return;
    if (response is NetworkSuccessResponse) {
      emit(CentrumBookingConfirmChangeAmountSuccessState(response.data));
    }
  }
}
