
// ignore_for_file: deprecated_member_use

import 'package:mysafar_sdk/src/core/enum/currency.dart';
import 'package:mysafar_sdk/src/core/styles/theme_notifier.dart' show ThemeNotifier;
import 'package:mysafar_sdk/src/core/tools/currency_provider.dart';
import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:provider/provider.dart' show Provider;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  static const String routeName = 'SettingsPage';

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final currencyProvider = Provider.of<CurrencyProvider>(context);

    return Scaffold(
      appBar: AppBar(centerTitle: false, title: Text('settings'.tr())),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: context.k16Padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(context),
            context.szBoxHeight24,
            _buildSectionLabel(context, 'lang_rate'.tr()),
            _buildCard(context, [
              _buildSettingTile(
                context: context,
                icon: Icons.language_rounded,
                iconColor: ProjectTheme.brandColor,
                title: 'lang'.tr(),
                value: context.locale.languageCode.toUpperCase(),
                onTap: () => ProjectDialogs.showLanguageMenu(context),
              ),
              _buildDivider(context),
              _buildSettingTile(
                context: context,
                icon: Icons.payments_rounded,
                iconColor: ProjectTheme.success,
                title: 'rate'.tr(),
                value: currencyProvider.currency.label,
                onTap: () => ProjectDialogs.showCurrencyMenu(context),
              ),
            ]),
            context.szBoxHeight16,
            _buildSectionLabel(context, 'theme'.tr()),
            _buildCard(context, [
              _buildSettingTile(
                context: context,
                icon: _themeIcon(themeNotifier.themeMode),
                iconColor: ProjectTheme.accentLight,
                title: 'theme'.tr(),
                value: themeNotifier.themeMode.name.tr(),
                onTap: () => ProjectDialogs.showThemeMenu(context),
              ),
            ]),
            context.szBoxHeight24,
          ],
        ),
      ),
    );
  }

  IconData _themeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
      case ThemeMode.system:
        return Icons.brightness_auto_rounded;
    }
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF003E8C),
            ProjectTheme.brandColor,
            ProjectTheme.accentLight,
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: ProjectTheme.brandColor.withOpacity(0.30),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -40,
              child: _decorCircle(150, 0.12),
            ),
            Positioned(
              left: -20,
              bottom: -50,
              child: _decorCircle(120, 0.06),
            ),
            Positioned(
              right: 70,
              bottom: -16,
              child: Transform.rotate(
                angle: 0.6,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'settings'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Gilroy',
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'settings_subtitle'.tr(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Gilroy',
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _decorCircle(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
        ),
      );

  Widget _buildSectionLabel(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
        child: Text(
          text.toUpperCase(),
          style: context.textTheme.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: context.disabledTextColor,
          ),
        ),
      );

  Widget _buildCard(BuildContext context, List<Widget> children) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: context.color.primaryContainer,
          boxShadow: context.shadowDown,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(children: children),
        ),
      );

  Widget _buildDivider(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 56),
        child: Divider(
          height: 1,
          thickness: 0.6,
          color: context.theme.dividerColor.withOpacity(0.4),
        ),
      );

  Widget _buildSettingTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              context.szBoxWidth12,
              Expanded(
                child: Text(
                  title,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              context.szBoxWidth8,
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: context.textTheme.titleMedium?.copyWith(
                    color: ProjectTheme.brandColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              context.szBoxWidth8,
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: context.lightDrop2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: context.color.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}