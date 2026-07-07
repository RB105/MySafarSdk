import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/service/booking_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'booking_confirm_cubit.dart';

abstract class CentrumBookingConfirmStates {
  CentrumBookingConfirmStates();
}

class CentrumBookingConfirmInitState extends CentrumBookingConfirmStates {
  CentrumBookingConfirmInitState();
}

class CentrumBookingConfirmLoadingState extends CentrumBookingConfirmStates {
  CentrumBookingConfirmLoadingState();
}
class CentrumBookingConfirmCardInfoLoadingState extends CentrumBookingConfirmStates {
  CentrumBookingConfirmCardInfoLoadingState();
}
class CentrumBookingConfirmSuccessState extends CentrumBookingConfirmStates {
  Map<String,dynamic> data;
  CentrumBookingConfirmSuccessState(this.data);
}
class CentrumBookingConfirmCardInfoSuccessState extends CentrumBookingConfirmStates {
  Map<String,dynamic> data;
  CentrumBookingConfirmCardInfoSuccessState(this.data);
}
class CentrumBookingConfirmChangeAmountSuccessState extends CentrumBookingConfirmStates {
  Map<String,dynamic> data;
  CentrumBookingConfirmChangeAmountSuccessState(this.data);
}
class CentrumBookingConfirmOtpSuccessState extends CentrumBookingConfirmStates {
  Map<String,dynamic> data;
  CentrumBookingConfirmOtpSuccessState(this.data);
}
class CentrumBookingConfirmErrorState extends CentrumBookingConfirmStates {
  final String error;
  CentrumBookingConfirmErrorState(this.error);
}
