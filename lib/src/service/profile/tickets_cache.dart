import 'package:mysafar_sdk/src/service/cache/hive_json_store.dart';

/// "Mening biletlarim" (confirmed tickets) ni Hive'да keshlaydi.
///
/// XOM server JSON ro'yxati saqlanadi (model.toJson EMAS) — chunki
/// `ConfirmedTicketsModel.toJson` to'liq emas (`response`, `transaction`,
/// `callback_status` tushib qoladi). Shu bois keshdan ham xuddi serverdek to'liq
/// ma'lumot qaytadi.
class TicketsCache {
  TicketsCache._();
  static final TicketsCache instance = TicketsCache._();
  factory TicketsCache() => instance;

  static const String boxName = 'tickets_cache';
  final HiveJsonStore _store = const HiveJsonStore(boxName, key: 'tickets');

  /// Xom bilet JSON ro'yxati (List) yoki null.
  List? read() {
    final data = _store.readJson();
    return data is List ? data : null;
  }

  Future<void> write(List rawTickets) => _store.writeJson(rawTickets);

  Future<void> clear() => _store.clear();
}
