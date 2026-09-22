import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/widgets/sdk_dialog.dart'
    show SdkDialogTone;
import 'package:mysafar_sdk/src/generated/assets.dart';

/// To'lov sahifasi yopilgandan keyingi holat.
enum PaymentStatusKind { checking, pending, paid }

/// To'lov holati kartasi — taymer kartasi (`PaymentCountdownCard`) o'rnida,
/// u bilan bir xil ko'rinishda: chapda sarlavha va izoh, o'ngda spinner yoki
/// holat belgisi.
class PaymentStatusCard extends StatelessWidget {
  const PaymentStatusCard({super.key, required this.kind});

  final PaymentStatusKind kind;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final (String title, String hint) = switch (kind) {
      PaymentStatusKind.checking => (
          'payment_checking_title'.tr(),
          'payment_checking_hint'.tr(),
        ),
      PaymentStatusKind.pending => (
          'payment_pending_title'.tr(),
          'payment_pending_hint'.tr(),
        ),
      PaymentStatusKind.paid => (
          'payment_success'.tr(),
          'payment_paid_hint'.tr(),
        ),
    };

    final Widget trailing = switch (kind) {
      PaymentStatusKind.checking => SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: ProjectTheme.brandColor,
          ),
        ),
      PaymentStatusKind.pending => _icon(
          Assets.iconsDialogHourglassIcon,
          SdkDialogTone.warning.color(context),
        ),
      PaymentStatusKind.paid => _icon(
          Assets.iconsDialogSuccessIcon,
          SdkDialogTone.success.color(context),
        ),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? ProjectTheme.cardColorDark : ProjectTheme.cardColorLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.color.outline.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    height: 1.3,
                    color: isDark
                        ? ProjectTheme.secondaryTextDark
                        : ProjectTheme.secondaryTextLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }

  Widget _icon(String asset, Color color) => SvgPicture.asset(
        asset,
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
}
