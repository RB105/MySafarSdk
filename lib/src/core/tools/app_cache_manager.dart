import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Rasmlar keshi uchun umumiy [CacheManager].
///
/// Standart [DefaultCacheManager] Android/iOS'da kesh metama'lumotlarini
/// `sqflite` (SQLite) orqali saqlaydi. Ba'zi qurilmalarda sqflite plagini
/// ro'yxatdan o'tmay `MissingPluginException` beradi (No implementation found
/// on channel com.tekartik.sqflite). Buni butunlay yo'qotish uchun bu yerda
/// metama'lumotlar oddiy JSON faylida saqlanadigan [JsonCacheInfoRepository]
/// ishlatiladi — sqflite'ga hech qanday bog'liqlik qolmaydi.
///
/// Barcha `CachedNetworkImage` lar `cacheManager: AppCacheManager.instance`
/// orqali shu manager'dan foydalanadi.
class AppCacheManager {
  AppCacheManager._();

  static const _key = 'mysafarImageCache';

  static final CacheManager instance = CacheManager(
    Config(
      _key,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 200,
      // sqflite o'rniga JSON — plagin registratsiyasiga bog'liq emas.
      repo: JsonCacheInfoRepository(databaseName: _key),
    ),
  );
}
