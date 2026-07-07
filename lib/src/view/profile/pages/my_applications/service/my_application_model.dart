/// Bitta autopay arizasi modeli.
///
/// API javobi: `result.data[]` ichidagi obyekt.
class MyApplicationModel {
  final int? id;
  final int? partnerId;
  final int? createdBy;
  final String? uuid;
  final String? pinfl;
  final String? passport;
  final String? passportGivenDate;
  final String? firstName;
  final String? lastName;
  final String? middleName;
  final String? phone;
  final String? region;
  final String? district;
  final String? status;
  final String? createdAt;
  final String? updatedAt;
  final dynamic price;
  final dynamic percent;
  final dynamic period;
  final String? isEligible;
  final String? eligibleReason;
  final Map<String, dynamic> raw;

  MyApplicationModel({
    this.id,
    this.partnerId,
    this.createdBy,
    this.uuid,
    this.pinfl,
    this.passport,
    this.passportGivenDate,
    this.firstName,
    this.lastName,
    this.middleName,
    this.phone,
    this.region,
    this.district,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.price,
    this.percent,
    this.period,
    this.isEligible,
    this.eligibleReason,
    this.raw = const {},
  });

  factory MyApplicationModel.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic v) =>
        v is int ? v : (v == null ? null : int.tryParse(v.toString()));
    String? toStr(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    return MyApplicationModel(
      id: toInt(json['id']),
      partnerId: toInt(json['partner_id']),
      createdBy: toInt(json['created_by']),
      uuid: toStr(json['uuid']),
      pinfl: toStr(json['pinfl']),
      passport: toStr(json['passport']),
      passportGivenDate: toStr(json['passport_given_date']),
      firstName: toStr(json['first_name']),
      lastName: toStr(json['last_name']),
      middleName: toStr(json['middle_name']),
      phone: toStr(json['phone']),
      region: toStr(json['region']),
      district: toStr(json['district']),
      status: toStr(json['status']),
      createdAt: toStr(json['created_at']),
      updatedAt: toStr(json['updated_at']),
      price: json['price'],
      percent: json['percent'],
      period: json['period'],
      isEligible: toStr(json['is_eligible']),
      eligibleReason: toStr(json['eligible_reason']),
      raw: json,
    );
  }

  /// "ABDUMALIKOV RASULJON BAHODIR OGLI"
  String get fullName {
    final parts = [lastName, firstName, middleName]
        .whereType<String>()
        .where((e) => e.trim().isNotEmpty)
        .map((e) => _capitalize(e.trim()))
        .toList();
    return parts.join(' ');
  }

  String get formattedCreatedAt => _formatDate(createdAt);

  String get formattedPassportGivenDate => _formatDate(passportGivenDate);

  /// `toshkent, toshkent` -> "Toshkent, Toshkent"
  String? get address {
    final parts = [region, district]
        .whereType<String>()
        .where((e) => e.trim().isNotEmpty)
        .map((e) => _capitalize(e.trim()))
        .toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  /// Ariza holatini bitta umumiy turga keltiradi (UI rang/yorliq uchun).
  ApplicationStatus get statusType {
    final s = (status ?? '').toLowerCase().trim();
    final e = (isEligible ?? '').toLowerCase().trim();

    if (s == 'approved' || s == 'success' || s == 'done' || e == 'eligible') {
      return ApplicationStatus.approved;
    }
    if (s == 'rejected' ||
        s == 'declined' ||
        s == 'canceled' ||
        s == 'cancelled' ||
        e == 'not_eligible' ||
        e == 'ineligible') {
      return ApplicationStatus.rejected;
    }
    if (s == 'review' || s == 'in_review' || e == 'review' || e == 'pending') {
      return ApplicationStatus.review;
    }
    if (s == 'new' || s.isEmpty) {
      return ApplicationStatus.created;
    }
    return ApplicationStatus.review;
  }

  static String _formatDate(String? value) {
    if (value == null || value.isEmpty) return '';
    final dt = DateTime.tryParse(value)?.toLocal();
    if (dt == null) return value;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year}';
  }

  static String _capitalize(String value) {
    return value
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty
            ? w
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}

enum ApplicationStatus { created, review, approved, rejected }

extension ApplicationStatusX on ApplicationStatus {
  /// `lang/*.json` dagi tarjima kaliti.
  String get labelKey {
    switch (this) {
      case ApplicationStatus.created:
        return 'application_status_new';
      case ApplicationStatus.review:
        return 'application_status_review';
      case ApplicationStatus.approved:
        return 'application_status_approved';
      case ApplicationStatus.rejected:
        return 'application_status_rejected';
    }
  }
}