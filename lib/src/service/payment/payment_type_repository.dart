import 'package:mysafar_sdk/src/model/remote/payment/payment_type_config.dart';
import 'package:mysafar_sdk/src/service/payment/payment_type_cache.dart';

/// To'lov turlari — faqat lokal Hive keshi.
///
/// Ilgari Firestore'dan o'qilardi; SDK'dan Firebase butunlay olib tashlangani
/// uchun endi manba: kesh → server (`/get-payment-type`, chaqiruvchi tomonda)
/// → lokal zaxira ro'yxat. [fetch] kesh mazmunini qaytaradi — bo'sh bo'lsa
/// chaqiruvchi keyingi manbaga o'tadi.
class PaymentTypeRepository {
  final PaymentTypeCache _cache = PaymentTypeCache();

  /// Keshdagi to'lov turlari — darhol ko'rsatish uchun (offline/tez).
  List<PaymentTypeConfig> cached() => _cache.load();

  Future<List<PaymentTypeConfig>> fetch() async => cached();
}
