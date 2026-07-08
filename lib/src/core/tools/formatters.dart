import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:mysafar_sdk/src/model/remote/booking/payment_confirm_model.dart'
    show Name;

import '../../model/remote/profile/confirmed_ticket_models.dart' show Passenger;

class ElementFormatter {
  // formats flight duration
  static String formatDuration(int durationInMinutes) {
    final int days = durationInMinutes ~/ (24 * 60);
    final int hours = (durationInMinutes % (24 * 60)) ~/ 60;
    final int minutes = durationInMinutes % 60;

    final List<String> parts = [];

    if (days > 0) {
      parts.add('s_day'.tr(namedArgs: {"d": "$days"}));
    }

    if (hours > 0) {
      parts.add('s_hour'.tr(namedArgs: {"h": "$hours"}));
    }

    if (minutes > 0) {
      parts.add('s_minute'.tr(namedArgs: {"m": "$minutes"}));
    }

    return parts.join(' ');
  }

  // format month
  static String formatMonth(int? month) {
    switch (month) {
      case 1:
        return 'jan'.tr();
      case 2:
        return 'fev'.tr();
      case 3:
        return 'marc'.tr();
      case 4:
        return 'apr'.tr();
      case 5:
        return 'ma'.tr();
      case 6:
        return 'jun'.tr();
      case 7:
        return 'jul'.tr();
      case 8:
        return 'aug'.tr();
      case 9:
        return 'sep'.tr();
      case 10:
        return 'oct'.tr();
      case 11:
        return 'nov'.tr();
      case 12:
        return 'dec'.tr();
      default:
        return "";
    }
  }

  static String getMonth(String date) {
    final list = date.split('-');
    return formatMonth(int.parse(list[1]));
  }

  static String getWeekDay(String date) {
    if (date.isEmpty) {
      return "";
    }
    final dateFormat = DateFormat('dd.MM.yyyy');
    final dateTime = dateFormat.parse(date);
    final weekDay = switch (dateTime.weekday) {
      1 => "Monday".tr(),
      2 => "Tuesday".tr(),
      3 => "Wednesday".tr(),
      4 => "Thursday".tr(),
      5 => "Friday".tr(),
      6 => "Saturday".tr(),
      7 => "Sunday".tr(),
      _ => ""
    };

    return weekDay;
  }

  static String formatWithWeekDay(String date) {
    late DateFormat dateFormat;
    if (date.contains("-")) {
      dateFormat = DateFormat('dd-MM-yyyy');
    } else {
      dateFormat = DateFormat('dd.MM.yyyy');
    }
    final dateTime = dateFormat.parse(date);
    late String weekDay;
    weekDay = switch (dateTime.weekday) {
      1 => "mon".tr(),
      2 => "tue".tr(),
      3 => "wed".tr(),
      4 => "thu".tr(),
      5 => "fri".tr(),
      6 => "sat".tr(),
      7 => "sun".tr(),
      _ => ""
    };

    return "${dateTime.day} ${formatMonth(dateTime.month)}, $weekDay";
  }

  static String formatPrice(String price) {
    var result = price.substring(0, price.length % 3);
    var end = price.replaceRange(0, price.length % 3, "");

    for (var i = 0; i < end.length; i++) {
      if (i % 3 == 0) {
        result += " ";
        result += end[i];
        continue;
      }
      result += end[i];
    }
    return result;
  }

  // static Segment getCorrectSegments(List<Segment> list) {
  //   if (list.isEmpty) {
  //     throw Exception("List bo'sh bo'lishi mumkin emas");
  //   }
  //   return list.length == 1 ? list.first : list.last;
  // }

  static String formatDateFull(String inputDate) {
    DateTime parsedDate = DateFormat("dd.MM.yyyy").parse(inputDate);
    return DateFormat("MMM d, yyyy").format(parsedDate);
  }

  static String formatFio(Name name) {
    return "${name.first} ${name.last}";
  }

  static String formatDate(String date) {
    if (date.isEmpty) {
      return "";
    }
    List<String> list = date.split('.');
    return "${list[0]} ${formatMonth(int.parse(list[1]))}";
  }

  static String formatTime(String time) {
    List<String> parts = time.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return time;
  }

  final MaskTextInputFormatter phoneFormatter = MaskTextInputFormatter(
    mask: 'XX XXX XX XX',
    type: MaskAutoCompletionType.eager,
    filter: {"X": RegExp(r'[0-9]')},
  );

  static String expireRemainingMinutes(String created) {
    DateTime parseCreated(String created) {
      try {
        return DateFormat('dd.MM.yyyy HH:mm:ss').parse(created);
      } catch (_) {
        try {
          return DateFormat('dd-MM-yyyy HH:mm:ss').parse(created);
        } catch (_) {
          return DateFormat('dd-MM-yyyy HH:mm').parse(created);
        }
      }
    }

    try {
      final DateTime now = DateTime.now();
      final DateTime createdTime = parseCreated(created);

      final Duration diff = now.difference(createdTime);
      final int remaining = 30 - diff.inMinutes;

      if (remaining <= 0) {
        return "Vaqt tugagan";
      } else {
        return "$remaining";
      }
    } catch (e) {
      return "Noto‘g‘ri vaqt formati";
    }
  }

  static String bookingExpireRemainingMinutes(String created) {
    try {
      final DateTime now = DateTime.now();
      final DateTime createdTime = DateTime.parse(created); // ISO 8601 format

      final Duration diff = now.difference(createdTime);
      final int remaining = 30 - diff.inMinutes;

      if (remaining <= 0) {
        return "Vaqt tugagan";
      } else {
        return "$remaining";
      }
    } catch (e) {
      return "Noto‘g‘ri vaqt formati";
    }
  }

  int bookingExpireRemainingSeconds(String created) {
    final createdTime = parseCreatedAt(created);
    if (createdTime == null) return 0;

    final now = DateTime.now();
    final diff = now.difference(createdTime);
    final int remaining = 1800 - diff.inSeconds;

    return remaining > 0 ? remaining : 0;
  }

  DateTime? parseCreatedAt(String created) {
    try {
      return DateTime.parse(created);
    } catch (_) {
      try {
        return DateFormat("dd-MM-yyyy HH:mm").parseStrict(created);
      } catch (_) {
        try {
          return DateFormat("dd.MM.yyyy HH:mm:ss").parseStrict(created);
        } catch (_) {
          try {
            return DateFormat("dd-MM-yyyy HH:mm:ss").parseStrict(created);
          } catch (_) {
            return null;
          }
        }
      }
    }
  }

  static bool expireStatus(String created) {
    final DateTime now = DateTime.now();

    final DateFormat formatter = DateFormat('dd-MM-yyyy HH:mm');
    final DateTime createdTime = formatter.parse(created);

    final bool isSameDay = createdTime.year == now.year &&
        createdTime.month == now.month &&
        createdTime.day == now.day;

    final Duration diff = now.difference(createdTime);

    return isSameDay && diff.inMinutes <= 30 && !diff.isNegative;
  }

  static String formatNumberWithSpaces(dynamic number) {
    double parsed;
    try {
      if (number is int || number is double) {
        parsed = number.toDouble();
      } else if (number is String) {
        parsed = double.parse(number.replaceAll(' ', ''));
      } else {
        throw FormatException('Unsupported type');
      }
    } catch (_) {
      return number.toString();
    }

    final parts = parsed.toStringAsFixed(1).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1] != '0' ? '.${parts[1]}' : '';

    final buffer = StringBuffer();
    int count = 0;

    for (int i = integerPart.length - 1; i >= 0; i--) {
      buffer.write(integerPart[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write(' ');
      }
    }

    final formattedInteger = buffer.toString().split('').reversed.join('');
    return formattedInteger + decimalPart;
  }

  static String getPassengerAgeSummary(List<Passenger>? passengers) {
    if (passengers == null || passengers.isEmpty) return "";

    int adultCount = 0;
    int childCount = 0;
    int infantCount = 0;

    for (var passenger in passengers) {
      switch (passenger.age?.toLowerCase()) {
        case "adt":
          adultCount++;
          break;
        case "chd":
          childCount++;
          break;
        case "inf":
          infantCount++;
          break;
      }
    }

    List<String> parts = [];

    if (adultCount > 0) {
      parts.add("adults".tr(args: ["$adultCount"]));
    }
    if (childCount > 0) {
      parts.add("children".tr(args: ["$childCount"]));
    }
    if (infantCount > 0) {
      parts.add("infants".tr(args: ["$infantCount"]));
    }

    return parts.join(", ");
  }

  static String getClassName(String code, String langCode) {
    switch (code.toLowerCase()) {
      case 'e':
        return {
              'ru': 'Эконом-класс',
              'en': 'Economy class',
              'uz': 'Ekonom klass'
            }[langCode] ??
            'Economy class';

      case 'b':
        return {
              'ru': 'Бизнес-класс',
              'en': 'Business class',
              'uz': 'Biznes klass'
            }[langCode] ??
            'Business class';

      case 'f':
        return {
              'ru': 'Первый класс',
              'en': 'First class',
              'uz': 'Birinchi klass'
            }[langCode] ??
            'First class';

      case 'w':
        return {
              'ru': 'Комфорт',
              'en': 'Comfort class',
              'uz': 'Qulay klass'
            }[langCode] ??
            'Comfort class';

      default:
        return {
              'ru': 'Неизвестный класс',
              'en': 'Unknown class',
              'uz': 'Nomaʼlum klass'
            }[langCode] ??
            'Unknown class';
    }
  }
 static final NumberFormat _amountFormatter = NumberFormat('#,###', 'en_US');

  static String formatAmount(double value) {
    return _amountFormatter.format(value).replaceAll(',', ' ');
  }

}
