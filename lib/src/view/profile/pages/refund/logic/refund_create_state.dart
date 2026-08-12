part of 'refund_create_cubit.dart';

enum RefundCreateStatus { initial, submitting, success, failure }

class RefundCreateState {
  final RefundCreateStatus status;

  /// `201` da serverdan qaytgan ariza.
  final RefundRequestModel? created;

  /// Xato — `code` (masalan `CARD_INVALID`) maydonni qizartirish uchun,
  /// `message` esa foydalanuvchi tilidagi tayyor matn.
  final RefundFailure? failure;

  const RefundCreateState({
    required this.status,
    this.created,
    this.failure,
  });

  const RefundCreateState.initial()
      : status = RefundCreateStatus.initial,
        created = null,
        failure = null;

  bool get isSubmitting => status == RefundCreateStatus.submitting;
}
