import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

class ResponseState {
  static Future<void> successState(BuildContext context, String success, void Function() onPressed) async {
    showDialog(useRootNavigator: false, 
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: context.color.primaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Icon(
                    Icons.check_circle_outline,
                    color: Color(0xff27AE60),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  success,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontSize: 16,fontWeight: FontWeight.w500
                  )
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: context.height * 0.062,
                  child: ElevatedButton(
                    style: ProjectTheme.blueButtonStyle,
                    onPressed:onPressed,
                    child: Text(
                      "close".tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Umumiy xato dialogi. [tid] berilsa (masalan bronlashda) foydalanuvchi
  /// uni nusxalab qo'llab-quvvatga yuborishi mumkin — mobile ilova bilan bir xil.
  static Future<void> errorState(
    String error,
    BuildContext context, {
    String? tid,
  }) async {
    final tidValue = tid?.trim() ?? '';
    final hasTid = tidValue.isNotEmpty;

    showDialog(
      useRootNavigator: false,
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final brand = ProjectTheme.brandColor;
        final isDark = dialogContext.isDarkMode;

        return Dialog(
          backgroundColor: dialogContext.color.primaryContainer,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xffEF2323),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'error_occurred'.tr(),
                  textAlign: TextAlign.center,
                  style: dialogContext.textTheme.bodyLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: dialogContext.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (hasTid) ...[
                  const SizedBox(height: 16),
                  _TidCopyBox(
                    tid: tidValue,
                    brand: brand,
                    isDark: isDark,
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brand,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    child: Text(
                      'understand_close'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Xato dialogidagi TID qatori — label + qiymat + "Nusxalash" tugmasi.
class _TidCopyBox extends StatelessWidget {
  final String tid;
  final Color brand;
  final bool isDark;

  const _TidCopyBox({
    required this.tid,
    required this.brand,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? const Color(0xffCCCFD3) : const Color(0xff8E8E92);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: brand.withAlpha(isDark ? 30 : 15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: brand.withAlpha(60)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'tid',
                  style: TextStyle(
                    fontFamily: 'packages/mysafar_sdk/Gilroy',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tid,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: brand,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: tid)).then((_) {
                if (context.mounted) {
                  ProjectDialogs.showCustomToast(context, 'id_copied'.tr());
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: brand.withAlpha(isDark ? 46 : 25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: brand.withAlpha(80)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy, size: 14, color: brand),
                  const SizedBox(width: 6),
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
        ],
      ),
    );
  }
}
