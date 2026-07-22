import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/tools/currency_provider.dart';
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
  const NextButtonWidget(
      {super.key,
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

    return Container(
      decoration: BoxDecoration(
        boxShadow: context.shadowUp,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        color: context.color.primaryContainer,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "${"ticket_price".tr()}:",
                    style: context.textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currencyProvider.getElementPrice(price!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: "packages/mysafar_sdk/Gilroy",
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: brand,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                "total_price_label".tr(namedArgs: {"count": "$passenger"}),
                style: TextStyle(
                  fontFamily: "packages/mysafar_sdk/Gilroy",
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: muted,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 56,
                width: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: loading || onPressed == null
                        ? null
                        : () {
                            AnalyticsService()
                                .trackButtonTap(analyticsId ?? nextTittle);
                            onPressed!.call();
                          },
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: buttonColor,
                        boxShadow: disabled
                            ? null
                            : [
                                BoxShadow(
                                  color: brand.withAlpha(70),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                      ),
                      child: Center(
                        child: loading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    nextTittle.tr(),
                                    style: TextStyle(
                                      fontFamily: "packages/mysafar_sdk/Gilroy",
                                      fontSize: 16,
                                      color: contentColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded,
                                      color: contentColor, size: 19),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
