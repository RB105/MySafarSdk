import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:mysafar_sdk/src/core/constants/end_points.dart';

/// Firebase Firestore'dan olinadigan va Hive'da keshlanadigan remote config.
///
/// Hozircha: avia **recommendation endpoint** ro'yxati.
/// Firestore hujjati (`config/avia`) tuzilishi:
/// ```
/// config (collection)
///   └── avia (document)
///         recommendation_endpoints: [   // map list — {url, isActive}
///           { "url": "/avia/get-recommendations-centrum",  "isActive": true  },
///           { "url": "/avia/get-recommendations-myagent",  "isActive": false },
///           { "url": "/avia/get-recommendations-flydubai", "isActive": true  }
///         ]
/// ```
/// Faqat `isActive == true` (yoki maydon umuman berilmagan) elementlarning `url`'i
/// olinadi; `isActive == false` bo'lsa — o'sha endpoint chiqarib tashlanadi.
///
/// Oqim:
///   1. App ochilganda [init] Hive box'ini ochadi.
///   2. [sync] Firestore'dan yangi ro'yxatni olib Hive'ga yozadi (fon rejimida).
///   3. [recommendationEndpoints] — Hive'da saqlangan bo'lsa o'sha, aks holda
///      koddagi 3 ta fallback endpoint qaytariladi.
///
/// Kelajakda boshqa remote config qiymatlarini ham shu servisga qo'shish mumkin.
class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  static const String boxName = 'remote_config';
  static const String _kRecommendationEndpoints = 'recommendation_endpoints';

  Box get _box => Hive.box(boxName);

  /// Firestore ham, kesh ham bo'sh bo'lsa ishlatiladigan zaxira ro'yxat —
  /// hozirgi qattiq yozilgan 3 endpoint.
  static const List<String> _fallbackEndpoints = <String>[
    EndPoints.avia_recommendations_centrum,
    EndPoints.avia_recommendations_myagent,
    EndPoints.avia_recommendations_flydubai,
  ];

  /// Berilgan kalitdagi endpoint ro'yxati:
  ///   • Firestore'dan kelib Hive'da saqlangan bo'lsa — o'sha
  ///   • bo'lmasa — [fallback]
  ///
  /// Yangi endpoint guruhi kerak bo'lsa shu metodni chaqiring — alohida kod
  /// yozish shart emas:
  /// `RemoteConfigService.instance.endpoints('hot_recommendations', fallback: [...])`
  List<String> endpoints(String key, {List<String> fallback = const []}) {
    try {
      final cached = _sanitize(_box.get(key));
      if (cached.isNotEmpty) return cached;
    } catch (_) {
      // Box ochilmagan bo'lsa ham fallback bilan ishlaymiz.
    }
    return fallback;
  }

  /// Recommendation endpointlari (Firestore → Hive → koddagi 3 fallback).
  List<String> get recommendationEndpoints => endpoints(
        _kRecommendationEndpoints,
        fallback: _fallbackEndpoints,
      );

  /// Ixtiyoriy tipdagi qiymatni toza `List<String>` (faqat aktiv URL'lar) ga
  /// aylantiradi.
  ///
  /// Har bir element quyidagilardan biri bo'lishi mumkin:
  ///   • Map `{url, isActive}` — `isActive == false` bo'lsa tashlab ketiladi,
  ///     aks holda (true yoki maydon yo'q) `url` olinadi;
  ///   • oddiy String — eski format, aktiv deb hisoblanadi.
  static List<String> _sanitize(dynamic raw) {
    if (raw is! List) return const [];
    final result = <String>[];
    for (final e in raw) {
      if (e is Map) {
        // Faqat aniq `false` yashiradi; true yoki maydon yo'q — aktiv.
        if (e['isActive'] == false) continue;
        final url = e['url']?.toString().trim() ?? '';
        if (url.isNotEmpty) result.add(url);
      } else {
        final url = e.toString().trim();
        if (url.isNotEmpty) result.add(url);
      }
    }
    return result;
  }
}
