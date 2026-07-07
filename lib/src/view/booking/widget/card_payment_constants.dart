import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

/// Karta to'lovi uchun konstantalar
class CardPaymentConstants {
  CardPaymentConstants._();

  // Transaction type
  static const String transactionType = 'UZCARD/HUMO';

  // OTP
  static const int otpLength = 6;
  static const int otpTimerSeconds = 59;

  // Karta raqami uzunligi (mask bilan)
  static const int cardNumberMaskedLength = 19;

  // Ranglar
  static const int brandColorValue = 0xff0057BE;
  static const int focusColorValue = 0xFF0064FA;
}

/// Karta formatlash uchun factory
///
/// Har safar yangi formatter qaytaradi - static muammosini hal qiladi
class CardFormatters {
  CardFormatters._();

  /// Karta raqami uchun formatter (#### #### #### ####)
  static MaskTextInputFormatter createCardNumberFormatter() {
    return MaskTextInputFormatter(
      type: MaskAutoCompletionType.lazy,
      mask: '#### #### #### ####',
      filter: {'#': RegExp(r'[0-9]')},
    );
  }

  /// Karta muddati uchun formatter (MM/YY)
  static MaskTextInputFormatter createCardExpFormatter() {
    return MaskTextInputFormatter(
      type: MaskAutoCompletionType.lazy,
      mask: '##/##',
      filter: {'#': RegExp(r'[0-9]')},
    );
  }
}

/// Karta ma'lumotlari modeli
class CardInfo {
  final bool isValid;
  final String? cardType;
  final String? bankName;
  final String? owner;
  final int? pcType;

  const CardInfo({
    this.isValid = false,
    this.cardType,
    this.bankName,
    this.owner,
    this.pcType,
  });

  factory CardInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CardInfo();
    final rawPcType = json['pc_type'];
    final pcType = rawPcType is int
        ? rawPcType
        : (rawPcType is String ? int.tryParse(rawPcType) : null);
    String? cardType = json['card_type'] as String?;
    if (cardType == null && pcType != null) {
      if (pcType == 1) cardType = 'sv';
      if (pcType == 3) cardType = 'humo';
    }
    return CardInfo(
      isValid: json['is_valid'] ?? false,
      cardType: cardType,
      bankName: json['bank_name'] as String?,
      owner: json['owner'] as String?,
      pcType: pcType,
    );
  }
}

