import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart'
    show NetworkResponse, NetworkSuccessResponse, NetworkErrorResponse;
import 'package:mysafar_sdk/src/service/ban_chek_and_visa_service.dart';
import 'package:mysafar_sdk/src/core/config/network_request_scope.dart'
    show NetworkCancel;

part 'myid_session_state.dart';

class MyIdSessionCubit extends Cubit<MyIdSessionState> with NetworkCancel {
  MyIdSessionCubit() : super(MyIdSessionInitState()) ;

  final BanCheckAndVisaService _aviaService = BanCheckAndVisaService();


  Future<void> myidSession(Map<String,dynamic> params) async {
    emit(MyIdSessionLoadingState());
    NetworkResponse? response = await withNetworkCancel(() => _aviaService.myIdSessionId(params));
    if (isClosed) return;
    if (response is NetworkSuccessResponse) {

      emit(MyIdSessionSuccessState(response.data));
    }else if(response is NetworkErrorResponse){
      emit(MyIdSessionErrorState(response.getError()));
    } else {
      emit(MyIdSessionInitState());
    }
  }
}


