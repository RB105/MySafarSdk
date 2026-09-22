class BookingCreateModel {
  int? id;
  String? createdAt;
  String? updatedAt;
  bool? isDeleted;
  String? deletedAt;
  dynamic amount;
  int? currency;
  String? trId;
  dynamic type;
  bool? status;
  int? statusType;
  int? user;
  int? ticket;

  int? commissionAmount;
  int? commissionCurrency;
  String? partnerFee;
  String? mysafarCommission;
  bool? isUsed;
  String? message;
  String? billingId;
  String? expire;
  dynamic hotel;

  BookingCreateModel({
    this.id,
    this.createdAt,
    this.updatedAt,
    this.isDeleted,
    this.deletedAt,
    this.amount,
    this.currency,
    this.trId,
    this.type,
    this.status,
    this.statusType,
    this.user,
    this.ticket,
    this.commissionAmount,
    this.commissionCurrency,
    this.partnerFee,
    this.mysafarCommission,
    this.isUsed,
    this.message,
    this.hotel,
    this.billingId,
    this.expire,
  });

  BookingCreateModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    isDeleted = json['is_deleted'];
    deletedAt = json['deleted_at'] ?? "";
    amount = json['amount'];
    // Valyuta kodi son yoki matn ("860") bo'lib kelishi mumkin.
    currency = _toInt(json['currency']);
    trId = json['tr_id']?.toString();
    type = json['type'] ?? "";
    status = json['status'];
    statusType = json['status_type'];
    user = json['user'];
    ticket = json['ticket'];

    commissionAmount = json['commission_amount'];
    commissionCurrency = json['commission_currency'];
    partnerFee = json['partner_fee']?.toString() ?? "0.0";
    mysafarCommission = json['mysafar_commission']?.toString() ?? "0.0";
    isUsed = json['is_used'];
    message = json['message'] ?? "";
    // `billing_id` bo'lmasa "null" matni emas, null qoladi.
    billingId = json['billing_id']?.toString();
    expire = json['expire'] ?? "";
    hotel = json['hotel'];
  }

  /// ISO 4217 raqamli kod → harfli: 860 UZS, 643 RUB, 840 USD.
  /// Noma'lum yoki yo'q bo'lsa `null`.
  static String? currencyLabelFor(int? code) => switch (code) {
        860 => 'UZS',
        643 => 'RUB',
        840 => 'USD',
        _ => null,
      };

  /// Bron valyutasi (`UZS` / `RUB` / `USD`) yoki `null`.
  String? get currencyLabel => currencyLabelFor(currency);

  static int? _toInt(dynamic value) =>
      value is int ? value : int.tryParse('${value ?? ''}'.trim());

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['is_deleted'] = isDeleted;
    data['deleted_at'] = deletedAt;
    data['amount'] = amount;
    data['currency'] = currency;
    data['tr_id'] = trId;
    data['type'] = type;
    data['status'] = status;
    data['status_type'] = statusType;
    data['user'] = user;
    data['ticket'] = ticket;

    data['commission_amount'] = commissionAmount;
    data['commission_currency'] = commissionCurrency;
    data['partner_fee'] = partnerFee;
    data['mysafar_commission'] = mysafarCommission;
    data['is_used'] = isUsed;
    data['message'] = message;
    data['hotel'] = hotel;

    return data;
  }
}
