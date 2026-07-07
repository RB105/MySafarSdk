import 'package:mysafar_sdk/src/model/remote/fornex/hot_tickets_model.dart';
import 'package:mysafar_sdk/src/service/fornex/fornex_repository.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

part 'hot_tickets_state.dart';

class HotTicketsCubit extends Cubit<HotTicketsState> {
  HotTicketsCubit() : super(HotTicketsInitState()) {
    getHotTickets();
  }

  //
  final fornexRepository = FornexRepository();

  Future<void> getHotTickets() async {
    emit(HotTicketsLoadingState());
    try {
      final response = await fornexRepository.getHotTickets();
      if (isClosed) return;
      if (response is NetworkSuccessResponse) {
        emit(HotTicketsSuccessState(response.data));
      } else {
        emit(HotTicketsInitState());
      }
    } catch (e) {
      debugPrint("HotTicketsCubit : ${e.toString()}");
      emit(HotTicketsInitState());
    }
  }
}
