import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart';

import '../service/my_contract_model.dart';
import '../service/my_contracts_service.dart';

part 'my_contract_detail_state.dart';

class MyContractDetailCubit extends Cubit<MyContractDetailState> {
  MyContractDetailCubit() : super(MyContractDetailInitState());

  final MyContractsService _service = MyContractsService();

  /// `loanId` -> contract detail. Ilovadan chiqib kirgunga qadar saqlanadi.
  static final Map<String, MyContractModel> _cache = {};

  /// Keshning maksimal hajmi — cheksiz o'sishni oldini olish uchun.
  static const int _maxCacheSize = 50;

  /// Logout / hisobni almashtirishda chaqirilsin.
  static void clearCache() => _cache.clear();

  Future<void> loadDetail(String loanId, {bool force = false}) async {
    if (!force && _cache.containsKey(loanId)) {
      emit(MyContractDetailSuccessState(_cache[loanId]!));
      return;
    }

    emit(MyContractDetailLoadingState());
    final response = await _service.getContractDetail(loanId: loanId);
    if (isClosed) return;

    if (response is NetworkSuccessResponse<MyContractModel>) {
      if (_cache.length >= _maxCacheSize) {
        _cache.clear();
      }
      _cache[loanId] = response.data;
      emit(MyContractDetailSuccessState(response.data));
    } else if (response is NetworkErrorResponse) {
      emit(MyContractDetailErrorState(response.getError()));
    } else {
      emit(MyContractDetailInitState());
    }
  }
}
