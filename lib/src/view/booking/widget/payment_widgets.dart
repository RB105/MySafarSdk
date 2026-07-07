import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart';
import 'package:mysafar_sdk/src/view/booking/widget/card_payment_constants.dart';

/// To'lov tugmasi widgeti
///
/// Loading state va disabled state'ni boshqaradi
class PaymentButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final bool isEnabled;
  final VoidCallback? onPressed;

  /// Funnel analytics uchun barqaror tugma identifikatori.
  /// Berilmasa [text] ishlatiladi.
  final String? analyticsId;

  const PaymentButton({
    super.key,
    required this.text,
    this.isLoading = false,
    this.isEnabled = true,
    this.onPressed,
    this.analyticsId,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: ProjectTheme.brandColor.withAlpha(40),
            backgroundColor: const Color(CardPaymentConstants.brandColorValue),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: isEnabled && !isLoading && onPressed != null
              ? () {
                  AnalyticsService().trackButtonTap(analyticsId ?? text);
                  onPressed!.call();
                }
              : null,
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
        ),
      ),
    );
  }
}

/// Bottom sheet sarlavhasi
class PaymentSheetHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onClose;

  const PaymentSheetHeader({
    super.key,
    required this.title,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Center(
            child: Text(
              title,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: onClose ?? () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}

