import 'package:mysafar_sdk/src/model/remote/destination/destination_detail_model.dart';
import 'package:mysafar_sdk/src/model/remote/destination/destination_list_model.dart'
    show DestinationListItem;
import 'package:mysafar_sdk/src/model/remote/fornex/pop_destinations.dart'
    show PopDestinationsModel;
import 'package:mysafar_sdk/src/service/fornex/fornex_repository.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

part 'destination_detail_state.dart';

/// Yo'nalish tafsilotini (`POST /v1/destination/detail`) yuklaydi.
class DestinationDetailCubit extends Cubit<DestinationDetailState> {
  DestinationDetailCubit({this.destination, this.listItem})
      : assert(destination != null || listItem != null,
            'destination yoki listItem berilishi shart'),
        super(DestinationDetailLoadingState()) {
    load();
  }

  final PopDestinationsModel? destination;
  final DestinationListItem? listItem;
  final FornexRepository _repo = FornexRepository();

  Future<void> load({bool refresh = false}) async {
    final DestinationDetailState previous = state;
    if (!refresh) emit(DestinationDetailLoadingState());

    final NetworkResponse response;
    if (listItem != null) {
      response = await _repo.getDestinationDetail(
        listItem!.slug,
        forceRefresh: refresh,
      );
    } else {
      final city = destination!.destination;
      response = await _repo.getDestinationDetail(
        city.slug,
        aviationCode: city.aviationCode,
        forceRefresh: refresh,
      );
    }
    if (isClosed) return;

    if (response is NetworkSuccessResponse) {
      emit(DestinationDetailSuccessState(
          response.data as DestinationDetailModel));
      return;
    }

    if (refresh && previous is DestinationDetailSuccessState) return;

    if (destination != null) {
      emit(DestinationDetailRedirectMapState());
    } else {
      emit(DestinationDetailErrorState());
    }
  }
}
