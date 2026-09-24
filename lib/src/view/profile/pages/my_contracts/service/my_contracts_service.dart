import 'package:flutter/foundation.dart';
import 'package:mysafar_sdk/src/core/config/request_config.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/core/constants/end_points.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/service/payment/sensitive_log.dart';
import 'my_contract_model.dart';

class MyContractsService with RequestConfig {
  Future<NetworkResponse> getMyContracts({
    required String pinfl,
  }) async {
    // JShShIR log'ga yozilmaydi (№63) — faqat debug'da, niqoblangan.
    SensitiveLog.debug('Contracts pinfl: ${SensitiveLog.maskTail(pinfl)}');

    final response = await postRequest(
      partnerToken: true,
      endPoint: EndPoints.autopayContract,
      params: {"pinfl": pinfl},
    );

    try {
      if (response is NetworkSuccessResponse) {
        final data = response.data;
        final List<dynamic> rawList = _extractList(data);
        // Bitta buzuq shartnoma butun ro'yxatni yiqitmasin (№89) — o'tkazib
        // yuboriladi.
        final contracts = <MyContractModel>[];
        for (final e in rawList.whereType<Map>()) {
          try {
            contracts
                .add(MyContractModel.fromJson(Map<String, dynamic>.from(e)));
          } catch (e) {
            debugPrint('MySafarSdk: shartnoma o\'tkazib yuborildi '
                '(${e.runtimeType})');
          }
        }
        return NetworkSuccessResponse<List<MyContractModel>>(
            data: contracts);
      }
      return response;
    } catch (e) {
      // Faqat Exception emas, TypeError ham — sahifa yuklanishda qotmasin.
      debugPrint('MySafarSdk: contracts parse xatosi (${e.runtimeType})');
      return NetworkErrorResponse(error: 'error_other'.tr());
    }
  }

  /// Bitta shartnomani products/graphics bilan to'liq olib keladi.
  Future<NetworkResponse> getContractDetail({
    required String loanId,
  }) async {
    SensitiveLog.debug('Contract find loan_id: $loanId');

    final response = await postRequest(
      partnerToken: true,
      endPoint: EndPoints.autopayContractFind,
      params: {"loan_id": loanId},
    );

    try {
      if (response is NetworkSuccessResponse) {
        final raw = _extractSingle(response.data);
        if (raw == null) {
          return NetworkErrorResponse(error: 'error_other'.tr());
        }
        final contract = MyContractModel.fromJson(raw);
        return NetworkSuccessResponse<MyContractModel>(data: contract);
      }
      return response;
    } catch (e) {
      // TypeError ham ushlanadi (№89) — sahifa xato holatini ko'rsatadi.
      debugPrint('MySafarSdk: contract parse xatosi (${e.runtimeType})');
      return NetworkErrorResponse(error: 'error_other'.tr());
    }
  }

  /// `contract-find` javob tuzilmasi: `{ status, result: {...}, error }`.
  /// `result` to'g'ridan-to'g'ri bitta obyekt.
  Map<String, dynamic>? _extractSingle(dynamic data) {
    if (data is Map) {
      final result = data['result'];
      if (result is Map) return Map<String, dynamic>.from(result);
      return Map<String, dynamic>.from(data);
    }
    return null;
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
