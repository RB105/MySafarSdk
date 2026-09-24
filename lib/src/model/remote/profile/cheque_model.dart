class ChequeModel {
  final String qrUrl;
  final int amount;
  final int currency;
  /// Sana kelmasa yoki o'qib bo'lmasa `null` (sahifa "—" ko'rsatadi).
  final DateTime? createdAt;
  final String orderNumber;
  final bool status;

  ChequeModel({
    required this.qrUrl,
    required this.amount,
    required this.currency,
    required this.createdAt,
    required this.orderNumber,
    required this.status,
  });

  /// Backend turlari farq qilsa ham yiqilmaydi (№89): summa `int`/`double`/
  /// matn, sana `null` yoki noto'g'ri formatda kelishi mumkin.
  factory ChequeModel.fromJson(Map<String, dynamic> json) {
    return ChequeModel(
      qrUrl: json['qr_url']?.toString() ?? "",
      amount: toInt(json['amount']) ?? 0,
      currency: toInt(json['currency']) ?? 860,
      createdAt: parseDate(json['created_at']),
      orderNumber: json['order_number']?.toString() ?? "",
      status: json['status'] == true ||
          json['status'] == 1 ||
          json['status']?.toString().toLowerCase() == 'true',
    );
  }

  /// `num` yoki matnni (`"12 500"`, `"12500.0"`) butun songa; imkonsiz — null.
  static int? toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.isFinite ? value.round() : null;
    final cleaned = value.toString().trim().replaceAll(' ', '');
    if (cleaned.isEmpty) return null;
    final parsed = num.tryParse(cleaned);
    return parsed != null && parsed.isFinite ? parsed.round() : null;
  }

  static DateTime? parseDate(dynamic value) =>
      value is String ? DateTime.tryParse(value.trim()) : null;

  Map<String, dynamic> toJson() {
    return {
      'qr_url': qrUrl,
      'amount': amount,
      'currency': currency,
      'created_at': createdAt?.toIso8601String(),
      'order_number': orderNumber,
      'status': status,
    };
  }
}
