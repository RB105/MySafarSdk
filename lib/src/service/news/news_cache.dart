import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:mysafar_sdk/src/model/remote/news/news_model.dart';

/// Yangiliklarni Hive'da keshlaydi.
///
/// Kesh Firestore bilan doim sinxron: `NewsRepository` har safar Firestore'dan
/// (bir martalik yoki real-time stream orqali) yangi ro'yxat olganда [save]
/// chaqiradi. Shu bois news qo'shilsa/tahrirlansa/o'chirilsa — kesh ham
/// avtomatik yangilanadi.
///
/// Ma'lumot JSON string ko'rinishida saqlanadi (Hive map/tur nozikliklaridan
/// xoli, ishonchli).
class NewsCache {
  NewsCache._();
  static final NewsCache instance = NewsCache._();
  factory NewsCache() => instance;

  static const String boxName = 'news_cache';
  // v2 — ko'p tilli (title/content Map) formatga o'tildi. Eski (bir tilli yoki
  // stringifikatsiya qilingan) keshni chetlab o'tamiz.
  static const String _key = 'items_v2';

  Box get _box => Hive.box(boxName);

  /// Keshni yangi ro'yxat bilan to'liq almashtiradi.
  Future<void> save(List<NewsModel> items) async {
    try {
      final encoded =
          jsonEncode(items.map((e) => e.toCacheMap()).toList());
      await _box.put(_key, encoded);
    } catch (e) {
      debugPrint('NewsCache.save error: $e');
    }
  }

  /// Keshdagi yangiliklar (bo'sh bo'lsa — bo'sh ro'yxat).
  List<NewsModel> load() {
    try {
      final raw = _box.get(_key);
      if (raw is! String || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((m) => NewsModel.fromCacheMap(Map<String, dynamic>.from(m)))
          .toList();
    } catch (e) {
      debugPrint('NewsCache.load error: $e');
      return const [];
    }
  }

  Future<void> clear() async {
    try {
      await _box.delete(_key);
    } catch (_) {}
  }
}
