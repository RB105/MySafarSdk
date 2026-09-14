import 'package:mysafar_sdk/src/core/tools/project_utils.dart';
import 'package:mysafar_sdk/src/model/remote/fornex/pop_destinations.dart';
import 'package:mysafar_sdk/src/service/fornex/fornex_repository.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/core/config/network_request_scope.dart'
    show NetworkCancel;

part 'pop_destinations_state.dart';

class PopularDestinationCubit extends Cubit<PopularDestinationState> with NetworkCancel {
  PopularDestinationCubit() : super(PopularDestinationInitState()) {
    getPopDestination();
  }

  final _repo = FornexRepository();

  Future<void> getPopDestination() async {
    emit(PopularDestinationLoadingState());
    try {
      NetworkResponse response = await withNetworkCancel(_repo.getPopDestinations);
      if (isClosed) return;
      if (response is NetworkSuccessResponse) {
        ProjectUtils.setPopularDestinations(response.data);
        emit(PopularDestinationSuccessState(response.data));
      } else {
        emit(PopularDestinationInitState());
      }
    } on Exception catch (e) {
      debugPrint("PopularDestinationCubit : ${e.toString()}");
      emit(PopularDestinationInitState());
    }
  }
}
