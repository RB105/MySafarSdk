import 'package:dio/dio.dart';
import 'package:mysafar_sdk/src/model/local/recom_req_model.dart';
import 'package:mysafar_sdk/src/service/fornex/fornex_repository.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

part 'ai_search_state.dart';

class AiSearchCubit extends Cubit<AiSearchState> {
  AiSearchCubit() : super(AiSearchInitState());

  final _fornexRepository = FornexRepository();

  Future<void> searchAiChat(String prompt) async {
    emit(AiSearchLoadingState());
    final response = await _fornexRepository.searchAiChat(prompt: prompt);
    if (isClosed) return;
    if (response is NetworkSuccessResponse) {
      emit(AiSearchSuccessState(response.data));
    } else if (response is NetworkErrorResponse) {
      if (response.error is Map && response.error['error'] is Map) {
        final msg = response.error['error']['message'];
        if (msg is String && msg.isNotEmpty) {
          emit(AiSearchErrorState(msg));
          return;
        }
      }
      emit(AiSearchErrorState(response.getError()));
    }
  }

  Future<void> searchAiVoice(FormData prompt) async {
    emit(AiSearchLoadingState());
    final response = await _fornexRepository.searchAiChatVoice(prompt: prompt);
    if (isClosed) return;
    if (response is NetworkSuccessResponse) {
      emit(AiSearchSuccessState(response.data));
    } else if (response is NetworkErrorResponse) {
      emit(AiSearchErrorState(response.getError()));
    }
  }
}
