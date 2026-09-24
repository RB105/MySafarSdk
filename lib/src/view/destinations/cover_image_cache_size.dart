import 'package:flutter/widgets.dart';

/// `BoxFit.cover` bilan chiziladigan tarmoq rasmini xotirada qaysi o'lchamda
/// dekodlash kerakligi (№43) — to'liq o'lchamdagi (masalan 4000px) rasm kichik
/// kartada ham to'liq dekodlanib, xotirani ko'p egallardi.
///
/// Faqat BITTA tomon beriladi (ikkinchisi `null`): ikkalasi berilsa
/// `ResizeImage` nisbatni saqlamay cho'zib yuboradi. Manzil rasmlari odatda
/// landshaft (≈3:2) — kengligi balandligidan ancha katta bo'lmagan qutida
/// `cover` rasmni balandlik bo'yicha moslaydi, shuning uchun balandlik
/// beriladi; juda keng qutilarda (>1.8) esa kenglik.
({int? width, int? height}) coverImageCacheSize(
  BuildContext context,
  double boxWidth,
  double boxHeight,
) {
  if (!boxWidth.isFinite ||
      !boxHeight.isFinite ||
      boxWidth <= 0 ||
      boxHeight <= 0) {
    return (width: null, height: null);
  }
  final double dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
  if (boxWidth / boxHeight > 1.8) {
    return (width: (boxWidth * dpr).ceil(), height: null);
  }
  return (width: null, height: (boxHeight * dpr).ceil());
}
