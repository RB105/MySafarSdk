import 'package:mysafar_sdk/src/model/remote/payment/payment_type_config.dart';
import 'package:mysafar_sdk/src/service/cache/hive_json_store.dart';

/// To'lov turlarini Hive'da keshlaydi (matn qismi; rasm lokal qoladi).
class PaymentTypeCache {
  PaymentTypeCache._();
  static final PaymentTypeCache instance = PaymentTypeCache._();
  factory PaymentTypeCache() => instance;

  static const String boxName = 'payment_types_cache';
  // v2 — cardName endi ko'p tilli (Map). Eski keshni chetlab o'tamiz.
  final HiveJsonStore _store = const HiveJsonStore(boxName, key: 'items_v2');

  List<PaymentTypeConfig> load() {
    final data = _store.readJson();
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((m) => PaymentTypeConfig.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> save(List<PaymentTypeConfig> items) =>
      _store.writeJson(items.map((e) => e.toCacheMap()).toList());

  Future<void> clear() => _store.clear();
}
