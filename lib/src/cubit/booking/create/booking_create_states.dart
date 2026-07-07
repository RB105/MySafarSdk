import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/model/remote/booking/booking_create_model.dart';
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart';
import 'package:mysafar_sdk/src/service/booking_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
part 'booking_create_cubit.dart';

abstract class BookingcreateStates {
  BookingcreateStates();
}

class BookingcreateInitState extends BookingcreateStates {
  BookingcreateInitState();
}

class BookingcreateLoadingState extends BookingcreateStates {
  BookingcreateLoadingState();
}

class BookingcreateSuccessState extends BookingcreateStates {
  BookingCreateModel data;
  BookingcreateSuccessState(this.data);
}

class BookingcreateErrorState extends BookingcreateStates {
  final String error;
  BookingcreateErrorState(this.error);
}
