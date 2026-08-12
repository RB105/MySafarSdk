import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart';

import '../service/refund_models.dart';
import '../service/refund_service.dart';

part 'refund_requests_state.dart';

/// Vozvrat arizalari ro'yxati.
///
/// [billingId] berilsa — faqat o'sha biletning arizalari (bilet ichidan
/// kirilganda), berilmasa — foydalanuvchining BARCHA arizalari (profil
/// bo'limidan kirilganda). Server ro'yxatni foydalanuvchi bo'yicha qaytaradi,
/// shuning uchun bilet bo'yicha filtr shu yerda qilinadi.
class RefundRequestsCubit extends Cubit<RefundRequestsState> {
  RefundRequestsCubit({this.billingId})
      : super(const RefundRequestsState.initial());

  final String? billingId;
  final RefundService _service = RefundService();

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(state.copyWith(status: RefundRequestsStatus.loading));

    final response = await _service.getRequests();
    if (isClosed) return;

    if (response is NetworkSuccessResponse<List<RefundRequestModel>>) {
      final id = billingId;
      final mine = (id == null || id.isEmpty)
          ? response.data
          : response.data.where((e) => (e.billingId ?? '') == id).toList();
      emit(state.copyWith(
        status: RefundRequestsStatus.success,
        requests: mine,
        error: '',
      ));
    } else if (response is NetworkErrorResponse<RefundFailure>) {
      emit(state.copyWith(
        status: RefundRequestsStatus.failure,
        error: response.error.message.isNotEmpty
            ? response.error.message
            : response.getError(),
      ));
    } else if (response is NetworkErrorResponse) {
      emit(state.copyWith(
        status: RefundRequestsStatus.failure,
        error: response.getError(),
      ));
    }
  }

  /// Forma yangi ariza yaratgach chaqiriladi — serverga qayta bormasdan
  /// ro'yxat darhol yangilanadi, keyin fon rejimida sinxronlanadi.
  void addLocal(RefundRequestModel request) {
    emit(state.copyWith(
      status: RefundRequestsStatus.success,
      requests: [request, ...state.requests],
      error: '',
    ));
    load(silent: true);
  }
}
