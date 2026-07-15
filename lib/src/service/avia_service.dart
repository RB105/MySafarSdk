import 'package:flutter/foundation.dart' show compute, debugPrint;
import 'package:mysafar_sdk/src/core/config/request_config.dart';
import 'package:mysafar_sdk/src/model/centrum/get_centrum_recommendation_model.dart';
import 'package:mysafar_sdk/src/model/local/recom_req_model.dart';
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart';
import 'package:mysafar_sdk/src/model/remote/avia/ticket_date_price_model.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
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
  Future<NetworkResponse> getAirports(
      {required String part, String? lang}) async {
    // sorov yuboriladi success bolsa AirPortsModelga parse qilinadi
    NetworkResponse response = await postRequest(
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

      
      return const NetworkErrorResponse(
        error: "Unexpected airports response",
        errorType: ErrorType.other,
      );
    }
    if(response is NetworkErrorResponse) {
      debugPrint(response.error);
    }
    return response;
  }

  /// get tickets
  Future<NetworkResponse> getRecommendations(
      {required Map<String, dynamic> params, String? endPoint}) async {
    NetworkResponse response = await postRequest(
        endPoint: endPoint ?? EndPoints.avia_recommendatins,
        params: params,
        partnerToken: true);
    if (response is NetworkSuccessResponse) {
      if (response.data['success'] == true) {
        // Large flight result sets are parsed off the UI thread to avoid jank.
        final data = await compute(
            _parseRecommendations, response.data as Map<String, dynamic>);

        if (data.recommedations?.flights.isEmpty ?? true) {
          return NetworkErrorResponse(
              error: "tickets_not_found".tr(),
              errorType: ErrorType.emptyResponse);
        }
        return NetworkSuccessResponse(data: data);
      } else {
        return NetworkErrorResponse(error: response.data);
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
        await postRequest(endPoint: EndPoints.main_pop_cities);

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

  Future<NetworkResponse> getPriceByMonth(String from, String to) async {
    final response = await postRequest(
        partnerToken: true,
        endPoint: EndPoints.ticket_price_by_month,
        params: {
          "segments": {"from": from, "to": to}
        });

    if (response is NetworkSuccessResponse) {
      return NetworkSuccessResponse(
          data: TicketDatePriceModel.fromJson(response.data));
    }

    return response;
  }

  Future<NetworkResponse> getTariff(String tid) async {
    final response = await postRequest(
        partnerToken: true,
        endPoint: EndPoints.avia_get_tariff,
        params: {"lang": "ru", "tid": tid});

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
    GetRecommendationResModel.fromJson(raw);

GetCentrumRecommendation _parseCentrumRecommendations(
        Map<String, dynamic> raw) =>
    GetCentrumRecommendation.fromJson(raw);
