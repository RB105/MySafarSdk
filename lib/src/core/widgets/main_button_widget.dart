// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/widgets/loading_widget.dart';
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart';

class MainButtonWidget extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final double? size;
  final String? icon;
  final bool? isLoading;
  final Color? backColor;

  /// Funnel analytics uchun barqaror tugma identifikatori.
  /// Berilmasa [title] ishlatiladi.
  final String? analyticsId;
  const MainButtonWidget(
      {super.key,
      required this.title,
      this.onTap,
      this.size,
      this.icon,
      this.isLoading,
      this.backColor,
      this.analyticsId});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
          onPressed: onTap == null
              ? null
              : () {
                  AnalyticsService().trackButtonTap(analyticsId ?? title);
                  onTap!.call();
                },
          style: ElevatedButton.styleFrom(
              backgroundColor: backColor ?? ProjectTheme.brandColor,
              disabledBackgroundColor: ProjectTheme.brandColor.withOpacity(.4),
              minimumSize: Size(double.infinity, size ?? 40),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon != null ? SvgPicture.asset(icon!) : SizedBox.shrink(),
              isLoading != null && isLoading!
                  ? LoadingWidgetButton()
                  : SizedBox.shrink(),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                    color: Color(0xffFFFFFF),
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
              ),
            ],
          )),
    );
  }
}

class MainButtonWidgetCustom extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final double? size;

  /// Funnel analytics uchun barqaror tugma identifikatori.
  /// Berilmasa [title] ishlatiladi.
  final String? analyticsId;
  const MainButtonWidgetCustom(
      {super.key,
      required this.title,
      required this.onTap,
      this.size,
      this.analyticsId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: context.k16horizontalPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
              onPressed: () {
                AnalyticsService().trackButtonTap(analyticsId ?? title);
                onTap.call();
              },
              style: ElevatedButton.styleFrom(
                  maximumSize: Size(double.infinity, size ?? 40),
                  backgroundColor: ProjectTheme.brandColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.radius8))),
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(
                      color: Color(0xffFFFFFF),
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
              )),
        ],
      ),
    );
  }
}
