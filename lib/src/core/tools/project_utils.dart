import 'package:flutter/material.dart' show debugPrint;
import 'package:flutter/services.dart' show MethodChannel, PlatformException;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:package_info_plus/package_info_plus.dart' show PackageInfo;
import 'package:mysafar_sdk/src/model/local/recom_req_model.dart';
import 'package:mysafar_sdk/src/model/remote/fornex/pop_destinations.dart';

class ProjectUtils {
  ProjectUtils._privateConstructor();

  static final ProjectUtils _instance = ProjectUtils._privateConstructor();

  factory ProjectUtils() {
    return _instance;
  }

  static late RecommendationRequestBody params;

  static List<PopDestinationsModel>? popularDestinations;

  /// Date formatters
  static MaskTextInputFormatter dateFormatter = MaskTextInputFormatter(
    type: MaskAutoCompletionType.lazy,
    mask: "##.##.####",
    filter: {"#": RegExp(r'[0-9]')},
  );

  static MaskTextInputFormatter get docexpFormatter => MaskTextInputFormatter(
        type: MaskAutoCompletionType.lazy,
        mask: "##.##.####",
        filter: {"#": RegExp(r'[0-9]')},
      );

  static MaskTextInputFormatter get birthdateFormatter =>
      MaskTextInputFormatter(
        type: MaskAutoCompletionType.lazy,
        mask: "##.##.####",
        filter: {"#": RegExp(r'[0-9]')},
      );

  static void setPopularDestinations(List<PopDestinationsModel> destinations) {
    popularDestinations = destinations;
  }

  static void setRecommendationParams(RecommendationRequestBody body) {
    params = body;
  }

  /// Clears cached static state so large lists are not retained for the
  /// whole app lifetime. Safe to call on logout / app reset.
  static void clear() {
    popularDestinations = null;
  }

  /// Kalendar integratsiyasi host app'ning native `MySafarChannel` handler'iga
  /// bog'liq. Handler yo'q bo'lsa (masalan begona host) chaqiruv jim
  /// o'tkazib yuboriladi — pastdagi catch'lar shuni ta'minlaydi.
  static final _channel = MethodChannel("MySafarChannel");

  /// Versiya endi native kanaldan emas, package_info_plus'dan olinadi —
  /// SDK har qanday host app ichida ishlashi uchun.
  static Future<int> getVersionCode() async {
    final info = await PackageInfo.fromPlatform();
    return int.tryParse(info.buildNumber) ?? 0;
  }

  static Future<String> getVersionName() async {
    final info = await PackageInfo.fromPlatform();
    return info.version.isEmpty ? 'Unknown' : info.version;
  }

  /// Add flight to calendar
  static Future<void> addFlightToCalendar({
    required DateTime departureDate,
    DateTime? arrivalDate,
    required String departureCity,
    required String arrivalCity,
  }) async {
    final args = {
      'departureDate': departureDate.millisecondsSinceEpoch,
      'arrivalDate': arrivalDate?.millisecondsSinceEpoch,
      'departureCity': departureCity,
      'arrivalCity': arrivalCity,
    };

    try {
      await _channel.invokeMethod('addFlight', args);
    } on PlatformException catch (e) {
      // Kalendar ruxsati berilmagan bo'lsa — jim o'tkazib yuboramiz.
      // Kalendarga qo'shish ixtiyoriy bo'lib, to'lov oqimini buzib
      // foydalanuvchini device sozlamalariga olib ketmasligi kerak.
      debugPrint('Calendar event skipped: ${e.code}');
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
  }

  /// to set Calendar Event by current search params
  static void setCalendarEventByLastSearch() async {
    if (params.flight_Type == 0) {
      await addFlightToCalendar(
          departureDate: params.segments?[0].getDateTime ?? DateTime.now(),
          departureCity: params.segments?[0].from?.cityName ?? "",
          arrivalCity: params.segments?[0].to?.cityName ?? "");
    } else {
      await addFlightToCalendar(
          departureDate: params.segments?[0].getDateTime ?? DateTime.now(),
          arrivalDate: params.segments?.last.getDateTime ?? DateTime.now(),
          departureCity: params.segments?[0].from?.cityName ?? "",
          arrivalCity: params.segments?[0].to?.cityName ?? "");
    }
  }
}
