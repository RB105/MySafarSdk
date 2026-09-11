import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart';
import 'package:flutter/material.dart';
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
      icon: Icons.check_rounded,
      color: ProjectTheme.success,
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
      icon: Icons.refresh_rounded,
      color: ProjectTheme.accentOrange,
      title: null,
      message: error,
      buttonText: "understand_close".tr(),
      copyableId: copyableId ?? tid,
      onRetry: onRetry,
    );
  }

  static Future<void> _showStatusDialog(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String? title,
    required String message,
    required String buttonText,
    VoidCallback? onPressed,
    String? copyableId,
    VoidCallback? onRetry,
  }) {
    final String? id =
        copyableId?.trim().isNotEmpty == true ? copyableId!.trim() : null;
    return showDialog<void>(
      useRootNavigator: false,
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final isDark = dialogContext.isDarkMode;
        final brand = ProjectTheme.brandColor;
        final muted = isDark ? const Color(0xffCCCFD3) : const Color(0xff8E8E92);
        return Dialog(
          backgroundColor: dialogContext.color.primaryContainer,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.92, end: 1),
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                      child: Icon(icon, color: Colors.white, size: 32),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (title != null) ...[
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: dialogContext.textTheme.bodyMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight:
                          MediaQuery.of(dialogContext).size.height * 0.3,
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: dialogContext.textTheme.bodyMedium?.copyWith(
                          fontSize: title == null ? 16 : 14.5,
                          fontWeight:
                              title == null ? FontWeight.w800 : FontWeight.w400,
                          height: 1.45,
                          color: title == null
                              ? null
                              : dialogContext.textTheme.headlineSmall?.color,
                        ),
                      ),
                    ),
                  ),
                  if (id != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                      decoration: BoxDecoration(
                        color: brand.withAlpha(isDark ? 30 : 15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: brand.withAlpha(60)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'request_id'.tr(),
                                  style: TextStyle(
                                    fontFamily: 'packages/mysafar_sdk/Gilroy',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: muted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  id,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: dialogContext.textTheme.bodyLarge
                                      ?.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: brand,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: id))
                                  .then((_) {
                                if (dialogContext.mounted) {
                                  ProjectDialogs.showCustomToast(
                                    dialogContext,
                                    'id_copied'.tr(),
                                  );
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: brand.withAlpha(isDark ? 46 : 25),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: brand.withAlpha(80)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.copy, size: 14, color: brand),
                                  const SizedBox(width: 4),
                                  Text(
                                    'copy'.tr(),
                                    style: dialogContext.textTheme.bodySmall
                                        ?.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: brand,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  if (onRetry != null)
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                side: BorderSide(
                                    color: dialogContext.color.outline),
                              ),
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              child: Text(
                                "close".tr(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: dialogContext.textTheme.bodyMedium
                                    ?.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              style: ProjectTheme.blueButtonStyle,
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                onRetry();
                              },
                              child: Text(
                                "retry_action".tr(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ProjectTheme.blueButtonStyle,
                        onPressed: onPressed ??
                            () => Navigator.of(dialogContext).pop(),
                        child: Text(
                          buttonText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
