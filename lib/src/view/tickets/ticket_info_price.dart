// ignore_for_file: unused_element
// part of ticket_info_page.dart

part of 'ticket_info_page.dart';

/// Tafsilot sheet'i uchun umumiy sokin ranglar (bron sahifasi bilan bir xil).
Color _tiMuted(BuildContext context) => context.isDarkMode
    ? ProjectTheme.secondaryTextDark
    : const Color(0xFF5B6475);

Color _tiTonal(BuildContext context) => context.isDarkMode
    ? Colors.white.withValues(alpha: 0.06)
    : const Color(0xFFF1F4F9);

Color _tiText(BuildContext context) => context.isDarkMode
    ? ProjectTheme.textColorDark
    : ProjectTheme.textColorLight;

/// Oddiy oq karta — soyasiz, radius 20.
class _TiCard extends StatelessWidget {
  final Widget child;

  const _TiCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.color.primaryContainer,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _FareRuleItem extends StatelessWidget {
  final String iconAsset;
  final String label;
  final bool positive;

  const _FareRuleItem({
    required this.iconAsset,
    required this.label,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shart yo'q bo'lsa ikonka ustidan qizil chiziq tortiladi.
          FareStatusIcon(asset: iconAsset, positive: positive),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium?.copyWith(
                fontSize: 13.5,
                height: 1.3,
                fontWeight: FontWeight.w600,
                // Salbiy shart ham o'qiladi, lekin e'tiborni tortmaydi —
                // rang ma'nosini ikonka beradi.
                color: positive ? _tiText(context) : _tiMuted(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
