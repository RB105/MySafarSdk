import 'package:mysafar_sdk/src/service/api_service.dart' show ApiService;

/// Token tekshiruvini (verifyToken) TTL bilan cache'laydigan yengil yordamchi.
///
/// Avval har bir booking/profil amalidan oldin `verifyToken()` chaqirilib,
/// har safar alohida tarmoq so'rovi yuborilardi. Bu yordamchi natijani qisqa
/// muddatga (TTL) eslab qoladi va shu oraliqdagi takroriy chaqiruvlarda
/// tarmoqqa chiqmaydi. Tokenni yangilash baribir interceptor'dagi 401
/// oqimi orqali amalga oshadi.
class TokenVerificationCache {
  TokenVerificationCache._();

  /// Tekshiruv natijasi shu muddat ichida qayta ishlatiladi.
  static const Duration _ttl = Duration(minutes: 5);

  static DateTime? _lastVerifiedAt;
  static Future<void>? _inFlight;

  /// Token oxirgi marta TTL ichida tekshirilgan bo'lsa darhol qaytadi;
  /// aks holda bitta `verifyToken()` so'rovini yuboradi (parallel chaqiruvlar
  /// bitta so'rovni baham ko'radi).
  static Future<void> ensureVerified(ApiService apiService) {
    final last = _lastVerifiedAt;
    if (last != null && DateTime.now().difference(last) < _ttl) {
      return Future<void>.value();
    }

    // Parallel chaqiruvlar bitta in-flight so'rovni kutadi.
    return _inFlight ??= _verify(apiService);
  }

  static Future<void> _verify(ApiService apiService) async {
    try {
      await apiService.verifyToken();
      _lastVerifiedAt = DateTime.now();
    } finally {
      _inFlight = null;
    }
  }

  /// Logout/login kabi holatlarda cache'ni tozalash uchun.
  static void invalidate() {
    _lastVerifiedAt = null;
  }
}
