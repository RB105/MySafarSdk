import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/cupertino.dart';

import 'country_codes.dart';
import 'country_localizations.dart';

/// Country element. This is the element that contains all the information
class CountryCode {
  /// the name of the country
  String? name;

  /// the flag of the country
  final String? phone_format;

  /// the country code (IT,AF..)
  final String? code;

  /// the dial code (39,93..)
  final String? dialCode;

  CountryCode({
    this.name,
    this.phone_format,
    this.code,
    this.dialCode,
  });

  @Deprecated('Use `fromCountryCode` instead.')
  factory CountryCode.fromCode(String isoCode) {
    return CountryCode.fromCountryCode(isoCode);
  }

  factory CountryCode.fromCountryCode(String countryCode) {
    final Map<String, String>? jsonCode = codes.firstWhereOrNull(
      (code) => code['code'] == countryCode,
    );
    return CountryCode.fromJson(jsonCode!);
  }

  factory CountryCode.fromDialCode(String dialCode) {
    final Map<String, String>? jsonCode = codes.firstWhereOrNull(
      (code) => code['dial_code'] == dialCode,
    );
    return CountryCode.fromJson(jsonCode!);
  }

  CountryCode localize(BuildContext context) {
    return this
      ..name = CountryLocalizations.of(context)?.translate(code) ?? name;
  }

  factory CountryCode.fromJson(Map<String, dynamic> json) {
    return CountryCode(
      name: json['country_name'],
      code: json['iso_code'],
      dialCode: json['country_code'],
      phone_format: json['phone_mask'],
    );
  }

  @override
  String toString() => "+$dialCode";

  String toLongString() => "+$dialCode  ${toCountryStringOnly()}";

  String toHint() => phone_format?.replaceAll(RegExp("X"), "-") ?? "";

  String toCountryStringOnly() {
    return '$_cleanName';
  }

  String? get _cleanName {
    return name?.replaceAll(RegExp(r'[[\]]'), '').split(',').first;
  }
}
