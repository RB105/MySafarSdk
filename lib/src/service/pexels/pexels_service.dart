import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

/// Pexels API kaliti.
///
/// Standart kalit kodga joylangan — barcha build'larda (debug/release/CI)
/// qo'shimcha sozlamasiz ishlaydi. Kalitni almashtirish kerak bo'lsa,
/// `--dart-define` orqali berilgani ustunlik qiladi:
///   flutter run --dart-define=PEXELS_API_KEY=xxxx
/// Kalit bo'sh bo'lsa servis tarmoqqa chiqmay bo'sh ro'yxat qaytaradi —
/// bunda kartalar zaxira rasmni (ticket_bg.png) ko'rsataveradi.
const String _kPexelsApiKey = String.fromEnvironment(
  'PEXELS_API_KEY',
  defaultValue: 'HsiK9x2Z0HNXW4kIgDBGnlJIoz2BJEUxe69AHtONMIaPZ2MpqNBKNAJM',
);

/// Manzil (shahar/davlat) nomi bo'yicha Pexels'dan landscape rasmlar oladi.
/// Natijalar xotirada va GetStorage'da cache'lanadi — qayta so'rov yubormaydi.
class PexelsService {
  PexelsService._();

  static final PexelsService instance = PexelsService._();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.pexels.com/v1/',
      headers: {'Authorization': _kPexelsApiKey},
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  final GetStorage _storage = GetStorage();
  final Map<String, List<String>> _memoryCache = {};


  String _cacheKey(String query) => 'pexels_${query.trim().toLowerCase()}';

  /// Faqat cache'dan (xotira yoki disk) o'qiydi — tarmoqqa chiqmaydi.
  /// Darhol ko'rsatish uchun ishlatiladi.
  List<String>? readCache(String query) {
    final key = _cacheKey(query);
    final mem = _memoryCache[key];
    if (mem != null) return mem;

    final stored = _storage.read(key);
    if (stored is List && stored.isNotEmpty) {
      final list = stored.map((e) => e.toString()).toList();
      _memoryCache[key] = list;
      return list;
    }
    return null;
  }

  /// Cache'da bo'lsa — o'shani qaytaradi; bo'lmasa Pexels'dan yuklab cache'laydi.
  Future<List<String>> getImages(String query, {int perPage = 4}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final cached = readCache(trimmed);
    if (cached != null && cached.isNotEmpty) return cached;

    // Kalit sozlanmagan bo'lsa tarmoqqa chiqmaymiz (401 oldini olamiz).
    if (_kPexelsApiKey.isEmpty) return const [];

    try {
      final res = await _dio.get(
        'search',
        queryParameters: {
          'query': trimmed,
          'orientation': 'landscape',
          'per_page': perPage,
        },
      );

      final photos = (res.data['photos'] as List?) ?? const [];
      final urls = <String>[];
      for (final photo in photos) {
        final src = photo['src'];
        final url =
            (src?['landscape'] ?? src?['large'] ?? src?['medium'])?.toString();
        if (url != null && url.isNotEmpty) urls.add(url);
      }

      if (urls.isNotEmpty) {
        _memoryCache[_cacheKey(trimmed)] = urls;
        await _storage.write(_cacheKey(trimmed), urls);
      }
      return urls;
    } catch (e) {
      debugPrint('PexelsService error for "$trimmed": $e');
      return const [];
    }
  }
}
