import 'package:flutter/foundation.dart';
import 'package:mysafar_sdk/src/core/config/request_config.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/core/constants/end_points.dart';
import 'my_application_model.dart';

/// TEST: UI ni mock data bilan sinash uchun `true`. Real API uchun `false`.
const bool kUseApplicationsMock = false;

/// Foydalanuvchi bergan mock javob.
/// Eslatma: shartnoma tugmasi faqat ariza "approved" bo'lganda chiqadi,
/// shu sabab `is_eligible` "eligible" qilingan. "review" badge'ni sinash
/// uchun quyidagi qiymatni "review" ga o'zgartiring.
final Map<String, dynamic> _applicationsMock = {
  "status": true,
  "result": {
    "page_size": 200,
    "page_number": 1,
    "total": 1,
    "last_page": 1,
    "current_page": 1,
    "data": [
      {
        "id": 473,
        "partner_id": 36,
        "created_by": 121,
        "uuid": "36-52602026750016",
        "pinfl": "52802026750016",
        "passport": "AD3534737",
        "passport_given_date": "2002-02-28",
        "first_name": "RASULJON",
        "last_name": "ABDUMALIKOV",
        "middle_name": "BAHODIR OGLI",
        "phone": "901183975",
        "region": "toshkent",
        "district": "toshkent",
        "status": "new",
        "created_at": "2026-01-20T11:18:17.000000Z",
        "updated_at": "2026-01-21T06:40:16.000000Z",
        "price": null,
        "percent": null,
        "period": null,
        "is_eligible": "eligible",
        "eligible_reason": "INCOME_TOO_RECENT_OR_TOO_OLD_2025-10-01 00:00:00_-3"
      }
    ]
  },
  "error": null
};

class MyApplicationsService with RequestConfig {
  Future<NetworkResponse> getMyApplications({
    required String pinfl,
  }) async {
    debugPrint("Applications pinfl: $pinfl");

    if (kUseApplicationsMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      final applications = _extractList(_applicationsMock)
          .whereType<Map>()
          .map((e) =>
              MyApplicationModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return NetworkSuccessResponse<List<MyApplicationModel>>(
          data: applications);
    }

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