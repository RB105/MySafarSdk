import 'package:get_storage/get_storage.dart';
import 'package:mysafar_sdk/src/model/local/passenger_model.dart';
import 'package:mysafar_sdk/src/core/config/sdk_storage.dart';

/// Yo'lovchi ma'lumotlarini saqlash uchun service
class PassengerStorageService {
  final GetStorage _box;

  PassengerStorageService() : _box = sdkStorage();

  /// Yo'lovchi maydonlarini cache'ga saqlash
  void savePassengerFields(List<PassengerModel> passengers, String phone) {
    for (final passenger in passengers) {
      _addIfNotExists('firstname', passenger.firstname);
      _addIfNotExists('lastname', passenger.lastname);
      _addIfNotExists('middlename', passenger.middlename);
      _addIfNotExists('birthdate', passenger.birthdate);
      _addIfNotExists('docnum', passenger.docnum);
      _addIfNotExists('docexp', passenger.docexp);
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
    return List<String>.from(_box.read(key) ?? []);
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

