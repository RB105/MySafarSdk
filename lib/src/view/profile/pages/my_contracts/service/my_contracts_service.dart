import 'package:flutter/foundation.dart';
import 'package:mysafar_sdk/src/core/config/request_config.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/core/constants/end_points.dart';
import 'my_contract_model.dart';

class MyContractsService with RequestConfig {
  Future<NetworkResponse> getMyContracts({
    required String pinfl,
  }) async {
    debugPrint("Contracts pinfl: $pinfl");

    final response = await postRequest(
      partnerToken: true,
      endPoint: EndPoints.autopayContract,
      params: {"pinfl": pinfl},
    );

    try {
      if (response is NetworkSuccessResponse) {
        final data = response.data;
        final List<dynamic> rawList = _extractList(data);
        final contracts = rawList
            .whereType<Map>()
            .map((e) =>
                MyContractModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        return NetworkSuccessResponse<List<MyContractModel>>(
            data: contracts);
      }
      return response;
    } on Exception catch (e) {
      debugPrint(e.toString());
      return response;
    }
  }

  /// Bitta shartnomani products/graphics bilan to'liq olib keladi.
  Future<NetworkResponse> getContractDetail({
    required String loanId,
  }) async {
    debugPrint("Contract find loan_id: $loanId");

    final response = await postRequest(
      partnerToken: true,
      endPoint: EndPoints.autopayContractFind,
      params: {"loan_id": loanId},
    );

    try {
      if (response is NetworkSuccessResponse) {
        final raw = _extractSingle(response.data);
        if (raw == null) return response;
        final contract = MyContractModel.fromJson(raw);
        return NetworkSuccessResponse<MyContractModel>(data: contract);
      }
      return response;
    } on Exception catch (e) {
      debugPrint(e.toString());
      return response;
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
