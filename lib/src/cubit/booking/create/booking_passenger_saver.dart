import 'package:flutter/foundation.dart' show debugPrint;
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
import 'package:mysafar_sdk/src/core/config/response_config.dart'
    show ErrorType, NetworkErrorResponse, NetworkSuccessResponse;
import 'package:mysafar_sdk/src/core/config/sdk_storage.dart' show sdkStorage;
import 'package:mysafar_sdk/src/cubit/profile/users_data/users_data_cubit.dart';
import 'package:mysafar_sdk/src/service/profile/profile_service.dart'
    show ProfileService;

/// Bron yaratilgach kiritilgan yo'lovchilarni backend'dagi saqlangan
/// yo'lovchilar ro'yxatiga (`/create-user-data`) fonda qo'shadi —
/// AddPassengerPage'dagi bilan bir xil API. Dublikat bo'lmasligi uchun
/// mavjud ro'yxat `docnum` bo'yicha tekshiriladi.
///
/// Yangi yo'lovchi qo'shilsa `cached_users` tozalanadi va qayta yuklanadi —
/// keyingi bronlashda "Yo'lovchi tanlash" chiqishi uchun.
class BookingPassengerSaver {
  BookingPassengerSaver._();

  static Future<void> saveInBackground(
      List<Map<String, dynamic>> passengersToSave) async {
    if (!MySafarSdk.tokens.isLoggedIn) return;
    if (passengersToSave.isEmpty) return;
    try {
      final service = ProfileService();
      final box = sdkStorage();

      // Mavjud saqlanganlar — dublikatni oldini olish. Avval server; ishlamasa kesh.
      List<dynamic> existing;
      final existingRes = await service.getUserDate();
      if (existingRes is NetworkSuccessResponse) {
        existing = existingRes.data as List? ?? const [];
      } else if (existingRes is NetworkErrorResponse &&
          existingRes.errorType == ErrorType.emptyResponse) {
        existing = const [];
      } else {
        existing = (box.read(UsersDataCubit.cacheKey) as List?) ?? const [];
      }

      final existingDocnums = <String>{
        for (final u in existing)
          if (u is Map && u['docnum'] != null)
            u['docnum'].toString().trim().toUpperCase(),
      };

      var createdAny = false;
      for (final p in passengersToSave) {
        final docnum = (p['docnum'] ?? '').toString().trim();
        if (docnum.isEmpty) continue;
        if (!existingDocnums.add(docnum.toUpperCase())) continue;

        final birthdate = toApiDate((p['birthdate'] ?? '').toString());
        final docexp = toApiDate((p['docexp'] ?? '').toString());
        if (birthdate == null || docexp == null) continue;

        final response = await service.createUser(params: {
          'firstname': (p['firstname'] ?? '').toString().trim(),
          'lastname': (p['lastname'] ?? '').toString().trim(),
          'middlename': (p['middlename'] ?? '').toString().trim(),
          'birthdate': birthdate,
          'docnum': docnum,
          'docexp': docexp,
          'gender': (p['gender'] ?? 'M').toString(),
          'citizen': (p['citizen'] ?? '').toString(),
        });
        if (response is NetworkSuccessResponse) createdAny = true;
      }

      // Yangi yozuv bo'lsa eski keshni bekor qilamiz; keyin (kesh yo'q
      // bo'lsa) serverdan qayta yuklaymiz — keyingi bronlashda tugma chiqadi.
      if (createdAny) {
        await UsersDataCubit.clearCache();
      }
      await UsersDataCubit.prefetchIfNeeded();
    } catch (e) {
      // Fon jarayoni — foydalanuvchi oqimiga ta'sir qilmaydi.
      debugPrint('Passenger background save failed: $e');
    }
  }

  /// `dd.MM.yyyy` yoki `yyyy-MM-dd` ko'rinishidagi sanani API formatiga
  /// (`yyyy-MM-dd`) keltiradi; noto'g'ri format bo'lsa `null`.
  static String? toApiDate(String raw) {
    final value = raw.trim();
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return value;
    if (RegExp(r'^\d{2}\.\d{2}\.\d{4}$').hasMatch(value)) {
      final parts = value.split('.');
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    }
    return null;
  }
}
