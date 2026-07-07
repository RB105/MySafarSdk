import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/model/remote/profile/cheque_model.dart'
    show ChequeModel;
import 'package:mysafar_sdk/src/service/account_service.dart';

part 'ofd_cheques_state.dart';

class OfdChequesCubit extends Cubit<OfdChequesState> {
  OfdChequesCubit() : super(OfdChequesInitState()) {
    getCheques();
  }

  // instance
  final _accountService = AccountService();

  Future<void> getCheques() async {
    emit(OfdChequesLoadingState());
    final response = await _accountService.getOfdCheques();
    if (isClosed) return;
    if (response is NetworkSuccessResponse) {
      emit(OfdChequesSuccesState(response.data));
    } else if (response is NetworkErrorResponse) {
      if (response.errorType == ErrorType.emptyResponse) {
        emit(OfdChequesEmptyState());
        return;
      }
      emit(OfdChequesErrorState(response.getError()));
    }
  }
}
