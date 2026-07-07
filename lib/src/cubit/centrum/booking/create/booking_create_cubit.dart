part of 'booking_create_states.dart';

class CentrumBookingcreateCubit extends Cubit<CentrumBookingcreateStates> {
  CentrumBookingcreateCubit() : super(BookingcreateInitState());

  TextEditingController clientEmailController = TextEditingController();

  final _bookingService = AviaService();

  Future<void> createBooking({
    required Map<String, dynamic> params,
  }) async {
    emit(CentrumBookingcreateLoadingState());
    await _bookingService
        .createCentrum(params: params)
        .then((NetworkResponse? response) {
      if (isClosed) return;
      if (response is NetworkSuccessResponse) {
        // Voronka 2-bosqichi — booking yaratildi (to'lovdan oldingi qadam).
        final passenger = params['passenger'];
        AnalyticsService().trackBookingCreated(
          tid: params['tid']?.toString(),
          passengers: passenger is List ? passenger.length : null,
        );
        emit(CentrumBookingcreateSuccessState(response.data));
      } else if (response is NetworkErrorResponse) {
        emit(CentrumBookingcreateErrorState(response.getError()));
      }
    });
  }

  @override
  Future<void> close() {
    clientEmailController.dispose();
    return super.close();
  }
}
