import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart';
import 'package:mysafar_sdk/src/service/avia_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
part 'booking_create_cubit.dart';

abstract class CentrumBookingcreateStates {
  CentrumBookingcreateStates();
}

class BookingcreateInitState extends CentrumBookingcreateStates {
  BookingcreateInitState();
}

class CentrumBookingcreateLoadingState extends CentrumBookingcreateStates {
  CentrumBookingcreateLoadingState();
}

class CentrumBookingcreateSuccessState extends CentrumBookingcreateStates {
  dynamic data;
  CentrumBookingcreateSuccessState(this.data);
}

class CentrumBookingcreateErrorState extends CentrumBookingcreateStates {
  final String error;
  CentrumBookingcreateErrorState(this.error);
}
