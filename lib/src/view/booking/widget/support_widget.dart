import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// Bron sahifasi tepasidagi yordam kartasi: naushnik ikonkasi + sarlavha +
/// bosiladigan telefon raqami. Dizayn maketiga mos — oq karta, ichida och
/// ko'k kvadrat ikonka.
class SupportWidget extends StatelessWidget {
  const SupportWidget({super.key});

  static const String _phone = "+998 55 512 00 08";

  Future<void> _call() async {
    // MUHIM: `tel:` path'da bo'shliq bo'lmasligi kerak — aks holda URI
    // buziladi va telefon ilovasi ochilmaydi.
    final Uri phoneUri = Uri(scheme: 'tel', path: _phone.replaceAll(' ', ''));
    try {
      await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Terish ilovasi mavjud emas (masalan planshet) — jim o'tkazamiz.
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    final brand = ProjectTheme.brandColor;

    return BookingCard(
      padding: const EdgeInsets.all(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _call,
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withAlpha(20)
                    : ProjectTheme.swimmer200,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Image.asset(
                'packages/mysafar_sdk/assets/img/home/icons/support_ic.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "need_help_ticket".tr(),
                    style: context.textTheme.bodyLarge?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _phone,
                    style: TextStyle(
                      fontFamily: "packages/mysafar_sdk/Gilroy",
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: brand,
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
}

/// Bron sahifasidagi barcha bloklar uchun umumiy oq karta.
class BookingCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const BookingCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.color.primaryContainer,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}
