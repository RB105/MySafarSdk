import 'package:mysafar_sdk/src/core/tools/project_utils.dart';
import 'package:mysafar_sdk/src/model/remote/fornex/pop_destinations.dart';
import 'package:mysafar_sdk/src/service/fornex/fornex_repository.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

part 'pop_destinations_state.dart';

class PopularDestinationCubit extends Cubit<PopularDestinationState> {
  PopularDestinationCubit() : super(PopularDestinationInitState()) {
    getPopDestination();
  }

  final _repo = FornexRepository();

  Future<void> getPopDestination() async {
    emit(PopularDestinationLoadingState());
    try {
      NetworkResponse response = await _repo.getPopDestinations();
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
