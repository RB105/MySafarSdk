import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/service/booking_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'booking_confirm_cubit.dart';

abstract class BookingConfirmStates {
  const BookingConfirmStates();
}

class BookingConfirmInitState extends BookingConfirmStates {
  const BookingConfirmInitState();
}

class BookingConfirmLoadingState extends BookingConfirmStates {
  const BookingConfirmLoadingState();
}
class BookingConfirmCardInfoLoadingState extends BookingConfirmStates {
  const BookingConfirmCardInfoLoadingState();
}
class BookingConfirmSuccessState extends BookingConfirmStates {
  final Map<String,dynamic> data;
  const BookingConfirmSuccessState(this.data);
}
class BookingConfirmCardInfoSuccessState extends BookingConfirmStates {
  final Map<String,dynamic> data;
  const BookingConfirmCardInfoSuccessState(this.data);
}
class BookingConfirmChangeAmountSuccessState extends BookingConfirmStates {
  final Map<String,dynamic> data;
  const BookingConfirmChangeAmountSuccessState(this.data);
}
class BookingConfirmOtpSuccessState extends BookingConfirmStates {
  final Map<String,dynamic> data;
  const BookingConfirmOtpSuccessState(this.data);
}
class BookingConfirmErrorState extends BookingConfirmStates {
  final String error;
  const BookingConfirmErrorState(this.error);
}
