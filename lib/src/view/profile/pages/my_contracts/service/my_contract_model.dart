import 'package:mysafar_sdk/src/core/tools/formatters.dart' show ElementFormatter;

/// Bitta autopay shartnomasi modeli.
///
/// API javobi: `result.data[]` ichidagi obyekt.
/// Summalar tiyinda keladi (1 so'm = 100 tiyin).
class MyContractModel {
  final int? id;
  final int? merchantId;
  final int? createdBy;
  final String? pinfl;
  final String? loanId;
  final String? ext;
  final num? totalDebt;
  final num? currentDebt;
  final num? paidAmount;
  final bool auto;
  final dynamic account;
  final dynamic info;
  final List<MyContractProduct> products;
  final Map<String, dynamic> raw;

  MyContractModel({
    this.id,
    this.merchantId,
    this.createdBy,
    this.pinfl,
    this.loanId,
    this.ext,
    this.totalDebt,
    this.currentDebt,
    this.paidAmount,
    this.auto = false,
    this.account,
    this.info,
    this.products = const [],
    this.raw = const {},
  });

  factory MyContractModel.fromJson(Map<String, dynamic> json) {
    final productsRaw = json['products'];
    final products = productsRaw is List
        ? productsRaw
            .whereType<Map>()
            .map((e) => MyContractProduct.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <MyContractProduct>[];

    return MyContractModel(
      id: _toInt(json['id']),
      merchantId: _toInt(json['merchant_id']),
      createdBy: _toInt(json['created_by']),
      pinfl: _toStr(json['pinfl']),
      loanId: _toStr(json['loan_id']),
      ext: _toStr(json['ext']),
      totalDebt: _toNum(json['total_debt']),
      currentDebt: _toNum(json['current_debt']),
      paidAmount: _toNum(json['paid_amount']),
      auto: json['auto'] == true,
      account: json['account'],
      info: json['info'],
      products: products,
      raw: json,
    );
  }

  /// "A-85"
  String get title {
    final id = loanId ?? ext;
    return (id == null || id.isEmpty) ? '—' : id;
  }

  String get formattedTotalDebt => _money(totalDebt);

  /// Joriy qarz: products bor bo'lsa graphics'lardagi `current_amount`
  /// yig'indisi (aniqroq), aks holda `totalDebt - paidAmount`.
  String get formattedCurrentDebt => _money(computedCurrentDebt);

  String get formattedPaidAmount => _money(paidAmount);

  /// Hisoblangan joriy qarz tiyinda.
  num get computedCurrentDebt {
    if (products.isNotEmpty) {
      num sum = 0;
      for (final product in products) {
        for (final graphic in product.graphics) {
          sum += graphic.currentAmount ?? 0;
        }
      }
      return sum;
    }
    final total = totalDebt ?? 0;
    final paid = paidAmount ?? 0;
    final remaining = total - paid;
    return remaining < 0 ? 0 : remaining;
  }

  /// `paidAmount / totalDebt` — 0..1 oralig'ida.
  double get progress {
    final total = totalDebt;
    final paid = paidAmount;
    if (total == null || total <= 0 || paid == null) return 0;
    final p = paid / total;
    if (p.isNaN || p.isInfinite) return 0;
    return p.clamp(0, 1).toDouble();
  }

  /// Tiyinni so'mga o'tkazib, bo'shliq bilan formatlaydi.
  static String _money(num? value) {
    if (value == null) return '0';
    return ElementFormatter.formatNumberWithSpaces(value / 100);
  }
}

/// Shartnoma ichidagi mahsulot.
class MyContractProduct {
  final int? id;
  final int? partnerId;
  final int? merchantId;
  final int? contractId;
  final String? name;
  final String? startDate;
  final String? dueDate;
  final num? amount;
  final int? period;
  final String? comment;
  final int? userId;
  final bool isGraphicSet;
  final String? createdAt;
  final String? updatedAt;
  final String? mode;
  final num? initialAmount;
  final String? percentage;
  final List<MyContractGraphic> graphics;
  final Map<String, dynamic> raw;

  MyContractProduct({
    this.id,
    this.partnerId,
    this.merchantId,
    this.contractId,
    this.name,
    this.startDate,
    this.dueDate,
    this.amount,
    this.period,
    this.comment,
    this.userId,
    this.isGraphicSet = false,
    this.createdAt,
    this.updatedAt,
    this.mode,
    this.initialAmount,
    this.percentage,
    this.graphics = const [],
    this.raw = const {},
  });

  factory MyContractProduct.fromJson(Map<String, dynamic> json) {
    final graphicsRaw = json['graphics'];
    final graphics = graphicsRaw is List
        ? graphicsRaw
            .whereType<Map>()
            .map((e) =>
                MyContractGraphic.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <MyContractGraphic>[];
    graphics.sort((a, b) =>
        (a.periodNumber ?? 0).compareTo(b.periodNumber ?? 0));

    return MyContractProduct(
      id: _toInt(json['id']),
      partnerId: _toInt(json['partner_id']),
      merchantId: _toInt(json['merchant_id']),
      contractId: _toInt(json['contract_id']),
      name: _toStr(json['name']),
      startDate: _toStr(json['start_date']),
      dueDate: _toStr(json['due_date']),
      amount: _toNum(json['amount']),
      period: _toInt(json['period']),
      comment: _toStr(json['comment']),
      userId: _toInt(json['user_id']),
      isGraphicSet: json['is_graphic_set'] == true,
      createdAt: _toStr(json['created_at']),
      updatedAt: _toStr(json['updated_at']),
      mode: _toStr(json['mode']),
      initialAmount: _toNum(json['initial_amount']),
      percentage: _toStr(json['percentage']),
      graphics: graphics,
      raw: json,
    );
  }

  String get formattedAmount => MyContractModel._money(amount);

  String get formattedInitialAmount => MyContractModel._money(initialAmount);

  String get formattedStartDate => _formatDate(startDate);

  String get formattedDueDate => _formatDate(dueDate);
}

/// Mahsulot uchun to'lov jadvalining bitta qatori.
class MyContractGraphic {
  final int? id;
  final int? partnerId;
  final int? merchantId;
  final int? contractId;
  final int? productId;
  final num? totalAmount;
  final num? paidAmount;
  final num? currentAmount;
  final int? periodNumber;
  final String? dueDate;
  final int? calculationCount;
  final int? delay;
  final String? createdAt;
  final String? updatedAt;
  final Map<String, dynamic> raw;

  MyContractGraphic({
    this.id,
    this.partnerId,
    this.merchantId,
    this.contractId,
    this.productId,
    this.totalAmount,
    this.paidAmount,
    this.currentAmount,
    this.periodNumber,
    this.dueDate,
    this.calculationCount,
    this.delay,
    this.createdAt,
    this.updatedAt,
    this.raw = const {},
  });

  factory MyContractGraphic.fromJson(Map<String, dynamic> json) {
    return MyContractGraphic(
      id: _toInt(json['id']),
      partnerId: _toInt(json['partner_id']),
      merchantId: _toInt(json['merchant_id']),
      contractId: _toInt(json['contract_id']),
      productId: _toInt(json['product_id']),
      totalAmount: _toNum(json['total_amount']),
      paidAmount: _toNum(json['paid_amount']),
      currentAmount: _toNum(json['current_amount']),
      periodNumber: _toInt(json['period_number']),
      dueDate: _toStr(json['due_date']),
      calculationCount: _toInt(json['calculation_count']),
      delay: _toInt(json['delay']),
      createdAt: _toStr(json['created_at']),
      updatedAt: _toStr(json['updated_at']),
      raw: json,
    );
  }

  String get formattedTotalAmount => MyContractModel._money(totalAmount);

  String get formattedPaidAmount => MyContractModel._money(paidAmount);

  String get formattedCurrentAmount => MyContractModel._money(currentAmount);

  String get formattedDueDate => _formatDate(dueDate);

  /// To'lov holati: paid / pending / overdue.
  ///
  /// `current_amount` shu davrda hali to'lanmagan summa.
  /// 0 ga teng bo'lsa — to'liq to'langan.
  /// > 0 bo'lsa va `delay > 0` — muddati o'tgan, aks holda kutilmoqda.
  GraphicStatus get status {
    final current = currentAmount ?? 0;
    if (current <= 0) return GraphicStatus.paid;
    final delayValue = delay ?? 0;
    if (delayValue > 0) return GraphicStatus.overdue;
    return GraphicStatus.pending;
  }
}

enum GraphicStatus { paid, pending, overdue }

extension GraphicStatusX on GraphicStatus {
  String get labelKey {
    switch (this) {
      case GraphicStatus.paid:
        return 'graphic_status_paid';
      case GraphicStatus.pending:
        return 'graphic_status_pending';
      case GraphicStatus.overdue:
        return 'graphic_status_overdue';
    }
  }
}

int? _toInt(dynamic v) =>
    v is int ? v : (v == null ? null : int.tryParse(v.toString()));

num? _toNum(dynamic v) =>
    v is num ? v : (v == null ? null : num.tryParse(v.toString()));

String? _toStr(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

String _formatDate(String? value) {
  if (value == null || value.isEmpty) return '';
  final dt = DateTime.tryParse(value)?.toLocal();
  if (dt == null) return value;
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(dt.day)}.${two(dt.month)}.${dt.year}';
}
