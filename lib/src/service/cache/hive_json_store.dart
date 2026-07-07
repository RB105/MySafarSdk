import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// Hive box ichida ma'lumotni JSON string ko'rinishida saqlaydigan umumiy
/// yordamchi. Map/List kabi turlar Hive'ning tur nozikliklaridan xoli,
/// ishonchli saqlanadi. News keshidagi yondashuvni umumlashtiradi — profile,
/// tickets, payment_types va boshqa keshlar shu orqali ishlaydi.
class HiveJsonStore {
  final String boxName;
  final String key;

  const HiveJsonStore(this.boxName, {this.key = 'data'});

  Box get _box => Hive.box(boxName);

  Future<void> writeJson(Object? value) async {
    try {
      await _box.put(key, jsonEncode(value));
    } catch (e) {
      debugPrint('HiveJsonStore($boxName).writeJson error: $e');
    }
  }

  /// Saqlangan qiymatni (Map yoki List) qaytaradi; bo'lmasa null.
  dynamic readJson() {
    try {
      final raw = _box.get(key);
      if (raw is! String || raw.isEmpty) return null;
      return jsonDecode(raw);
    } catch (e) {
      debugPrint('HiveJsonStore($boxName).readJson error: $e');
      return null;
    }
  }

  Future<void> clear() async {
    try {
      await _box.delete(key);
    } catch (_) {}
  }
}
