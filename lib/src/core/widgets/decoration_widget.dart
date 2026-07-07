// ignore_for_file: deprecated_member_use

/*
 *  (c) Diyor Xalloqov 2024.8.15 Toshkent, Uzbekistan
 *  github: https://github.com/diyorxalloqov
 *  LinkedIn: https://www.linkedin.com/in/diyor-xalloqov-024b63231/
 *  Telegram: https://t.me/Flutter_dart_developer
 */

import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

BoxDecoration decoration(BuildContext context,
        {bool? isNotShadow,
        BorderRadiusGeometry? borderRadius,
        double? blurRadius}) =>
    BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        boxShadow: isNotShadow != null
            ? []
            : [
                BoxShadow(
                    spreadRadius: 0,
                    offset: const Offset(0, 1),
                    blurRadius: blurRadius ?? 4,
                    color: ProjectTheme.containerShadow)
              ],
        color: context.theme.colorScheme.onPrimaryFixed);

BoxDecoration mainDecoration(BuildContext context,
    {ImageProvider? image,
    bool? isNotShadow,
    bool? isNotBorder,
    Color? color}) {
  return BoxDecoration(
      image: image != null
          ? DecorationImage(image: image, fit: BoxFit.cover)
          : null,
      border: isNotBorder != null
          ? Border()
          : Border.all(width: 1, color: Color(0xffDBDCDF)),
      boxShadow: [
        if (isNotShadow == null)
          BoxShadow(
              color: const Color(0xffC6C7C9).withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 2))
      ],
      borderRadius: BorderRadius.circular(context.radius8),
      color: color ?? context.theme.cardColor);
}
