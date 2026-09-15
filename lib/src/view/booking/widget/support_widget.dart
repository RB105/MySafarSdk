import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:url_launcher/url_launcher.dart';

/// Bron sahifasi tepasidagi yordam kartasi: naushnik ikonkasi + sarlavha +
/// bosiladigan telefon raqami. Dizayn maketiga mos — oq karta, ichida och
/// ko'k kvadrat ikonka.
class SupportWidget extends StatelessWidget {
  const SupportWidget({super.key});

  String get _phone => MySafarSdk.config.supportPhone;

  Future<void> _call() => callSupport();

  /// Qo'llab-quvvatlash raqamiga qo'ng'iroq (masalan app bar tugmasidan).
  static Future<void> callSupport() async {
    final phone = MySafarSdk.config.supportPhone;
    // MUHIM: `tel:` path'da bo'shliq bo'lmasligi kerak — aks holda URI
    // buziladi va telefon ilovasi ochilmaydi.
    final Uri phoneUri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    try {
      await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Terish ilovasi mavjud emas (masalan planshet) — jim o'tkazamiz.
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brand = ProjectTheme.brandColor;

    return BookingCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: _call,
        child: Padding(
          padding: const EdgeInsets.all(14),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? ProjectTheme.textColorDark
                            : ProjectTheme.textColorLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _phone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: "packages/mysafar_sdk/Gilroy",
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? ProjectTheme.secondaryTextDark
                            : const Color(0xFF5B6475),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Qo'ng'iroq tugmasi — karta butunlay bosiladi, bu esa amalni
              // ko'rinadigan qiladi.
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: brand,
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  Assets.iconsBookingCallIcon,
                  width: 20,
                  height: 20,
                  colorFilter:
                      const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
            ],
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? ProjectTheme.cardColorDark : ProjectTheme.cardColorLight,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}
