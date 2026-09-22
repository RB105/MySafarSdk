/// `ticket-data/{billing_id}` javobidan olingan to'lov holati.
///
/// TAXMIN (backend bilan tasdiqlanishi kerak): javob hamkor (myagent)
/// buyurtmasi ko'rinishida — `data.book.order.status.sign` (ba'zan yozuv
/// ko'rinishida `response.data.book...`). Holat manbai ilovaning boshqa
/// joylaridagi kabi (`ConfirmedTicketsModel.orderStatus`): avval
/// `callback_status`, bo'sh bo'lsa `order.status.sign`.
///   * `Paid`, `Ticketed`, `PartiallyTicketed`, `TicketedWaitingPNR`,
///     `PartlyTicketedWaitingPNR` — to'langan ([paid]);
///   * `Booked` — bron to'lovni kutmoqda, hali to'lanmagan ([unpaid]);
///   * `Cancelled` — bron bekor qilingan, to'lov o'tmagan ([failed]);
///   * qolganlari (`AwaitPayment`, bo'sh yoki noma'lum) — aniq emas,
///     tekshirishda davom etamiz ([pending]).
/// `transaction.status` (bool) ATAYIN hisobga olinmaydi — ma'nosi
/// tasdiqlanmagan, xato "to'langan" deb topilsa to'lov bloklanadi.
enum BookingPaymentState { paid, unpaid, failed, pending }

class BookingPaymentStatus {
  const BookingPaymentStatus({
    required this.state,
    this.sign = '',
    this.book,
    this.ticketReceiptUrl,
    this.billingNumber,
    this.changedTotal,
    this.currency,
  });

  final BookingPaymentState state;

  /// Serverning xom holat nomi (analitika/log uchun), masalan `Booked`.
  final String sign;

  /// `data.book` — [ticketPdfArguments] uchun.
  final Map<String, dynamic>? book;
  final String? ticketReceiptUrl;
  final String? billingNumber;

  /// Backend narx o'zgarganini bildirgan bo'lsa (`is_price_changed` /
  /// `is_search_price_changed`) — yangi jami summa, aks holda `null`.
  final double? changedTotal;

  /// Buyurtma valyutasi (`order.price` kaliti yoki provayder valyutasi).
  final String? currency;

  bool get isPaid => state == BookingPaymentState.paid;

  /// `TicketPdfPage` kutgan shakl: `{data: {book: ...}}`.
  Map<String, dynamic>? get ticketPdfArguments => book == null
      ? null
      : {
          'data': {'book': book}
        };

  static const Set<String> _paidSigns = {
    'paid',
    'ticketed',
    'partiallyticketed',
    'ticketedwaitingpnr',
    'partlyticketedwaitingpnr',
  };
  static const Set<String> _unpaidSigns = {'booked'};
  static const Set<String> _failedSigns = {'cancelled', 'canceled'};

  static String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');

  /// Bitta holat nomini toifaga ajratadi (katta-kichik harf, `_`/`-` farqsiz).
  static BookingPaymentState stateOf(String? sign) {
    final key = _normalize(sign ?? '');
    if (_paidSigns.contains(key)) return BookingPaymentState.paid;
    if (_unpaidSigns.contains(key)) return BookingPaymentState.unpaid;
    if (_failedSigns.contains(key)) return BookingPaymentState.failed;
    return BookingPaymentState.pending;
  }

  /// Javob shakli kutilganidan farq qilsa ham yiqilmaydi — holat topilmasa
  /// [BookingPaymentState.pending] qaytadi.
  factory BookingPaymentStatus.fromTicketData(dynamic json) {
    try {
      if (json is! Map) {
        return const BookingPaymentStatus(state: BookingPaymentState.pending);
      }
      final book = _map(_dig(json, const ['data', 'book'])) ??
          _map(_dig(json, const ['response', 'data', 'book']));
      final order = _map(book?['order']);

      final callback = _string(json['callback_status']) ?? '';
      final orderSign = _string(_dig(order, const ['status', 'sign'])) ?? '';
      // Qaysi manba bo'lsa ham "to'langan" desa — to'langan (callback yoki
      // buyurtma holatidan biri kechikib yangilanishi mumkin).
      final BookingPaymentState state;
      final String sign;
      if (stateOf(callback) == BookingPaymentState.paid) {
        state = BookingPaymentState.paid;
        sign = callback;
      } else if (stateOf(orderSign) == BookingPaymentState.paid) {
        state = BookingPaymentState.paid;
        sign = orderSign;
      } else {
        sign = callback.isNotEmpty ? callback : orderSign;
        state = stateOf(sign);
      }

      String? receipt;
      final tickets = book?['tickets'];
      if (tickets is List && tickets.isNotEmpty) {
        receipt = _string(_dig(tickets.first, const ['documents', 'ticket_receipt']));
      }

      final priceChanged = book?['is_search_price_changed'] == true ||
          book?['is_price_changed'] == true;
      final total = priceChanged
          ? toDouble(_dig(
              book, const ['agent_mode_prices', 'total_amount_for_active_agent_mode']))
          : null;

      return BookingPaymentStatus(
        state: state,
        sign: sign,
        book: book == null ? null : Map<String, dynamic>.from(book),
        ticketReceiptUrl: receipt,
        billingNumber: _string(order?['billing_number']?.toString()),
        changedTotal: total,
        currency: _currencyOf(book, order),
      );
    } catch (_) {
      return const BookingPaymentStatus(state: BookingPaymentState.pending);
    }
  }

  /// `order.price` bitta valyuta kaliti bilan keladi (`{"UZS": {...}}`);
  /// bo'lmasa birinchi chiptaning provayder valyutasi.
  static String? _currencyOf(Map? book, Map? order) {
    final price = order?['price'];
    if (price is Map && price.length == 1) {
      final key = _string(price.keys.first?.toString());
      if (key != null) return key.toUpperCase();
    }
    final tickets = book?['tickets'];
    if (tickets is List && tickets.isNotEmpty) {
      final c = _string(_dig(tickets.first, const ['provider', 'currency']));
      if (c != null) return c.toUpperCase();
    }
    return null;
  }

  /// Backenddan keladigan qiymatni (null, son yoki matn) xavfsiz double'ga
  /// o'giradi; imkonsiz bo'lsa null.
  static double? toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final cleaned = value.toString().trim().replaceAll(' ', '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  static dynamic _dig(dynamic root, List<String> path) {
    dynamic current = root;
    for (final key in path) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }

  static Map? _map(dynamic value) => value is Map ? value : null;

  static String? _string(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty || trimmed == 'null' ? null : trimmed;
  }
}

/// To'lov sahifasida ko'rsatiladigan summa. [currency] — `UZS` / `RUB` /
/// `USD`; `null` bo'lsa valyuta aniqlanmagan (foydalanuvchi tanlagan valyuta
/// belgisi ishlatiladi).
class BookingDisplayAmount {
  const BookingDisplayAmount(this.amount, this.currency);

  final double amount;
  final String? currency;

  /// Tanlash tartibi:
  ///  1. Backend narx o'zgarganini bildirgan va summa haqiqatan farq qilsa —
  ///     `ticket-data` dagi yangi jami summa (avvalgi xatti-harakat);
  ///  2. bron (`booking-create`) summasi va valyutasi — foydalanuvchi aynan
  ///     shuni to'laydi (qidiruv narxi emas);
  ///  3. aks holda `null` — sahifaga berilgan narx ko'rsatiladi.
  ///
  /// Eslatma: `ticket-data` jami summasi (hamkor narxi) MySafar komissiyasini
  /// o'z ichiga olmasligi mumkin, shu sabab narx o'zgarmagan bo'lsa bron
  /// summasi ustun.
  static BookingDisplayAmount? resolve({
    required dynamic bookingAmount,
    required String? bookingCurrency,
    BookingPaymentStatus? ticketData,
  }) {
    final booked = BookingPaymentStatus.toDouble(bookingAmount);
    final changed = ticketData?.changedTotal;
    if (changed != null && (booked == null || (booked - changed).abs() >= 0.5)) {
      return BookingDisplayAmount(
          changed, ticketData?.currency ?? bookingCurrency);
    }
    if (booked != null && booked > 0 && bookingCurrency != null) {
      return BookingDisplayAmount(booked, bookingCurrency);
    }
    return null;
  }
}
