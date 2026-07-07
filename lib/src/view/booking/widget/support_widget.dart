import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportWidget extends StatelessWidget {
  const SupportWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    final brand = ProjectTheme.brandColor;
    final accent = ProjectTheme.accentLight;
    final muted = isDark
        ? ProjectTheme.secondaryTextDark
        : ProjectTheme.secondaryTextLight;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [brand.withAlpha(60), accent.withAlpha(28)]
              : [const Color(0xffEAF2FE), const Color(0xffF1F7FF)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: brand.withAlpha(isDark ? 90 : 45)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [brand, accent],
              ),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: brand.withAlpha(75),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.headset_mic_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "have_questions".tr(),
                  style: context.textTheme.bodyLarge
                      ?.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    // MUHIM: `tel:` path'da bo'shliq bo'lmasligi kerak — aks
                    // holda URI buziladi va telefon ilovasi ochilmaydi.
                    final Uri phoneUri =
                        Uri(scheme: 'tel', path: "+998555120008");
                    try {
                      await launchUrl(phoneUri,
                          mode: LaunchMode.externalApplication);
                    } catch (_) {
                      // Terish ilovasi mavjud emas (masalan planshet) — jim
                      // o'tkazamiz, ilovani yiqitmaymiz.
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          "call_us".tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.titleSmall
                              ?.copyWith(fontSize: 12.5, color: muted),
                        ),
                      ),
                      const SizedBox(width: 7),
                      SvgPicture.asset(
                        "assets/img/booking/phone_icon.svg",
                        width: 13,
                        height: 13,
                        colorFilter:
                            ColorFilter.mode(brand, BlendMode.srcIn),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        "+998 55 512 00 08",
                        style: TextStyle(
                          fontFamily: "Gilroy",
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: brand,
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
    );
  }
}
