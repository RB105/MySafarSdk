import 'package:flutter/foundation.dart';
import 'package:mysafar_sdk/src/model/local/recom_req_model.dart'
    show RecommendationRequestBody, RecommendationReqBodySegment;
import 'package:mysafar_sdk/src/model/remote/avia/airports_model.dart';
import 'package:mysafar_sdk/src/service/cache/hive_json_store.dart';

/// Foydalanuvchi bajargan oxirgi bilet qidiruvlarini Hive'da (faqat lokal)
/// keshlaydi. Bosh sahifadagi "So'ngi qidiruvlar" bo'limi shu keshdan o'qiydi.
///
/// Eslatma: [RecommendationReqBodySegment.toJson] faqat `cityIataCode` ni
/// saqlaydi (shahar nomi yo'qoladi). Ro'yxatda "Toshkent - Dubay" kabi nomlarni
/// ko'rsatish uchun bu yerda to'liq [AirPortsModel] JSON'i saqlanadi.
class RecentSearchCache {
  RecentSearchCache._();
  static final RecentSearchCache instance = RecentSearchCache._();
  factory RecentSearchCache() => instance;

  static const String boxName = 'recent_search_cache';
  static const int _maxItems = 10;

  final HiveJsonStore _store = const HiveJsonStore(boxName, key: 'items');

  /// Kesh o'zgarganda (yangi qidiruv qo'shilganda) UI'ni yangilash uchun.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// Keshdagi barcha qidiruvlar (eng oxirgisi birinchi).
  List<RecommendationRequestBody> read() {
    final data = _store.readJson();
    if (data is! List) return <RecommendationRequestBody>[];
    final result = <RecommendationRequestBody>[];
    for (final item in data) {
      if (item is! Map) continue;
      final body = _fromCacheJson(Map<String, dynamic>.from(item));
      if (body != null) result.add(body);
    }
    return result;
  }

  /// Yangi qidiruvni keshga qo'shadi (bir xil yo'nalish+sana takrorlanmaydi,
  /// eng oxirgisi ro'yxat boshiga chiqadi).
  Future<void> add(RecommendationRequestBody body) async {
    final segments = body.segments;
    if (segments == null || segments.isEmpty) return;

    final key = _dedupeKey(body);
    // `read()` o'zgartiriladigan ro'yxat qaytaradi, lekin himoya uchun nusxa
    // olamiz — hech qanday holatda unmodifiable ustida removeWhere/insert
    // chaqirilmasin (ilgari bo'sh kesh `const []` qaytarib crash bo'lardi).
    final current = List<RecommendationRequestBody>.of(read())
      ..removeWhere((e) => _dedupeKey(e) == key);
    current.insert(0, body);

    final trimmed = current.length > _maxItems
        ? current.sublist(0, _maxItems)
        : current;

    await _store.writeJson(trimmed.map(_toCacheJson).toList());
    revision.value++;
  }

  Future<void> clear() async {
    await _store.clear();
    revision.value++;
  }

  String _dedupeKey(RecommendationRequestBody b) {
    final s = b.segments!;
    return '${s.first.from?.cityIataCode}-${s.first.to?.cityIataCode}'
        '-${s.first.date}-${s.length}-${b.adt}-${b.chd}-${b.inf}';
  }

  Map<String, dynamic> _toCacheJson(RecommendationRequestBody b) {
    return {
      'adt': b.adt,
      'chd': b.chd,
      'inf': b.inf,
      'klass': b.klass,
      'flight_Type': b.flight_Type,
      'is_direct_only': b.isDirectOnly,
      'is_baggage': b.isBaggage,
      'segments': b.segments
          ?.map((s) => {
                'from': s.from?.toJson(),
                'to': s.to?.toJson(),
                'date': s.date,
              })
          .toList(),
    };
  }

  RecommendationRequestBody? _fromCacheJson(Map<String, dynamic> json) {
    try {
      final rawSegments = json['segments'];
      if (rawSegments is! List || rawSegments.isEmpty) return null;

      final segments = <RecommendationReqBodySegment>[];
      for (final s in rawSegments) {
        if (s is! Map) continue;
        segments.add(RecommendationReqBodySegment(
          from: s['from'] is Map
              ? AirPortsModel.fromJson(Map<String, dynamic>.from(s['from']))
              : null,
          to: s['to'] is Map
              ? AirPortsModel.fromJson(Map<String, dynamic>.from(s['to']))
              : null,
          date: s['date'] as String?,
        ));
      }
      if (segments.isEmpty) return null;

      return RecommendationRequestBody(
        adt: json['adt'] ?? 1,
        chd: json['chd'] ?? 0,
        inf: json['inf'] ?? 0,
        klass: json['klass'] as String? ?? 'a',
        flight_Type: json['flight_Type'] as int?,
        isDirectOnly: json['is_direct_only'] as int?,
        isBaggage: json['is_baggage'] as bool?,
        segments: segments,
      );
    } catch (e) {
      debugPrint('RecentSearchCache parse error: $e');
      return null;
    }
  }
}
