part of 'booking_create_states.dart';

class BookingcreateCubit extends Cubit<BookingcreateStates> {
  BookingcreateCubit() : super(BookingcreateInitState());

  TextEditingController clientEmailController = TextEditingController();

  // instance
  final _bookingService = BookingService();

  Future<void> createBooking(
      {required String email,
      required String tid,
      required String firstName,
      required List<Map<String, dynamic>> passenger,
      required String phoneNumber,
      required BuildContext context}) async {
    emit(BookingcreateLoadingState());
    // token verify
    await _bookingService
        .createBooking(
            context: context,
            passenger: passenger,
            tid: tid,
            clientEmail: email,
            firstName: firstName,
            clientPhoneNum: phoneNumber)
        .then((NetworkResponse? response) {
      if (isClosed) return;
      if (response is NetworkSuccessResponse) {
        // Voronka 2-bosqichi — booking yaratildi (to'lovdan oldingi qadam).
        AnalyticsService().trackBookingCreated(
          tid: tid,
          passengers: passenger.length,
        );
        emit(BookingcreateSuccessState(response.data));
      } else if (response is NetworkErrorResponse) {
        emit(BookingcreateErrorState(response.getError()));
      }
    });
  }

  @override
  Future<void> close() {
    clientEmailController.dispose();
    return super.close();
  }
}
