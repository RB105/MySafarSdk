import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:flutter/material.dart';

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

  static Future<void> errorState(
    String error,
    BuildContext context,
  ) async {
    showDialog(useRootNavigator: false, 
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: context.color.primaryContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Center(child:
                  Icon(
                  Icons.close,
                  color: Color(0xffEF2323),
                  size: 36,
                )),
                const SizedBox(height: 16),
                 Text(
                  error,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0060FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child:  Text(
                      "retry".tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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
