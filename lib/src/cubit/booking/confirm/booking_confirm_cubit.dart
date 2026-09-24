// ignore_for_file: use_build_context_synchronously

part of 'booking_confirm_states.dart';

class BookingConfirmCubit extends Cubit<BookingConfirmStates>
    with NetworkCancel {
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

  /// Bitta holat so'rovi uchun chegara — sekin tarmoqda tekshiruv daqiqalab
  /// cho'zilmasin (so'rov keyingi urinishda takrorlanadi).
  static const Duration paymentCheckRequestTimeout = Duration(seconds: 10);

  /// Butun tekshiruv uchun umumiy chegara.
  static const Duration paymentCheckDeadline = Duration(seconds: 90);

  /// Har [checkPaymentStatus] chaqiruvi oshiradi — eskirgan tekshiruv
  /// natijasi chiqarilmaydi.
  int _checkGeneration = 0;

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
      debugPrint('MySafarSdk: card-info xatosi (${e.runtimeType})');
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
      if (isClosed || _checkGeneration > 0) return;
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
    if (billingId.isEmpty) return;
    // Yangi tekshiruv (masalan boshqa usul bilan qayta to'lab yopilgan) eskisini
    // bekor qiladi — "allaqachon tekshirilmoqda" deb jim qaytib, sahifani
    // yuklanishda qoldirmaydi.
    final generation = ++_checkGeneration;
    bool stale() => isClosed || generation != _checkGeneration;
    emit(const BookingConfirmPaymentCheckingState());
    try {
      final result = await pollPaymentStatus(
        fetch: () => _fetchPaymentStatus(billingId),
        isCancelled: stale,
        onFirstStatus: (status) {
          if (stale()) return;
          // To'lov jarayonda bo'lsa (pending) kutamiz; to'lanmagan yoki javob
          // yo'q bo'lsa — sahifa ochiladi, tekshiruv fonda davom etadi.
          if (status == null ||
              status.state == BookingPaymentState.unpaid ||
              status.state == BookingPaymentState.failed) {
            emit(const BookingConfirmPaymentBackgroundCheckState());
          }
        },
      );
      if (stale()) return;
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
      if (stale()) return;
      emit(const BookingConfirmPaymentPendingState(null));
    }
  }

  Future<BookingPaymentStatus?> _fetchPaymentStatus(String billingId) async {
    try {
      final NetworkResponse response = await withNetworkCancel(
        () => bookingService.getTicketStatus(billingId: billingId),
      ).timeout(paymentCheckRequestTimeout);
      if (response is NetworkSuccessResponse) {
        return BookingPaymentStatus.fromTicketData(response.data);
      }
    } catch (_) {
      // Tarmoq xatosi yoki timeout — keyingi urinishda qayta so'raladi.
    }
    return null;
  }

  /// Holatni [delays] oraliqlari bilan so'raydi. Faqat "to'langan" javobi
  /// tekshiruvni darhol tugatadi. `Booked` / `Cancelled` oxirgi so'z emas —
  /// bank → shlyuz → backend zanjiri bir necha o'n soniya kechikishi mumkin,
  /// shuning uchun oyna oxirigacha kutiladi (aks holda to'lagan foydalanuvchi
  /// "to'lov o'tmadi" ko'rib, ikkinchi marta to'lardi).
  /// Oxirida: oxirgi javob `Booked` → to'lanmagan, `Cancelled` →
  /// muvaffaqiyatsiz, javob yo'q / noma'lum → pending.
  /// [fetch] `null` qaytarsa (tarmoq xatosi) keyingi urinishga o'tiladi.
  static Future<({BookingPaymentState state, BookingPaymentStatus? status})>
      pollPaymentStatus({
    required Future<BookingPaymentStatus?> Function() fetch,
    List<Duration> delays = paymentCheckDelays,
    Duration deadline = paymentCheckDeadline,
    bool Function()? isCancelled,
    void Function(BookingPaymentStatus? status)? onFirstStatus,
  }) async {
    final watch = Stopwatch()..start();
    BookingPaymentStatus? last;
    var first = true;
    for (final delay in delays) {
      if (delay > Duration.zero) await Future<void>.delayed(delay);
      if (isCancelled?.call() == true || watch.elapsed > deadline) break;
      final status = await fetch();
      if (first) {
        first = false;
        if (status?.state != BookingPaymentState.paid) {
          onFirstStatus?.call(status);
        }
      }
      if (status == null) continue;
      last = status;
      if (status.state == BookingPaymentState.paid) {
        return (state: BookingPaymentState.paid, status: status);
      }
    }
    final state = switch (last?.state) {
      BookingPaymentState.unpaid => BookingPaymentState.unpaid,
      BookingPaymentState.failed => BookingPaymentState.failed,
      _ => BookingPaymentState.pending,
    };
    return (state: state, status: last);
  }
}
