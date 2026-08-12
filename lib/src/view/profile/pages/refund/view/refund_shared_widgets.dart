import 'package:flutter/services.dart'
    show HapticFeedback, TextEditingValue, TextInputFormatter, TextSelection;
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

import '../service/refund_models.dart';

/// Ariza holati chipi — rangi va ikonkasi [RefundStatus] dan olinadi.
class RefundStatusChip extends StatelessWidget {
  final RefundStatus status;
  final bool compact;

  const RefundStatusChip({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    final Color c = status.color;
    // Matn fon ustida o'qilishi uchun: yorug' temada quyuqroq, qorong'uda
    // ochroq variant (bilet kartasidagi status chip bilan bir xil qoida).
    final Color textColor = isDark
        ? Color.lerp(c, Colors.white, 0.25)!
        : Color.lerp(c, Colors.black, 0.30)!;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: c.withAlpha(isDark ? 46 : 26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withAlpha(110), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: compact ? 12 : 14, color: textColor),
          const SizedBox(width: 5),
          Text(
            status.labelKey.tr(),
            style: context.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: compact ? 11 : 12,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Yorliq — qiymat" qatori. Qiymat o'ngda, uzun bo'lsa qisqartiriladi.
class RefundInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final int maxLines;

  const RefundInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    final secondary = context.themeProvider.isDark
        ? ProjectTheme.secondaryTextDark
        : ProjectTheme.secondaryTextLight;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: secondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium?.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sahifadagi barcha bloklar uchun yagona "karta" konteyneri —
/// bilet kartasi bilan bir xil radius/soya/chegara tili.
class RefundCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  /// Berilsa karta bosiladigan bo'ladi (ripple bilan) — masalan ariza
  /// kartasi to'liq ma'lumot oynasini ochadi.
  final VoidCallback? onTap;

  const RefundCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    final BorderRadius radius = BorderRadius.circular(18);
    final Widget content = Padding(padding: padding, child: child);

    return Container(
      width: double.infinity,
      // Soya konteynerda qoladi, fon va ripple esa Material'da — shunda
      // bosilganda to'lqin effekti karta ostida ko'rinmay qolmaydi.
      decoration: BoxDecoration(borderRadius: radius, boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withAlpha(60)
              : const Color(0x80C6C7C9).withAlpha(90),
          offset: const Offset(0, 4),
          blurRadius: 12,
        ),
      ]),
      child: Material(
        color: context.color.primaryContainer,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: borderColor ??
                (isDark
                    ? Colors.white.withAlpha(15)
                    : Colors.black.withAlpha(8)),
            width: 1,
          ),
        ),
        child: onTap == null
            ? content
            : InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
                child: content,
              ),
      ),
    );
  }
}

/// Karta raqamini kiritishda har 4 raqamdan keyin probel qo'yadi va
/// 19 raqamdan oshirmaydi (backend 13–19 raqamni qabul qiladi).
class CardNumberInputFormatter extends TextInputFormatter {
  static const int maxDigits = 19;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final trimmed = digits.length > maxDigits
        ? digits.substring(0, maxDigits)
        : digits;

    final buffer = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      if (i != 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(trimmed[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
