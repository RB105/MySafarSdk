// ignore_for_file: unused_element
// part of ticket_info_page.dart

part of 'ticket_info_page.dart';

class _MapRouteButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MapRouteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final brand = isDark ? ProjectTheme.accentLight : ProjectTheme.brandColor;
    final secondary = isDark
        ? ProjectTheme.secondaryTextDark
        : ProjectTheme.secondaryTextLight;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: brand.withAlpha(isDark ? 38 : 20),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: brand.withAlpha(isDark ? 90 : 60)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [ProjectTheme.brandColor, ProjectTheme.blueBg],
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.public_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "route_map_title".tr(),
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: brand,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "route_map_subtitle".tr(),
                      style: context.textTheme.titleSmall?.copyWith(
                        fontSize: 11.5,
                        color: secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: brand, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  BOOK BUTTON
// ════════════════════════════════════════════════════════════════════

class _BookButton extends StatefulWidget {
  final String priceLabel;
  final VoidCallback onTap;
  final bool enabled;
  final bool isLoading;

  /// Narx necha kishi uchunligi ("Umumiy narx 2 kishi uchun").
  final int passengerCount;

  const _BookButton({
    required this.priceLabel,
    required this.onTap,
    this.enabled = true,
    this.isLoading = false,
    this.passengerCount = 1,
  });

  @override
  State<_BookButton> createState() => _BookButtonState();
}

/// Pastki panel: chapda umumiy narx, o'ngda katta "Buyurtma berish" tugmasi
/// (54px, bosilganda biroz kichrayadi). Reys tekshirilayotganda — spinner,
/// bron qilib bo'lmasa — kulrang.
class _BookButtonState extends State<_BookButton> {
  bool _pressed = false;

  bool get _tappable => widget.enabled && !widget.isLoading;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final brand = ProjectTheme.brandColor;
    final muted =
        isDark ? ProjectTheme.secondaryTextDark : const Color(0xFF5B6475);
    final priceColor =
        isDark ? ProjectTheme.textColorDark : ProjectTheme.textColorLight;

    final bool unavailable = !widget.enabled && !widget.isLoading;
    final Color buttonColor = unavailable
        ? (isDark
            ? Colors.white.withValues(alpha: 0.10)
            : const Color(0xFFE3E7F0))
        : widget.isLoading
            ? brand.withValues(alpha: 0.65)
            : brand;
    final Color contentColor = unavailable ? muted : Colors.white;

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "total_price_label"
                    .tr(namedArgs: {"count": "${widget.passengerCount}"}),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: muted,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.priceLabel,
                  maxLines: 1,
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    color: priceColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: Semantics(
            button: true,
            enabled: _tappable,
            label: "book_ticket".tr(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: _tappable ? (_) => _setPressed(true) : null,
              onTapCancel: () => _setPressed(false),
              onTapUp: _tappable
                  ? (_) {
                      _setPressed(false);
                      widget.onTap();
                    }
                  : null,
              child: AnimatedScale(
                scale: _pressed ? 0.96 : 1,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 54,
                  decoration: BoxDecoration(
                    color: buttonColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: unavailable || widget.isLoading
                        ? null
                        : [
                            BoxShadow(
                              color: brand.withValues(alpha: 0.28),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  child: widget.isLoading
                      ? const CupertinoActivityIndicator(
                          radius: 11,
                          color: Colors.white,
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                "book_ticket".tr(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.textTheme.bodyLarge?.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: contentColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SvgPicture.asset(
                              Assets.iconsBookingArrowRightIcon,
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                  contentColor, BlendMode.srcIn),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
