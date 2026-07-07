import 'package:mysafar_sdk/src/service/cache/hive_json_store.dart';

/// Profilni Hive'da keshlaydi. To'liq server JSON'i (ProfileModel.toJson)
/// saqlanadi — round-trip'да hech qanday maydon yo'qolmasligi uchun
/// `ProfileModel.toJson` `fromJson` bilan simmetrik qilingan.
class ProfileCache {
  ProfileCache._();
  static final ProfileCache instance = ProfileCache._();
  factory ProfileCache() => instance;

  static const String boxName = 'profile_cache';
  final HiveJsonStore _store = const HiveJsonStore(boxName, key: 'profile');

  Map<String, dynamic>? read() {
    final data = _store.readJson();
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  Future<void> write(Map<String, dynamic> profileJson) =>
      _store.writeJson(profileJson);

  Future<void> clear() => _store.clear();
}
