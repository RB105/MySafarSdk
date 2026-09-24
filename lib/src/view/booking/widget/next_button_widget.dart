import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/tools/currency_provider.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart';
import 'package:provider/provider.dart' show Provider;

import '../../../model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightPrice;

class NextButtonWidget extends StatelessWidget {
  final int passenger;
  final FlightPrice? price;
  final String nextTittle;
  final bool? isLoading;
  final bool showButton;
  final void Function()? onPressed;

  /// Funnel analytics uchun barqaror tugma identifikatori.
  /// Berilmasa [nextTittle] (tarjima kaliti) ishlatiladi.
  final String? analyticsId;

  /// Tugma ostidagi ixtiyoriy qator (masalan, oferta shartlari — №22).
  final Widget? footer;
  const NextButtonWidget(
      {super.key,
      this.footer,
      this.isLoading,
      required this.nextTittle,
      required this.passenger,
      required this.price,
      required this.showButton,
      required this.onPressed,
      this.analyticsId});

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final brand = ProjectTheme.brandColor;
    final isDark = context.themeProvider.isDark;
    final muted = isDark
        ? ProjectTheme.secondaryTextDark
        : ProjectTheme.secondaryTextLight;
    final loading = isLoading == true;
    // onPressed null bo'lsa (mas. oferta belgilamagan) — tugma o'chirilgan:
    // bosilmaydi va vizual ravishda ham xira ko'rinadi.
    final bool disabled = onPressed == null;
    final Color buttonColor = disabled
        ? (isDark ? Colors.white.withAlpha(28) : const Color(0xffE3E7F0))
        : brand;
    final Color contentColor = disabled ? muted : Colors.white;

    final Color priceColor =
        isDark ? ProjectTheme.textColorDark : ProjectTheme.textColorLight;

    return Container(
      decoration: BoxDecoration(
        color: context.color.primaryContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.07),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Narx hali yo'q bo'lsa (null) narx qatori ko'rsatilmaydi —
              // faqat tugma qoladi.
              if (price != null) ...[
                Text(
                  "total_price_label".tr(namedArgs: {"count": "$passenger"}),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: "packages/mysafar_sdk/Gilroy",
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 2),
                // Uzun summa (masalan so'mda) bir qatorga sig'masa kichrayadi.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    currencyProvider.getElementPrice(price),
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: "packages/mysafar_sdk/Gilroy",
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      color: priceColor,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // Qat'iy balandlik emas — katta tizim shriftida matn
              // sig'maganda tugma o'sadi (№32).
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: disabled
                        ? null
                        : [
                            BoxShadow(
                              color: brand.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Material(
                    color: buttonColor,
                    borderRadius: BorderRadius.circular(14),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: loading || onPressed == null
                          ? null
                          : () {
                              AnalyticsService()
                                  .trackButtonTap(analyticsId ?? nextTittle);
                              onPressed!.call();
                            },
                      child: Center(
                        child: loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        nextTittle.tr(),
                                        maxLines: 2,
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily:
                                              "packages/mysafar_sdk/Gilroy",
                                          fontSize: 16,
                                          color: contentColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SvgPicture.asset(
                                      Assets.iconsBookingArrowRightIcon,
                                      width: 20,
                                      height: 20,
                                      colorFilter: ColorFilter.mode(
                                          contentColor, BlendMode.srcIn),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              if (footer != null) ...[
                const SizedBox(height: 8),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
