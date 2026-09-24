import 'package:get_storage/get_storage.dart';
import 'package:mysafar_sdk/src/model/local/passenger_model.dart';
import 'package:mysafar_sdk/src/core/config/sdk_storage.dart';

/// Yo'lovchi ma'lumotlarini saqlash uchun service
class PassengerStorageService {
  final GetStorage _box;

  PassengerStorageService() : _box = sdkStorage();

  /// Avtoto'ldirish ro'yxatlari saqlanadigan kalitlar (ism/email/telefon).
  static const List<String> suggestionKeys = [
    'firstname',
    'lastname',
    'middlename',
    'phone',
    'email',
  ];

  /// №62: pasport raqami, amal muddati va tug'ilgan kun diskka (GetStorage)
  /// ochiq yozilmaydi — ular uchun avtoto'ldirish ro'yxati yo'q. Eski
  /// build'lar yozib qo'ygan qiymatlar [purgeSensitiveSuggestions] bilan
  /// o'chiriladi.
  static const List<String> sensitiveKeys = ['birthdate', 'docnum', 'docexp'];

  /// Saqlangan yo'lovchilar keshi (`UsersDataCubit.cacheKey` bilan bir xil).
  static const String cachedUsersKey = 'cached_users';

  /// Yo'lovchi maydonlarini cache'ga saqlash (faqat ism/email/telefon).
  void savePassengerFields(List<PassengerModel> passengers, String phone) {
    for (final passenger in passengers) {
      _addIfNotExists('firstname', passenger.firstname);
      _addIfNotExists('lastname', passenger.lastname);
      _addIfNotExists('middlename', passenger.middlename);
      _addIfNotExists('phone', phone);
      _addIfNotExists('email', passenger.email);
    }
  }

  void _addIfNotExists(String key, String value) {
    if (value.isEmpty) return;
    final List<String> currentList = List<String>.from(_box.read(key) ?? []);
    if (!currentList.contains(value)) {
      currentList.add(value);
      _box.write(key, currentList);
    }
  }

  /// Cache'dan oldingi qiymatlarni olish
  List<String> getSuggestions(String key) {
    if (sensitiveKeys.contains(key)) return <String>[];
    final raw = _box.read(key);
    return raw is List ? List<String>.from(raw) : <String>[];
  }

  /// Eski build'lar yozgan pasport/tug'ilgan kun ro'yxatlarini o'chiradi
  /// (SDK init'da bir marta).
  static Future<void> purgeSensitiveSuggestions([GetStorage? box]) async {
    final db = box ?? sdkStorage();
    for (final key in sensitiveKeys) {
      if (db.hasData(key)) await db.remove(key);
    }
  }

  /// Foydalanuvchi almashganda / chiqishda: barcha avtoto'ldirish
  /// ro'yxatlari va saqlangan yo'lovchilar keshi o'chiriladi.
  static Future<void> clearUserScoped([GetStorage? box]) async {
    final db = box ?? sdkStorage();
    for (final key in [...suggestionKeys, ...sensitiveKeys, cachedUsersKey]) {
      await db.remove(key);
    }
  }

  /// Cached users ma'lumotlarini olish
  List<dynamic> getCachedUsers() {
    return _box.read("cached_users") ?? [];
  }

  /// Til sozlamasini olish
  String getLanguage() {
    return _box.read('lang') ?? 'uz';
  }
}

