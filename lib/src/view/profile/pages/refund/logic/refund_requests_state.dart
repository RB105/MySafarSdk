part of 'refund_requests_cubit.dart';

enum RefundRequestsStatus { initial, loading, success, failure }

class RefundRequestsState {
  final RefundRequestsStatus status;
  final List<RefundRequestModel> requests;
  final String error;

  const RefundRequestsState({
    required this.status,
    required this.requests,
    required this.error,
  });

  const RefundRequestsState.initial()
      : status = RefundRequestsStatus.initial,
        requests = const [],
        error = '';

  /// Ochiq (`pending`) ariza bormi — bo'lsa yangi ariza yuborib bo'lmaydi,
  /// server `409 ALREADY_REQUESTED` qaytaradi.
  bool get hasOpenRequest => requests.any((e) => e.status.isOpen);

  bool get isLoading => status == RefundRequestsStatus.loading;
  bool get isEmpty =>
      status == RefundRequestsStatus.success && requests.isEmpty;

  RefundRequestsState copyWith({
    RefundRequestsStatus? status,
    List<RefundRequestModel>? requests,
    String? error,
  }) =>
      RefundRequestsState(
        status: status ?? this.status,
        requests: requests ?? this.requests,
        error: error ?? this.error,
      );
}
