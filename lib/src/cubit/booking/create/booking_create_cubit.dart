part of 'booking_create_states.dart';

class BookingcreateCubit extends Cubit<BookingcreateStates> with NetworkCancel {
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
    try {
      // token verify
      final NetworkResponse response = await withNetworkCancel(
        () => _bookingService.createBooking(
            context: context,
            passenger: passenger,
            tid: tid,
            clientEmail: email,
            firstName: firstName,
            clientPhoneNum: phoneNumber),
      );
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
      } else {
        emit(BookingcreateErrorState('error_other'.tr()));
      }
    } catch (e) {
      // Kutilmagan xato — yuklanish dialogi qotib qolmasin.
      debugPrint('MySafarSdk: booking-create xatosi ($e)');
      if (isClosed) return;
      emit(BookingcreateErrorState('error_other'.tr()));
    }
  }

  @override
  Future<void> close() {
    clientEmailController.dispose();
    return super.close();
  }
}
