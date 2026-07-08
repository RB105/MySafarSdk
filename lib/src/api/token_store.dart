import 'package:get_storage/get_storage.dart';
import 'package:mysafar_sdk/src/core/config/sdk_storage.dart';

/// Auth tokenlarini saqlash chegarasi. SDK ichidagi barcha token o'qish/yozish
/// shu interfeys orqali o'tadi — host app o'z xohishiga ko'ra secure storage
/// yoki o'z session mexanizmini ulashi mumkin.
///
/// O'qishlar sinxron: Dio interceptor'ining hot-path'i va `isLoggedIn`
/// tekshiruvlari await'siz ishlaydi. Asinxron storage ishlatadigan
/// implementatsiyalar qiymatlarni oldindan xotiraga yuklab turishi kerak.
abstract class MySafarTokenStore {
  String? get accessToken;
  String? get refreshToken;

  /// Foydalanuvchi login qilganmi — access token mavjud va bo'sh emasmi.
  bool get isLoggedIn => accessToken?.isNotEmpty == true;

  /// Muvaffaqiyatli login/registratsiyadan keyin ikkala token yoziladi.
  Future<void> saveTokens({required String access, required String refresh});

  /// 401 refresh muvaffaqiyatli bo'lganda faqat access yangilanadi.
  Future<void> saveAccess(String access);

  Future<void> clear();
}

/// Default implementatsiya — app'ning hozirgi xatti-harakati bilan bir xil
/// (GetStorage, `access_token`/`refresh_token` kalitlari).
class GetStorageTokenStore extends MySafarTokenStore {
  GetStorageTokenStore({GetStorage? storage}) : _db = storage ?? sdkStorage();

  static const String accessKey = 'access_token';
  static const String refreshKey = 'refresh_token';

  final GetStorage _db;

  @override
  String? get accessToken => _db.read<String>(accessKey);

  @override
  String? get refreshToken => _db.read<String>(refreshKey);

  @override
  Future<void> saveTokens({required String access, required String refresh}) async {
    await _db.write(refreshKey, refresh);
    await _db.write(accessKey, access);
  }

  @override
  Future<void> saveAccess(String access) => _db.write(accessKey, access);

  @override
  Future<void> clear() async {
    await _db.remove(accessKey);
    await _db.remove(refreshKey);
  }
}
