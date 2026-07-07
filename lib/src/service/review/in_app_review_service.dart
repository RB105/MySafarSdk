import 'package:get_storage/get_storage.dart';
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;

/// In-App Review service
///
/// Foydalanuvchidan ilovani baholashni so'raydi. Konkret review dialogi host
/// app'ning `MySafarCallbacks.onRequestReview` hook'i orqali ko'rsatiladi
/// (SDK'da to'g'ridan-to'g'ri in_app_review bog'liqligi yo'q) — hook
/// berilmagan bo'lsa hech narsa so'ralmaydi.
class InAppReviewService {
  static const String _reviewTimeKey = 'reviewTime';
  static const int _daysBetweenReviews = 7;

  final GetStorage _storage;

  InAppReviewService({GetStorage? storage}) : _storage = storage ?? GetStorage();

  /// Review so'rash kerakmi tekshirish va so'rash
  Future<void> requestReviewIfNeeded() async {
    final onRequestReview = MySafarSdk.callbacks.onRequestReview;
    if (onRequestReview == null) return;

    final lastReviewTime = _getLastReviewTime();

    if (lastReviewTime == null) {
      // Birinchi marta - review so'rash
      await _requestReview(onRequestReview);
    } else {
      // Oxirgi reviewdan qancha kun o'tganini tekshirish
      final daysSinceLastReview =
          DateTime.now().difference(lastReviewTime).inDays;

      if (daysSinceLastReview >= _daysBetweenReviews) {
        await _requestReview(onRequestReview);
      }
    }
  }

  DateTime? _getLastReviewTime() {
    final timeString = _storage.read<String>(_reviewTimeKey);
    if (timeString == null) return null;

    try {
      return DateTime.parse(timeString);
    } catch (_) {
      return null;
    }
  }

  Future<void> _requestReview(Future<void> Function() onRequestReview) async {
    _storage.write(_reviewTimeKey, DateTime.now().toIso8601String());
    await onRequestReview();
  }
}
