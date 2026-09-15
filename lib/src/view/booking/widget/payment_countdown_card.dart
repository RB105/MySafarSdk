import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/model/local/payment_type.dart';
import 'package:mysafar_sdk/src/view/booking/support/payment_helper.dart';

/// To'lov uchun qolgan vaqt — sahifa tepasiga qadalgan gradient karta:
/// chapda sarlavha va izoh, o'ngda katta taymer (raqamlar aylanib almashadi),
/// pastda ingichka progress chizig'i. Rang holatga qarab: odatiy — brend,
/// 5 daqiqadan kam — to'q sariq, tugagan — qizil.
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
    final isExpired = seconds <= 0;
    final low = !isExpired && seconds < lowTimeThresholdSeconds;
    final brand = ProjectTheme.brandColor;

    final List<Color> gradient = isExpired
        ? const [Color(0xFFE5484D), Color(0xFFB42318)]
        : low
            ? const [Color(0xFFF59F00), Color(0xFFE8590C)]
            : [
                Color.lerp(brand, Colors.white, 0.10)!,
                Color.lerp(brand, Colors.black, 0.30)!,
              ];
    final Color shadow = gradient.last.withValues(
      alpha: context.isDarkMode ? 0.0 : 0.22,
    );

    final progress =
        (seconds / PaymentConstants.paymentTimeLimitSeconds).clamp(0.0, 1.0);
    // Satr oxiridagi ":" olib tashlanadi — taymer alohida ko'rsatiladi.
    final title =
        (isExpired ? 'payment_time_expired'.tr() : 'payment_time_left'.tr())
            .replaceFirst(RegExp(r'[:\s]+$'), '');
    final hint = !isExpired
        ? 'payment_time_hint'.tr()
        : researching
            ? 'payment_expired_researching'.tr()
            : 'payment_expired_hint'.tr();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadow,
            blurRadius: 20,
            spreadRadius: -6,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodyMedium?.copyWith(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hint,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 12.5,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _TimerPill(
                seconds: seconds,
                expired: isExpired,
                researching: researching,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: progress),
              duration: const Duration(milliseconds: 900),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 4,
                color: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerPill extends StatelessWidget {
  const _TimerPill({
    required this.seconds,
    required this.expired,
    required this.researching,
  });

  final int seconds;
  final bool expired;
  final bool researching;

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (!expired) {
      content = _RollingText(
        PaymentHelper.formatDuration(seconds),
        style: context.textTheme.bodyLarge!.copyWith(
          fontSize: 28,
          height: 1.1,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
    } else if (researching) {
      content = const SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
      );
    } else {
      content = Text(
        '00:00',
        style: context.textTheme.bodyLarge!.copyWith(
          fontSize: 28,
          height: 1.1,
          fontWeight: FontWeight.w800,
          color: Colors.white.withValues(alpha: 0.7),
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
    }

    return Semantics(
      label: expired ? null : PaymentHelper.formatDuration(seconds),
      child: Container(
        constraints: const BoxConstraints(minWidth: 96, minHeight: 50),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: ExcludeSemantics(child: content),
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
