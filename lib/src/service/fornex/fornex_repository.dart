import 'dart:io' show InternetAddressType, NetworkInterface;

import 'package:dio/dio.dart';
import 'package:mysafar_sdk/src/model/remote/destination/destination_detail_model.dart';
import 'package:mysafar_sdk/src/model/remote/destination/destination_list_model.dart';
import 'package:mysafar_sdk/src/model/remote/fornex/destinations_info_model.dart';
import 'package:mysafar_sdk/src/model/local/recom_req_model.dart';
import 'package:mysafar_sdk/src/model/remote/fornex/hot_tickets_model.dart';
import 'package:mysafar_sdk/src/model/remote/fornex/pop_destinations.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

class FornexRepository with RequestConfig {
  /// Session davomida o'zgarmaydigan lokal IP cache'i — har chaqiruvda
  /// barcha tarmoq interfeyslarini qayta sanab chiqishning oldini oladi.
  static String? _cachedLocalIp;

  /// TTL cache'lar — cubitlar har qayta yaratilganda (navigatsiya, provider
  /// rebuild) bir xil so'rovni qayta yubormasligi uchun. `forceRefresh: true`
  /// bilan (masalan pull-to-refresh) cache chetlab o'tiladi.
  static _TtlEntry? _hotTicketsCache;
  static _TtlEntry? _popDestCache;
  static final Map<String, _TtlEntry> _popDestInfoCache = {};
  static final Map<String, _TtlEntry> _destDetailCache = {};
  static _TtlEntry? _allDestCache;
  static const Duration _hotTicketsTtl = Duration(minutes: 5);
  static const Duration _popDestTtl = Duration(minutes: 30);

  /// Logout / hisob almashtirishda chaqiriladi.
  static void clearCache() {
    _hotTicketsCache = null;
    _popDestCache = null;
    _popDestInfoCache.clear();
    _destDetailCache.clear();
    _allDestCache = null;
  }

  Future<List<DestinationListItem>> _fetchAllDestinations() async {
    final cached = _allDestCache;
    if (cached != null && cached.isFresh(_popDestTtl)) {
      return cached.data as List<DestinationListItem>;
    }

    final response = await postRequest(
      endPoint: EndPoints.destination_list,
      params: const <String, dynamic>{"page": 1, "page_size": 20},
    );
    if (response is NetworkSuccessResponse &&
        response.data is Map<String, dynamic>) {
      final page =
          DestinationListPageResult.fromJson(response.data as Map<String, dynamic>);
      if (page.items.isNotEmpty) {
        _allDestCache = _TtlEntry(page.items);
        return page.items;
      }
    }
    return const [];
  }

  Future<NetworkResponse> getDestinationDetail(String slug,
      {bool forceRefresh = false}) async {
    final resolved = slug.trim();
    if (resolved.isEmpty) {
      return const NetworkErrorResponse(error: 'empty destination');
    }

    if (!forceRefresh) {
      final cached = _destDetailCache[resolved];
      if (cached != null && cached.isFresh(_popDestTtl)) {
        return NetworkSuccessResponse(data: cached.data);
      }
    }

    final response = await postRequest(
      endPoint: EndPoints.destination_detail,
      params: {"id": resolved},
    );
    if (response is NetworkSuccessResponse &&
        response.data is Map<String, dynamic>) {
      final model =
          DestinationDetailModel.fromJson(response.data as Map<String, dynamic>);
      _destDetailCache[resolved] = _TtlEntry(model);
      return NetworkSuccessResponse(data: model);
    }

    return response is NetworkSuccessResponse
        ? const NetworkErrorResponse(
            error: "Unexpected destination detail response")
        : response;
  }

  Future<NetworkResponse> getDestinationDetailByCity(String cityName) async {
    final name = cityName.trim().toLowerCase();
    if (name.isEmpty) {
      return const NetworkErrorResponse(error: 'empty city');
    }

    final items = await _fetchAllDestinations();
    for (final item in items) {
      final matches = item.cityName.uz.toLowerCase() == name ||
          item.cityName.ru.toLowerCase() == name ||
          item.cityName.en.toLowerCase() == name;
      if (matches && item.slug.isNotEmpty) {
        return getDestinationDetail(item.slug);
      }
    }
    return const NetworkErrorResponse(error: 'destination not found');
  }

  Future<NetworkResponse> getHotTickets({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _hotTicketsCache;
      if (cached != null && cached.isFresh(_hotTicketsTtl)) {
        return NetworkSuccessResponse(data: cached.data);
      }
    }

    final ip = await _getLocalIp();

    final response =
        await get(endPoint: EndPoints.hot_tickets, query: {"user_ip": ip});
    if (response is NetworkSuccessResponse) {
      final result = (response.data['result']['flights'] as List)
          .map(
            (e) => HotTicket.fromJson(e),
          )
          .toList();
      _hotTicketsCache = _TtlEntry(result);
      return NetworkSuccessResponse(data: result);
    }

    return response;
  }

  Future<NetworkResponse> getPopDestinations({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _popDestCache;
      if (cached != null && cached.isFresh(_popDestTtl)) {
        return NetworkSuccessResponse(data: cached.data);
      }
    }

    final response = await get(endPoint: EndPoints.destinations);

    if (response is NetworkSuccessResponse) {
      final result = (response.data['result'] as List)
          .map((e) => PopDestinationsModel.fromJson(e))
          .toList();
      _popDestCache = _TtlEntry(result);
      return NetworkSuccessResponse(data: result);
    }

    return response;
  }

  Future<NetworkResponse> getPopDestinationsInfo(
      {required String info, bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _popDestInfoCache[info];
      if (cached != null && cached.isFresh(_popDestTtl)) {
        return NetworkSuccessResponse(data: cached.data);
      }
    }

    final response = await get(endPoint: "${EndPoints.destinations}/$info");

    if (response is NetworkSuccessResponse) {
      final result = DestinationsInfoModel.fromJson(response.data);
      _popDestInfoCache[info] = _TtlEntry(result);
      return NetworkSuccessResponse(data: result);
    }else if (response is NetworkErrorResponse) {
      return NetworkErrorResponse(
          error: response.getError(), errorType: response.errorType);
    }
    return response;
  }

  Future<NetworkResponse> searchAiChat({required String prompt}) async {
    final response = await post(
        endPoint: EndPoints.ai_search_chat, query: {"message": prompt});
    if (response is NetworkSuccessResponse) {
      return NetworkSuccessResponse(
          data: RecommendationRequestBody.fromJson(
              response.data['query_search']));
    }

    return response;
  }
  Future<NetworkResponse> searchAiChatVoice({required FormData prompt}) async {

    final response = await post(
        contentType: "multipart/form-data",
        endPoint: EndPoints.ai_search_chat,
        params:  prompt,);
    if (response is NetworkSuccessResponse) {
      if(response.data['query_search']!=null){
        return NetworkSuccessResponse(
            data: RecommendationRequestBody.fromJson(
                response.data['query_search']));
      }else{
        return NetworkErrorResponse(error:"speak_clear_address_date".tr());
      }
    }else if (response is NetworkErrorResponse) {
      return NetworkErrorResponse(
          error: response.getError(), errorType: response.errorType);
    }

    return response;
  }

  Future<String?> _getLocalIp() async {
    if (_cachedLocalIp != null) return _cachedLocalIp;
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          return _cachedLocalIp = addr.address;
        }
      }
    }
    return null;
  }

  // Future<NetworkResponse> getQuickRecommendations() async {
  //   final response = await _dio.get(
  //     EndPoints.get_quick_recommendations,
  //   );
  //   if (response.statusCode == 200 && response.data['error'] == null) {
  //     final result = (response.data['data'] as List)
  //         .map(
  //           (e) => GetQuickRecommendationsModel.fromJson(e),
  //         )
  //         .toList();
  //     return NetworkSuccessResponse(data: result);
  //   }

  //   return NetworkErrorResponse(error: response.data['error']);
  // }
}

/// TTL cache yozuvi — yaratilgan vaqtni saqlaydi va eskirganligini tekshiradi.
class _TtlEntry {
  _TtlEntry(this.data) : _at = DateTime.now();

  final Object data;
  final DateTime _at;

  bool isFresh(Duration ttl) => DateTime.now().difference(_at) < ttl;
}
