import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart';

import '../service/refund_models.dart';
import '../service/refund_service.dart';

part 'refund_create_state.dart';

/// Yangi vozvrat arizasini yuborish (`POST /tickets/refund/request`).
class RefundCreateCubit extends Cubit<RefundCreateState> {
  RefundCreateCubit() : super(const RefundCreateState.initial());

  final RefundService _service = RefundService();

  Future<void> submit({
    required String billingId,
    required String cardNumber,
    String? cardHolder,
    String? phoneNumber,
    String? reason,
    RefundType refundType = RefundType.voluntary,
  }) async {
    if (state.isSubmitting) return;
    emit(const RefundCreateState(status: RefundCreateStatus.submitting));

    final response = await _service.createRequest(
      billingId: billingId,
      cardNumber: cardNumber,
      cardHolder: cardHolder,
      phoneNumber: phoneNumber,
      reason: reason,
      refundType: refundType,
    );
    if (isClosed) return;

    if (response is NetworkSuccessResponse<RefundRequestModel>) {
      emit(RefundCreateState(
        status: RefundCreateStatus.success,
        created: response.data,
      ));
    } else if (response is NetworkErrorResponse<RefundFailure>) {
      emit(RefundCreateState(
        status: RefundCreateStatus.failure,
        failure: response.error,
      ));
    } else if (response is NetworkErrorResponse) {
      emit(RefundCreateState(
        status: RefundCreateStatus.failure,
        failure: RefundFailure(code: '', message: response.getError()),
      ));
    }
  }
}
