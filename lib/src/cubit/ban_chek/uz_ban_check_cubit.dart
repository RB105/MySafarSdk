import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart'
    show NetworkResponse, NetworkSuccessResponse;
import 'package:mysafar_sdk/src/service/ban_chek_and_visa_service.dart';

part 'uz_ban_check_state.dart';

class UzBanCheckCubit extends Cubit<UzBanCheckState> {
  UzBanCheckCubit() : super(UzBanCheckInitState()) ;

  final BanCheckAndVisaService _aviaService = BanCheckAndVisaService();


  Future<void> getUzBanChek(Map<String,dynamic> params) async {
    emit(UzBanCheckLoadingState());
    NetworkResponse? response = await _aviaService.getUzBanChek(params);
    if (isClosed) return;
    if (response is NetworkSuccessResponse) {

      emit(UzBanCheckSuccessState(response.data));
    } else {
      emit(UzBanCheckInitState());
    }
  }
}
