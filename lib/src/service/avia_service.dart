import 'dart:convert' show JsonDecoder, Utf8Decoder;

import 'package:dio/dio.dart' show ResponseType;
import 'package:flutter/foundation.dart' show compute, debugPrint;
import 'package:mysafar_sdk/src/core/config/request_config.dart';
import 'package:mysafar_sdk/src/model/centrum/get_centrum_recommendation_model.dart';
import 'package:mysafar_sdk/src/model/local/recom_req_model.dart';
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart';
import 'package:mysafar_sdk/src/model/remote/avia/ticket_date_price_model.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/tools/lang_helper.dart' show dataLang;
import 'package:mysafar_sdk/src/core/config/response_config.dart'
    show
        ErrorType,
        NetworkErrorResponse,
        NetworkResponse,
        NetworkSuccessResponse;
import 'package:mysafar_sdk/src/model/remote/avia/airports_model.dart'
    show AirPortsModel;
import 'package:mysafar_sdk/src/core/constants/end_points.dart' show EndPoints;
import 'package:mysafar_sdk/src/model/remote/avia/ticket_tariff_model.dart';
import 'package:mysafar_sdk/src/model/remote/avia/top_city_model.dart'
    show TopCityModel;

class AviaService with RequestConfig {
  // Oylik narxlar keshi: muddati (TTL) va chegarasi bor — ilgari cheksiz
  // o'sardi va eskirgan narxlar sessiya oxirigacha qolardi. Bir vaqtda
  // ketayotgan bir xil so'rovlar bitta so'rovga birlashtiriladi.
  static const Duration _monthPriceTtl = Duration(minutes: 15);
  static const int _monthPriceMaxEntries = 40;
  static final Map<String, (DateTime, TicketDatePriceModel)> _monthPriceCache =
      {};
  static final Map<String, Future<NetworkResponse>> _monthPriceInFlight = {};

  Future<NetworkResponse> getAirports(
      {required String part, String? lang}) async {
    // sorov yuboriladi success bolsa AirPortsModelga parse qilinadi
    NetworkResponse response = await postRequest(
      retryable: true,
      partnerToken: true,
      endPoint: EndPoints.avia_airports,
      params: {"lang": lang ?? "ru", "part": part},
    );

    if (response is NetworkSuccessResponse) {
      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (data is List && data.isEmpty) {
          return NetworkErrorResponse(error: "nothingFound".tr());
        } else if (data is Map && data['cities'] is Map) {
          return NetworkSuccessResponse(
              data: (data['cities'] as Map)
                  .values
                  .map((e) => AirPortsModel.fromJson(e))
                  .toList());
        }
      }

      return NetworkErrorResponse(
        error: "city_search_failed".tr(),
        errorType: ErrorType.other,
      );
    }
    if (response is NetworkErrorResponse) {
      debugPrint(response.error);
    }
    return response;
  }

  /// get tickets
  ///
  /// Javob XOM bayt ko'rinishida olinadi (`ResponseType.bytes`, faqat shu
  /// so'rov uchun) va JSON o'qish + modelga o'girish TO'LIQ fon isolate'da
  /// bajariladi. Ilgari Dio JSON'ni UI oqimida o'qirdi, so'ng katta `Map`
  /// `compute`ga uzatilayotganda yana UI oqimida chuqur nusxalanardi —
  /// past qurilmalarda reyslar chiqayotganda ekran qotardi.
  Future<NetworkResponse> getRecommendations(
      {required Map<String, dynamic> params, String? endPoint}) async {
    NetworkResponse response = await postRequest(
        retryable: true,
        endPoint: endPoint ?? EndPoints.avia_recommendatins,
        params: params,
        partnerToken: true,
        responseType: ResponseType.bytes);
    if (response is NetworkSuccessResponse) {
      final raw = response.data;
      final Object? parsed;
      try {
        parsed = raw is List<int>
            // Baytlar (tekis bufer) isolate'ga arzon ko'chiriladi; natija
            // (model) esa `Isolate.exit` orqali nusxasiz qaytadi.
            ? await compute(_decodeAndParseRecommendations, raw)
            // Zaxira: javob allaqachon o'qilgan (Map) bo'lsa — avvalgi yo'l.
            : raw is Map<String, dynamic>
                ? (raw['success'] == true
                    ? await compute(_parseRecommendations, raw)
                    : raw)
                : raw;
      } catch (e) {
        debugPrint('getRecommendations parse error: $e');
        return NetworkErrorResponse(
            error: "error_other".tr(), errorType: ErrorType.other);
      }

      if (parsed is GetRecommendationResModel) {
        if (parsed.recommedations?.flights.isEmpty ?? true) {
          return NetworkErrorResponse(
              error: "tickets_not_found".tr(),
              errorType: ErrorType.emptyResponse);
        }
        return NetworkSuccessResponse(data: parsed);
      } else {
        return NetworkErrorResponse(error: parsed);
      }
    } else if (response is NetworkErrorResponse) {
      return NetworkErrorResponse(
          error: response.getError(), errorType: response.errorType);
    }

    return response;
  }

  /// Top (mashhur) shaharlar kam o'zgaradi — cubit qayta yaratilganda takror
  /// so'rovni oldini olish uchun 30 daqiqalik TTL cache. `forceRefresh: true`
  /// cache'ni chetlab o'tadi.
  static List<TopCityModel>? _topCitiesCache;
  static DateTime? _topCitiesCachedAt;
  static const Duration _topCitiesTtl = Duration(minutes: 30);

  Future<NetworkResponse> getTopCities({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _topCitiesCache != null &&
        _topCitiesCachedAt != null &&
        DateTime.now().difference(_topCitiesCachedAt!) < _topCitiesTtl) {
      return NetworkSuccessResponse(data: _topCitiesCache);
    }

    NetworkResponse response =
        await postRequest(retryable: true, endPoint: EndPoints.main_pop_cities);

    if (response is NetworkSuccessResponse) {
      final result =
          (response.data as List).map((e) => TopCityModel.fromJson(e)).toList();
      _topCitiesCache = result;
      _topCitiesCachedAt = DateTime.now();
      return NetworkSuccessResponse(data: result);
    } else if (response is NetworkErrorResponse) {
      return NetworkErrorResponse(
          error: response.getError(), errorType: response.errorType);
    }
    return response;
  }

  Future<NetworkResponse> getSearchHistory() async {
    final response = await getRequest(
        endPoint: EndPoints.main_search_history, headers: true);

    if (response is NetworkSuccessResponse) {
      return (response.data as List).isNotEmpty
          ? NetworkSuccessResponse(
              data: (response.data as List)
                  .map((e) => RecommendationRequestBody.fromJson(e['request']))
                  .toList())
          : const NetworkErrorResponse(
              error: '', errorType: ErrorType.emptyResponse);
    } else if (response is NetworkErrorResponse) {
      return NetworkErrorResponse(
          error: response.getError(), errorType: response.errorType);
    }
    return response;
  }

  /// Oylik narxlar kalendari (`/avia/monthly-price-calendar`).
  ///
  /// [direct] va [baggage] — filtr kalitlari: **o'chiq bo'lsa mos maydon
  /// so'rovga umuman qo'shilmaydi**, yoqilganda `is_direct_only: 1` /
  /// `baggage: "1"` yuboriladi (web / MySafar bilan bir xil).
  Future<NetworkResponse> getPriceByMonth(
    String from,
    String to, {
    DateTime? date,
    int adt = 1,
    int chd = 0,
    int inf = 0,
    String klass = 'a',
    String? lang,
    int count = 30,
    bool direct = false,
    bool baggage = false,
  }) async {
    final DateTime start = date ?? DateTime.now();
    final String startText = '${start.day.toString().padLeft(2, '0')}.'
        '${start.month.toString().padLeft(2, '0')}.${start.year}';

    // Klass turli joylardan 'E' / 'e' / '' ko'rinishida kelardi — bir xil
    // so'rov har xil kesh kaliti bo'lib, 2–3 marta yuborilardi.
    final String normalizedKlass = klass.trim().toLowerCase();
    klass = normalizedKlass.isEmpty ? 'a' : normalizedKlass;

    final String cacheKey =
        '$from-$to-$startText-$adt-$chd-$inf-$klass-$count-$direct-$baggage';
    final cached = _monthPriceCache[cacheKey];
    if (cached != null) {
      if (DateTime.now().difference(cached.$1) < _monthPriceTtl) {
        return NetworkSuccessResponse(data: cached.$2);
      }
      _monthPriceCache.remove(cacheKey);
    }

    // Xuddi shu so'rov allaqachon ketayotgan bo'lsa — o'shani kutamiz.
    // Birinchi chaqiruvchi bekor qilgan (yoki xato bo'lgan) bo'lsa, o'z
    // so'rovimiz bilan qayta urinamiz.
    final inFlight = _monthPriceInFlight[cacheKey];
    if (inFlight != null) {
      final shared = await inFlight;
      if (shared is NetworkSuccessResponse) return shared;
    }

    final future = _fetchPriceByMonth(
      cacheKey: cacheKey,
      from: from,
      to: to,
      startText: startText,
      adt: adt,
      chd: chd,
      inf: inf,
      klass: klass,
      lang: lang ?? dataLang(),
      count: count,
      direct: direct,
      baggage: baggage,
    );
    _monthPriceInFlight[cacheKey] = future;
    try {
      return await future;
    } finally {
      if (identical(_monthPriceInFlight[cacheKey], future)) {
        _monthPriceInFlight.remove(cacheKey);
      }
    }
  }

  Future<NetworkResponse> _fetchPriceByMonth({
    required String cacheKey,
    required String from,
    required String to,
    required String startText,
    required int adt,
    required int chd,
    required int inf,
    required String klass,
    required String lang,
    required int count,
    required bool direct,
    required bool baggage,
  }) async {
    final params = <String, dynamic>{
      "adt": "$adt",
      "chd": "$chd",
      "inf": "$inf",
      "ins": 0,
      "src": 0,
      "yth": 0,
      "lang": lang,
      "class_": klass,
      "count": count,
      "filter_airlines": <String>[],
      "gds_black_list": <String>[],
      "gds_white_list": <String>[],
      "is_charter": false,
      if (direct) "is_direct_only": 1,
      if (baggage) "baggage": "1",
      "segments": [
        {"from": from, "to": to, "date": startText}
      ],
      "token": "",
    };

    final response = await postRequest(
      retryable: true,
      partnerToken: true,
      endPoint: EndPoints.ticket_price_by_month,
      params: params,
    );

    if (response is NetworkSuccessResponse) {
      final raw = response.data;
      final Map<String, dynamic> json;
      if (raw is Map<String, dynamic>) {
        // Ba'zi javoblar `{success, data: {prices…}}` bo'lishi mumkin.
        final nested = raw['data'];
        if (raw.containsKey('prices') || raw.containsKey('uzs')) {
          json = raw;
        } else if (nested is Map) {
          json = Map<String, dynamic>.from(nested);
        } else {
          json = raw;
        }
      } else if (raw is Map) {
        json = Map<String, dynamic>.from(raw);
      } else {
        return const NetworkErrorResponse(
          error: 'Unexpected monthly price response',
          errorType: ErrorType.other,
        );
      }
      final model = TicketDatePriceModel.fromJson(json);
      _monthPriceCache.remove(cacheKey);
      _monthPriceCache[cacheKey] = (DateTime.now(), model);
      while (_monthPriceCache.length > _monthPriceMaxEntries) {
        // Map kiritilish tartibini saqlaydi — birinchisi eng eskisi.
        _monthPriceCache.remove(_monthPriceCache.keys.first);
      }
      return NetworkSuccessResponse(data: model);
    }

    return response;
  }

  /// Bron qilishdan oldin reysni qayta tekshiradi (`/avia/get-flight-info`).
  ///
  /// Backend `{success, data: {flight: {...}}}` qaytaradi. `data.flight` —
  /// qidiruv natijasidagi bilan bir xil tuzilma, ya'ni [FlightElement] ga
  /// o'giriladi (yangilangan narx, qolgan joy, bagaj, shartlar).
  ///
  /// MUHIM: javobdagi `flight.id` qidiruvdagidan farq qiladi — u bron uchun
  /// amaldagi token. Bron sahifasiga aynan shu yangi element uzatilishi kerak.
  Future<NetworkResponse> getFlightInfo(String tid, {String? lang}) async {
    final response = await postRequest(
      retryable: true,
      partnerToken: true,
      endPoint: EndPoints.avia_get_flight_info,
      params: {"lang": lang ?? dataLang(), "tid": tid},
    );

    if (response is! NetworkSuccessResponse) return response;

    try {
      final body = response.data;
      if (body is! Map || body['success'] != true) {
        final message =
            body is Map ? (body['data']?['message'] ?? body['message']) : null;
        return NetworkErrorResponse(
          error: message ?? body,
          errorType: ErrorType.other,
        );
      }

      final flight = body['data']?['flight'];
      if (flight is! Map<String, dynamic>) {
        return NetworkErrorResponse(
          error: "flight_info_unavailable".tr(),
          errorType: ErrorType.other,
        );
      }
      return NetworkSuccessResponse(data: FlightElement.fromJson(flight));
    } catch (e) {
      debugPrint('getFlightInfo parse error: $e');
      // Foydalanuvchiga inglizcha texnik matn emas, tarjima qilingan xabar.
      return NetworkErrorResponse(
        error: "flight_info_unavailable".tr(),
        errorType: ErrorType.other,
      );
    }
  }

  Future<NetworkResponse> getTariff(String tid, {String? lang}) async {
    // Tarif shartlari foydalanuvchi tilida (ilgari doim "ru" edi, №81).
    final response = await postRequest(
        retryable: true,
        partnerToken: true,
        endPoint: EndPoints.avia_get_tariff,
        params: {"lang": lang ?? dataLang(), "tid": tid});

    try {
      if (response is NetworkSuccessResponse) {
        if (response.data['success'] != true) {
          return NetworkErrorResponse(
              error: response.data['data']?['message'] ?? 'Unknown error',
              errorType: ErrorType.other);
        }

        final flights = response.data['data']['flights'] as List;

        List<FlightTariffModel> result = [];
        for (final element in flights) {
          result.add(FlightTariffModel.fromJson(element));
        }

        return NetworkSuccessResponse(data: result);
      }
      return response;
    } catch (e) {
      debugPrint(e.toString());
      return const NetworkErrorResponse(
          error: 'Failed to parse tariffs', errorType: ErrorType.other);
    }
  }

  Future<NetworkResponse> getCentrumRecommedations(
      {required Map<String, dynamic> params}) async {
    NetworkResponse response = await postRequest(
        retryable: true,
        endPoint: EndPoints.centrum_recommendatins,
        params: params,
        partnerToken: true);
    if (response is NetworkSuccessResponse) {
      final dataMap = response.data;
      if (dataMap is! Map<String, dynamic>) {
        return const NetworkErrorResponse(
            error: "Unexpected centrum response", errorType: ErrorType.other);
      }

      final errorsSection = dataMap["OTAPSS_AirFareFamilySearchRS"]?['Errors'];

      if (errorsSection != null) {
        return NetworkErrorResponse(
            error: dataMap, errorType: ErrorType.emptyResponse);
      }

      // Large centrum result sets are parsed off the UI thread to avoid jank.
      final data = await compute(_parseCentrumRecommendations, dataMap);
      return NetworkSuccessResponse(data: data);
    } else if (response is NetworkErrorResponse) {
      return NetworkErrorResponse(
          error: response.getError(), errorType: response.errorType);
    }

    return response;
  }

  Future<NetworkResponse> createCentrum(
      {required Map<String, dynamic> params}) async {
    NetworkResponse response = await postRequest(
        endPoint: "/centrum/create-ticket", params: params, partnerToken: true);
    if (response is NetworkSuccessResponse) {
      if (response.data["tr_id"] != null) {
        return NetworkSuccessResponse(data: response.data);
      }
      if (response.data["OTA_AirBookRS"] != null) {
        if (response.data["OTA_AirBookRS"]['Errors']["Error"]["@ShortText"] !=
            null) {
          return NetworkErrorResponse(
              error: response.data["OTA_AirBookRS"]['Errors']["Error"]
                  ["@ShortText"],
              errorType: ErrorType.emptyResponse);
        }
      } else {
        return NetworkErrorResponse(
            error: response.data.toString(), errorType: ErrorType.other);
      }
    } else if (response is NetworkErrorResponse) {
      return NetworkErrorResponse(
          error: response.getError(), errorType: response.errorType);
    }

    return response;
  }
}

// Top-level entrypoints for compute(): heavy recommendation JSON is parsed on a
// background isolate so the UI thread stays responsive during flight search.
// Both fromJson chains are pure data mapping (no .tr()/GetStorage/BuildContext),
// hence isolate-safe.
GetRecommendationResModel _parseRecommendations(Map<String, dynamic> raw) =>
    _warmSortPrices(GetRecommendationResModel.fromJson(raw));

final _utf8JsonDecoder = const Utf8Decoder().fuse(const JsonDecoder());

/// Fon isolate: bayt → JSON → model. `success != true` bo'lsa — o'qilgan
/// (kichik) javob tanasi o'zi qaytadi (xato xabari uchun).
Object? _decodeAndParseRecommendations(List<int> bytes) {
  final body = _utf8JsonDecoder.convert(bytes);
  if (body is Map<String, dynamic> && body['success'] == true) {
    return _warmSortPrices(GetRecommendationResModel.fromJson(body));
  }
  return body;
}

/// Saralash narxini ([FlightElement.sortPrice]) shu yerda — fon isolate'da —
/// oldindan hisoblab qo'yamiz; UI oqimida narx matni qayta o'qilmaydi.
GetRecommendationResModel _warmSortPrices(GetRecommendationResModel model) {
  for (final f in model.recommedations?.flights ?? const <FlightElement>[]) {
    f.sortPrice;
  }
  return model;
}

GetCentrumRecommendation _parseCentrumRecommendations(
        Map<String, dynamic> raw) =>
    GetCentrumRecommendation.fromJson(raw);
