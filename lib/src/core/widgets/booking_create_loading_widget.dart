import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';

class LoadingDialog {
  static bool _isDialogShowing = false;

  static void show(BuildContext context) {
    if (_isDialogShowing) return;
    _isDialogShowing = true;

    showDialog(
      useRootNavigator: false,
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(50),
      builder: (BuildContext context) {
        // Bron yaratilayotganda tizim "orqaga" oynani yopmasin: aks holda
        // javob kelganda dismiss() oyna o'rniga bron sahifasining o'zini
        // yopib yuborardi va foydalanuvchi qayta "Davom etish"ni bosib ikkinchi
        // bron yaratishi mumkin edi.
        return PopScope(
          canPop: false,
          child: Center(
            child: SizedBox(
              width: context.width * 0.8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.color.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 152,
                      height: 152,
                      child: Lottie.asset(
                        'packages/mysafar_sdk/assets/img/booking/airplane.json',
                        repeat: true,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: 16, right: 16, left: 16),
                      child: Text(
                        "booking_in_progress_notice".tr(),
                        style: context.textTheme.bodyMedium
                            ?.copyWith(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      // Oyna qanday yopilmasin (dismiss yoki route bilan birga) — holat
      // tozalanadi, keyingi show() o'tkazib yuborilmaydi.
    ).whenComplete(() => _isDialogShowing = false);
  }

  static void dismiss(BuildContext context) {
    if (_isDialogShowing) {
      // Dialog SDK navigatorida ochilgan (show'da useRootNavigator: false) —
      // yopish ham o'sha navigatorda bo'lishi shart. rootNavigator: true embed
      // rejimda HOST (Unired) route'ini yopib yuborardi: booking xatosida
      // foydalanuvchi to'satdan host to'lovlar ekraniga otilib ketardi.
      Navigator.of(context).pop();
      _isDialogShowing = false;
    }
  }
}
