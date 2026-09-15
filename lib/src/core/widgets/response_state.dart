import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart';
import 'package:mysafar_sdk/src/core/widgets/sdk_dialog.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart'
    show Clipboard, ClipboardData, HapticFeedback;

/// Server javobi natijasini ko'rsatadigan umumiy holat dialoglari:
/// muvaffaqiyat (yashil) va xatolik (qizil).
class ResponseState {
  /// Muvaffaqiyat dialogi. E'tibor: [onPressed] dialogni YOPMAYDI —
  /// yopish chaqiruvchining zimmasida (mavjud shartnoma saqlangan).
  static Future<void> successState(BuildContext context, String success,
      void Function() onPressed) async {
    HapticFeedback.lightImpact();
    return _showStatusDialog(
      context,
      tone: SdkDialogTone.success,
      title: "successful".tr(),
      message: success,
      buttonText: "close".tr(),
      onPressed: onPressed,
    );
  }

  /// Muvaffaqiyatsiz urinish dialogi — umumiy sarlavhasiz, faqat serverdan
  /// kelgan aniq xabar ko'rsatiladi. [onRetry] berilsa ikkita tugma
  /// ko'rsatiladi: ikkinchi darajali "Yopish" va asosiy "Qayta urinish".
  ///
  /// [copyableId] / [tid] berilsa (masalan booking `tr_id`) xabar ostida
  /// nusxalanadigan ID ko'rsatiladi.
  static Future<void> errorState(
    String error,
    BuildContext context, {
    String? copyableId,
    @Deprecated('Use copyableId') String? tid,
    VoidCallback? onRetry,
  }) async {
    HapticFeedback.mediumImpact();
    return _showStatusDialog(
      context,
      tone: SdkDialogTone.error,
      title: null,
      message: error,
      buttonText: "understand_close".tr(),
      copyableId: copyableId ?? tid,
      onRetry: onRetry,
    );
  }

  static Future<void> _showStatusDialog(
    BuildContext context, {
    required SdkDialogTone tone,
    required String? title,
    required String message,
    required String buttonText,
    VoidCallback? onPressed,
    String? copyableId,
    VoidCallback? onRetry,
  }) {
    final String? id =
        copyableId?.trim().isNotEmpty == true ? copyableId!.trim() : null;
    return showSdkAlert<void>(
      context: context,
      tone: tone,
      barrierDismissible: false,
      title: title,
      message: message,
      content: id == null ? null : _CopyableIdField(id: id),
      actions: [
        if (onRetry != null) ...[
          SdkDialogAction(
            label: "retry_action".tr(),
            onTap: (dialogContext) {
              Navigator.of(dialogContext).pop();
              onRetry();
            },
          ),
          SdkDialogAction(
            label: "close".tr(),
            variant: SdkDialogButtonVariant.secondary,
          ),
        ] else
          SdkDialogAction(
            label: buttonText,
            onTap: onPressed == null ? null : (_) => onPressed(),
          ),
      ],
    );
  }
}

class _CopyableIdField extends StatelessWidget {
  const _CopyableIdField({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final brand = SdkDialogTone.info.color(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: sdkDialogMutedFill(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'request_id'.tr(),
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  id,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: brand.withValues(alpha: context.isDarkMode ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                Clipboard.setData(ClipboardData(text: id)).then((_) {
                  if (context.mounted) {
                    ProjectDialogs.showCustomToast(context, 'id_copied'.tr());
                  }
                });
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      Assets.iconsDialogCopyIcon,
                      width: 16,
                      height: 16,
                      colorFilter: ColorFilter.mode(brand, BlendMode.srcIn),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'copy'.tr(),
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: brand,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
