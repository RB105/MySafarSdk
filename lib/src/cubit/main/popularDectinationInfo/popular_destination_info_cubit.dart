
import 'package:mysafar_sdk/src/model/remote/fornex/destinations_info_model.dart';
import 'package:mysafar_sdk/src/service/fornex/fornex_repository.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/core/config/network_request_scope.dart'
    show NetworkCancel;
part 'popular_destination_info_state.dart';

class PopularDestinationInfoCubit extends Cubit<PopularDestinationInfoState> with NetworkCancel {
  PopularDestinationInfoCubit({required String info}) : super(PopularDestinationInfoInitState()) {
    getPopDestination(info);
  }

  final _repo = FornexRepository();

  Future<void> getPopDestination(String info) async {
    emit(PopularDestinationInfoLoadingState());
    try {
      NetworkResponse response = await withNetworkCancel(() => _repo.getPopDestinationsInfo(info: info));
      if (isClosed) return;
      if (response is NetworkSuccessResponse) {
        emit(PopularDestinationInfoSuccessState(response.data));
      } else {
        emit(PopularDestinationInfoInitState());
      }
    } on Exception catch (e) {
      debugPrint("PopularDestinationInfoCubit : ${e.toString()}");
      emit(PopularDestinationInfoInitState());
    }
  }
}
