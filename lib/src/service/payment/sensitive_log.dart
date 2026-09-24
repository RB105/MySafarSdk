import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

/// Karta / SMS kod / JShShIR kabi maxfiy qiymatlar uchun log yordamchilari
/// (№63). `debugPrint` release'da ham ishlaydi (Android logcat) — shuning
/// uchun maxfiy ma'lumot faqat debug build'da VA niqoblangan holda chiqadi.
class SensitiveLog {
  SensitiveLog._();

  /// Faqat debug build'da yozadi. Chaqiruvchi qiymatlarni o'zi niqoblaydi.
  static void debug(String message) {
    if (!kDebugMode) return;
    debugPrint(message);
  }

  /// Oxirgi [visible] belgidan boshqasini `*` bilan almashtiradi:
  /// `8600123412341234` → `************1234`. Qisqa qiymat to'liq yashiriladi.
  static String maskTail(Object? value, {int visible = 4}) {
    final s = value?.toString() ?? '';
    if (s.isEmpty) return '';
    if (s.length <= visible * 2) return '*' * s.length;
    return '${'*' * (s.length - visible)}${s.substring(s.length - visible)}';
  }

  /// Qiymatni butunlay yashiradi (SMS kod, muddat) — faqat uzunligi qoladi.
  static String hide(Object? value) {
    final s = value?.toString() ?? '';
    return s.isEmpty ? '' : '*' * s.length;
  }
}
