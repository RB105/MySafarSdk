import 'package:flutter/foundation.dart' show debugPrint;
import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/model/remote/booking/booking_payment_status.dart';
import 'package:mysafar_sdk/src/service/booking_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysafar_sdk/src/core/config/network_request_scope.dart'
    show NetworkCancel;

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

/// To'lov sahifasi (WebView) yopildi — to'lov holati tekshirilmoqda.
class BookingConfirmPaymentCheckingState extends BookingConfirmStates {
  const BookingConfirmPaymentCheckingState();
}

/// To'lov tasdiqlandi. [isNew] — shu tekshiruvda aniqlandi (analitika va
/// natija dialogi uchun); `false` — sahifa ochilganda allaqachon to'langan.
class BookingConfirmPaidState extends BookingConfirmStates {
  final BookingPaymentStatus status;
  final bool isNew;
  const BookingConfirmPaidState(this.status, {this.isNew = true});
}

/// To'lov o'tmadi (bron hali to'lanmagan yoki bekor qilingan).
class BookingConfirmNotPaidState extends BookingConfirmStates {
  final BookingPaymentStatus? status;
  const BookingConfirmNotPaidState(this.status);
}

/// Tekshiruv tugadi, lekin to'lov hali tasdiqlanmadi (bank/shlyuz javobi
/// kechikmoqda yoki holatni olib bo'lmadi).
class BookingConfirmPaymentPendingState extends BookingConfirmStates {
  final BookingPaymentStatus? status;
  const BookingConfirmPaymentPendingState(this.status);
}
