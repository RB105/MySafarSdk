// ignore_for_file: use_build_context_synchronously

part of 'booking_confirm_states.dart';

class BookingConfirmCubit extends Cubit<BookingConfirmStates> with NetworkCancel {
  BookingConfirmCubit(String billingId) : super(BookingConfirmInitState()) {
    if (billingId.isNotEmpty) {
      getTicketStatus(billingId: billingId);
    }
  }

  // instance
  BookingService bookingService = BookingService();

  /// WebView yopilgach holatni so'rash oraliqlari (jami ~60 s): avval
  /// tez-tez, keyin siyrakroq.
  static const List<Duration> paymentCheckDelays = [
    Duration.zero,
    Duration(seconds: 3),
    Duration(seconds: 4),
    Duration(seconds: 5),
    Duration(seconds: 8),
    Duration(seconds: 10),
    Duration(seconds: 15),
    Duration(seconds: 15),
  ];

  /// `Booked` (to'lanmagan) javobiga shuncha vaqtgacha ishonmaymiz — bank /
  /// shlyuz callback'i backendga kechikib yetishi mumkin.
  static const Duration paymentUnpaidGrace = Duration(seconds: 12);

  bool _checkingPayment = false;

  Future<void> confirmBooking({
    required Map<String, dynamic> params,
  }) async {
    emit(BookingConfirmLoadingState());
    try {
      final NetworkResponse response = await withNetworkCancel(
          () => bookingService.confirmBooking(params: params));
      if (isClosed) return;
      if (response is NetworkSuccessResponse) {
        emit(BookingConfirmSuccessState(response.data));
      } else if (response is NetworkErrorResponse) {
        emit(BookingConfirmErrorState(response.getError()));
      } else {
        emit(BookingConfirmErrorState('error_other'.tr()));
      }
    } catch (e) {
      // Kutilmagan xato — tugma yuklanishda qotib qolmasin.
      debugPrint('MySafarSdk: booking-confirm xatosi ($e)');
      if (isClosed) return;
      emit(BookingConfirmErrorState('error_other'.tr()));
    }
  }

  Future<void> getCardInfo({
    required String cardNumber,
  }) async {
    emit(BookingConfirmCardInfoLoadingState());
    try {
      final NetworkResponse response = await withNetworkCancel(
          () => bookingService.getCardInfo(cardNumber: cardNumber));
      if (isClosed) return;
      if (response is NetworkSuccessResponse) {
        emit(BookingConfirmCardInfoSuccessState(response.data));
      } else if (response is NetworkErrorResponse) {
        emit(BookingConfirmErrorState(response.getError()));
      }
    } catch (e) {
      debugPrint('MySafarSdk: card-info xatosi ($e)');
      if (isClosed) return;
      emit(BookingConfirmErrorState('error_other'.tr()));
    }
  }

  Future<void> otpPaymont({
    required String trId,
    required int otpCode,
    required String otpToken,
  }) async {
    emit(BookingConfirmLoadingState());
    try {
      final NetworkResponse response = await withNetworkCancel(
        () => bookingService.confirmPayment(
          trId: trId,
          otpToken: otpToken,
          otp: otpCode,
        ),
      );
      if (isClosed) return;
      if (response is NetworkSuccessResponse) {
        emit(BookingConfirmOtpSuccessState(response.data));
      } else if (response is NetworkErrorResponse) {
        emit(BookingConfirmErrorState(response.getError()));
      }
    } catch (e) {
      debugPrint('MySafarSdk: payment-confirm xatosi ($e)');
      if (isClosed) return;
      emit(BookingConfirmErrorState('error_other'.tr()));
    }
  }

  /// Sahifa ochilganda bir marta: narx o'zgarganini tekshirish uchun.
  /// Buyurtma allaqachon to'langan bo'lsa — to'lov qayta boshlanmasin.
  Future<void> getTicketStatus({
    required String billingId,
  }) async {
    try {
      final NetworkResponse response = await withNetworkCancel(
        () => bookingService.getTicketStatus(billingId: billingId),
      );
      if (isClosed || _checkingPayment) return;
      if (response is NetworkSuccessResponse && response.data is Map) {
        final data = Map<String, dynamic>.from(response.data as Map);
        final status = BookingPaymentStatus.fromTicketData(data);
        if (status.isPaid) {
          emit(BookingConfirmPaidState(status, isNew: false));
        } else {
          emit(BookingConfirmChangeAmountSuccessState(data));
        }
      }
    } catch (e) {
      // Jim — bu faqat qo'shimcha tekshiruv, to'lov oqimini to'xtatmaydi.
      debugPrint('MySafarSdk: ticket-data xatosi ($e)');
    }
  }

  /// To'lov sahifasi yopilgach holatni `ticket-data` orqali qayta tekshiradi
  /// ([paymentCheckDelays] bo'yicha, jami ~60 s). Natija: to'langan /
  /// to'lanmagan / hali aniq emas holatlaridan biri.
  Future<void> checkPaymentStatus({required String billingId}) async {
    if (_checkingPayment || billingId.isEmpty) return;
    _checkingPayment = true;
    emit(const BookingConfirmPaymentCheckingState());
    try {
      final result = await pollPaymentStatus(
        fetch: () => _fetchPaymentStatus(billingId),
        isCancelled: () => isClosed,
      );
      if (isClosed) return;
      switch (result.state) {
        case BookingPaymentState.paid:
          emit(BookingConfirmPaidState(result.status!));
        case BookingPaymentState.unpaid:
        case BookingPaymentState.failed:
          emit(BookingConfirmNotPaidState(result.status));
        case BookingPaymentState.pending:
          emit(BookingConfirmPaymentPendingState(result.status));
      }
    } catch (e) {
      debugPrint('MySafarSdk: to\'lov holatini tekshirishda xato ($e)');
      if (isClosed) return;
      emit(const BookingConfirmPaymentPendingState(null));
    } finally {
      _checkingPayment = false;
    }
  }

  Future<BookingPaymentStatus?> _fetchPaymentStatus(String billingId) async {
    try {
      final NetworkResponse response = await withNetworkCancel(
        () => bookingService.getTicketStatus(billingId: billingId),
      );
      if (response is NetworkSuccessResponse) {
        return BookingPaymentStatus.fromTicketData(response.data);
      }
    } catch (_) {
      // Tarmoq xatosi — keyingi urinishda qayta so'raladi.
    }
    return null;
  }

  /// Holatni [delays] oraliqlari bilan so'raydi: to'langan yoki bekor
  /// qilingan bo'lsa darhol qaytadi; `Booked` javobi faqat [unpaidGrace]
  /// o'tgach "to'lanmagan" deb qabul qilinadi; urinishlar tugasa — pending.
  /// [fetch] `null` qaytarsa (tarmoq xatosi) keyingi urinishga o'tiladi.
  static Future<({BookingPaymentState state, BookingPaymentStatus? status})>
      pollPaymentStatus({
    required Future<BookingPaymentStatus?> Function() fetch,
    List<Duration> delays = paymentCheckDelays,
    Duration unpaidGrace = paymentUnpaidGrace,
    bool Function()? isCancelled,
  }) async {
    BookingPaymentStatus? last;
    var waited = Duration.zero;
    for (final delay in delays) {
      if (delay > Duration.zero) await Future<void>.delayed(delay);
      waited += delay;
      if (isCancelled?.call() == true) break;
      final status = await fetch();
      if (status == null) continue;
      last = status;
      switch (status.state) {
        case BookingPaymentState.paid:
        case BookingPaymentState.failed:
          return (state: status.state, status: status);
        case BookingPaymentState.unpaid:
          if (waited >= unpaidGrace) {
            return (state: BookingPaymentState.unpaid, status: status);
          }
        case BookingPaymentState.pending:
          break;
      }
    }
    return (
      state: last?.state == BookingPaymentState.unpaid
          ? BookingPaymentState.unpaid
          : BookingPaymentState.pending,
      status: last,
    );
  }
}
