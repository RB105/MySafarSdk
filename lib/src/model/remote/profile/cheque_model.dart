class ChequeModel {
  final String qrUrl;
  final int amount;
  final int currency;
  final DateTime createdAt;
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

  factory ChequeModel.fromJson(Map<String, dynamic> json) {
    return ChequeModel(
      qrUrl: json['qr_url'] ?? "",
      amount: json['amount'] ?? 0,
      currency: json['currency'] ?? 860,
      createdAt: DateTime.parse(json['created_at'] as String),
      orderNumber: json['order_number'] ?? "",
      status: json['status'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'qr_url': qrUrl,
      'amount': amount,
      'currency': currency,
      'created_at': createdAt.toIso8601String(),
      'order_number': orderNumber,
      'status': status,
    };
  }
}
