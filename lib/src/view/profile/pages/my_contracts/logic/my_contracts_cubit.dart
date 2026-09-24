import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';

import '../service/my_contract_model.dart';
import '../service/my_contracts_service.dart';
import 'package:mysafar_sdk/src/core/config/network_request_scope.dart'
    show NetworkCancel;

part 'my_contracts_state.dart';

class MyContractsCubit extends Cubit<MyContractsState> with NetworkCancel {
  MyContractsCubit() : super(MyContractsInitState());

  final MyContractsService _service = MyContractsService();

  /// In-memory cache. Ilovadan chiqib kirgunga qadar saqlanadi.
  static List<MyContractModel>? _cache;
  static String? _cacheKey;

  /// Logout / hisobni almashtirishda chaqirilsin.
  static void clearCache() {
    _cache = null;
    _cacheKey = null;
  }

  Future<void> loadContracts(String pinfl, {bool force = false}) async {
    if (!force && _cacheKey == pinfl && _cache != null) {
      emit(MyContractsSuccessState(_cache!));
      return;
    }

    emit(MyContractsLoadingState());
    final NetworkResponse response;
    try {
      response = await withNetworkCancel(() => _service.getMyContracts(pinfl: pinfl));
    } catch (_) {
      // Kutilmagan xato — sahifa yuklanishda qotib qolmasin (№89).
      if (!isClosed) emit(MyContractsErrorState('error_other'.tr()));
      return;
    }
    if (isClosed) return;

    if (response is NetworkSuccessResponse<List<MyContractModel>>) {
      _cache = response.data;
      _cacheKey = pinfl;
      emit(MyContractsSuccessState(response.data));
    } else if (response is NetworkErrorResponse) {
      emit(MyContractsErrorState(response.getError()));
    } else {
      emit(MyContractsInitState());
    }
  }
}
