import 'package:flutter/material.dart' show Color, IconData, Icons;
import 'package:mysafar_sdk/src/core/styles/theme.dart' show ProjectTheme;

/// Vozvrat arizasining holati (`status` maydoni).
///
/// Backend faqat `pending` / `approved` / `rejected` qaytaradi; noma'lum
/// qiymat kelsa [unknown] ga tushadi va UI baribir yiqilmaydi.
enum RefundStatus {
  pending,
  approved,
  rejected,
  unknown;

  static RefundStatus parse(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'pending':
        return RefundStatus.pending;
      case 'approved':
        return RefundStatus.approved;
      case 'rejected':
        return RefundStatus.rejected;
      default:
        return RefundStatus.unknown;
    }
  }

  /// Ariza hali yopilmagan — bu biletga yangi ariza yuborib bo'lmaydi
  /// (server `409 ALREADY_REQUESTED` qaytaradi).
  bool get isOpen => this == RefundStatus.pending;

  String get labelKey => switch (this) {
        RefundStatus.pending => 'refund_status_pending',
        RefundStatus.approved => 'refund_status_approved',
        RefundStatus.rejected => 'refund_status_rejected',
        RefundStatus.unknown => 'refund_status_unknown',
      };

  Color get color => switch (this) {
        RefundStatus.pending => ProjectTheme.warning,
        RefundStatus.approved => ProjectTheme.success,
        RefundStatus.rejected => ProjectTheme.error,
        RefundStatus.unknown => ProjectTheme.brandColor,
      };

  IconData get icon => switch (this) {
        RefundStatus.pending => Icons.hourglass_top_rounded,
        RefundStatus.approved => Icons.verified_rounded,
        RefundStatus.rejected => Icons.cancel_rounded,
        RefundStatus.unknown => Icons.help_outline_rounded,
      };
}

/// Qaytarish turi. `voluntary` — foydalanuvchi o'zi voz kechdi;
/// `involuntary` — reys aviakompaniya tomonidan bekor qilingan.
enum RefundType {
  voluntary,
  involuntary;

  String get apiValue => name;

  String get labelKey => this == RefundType.voluntary
      ? 'refund_type_voluntary'
      : 'refund_type_involuntary';

  String get descriptionKey => this == RefundType.voluntary
      ? 'refund_type_voluntary_desc'
      : 'refund_type_involuntary_desc';

  static RefundType parse(String? raw) =>
      (raw ?? '').trim().toLowerCase() == 'involuntary'
          ? RefundType.involuntary
          : RefundType.voluntary;
}

/// Bitta vozvrat arizasi (`POST /tickets/refund/request` javobidagi `request`
/// va `GET /tickets/refund/requests` ro'yxatidagi element — maydonlari bir xil).
class RefundRequestModel {
  final int? id;
  final String? billingId;
  final int? ticketId;
  final String? direction;
  final String? airline;
  final String? ticketStatus;
  final String? cardNumber;
  final String? cardHolder;
  final String? phoneNumber;
  final String? reason;
  final RefundType refundType;
  final RefundStatus status;
  final String? supportComment;
  final DateTime? createdAt;
  final DateTime? processedAt;

  const RefundRequestModel({
    this.id,
    this.billingId,
    this.ticketId,
    this.direction,
    this.airline,
    this.ticketStatus,
    this.cardNumber,
    this.cardHolder,
    this.phoneNumber,
    this.reason,
    this.refundType = RefundType.voluntary,
    this.status = RefundStatus.unknown,
    this.supportComment,
    this.createdAt,
    this.processedAt,
  });

  factory RefundRequestModel.fromJson(Map<String, dynamic> json) =>
      RefundRequestModel(
        id: _asInt(json['id']),
        billingId: _asString(json['billing_id']),
        ticketId: _asInt(json['ticket_id']),
        direction: _asString(json['direction']),
        airline: _asString(json['airline']),
        ticketStatus: _asString(json['ticket_status']),
        cardNumber: _asString(json['card_number']),
        cardHolder: _asString(json['card_holder']),
        phoneNumber: _asString(json['phone_number']),
        reason: _asString(json['reason']),
        refundType: RefundType.parse(_asString(json['refund_type'])),
        status: RefundStatus.parse(_asString(json['status'])),
        supportComment: _asString(json['support_comment']),
        createdAt: _asDate(json['created_at']),
        processedAt: _asDate(json['processed_at']),
      );

  /// Kartaning oxirgi 4 raqami — ro'yxatda to'liq raqamni ko'rsatmaymiz.
  /// Backend probelsiz saqlaydi, lekin har ehtimolga qarshi tozalaymiz.
  String get maskedCard {
    final digits = (cardNumber ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return '';
    return '•••• ${digits.substring(digits.length - 4)}';
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.trim().isEmpty ? null : value.trim();
    return '$value';
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('${value ?? ''}');
  }

  static DateTime? _asDate(dynamic value) {
    final raw = _asString(value);
    if (raw == null) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }
}

/// Serverning xato javobi: `{ "code": "...", "detail": {uz, ru, en} }`.
///
/// [message] allaqachon foydalanuvchi tilida — uni to'g'ridan-to'g'ri ekranga
/// chiqarish mumkin. [code] esa UI mantiqi uchun (masalan `ALREADY_REQUESTED`
/// bo'lsa "Yangi ariza" tugmasini bloklash).
class RefundFailure {
  final String code;
  final String message;

  const RefundFailure({required this.code, required this.message});

  static const String alreadyRequested = 'ALREADY_REQUESTED';
  static const String cardInvalid = 'CARD_INVALID';
  static const String phoneInvalid = 'PHONE_INVALID';
  static const String notRefundable = 'NOT_REFUNDABLE';
  static const String notYourTicket = 'NOT_YOUR_TICKET';
  static const String ticketNotFound = 'TICKET_NOT_FOUND';

  bool get isAlreadyRequested => code == alreadyRequested;

  /// Xato qaysi maydonga tegishli — forma o'sha maydonni qizartirishi uchun.
  bool get isCardError => code == cardInvalid;
  bool get isPhoneError => code == phoneInvalid;
}
