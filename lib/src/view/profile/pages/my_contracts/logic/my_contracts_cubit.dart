import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart';

import '../service/my_contract_model.dart';
import '../service/my_contracts_service.dart';

part 'my_contracts_state.dart';

class MyContractsCubit extends Cubit<MyContractsState> {
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
    final response = await _service.getMyContracts(pinfl: pinfl);
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
