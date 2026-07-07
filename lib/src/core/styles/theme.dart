// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;

class ProjectTheme {
  /// Android va iOS'da (va boshqa platformalarda) bir xil — chetdan surib
  /// ortga qaytish (iOS uslubidagi swipe-back) gesturei. Barcha
  /// MaterialPageRoute'larga qo'llanadi. PopScope(canPop:false) bo'lgan
  /// sahifalarda gesture avtomatik o'chadi (ya'ni PopScope hurmat qilinadi).
  static const PageTransitionsTheme _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
    },
  );

  static ThemeData get light => ThemeData.light(useMaterial3: true).copyWith(
      pageTransitionsTheme: _pageTransitions,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: lightColorScheme,
      appBarTheme: AppBarTheme(
          systemOverlayStyle: kStatusBarLight,
          backgroundColor: cardColorLight,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: textColorLight)),
      textTheme: textThemeLight,
      dividerColor: Color(0xffDBDCDF),
      dividerTheme: DividerThemeData(color: Color(0xffDBDCDF)),
      cardColor: Color(0xffFFFFFF),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14.5),
        focusColor: Colors.transparent,
        fillColor: Colors.white,
        filled: true,
        disabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(8)),
        // OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xffE7E12EA), width: 1)),
        outlineBorder: BorderSide.none,
        // const BorderSide(color: Color(0xffE7E12EA), width: 1),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(8)),
        // OutlineInputBorder(
        //     borderRadius: BorderRadius.circular(12),
        //     borderSide: const BorderSide(color: Color(0xff2A2A2A), width: 1)),
        enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(8)),
        // OutlineInputBorder(
        //     borderRadius: BorderRadius.circular(12),
        //     borderSide: const BorderSide(color: Color(0xffE7E12EA), width: 1)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red)),
        border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(8)),
        hintStyle: const TextStyle(
            color: Color(0xffA7A7AA),
            fontFamily: "Gilroy",
            fontWeight: FontWeight.w400,
            fontSize: 14),
      ));

  static ThemeData get dark => ThemeData.dark(useMaterial3: true).copyWith(
      pageTransitionsTheme: _pageTransitions,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: darkColorScheme,
      appBarTheme: AppBarTheme(
          backgroundColor: cardColorDark,
          systemOverlayStyle: kStatusBarDark,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: textColorDark)),
      textTheme: textThemeDark,
      cardColor: Color(0xff000000),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14.5),
        focusColor: Colors.transparent,
        fillColor: const Color(0xff313131),
        filled: true,
        hoverColor: const Color(0xff313131),
        disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xff454B57), width: 1)),
        outlineBorder: const BorderSide(color: Color(0xff454B57), width: 1),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xffFAFAFA), width: 1)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xff454B57), width: 1)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        hintStyle: const TextStyle(
            color: Color(0xffB2B2B2),
            fontFamily: "Gilroy",
            fontWeight: FontWeight.w400,
            fontSize: 14),
      ));

  // Text Theme
  static final textThemeLight = TextTheme(
    labelLarge:
        textLightStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
    labelMedium: textLightStyle.copyWith(fontWeight: FontWeight.w700),
    labelSmall:
        textLightStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w700),
    //
    displayLarge:
        textLightStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
    displayMedium: textLightStyle.copyWith(fontWeight: FontWeight.w600),
    displaySmall:
        textLightStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
    //
    bodyLarge: textLightStyle.copyWith(fontSize: 18),
    bodyMedium: textLightStyle,
    bodySmall: textLightStyle.copyWith(fontSize: 12),
    //
    titleLarge:
        textLightStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w400),
    titleMedium: textLightStyle.copyWith(fontWeight: FontWeight.w400),
    titleSmall:
        textLightStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w400),
    //
    headlineLarge: secondaryTextLightStyle.copyWith(fontSize: 18),
    headlineMedium: secondaryTextLightStyle,
    headlineSmall: secondaryTextLightStyle.copyWith(fontSize: 12),
    //
  ).apply(fontFamily: "Gilroy");

  static final textThemeDark = TextTheme(
    labelLarge:
        textDarkStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
    labelMedium: textDarkStyle.copyWith(fontWeight: FontWeight.w700),
    labelSmall:
        textDarkStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w700),
    //
    displayLarge:
        textDarkStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
    displayMedium: textDarkStyle.copyWith(fontWeight: FontWeight.w600),
    displaySmall:
        textDarkStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
    //
    bodyLarge: textDarkStyle.copyWith(fontSize: 18),
    bodyMedium: textDarkStyle,
    bodySmall: textDarkStyle.copyWith(fontSize: 12),
    //
    titleLarge:
        textDarkStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w400),
    titleMedium: textDarkStyle.copyWith(fontWeight: FontWeight.w400),
    titleSmall:
        textDarkStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w400),
    //
    headlineLarge: secondaryTextDarkStyle.copyWith(fontSize: 18),
    headlineMedium: secondaryTextDarkStyle,
    headlineSmall: secondaryTextDarkStyle.copyWith(fontSize: 12),
  ).apply(fontFamily: "Gilroy");

  static final textLightStyle = TextStyle(
      color: textColorLight, fontSize: 16, fontWeight: FontWeight.w500);
  static final textDarkStyle = TextStyle(
      color: textColorDark, fontSize: 16, fontWeight: FontWeight.w500);

  static final secondaryTextLightStyle = TextStyle(
      color: secondaryTextLight, fontSize: 16, fontWeight: FontWeight.w400);
  static final secondaryTextDarkStyle = TextStyle(
      color: secondaryTextDark, fontSize: 16, fontWeight: FontWeight.w400);

  static final focusGradient = [accentLight, brandColor];

  static final kStatusBarLight = SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarColor: white,
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark);
  static final kStatusBarDark = SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarColor: black,
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light);

  // COLORS
  static final lightColorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: ThemeData.light(useMaterial3: true).colorScheme.primary,
      onPrimary: ThemeData.light(useMaterial3: true).colorScheme.onPrimary,
      secondary: ThemeData.light(useMaterial3: true).colorScheme.secondary,
      onSecondary: ThemeData.light(useMaterial3: true).colorScheme.onSecondary,
      error: ThemeData.light(useMaterial3: true).colorScheme.error,
      onError: ThemeData.light(useMaterial3: true).colorScheme.onError,
      surface: ThemeData.light(useMaterial3: true).colorScheme.surface,
      onSurface: ThemeData.light(useMaterial3: true).colorScheme.onSurface,
      primaryContainer: cardColorLight,
      secondaryContainer: lightDropLight,
      outline: borderLight);

  static final darkColorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: ThemeData.dark(useMaterial3: true).colorScheme.primary,
      onPrimary: ThemeData.dark(useMaterial3: true).colorScheme.onPrimary,
      secondary: ThemeData.dark(useMaterial3: true).colorScheme.secondary,
      onSecondary: ThemeData.dark(useMaterial3: true).colorScheme.onSecondary,
      error: ThemeData.dark(useMaterial3: true).colorScheme.error,
      onError: ThemeData.dark(useMaterial3: true).colorScheme.onError,
      surface: ThemeData.dark(useMaterial3: true).colorScheme.surface,
      onSurface: ThemeData.dark(useMaterial3: true).colorScheme.onSurface,
      primaryContainer: cardColorDark,
      secondaryContainer: lightDropDark,
      outline: borderDark);
  // Brand
  static final brandColor = const Color(0xFF0057BE);
  static final brandDisableLight = const Color(0xFF0057BE).withOpacity(0.4);
  static final brandDisableDark = const Color(0xFF0057BE).withOpacity(0.4);

  // Accent
  static final accentLight = const Color(0xFF00A8FF);
  static final accentDark = const Color(0xFF00A8FF);

  // Orange accent (bosh sahifa qidiruv kartasi — swap tugmasi, "Bilet izlash")
  static final accentOrange = const Color(0xFFF5A623);
  static final accentOrangeDark = const Color(0xFFE0940F);

  // Switch active (bosh sahifadagi "Bagaj bilan" toggle'i)
  static final switchGreen = const Color(0xFF34C759);

  // Background
  static final backgroundLight = const Color(0xFFECECEC);
  static final backgroundDark = const Color(0xFF1C1C1C);

  // Text
  static final textColorLight = const Color(0xFF1C1C1C);
  static final textColorDark = const Color(0xFFF8F8F8);

  static final secondaryTextLight = const Color(0xFF8E8E92);
  static final secondaryTextDark = const Color(0xFFCCCFD3);

  // Border
  static final borderLight = const Color(0xFFDBDCDF);
  static final borderDark = const Color(0xFF5B5B5B);

  // Card
  static final cardColorLight = const Color(0xFFFFFFFF);
  static final cardColorDark = const Color(0xFF2F2F2F);

  // Input
  static final inputColorLight = const Color(0xFFD5DEE8);
  static final inputColorDark = const Color(0xFF4A4A4A);

  // Disabled
  static final disabledBackgroundLight = const Color(0xFFE1E2E4);
  static final disabledBackgroundDark = const Color(0xFF3B3B41);

  static final disabledTextLight = const Color(0xFFA7A7AA);
  static final disabledTextDark = const Color(0xFFB2B2B2);

  // Link
  static final linkLight = const Color(0xFF0A84FF);
  static final linkDark = const Color(0xFF0A84FF);

  // Purple
  static final purpleLight = const Color(0xFF9A3BFF);
  static final purpleDark = const Color(0xFF9A3BFF);

  // Light Background Variants
  static final blueBgLight = const Color(0xFFD5DEE8);
  static final blueBg = const Color(0xFF00A8FF);

  static final greenBgLight = const Color(0xFFE9F7EF);
  static final purpleBgLight = const Color(0xFFEBD8FF);
  static final redBgLight = const Color(0xFFF8D7D3);
  static final swimmer200 = const Color(0xFFE4ECF4);

  // Base
  static final white = const Color(0xFFFFFFFF);
  static final black = const Color(0xFF000000);

  static final backdropLight = const Color(0xFF000000).withOpacity(0.3); // 30%
  static final backdropDark = const Color(0xFF151515).withOpacity(0.3); // 30%

  static final shadowDropLight =
      const Color(0xFFC6C7C9).withOpacity(0.5); // 50%
  static final shadowDropDark = const Color(0xFF000000).withOpacity(0.3); // 30%

  static final lightDropLight =
      const Color(0xFFC6C7C9).withOpacity(0.15); // 15%
  static final lightDropDark = const Color(0xFF151515).withOpacity(0.15); // 15%

  static final lightDrop2Light =
      const Color(0xFF6E6E6E).withOpacity(0.15); // 15%
  static final lightDrop2Dark =
      const Color(0xFF151515).withOpacity(0.15); // 15%

  // Helper
  static final error = const Color(0xFFD92D20);
  static final success = const Color(0xFF27AE60);
  static final successDisabled =
      const Color(0xFF27AE60).withOpacity(0.4); // 40%
  static final warning = const Color(0xFFE2AE12);
  static final containerShadow = const Color(0xFF6E6E6E).withOpacity(0.15);

  // Gradient

  // Styles
  static final greenButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: success,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      foregroundColor: white,
      textStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 16));
  static final blueButtonStyle = ElevatedButton.styleFrom(
      disabledBackgroundColor: brandColor.withAlpha(60),
      backgroundColor: brandColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      foregroundColor: white,
      textStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 16));
  static final orangeButtonStyle = ElevatedButton.styleFrom(
      elevation: 0.0,
      disabledBackgroundColor: accentOrange.withAlpha(90),
      backgroundColor: accentOrange,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      foregroundColor: white,
      textStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 16));
  static final disabledButtonDarkStyle = ElevatedButton.styleFrom(
      backgroundColor: lightDrop2Dark,
      elevation: 0.0,
      overlayColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      foregroundColor: black,
      textStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 16));
  static final disabledButtonLightStyle = ElevatedButton.styleFrom(
      backgroundColor: lightDrop2Light,
      elevation: 0.0,
      overlayColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      foregroundColor: black,
      textStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 16));
  static final blueBorderButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: brandColor, width: 1)),
      foregroundColor: brandColor,
      textStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 16));
}
