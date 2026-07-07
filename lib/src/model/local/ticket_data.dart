/// Chipta PDF sahifasi uchun konstantalar va modellar
class TicketPdfConstants {
  TicketPdfConstants._();

  // Status values
  static const String statusTicketed = 'ticketed';
  static const String statusPaid = 'paid';

  // File naming
  static const String filePrefix = 'MySafar_ticket_';
}

/// Chipta ma'lumotlari modeli
///
/// API dan kelgan raw data'ni type-safe modelga o'giradi
class TicketData {
  final String? statusSign;
  final String? statusTitle;
  final String? expire;
  final String? billingNumber;
  final String? ticketReceiptUrl;

  const TicketData({
    this.statusSign,
    this.statusTitle,
    this.expire,
    this.billingNumber,
    this.ticketReceiptUrl,
  });

  factory TicketData.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TicketData();

    try {
      final book = json['data']?['book'];
      if (book == null) return const TicketData();

      final order = book['order'] as Map<String, dynamic>?;
      final status = order?['status'] as Map<String, dynamic>?;
      final tickets = book['tickets'] as List<dynamic>?;

      String? receiptUrl;
      if (tickets != null && tickets.isNotEmpty) {
        final firstTicket = tickets[0] as Map<String, dynamic>?;
        final documents = firstTicket?['documents'] as Map<String, dynamic>?;
        receiptUrl = documents?['ticket_receipt'] as String?;
      }

      return TicketData(
        statusSign: status?['sign'] as String?,
        statusTitle: status?['title'] as String?,
        expire: order?['expire'] as String?,
        billingNumber: order?['billing_number']?.toString(),
        ticketReceiptUrl: receiptUrl,
      );
    } catch (e) {
      return const TicketData();
    }
  }

  bool get isSuccessful {
    final sign = statusSign?.toLowerCase();
    return sign == TicketPdfConstants.statusTicketed ||
        sign == TicketPdfConstants.statusPaid;
  }

  String get fileName => '${TicketPdfConstants.filePrefix}$billingNumber';
}

