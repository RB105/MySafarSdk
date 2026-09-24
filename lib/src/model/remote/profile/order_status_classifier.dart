import 'package:mysafar_sdk/src/model/remote/booking/booking_payment_status.dart';

/// Buyurtma holatini (`ConfirmedTicketsModel.orderStatus`, `callback_status`
/// yoki `order.status.sign`) toifalarga ajratuvchi yagona joy (№58, №59).
///
/// Katta-kichik harf, `_` / `-` / bo'shliq farqsiz ishlaydi. "To'langan"
/// ro'yxati to'lov tekshiruvi bilan bir xil ([BookingPaymentStatus.stateOf]):
/// `Paid`, `Ticketed`, `PartiallyTicketed`, `TicketedWaitingPNR`,
/// `PartlyTicketedWaitingPNR`.
class OrderStatusClassifier {
  OrderStatusClassifier._();

  static String _normalize(String? s) =>
      (s ?? '').toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');

  /// Chipta allaqachon chiqarilgan holatlar (PNR kutilayotgan bo'lsa ham
  /// e-chipta kvitansiyasi bo'lishi mumkin).
  static const Set<String> _ticketSigns = {
    'ticketed',
    'partiallyticketed',
    'ticketedwaitingpnr',
    'partlyticketedwaitingpnr',
  };

  /// To'lovni kutayotgan holatlar ("To'lash" tugmasi mumkin).
  static const Set<String> _payableSigns = {'booked'};

  /// Pul to'langan ("To'langan" bo'limi).
  static bool isPaid(String? status) =>
      BookingPaymentStatus.stateOf(status) == BookingPaymentState.paid;

  /// Holat bo'yicha chipta chiqarilgan.
  static bool isTicketIssued(String? status) =>
      _ticketSigns.contains(_normalize(status));

  /// "Chiptani yuklab olish" faqat chipta haqiqatan bor bo'lsa: holat
  /// chipta chiqarilganini bildiradi VA kvitansiya havolasi bor.
  static bool canDownloadTicket(String? status, String? ticketUrl) =>
      isTicketIssued(status) && (ticketUrl ?? '').trim().isNotEmpty;

  /// To'langan, lekin chipta hali yo'q — "chipta rasmiylashtirilmoqda".
  static bool isTicketPending(String? status, String? ticketUrl) =>
      isPaid(status) && !canDownloadTicket(status, ticketUrl);

  /// Bron to'lovni kutmoqda (muddati alohida tekshiriladi).
  static bool isAwaitingPayment(String? status) =>
      _payableSigns.contains(_normalize(status));
}
