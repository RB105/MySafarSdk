import 'package:flutter/foundation.dart';
import 'package:mysafar_sdk/src/core/config/request_config.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/core/constants/end_points.dart';
import 'my_application_model.dart';

class MyApplicationsService with RequestConfig {
  Future<NetworkResponse> getMyApplications({
    required String pinfl,
  }) async {
    debugPrint("Applications pinfl: $pinfl");

    final response = await postRequest(
      partnerToken: true,
      endPoint: EndPoints.autopayApplication,
      params: {"pinfl": pinfl},
    );

    try {
      if (response is NetworkSuccessResponse) {
        final data = response.data;
        final List<dynamic> rawList = _extractList(data);
        final applications = rawList
            .whereType<Map>()
            .map((e) =>
                MyApplicationModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        return NetworkSuccessResponse<List<MyApplicationModel>>(
            data: applications);
      }
      return response;
    } on Exception catch (e) {
      debugPrint(e.toString());
      return response;
    }
  }

  /// Javob tuzilmasi: `{ status, result: { data: [...] }, error }`.
  /// Eski/boshqa formatlar uchun ham himoyalangan.
  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is! Map) return const [];

    final result = data['result'];
    if (result is Map && result['data'] is List) {
      return result['data'] as List;
    }
    if (result is List) return result;
    if (data['data'] is List) return data['data'] as List;
    if (data['results'] is List) return data['results'] as List;
    return const [];
  }
}