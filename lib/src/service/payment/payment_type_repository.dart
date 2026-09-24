import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:mysafar_sdk/src/core/config/response_config.dart'
    show NetworkSuccessResponse;
import 'package:mysafar_sdk/src/model/remote/booking/payment_type_model.dart'
    show Result;
import 'package:mysafar_sdk/src/model/remote/payment/payment_type_config.dart';
import 'package:mysafar_sdk/src/service/booking_service.dart';
import 'package:mysafar_sdk/src/service/payment/payment_type_cache.dart';

/// To'lov turlari: Hive keshi + server (`/get-payment-type`).
///
/// Ilgari Firestore'dan o'qilardi; SDK'dan Firebase butunlay olib tashlangani
/// uchun endi manba: kesh → server → lokal zaxira ro'yxat (chaqiruvchida).
///
/// №38: server javobi endi keshga yoziladi va sessiya ichida [ttl] davomida
/// "yangi" hisoblanadi — to'lov sahifasi keshni darhol ko'rsatadi, server
/// esa faqat muddati o'tganda (fonda) qayta so'raladi. Parallel chaqiruvlar
/// bitta so'rovni baham ko'radi. (Endpoint valyuta parametrini olmaydi —
/// ro'yxat valyutaga bog'liq emas.)
class PaymentTypeRepository {
  final PaymentTypeCache _cache = PaymentTypeCache();

  /// Server javobi shu muddat ichida qayta so'ralmaydi.
  static const Duration ttl = Duration(minutes: 10);

  static DateTime? _fetchedAt;
  static Future<List<PaymentTypeConfig>>? _inFlight;

  /// Keshdagi to'lov turlari — darhol ko'rsatish uchun (offline/tez).
  List<PaymentTypeConfig> cached() => _cache.load();

  /// Oldingi mazmun bilan moslik uchun: kesh mazmuni.
  Future<List<PaymentTypeConfig>> fetch() async => cached();

  /// Server ro'yxati shu sessiyada [ttl] ichida olinganmi.
  static bool get isFresh {
    final at = _fetchedAt;
    return at != null && DateTime.now().difference(at) < ttl;
  }

  /// Serverdan oladi, bo'sh bo'lmasa keshga yozadi. Xato/bo'sh — `[]`.
  static Future<List<PaymentTypeConfig>> fetchFromServer() {
    return _inFlight ??= _fetchFromServer().whenComplete(() {
      _inFlight = null;
    });
  }

  /// Bron sahifasida fonda chaqiriladi — to'lov sahifasi ochilganda ro'yxat
  /// keshda tayyor bo'ladi. Xatolar jim o'tadi.
  static Future<void> prefetch() async {
    if (isFresh) return;
    try {
      await fetchFromServer();
    } catch (_) {}
  }

  static Future<List<PaymentTypeConfig>> _fetchFromServer() async {
    try {
      final response = await BookingService().getPaymentType();
      if (response is NetworkSuccessResponse && response.data is List<Result>) {
        final configs = configsFromServer(response.data as List<Result>);
        if (configs.isNotEmpty) {
          _fetchedAt = DateTime.now();
          await PaymentTypeCache().save(configs);
        }
        return configs;
      }
    } catch (e) {
      debugPrint('MySafarSdk: to\'lov turlari olinmadi ($e)');
    }
    return const [];
  }

  /// `/get-payment-type` natijasi → [PaymentTypeConfig] ro'yxati.
  static List<PaymentTypeConfig> configsFromServer(List<Result> results) =>
      results
          .where((r) => (r.name ?? '').trim().isNotEmpty)
          .map((r) => PaymentTypeConfig(
                name: (r.name ?? '').trim().toUpperCase(),
                isActive: r.isActive ?? false,
              ))
          .toList();

  @visibleForTesting
  static void resetForTest() {
    _fetchedAt = null;
    _inFlight = null;
  }
}
