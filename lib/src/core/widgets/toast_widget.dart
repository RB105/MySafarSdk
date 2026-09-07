import 'package:fluttertoast/fluttertoast.dart';

import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

/// Toast kalitlari uchun o'zbekcha default — lang JSON yuklanmagan yoki
/// kalit topilmasa raw `snake_case` o'rniga shu matn chiqadi.
const Map<String, String> _uzToastDefaults = {
  'press_again_to_exit': 'Chiqish uchun yana bosing',
  'home_fill_search': "Yo'nalish va sanani tanlang",
  'same_airport_warning':
      "Uchish va qo'nish shaharlari bir xil bo'lmasligi kerak",
  'profile_success_update':
      "Profil ma'lumotlari muvaffaqiyatli o'zgartirildi",
  'error_other': 'Xatolik yuz berdi. Iltimos, qayta urinib ko‘ring',
};

String _uzDefaultFor(String key) =>
    _uzToastDefaults[key] ?? 'Xatolik yuz berdi. Iltimos, qayta urinib ko‘ring';

/// Tarjima kaliti bo'yicha toast — topilmasa o'zbekcha default.
void showToastTr(String key) {
  showToastMessage(key.tr(defaultValue: _uzDefaultFor(key)));
}

/// Tayyor matn (API xato, exception va hokazo).
void showToastMessage(String title) {
  if (title.isEmpty) return;
  Fluttertoast.showToast(
      msg: title,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0);
}
