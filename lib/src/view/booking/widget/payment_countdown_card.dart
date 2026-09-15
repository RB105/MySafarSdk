import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/view/booking/support/payment_helper.dart';

/// To'lov uchun qolgan vaqt — minimalistik bir qatorli karta: chapda sarlavha
/// va izoh, o'ngda taymer (raqamlar aylanib almashadi). Karta doim neytral;
/// holatni faqat taymer rangi bildiradi: 5 daqiqadan kam — to'q sariq,
/// tugagan — qizil `00:00`.
class PaymentCountdownCard extends StatelessWidget {
  const PaymentCountdownCard({
    super.key,
    required this.remaining,
    this.researching = false,
  });

  /// Qolgan soniyalar — soniyalik yangilanish faqat shu kartani qayta chizadi.
  final ValueListenable<int> remaining;

  /// Vaqt tugagach chiptalar sahifasiga qaytib qayta qidirilyaptimi —
  /// taymer o'rnida spinner va "qayta qidirilmoqda" matni chiqadi.
  final bool researching;

  /// Shundan kam vaqt qolganda taymer ogohlantirish rangiga o'tadi.
  static const int lowTimeThresholdSeconds = 300;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: remaining,
      builder: (context, seconds, _) => _buildCard(context, seconds),
    );
  }

  Widget _buildCard(BuildContext context, int seconds) {
    final isDark = context.isDarkMode;
    final isExpired = seconds <= 0;
    final low = !isExpired && seconds < lowTimeThresholdSeconds;

    // `null` — oddiy matn rangi.
    final Color? timerColor = isExpired
        ? (isDark ? const Color(0xFFFF6B61) : ProjectTheme.error)
        : low
            ? (isDark ? const Color(0xFFFFA94D) : const Color(0xFFE8590C))
            : null;

    // Satr oxiridagi ":" olib tashlanadi — taymer alohida ko'rsatiladi.
    final title =
        (isExpired ? 'payment_time_expired'.tr() : 'payment_time_left'.tr())
            .replaceFirst(RegExp(r'[:\s]+$'), '');
    final hint = !isExpired
        ? 'payment_time_hint'.tr()
        : researching
            ? 'payment_expired_researching'.tr()
            : 'payment_expired_hint'.tr();
    final timerStyle = context.textTheme.bodyLarge!.copyWith(
      fontSize: 22,
      height: 1.1,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
      color: timerColor,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final Widget timer;
    if (isExpired && researching) {
      timer = SizedBox.square(
        dimension: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: timerColor),
      );
    } else {
      final text = PaymentHelper.formatDuration(seconds);
      timer = Semantics(
        label: text,
        child: ExcludeSemantics(child: _RollingText(text, style: timerStyle)),
      );
    }

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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  maxLines: 2,
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
          timer,
        ],
      ),
    );
  }
}

/// Har bir belgi o'zgarganda pastdan yuqoriga siljib almashadi
/// (faqat o'zgargan raqam harakatlanadi).
class _RollingText extends StatelessWidget {
  const _RollingText(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < text.length; i++)
          ClipRect(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.center,
                children: [...previous, if (current != null) current],
              ),
              transitionBuilder: (child, animation) {
                final incoming = child.key == ValueKey('$i-${text[i]}');
                final offset = Tween<Offset>(
                  begin: Offset(0, incoming ? 0.6 : -0.6),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: offset, child: child),
                );
              },
              child:
                  Text(text[i], key: ValueKey('$i-${text[i]}'), style: style),
            ),
          ),
      ],
    );
  }
}
