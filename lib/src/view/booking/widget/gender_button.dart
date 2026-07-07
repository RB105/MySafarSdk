import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart';

class GenderButton extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onPressed;

  const GenderButton({
    super.key,
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.themeProvider.isDark;

    final backgroundColor =
        isSelected ? ProjectTheme.brandColor : Colors.transparent;

    final textColor =
        isSelected ? Colors.white : (isDark ? Colors.white : Colors.black);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          AnalyticsService()
              .trackButtonTap('gender_select', extra: {'value': value});
          onPressed.call();
        },
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: context.textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
