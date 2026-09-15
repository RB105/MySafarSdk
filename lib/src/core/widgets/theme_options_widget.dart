import 'package:mysafar_sdk/src/core/styles/theme_notifier.dart'
    show ThemeNotifier;
import 'package:mysafar_sdk/src/core/widgets/sdk_dialog.dart'
    show SdkSheetFrame;
import 'package:mysafar_sdk/src/core/widgets/sdk_option_sheet.dart';
import 'package:mysafar_sdk/src/generated/assets.dart' show Assets;
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:provider/provider.dart' show Provider;

/// Mavzu tanlash sheet'i — til/valyuta sheet'lari bilan bir xil ko'rinish.
class ThemeOptionsWidget extends StatelessWidget {
  const ThemeOptionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return SdkSheetFrame(
      child: SdkOptionList<ThemeMode>(
        title: "theme".tr(),
        selected: themeNotifier.themeMode,
        options: [
          _option(context, ThemeMode.system, "system".tr(),
              Assets.profileSystemColorIcon),
          _option(context, ThemeMode.light, "light".tr(),
              Assets.profileLightModeIcon),
          _option(
              context, ThemeMode.dark, "dark".tr(), Assets.profileDarkModeIcon),
        ],
        onSelected: (mode) {
          themeNotifier.setTheme(mode);
          Navigator.pop(context);
        },
      ),
    );
  }

  SdkOptionItem<ThemeMode> _option(
    BuildContext context,
    ThemeMode mode,
    String title,
    String icon,
  ) {
    final bool isDark = context.isDarkMode;
    final Color brand = ProjectTheme.brandColor;
    return SdkOptionItem(
      value: mode,
      title: title,
      leading: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : brand.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: SvgPicture.asset(
          icon,
          width: 20,
          height: 20,
          colorFilter:
              ColorFilter.mode(isDark ? Colors.white : brand, BlendMode.srcIn),
        ),
      ),
    );
  }
}
