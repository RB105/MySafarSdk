import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';

extension DateTimeExt on DateTime {
  bool isSame(DateTime? date) {
    if (date == null) {
      return false;
    }
    if (date.year == year && date.month == month && date.day == day) {
      return true;
    }
    return false;
  }

  String get dateWithMonth {
    String monthName(int month) {
      final months = [
        'january'.tr(),
        'february'.tr(),
        'march'.tr(),
        'april'.tr(),
        'may'.tr(),
        'june'.tr(),
        'july'.tr(),
        'august'.tr(),
        'september'.tr(),
        'october'.tr(),
        'november'.tr(),
        'december'.tr()
      ];
      return months[month - 1];
    }

    return "$day ${monthName(month)}";
  }

  String get dateWithMonthLowerCase {
    String monthName(int month) {
      final months = [
        'jan'.tr(),
        'fev'.tr(),
        'marc'.tr(),
        'apr'.tr(),
        'ma'.tr(),
        'jun'.tr(),
        'jul'.tr(),
        'aug'.tr(),
        'sep'.tr(),
        'oct'.tr(),
        'nov'.tr(),
        'dec'.tr()
      ];
      return months[month - 1];
    }

    return "$day ${monthName(month)}";
  }

  /// Checks if the dot-formatted string (like "01.01.1999") matches this DateTime
  bool isSameDotDate(String dotDate) {
    try {
      final parts = dotDate.split('.');
      if (parts.length != 3) return false;

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      return this.day == day && this.month == month && this.year == year;
    } catch (_) {
      return false; // In case of invalid format or parsing error
    }
  }

  /// formats date like -> **1.1.1999**
  String get formattedDotDate {
    return "$day.$month.$year";
  }
}
