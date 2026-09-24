import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/widgets/app_refresh_indicator.dart';
import 'package:mysafar_sdk/src/generated/assets.dart' show Assets;
import 'package:mysafar_sdk/src/model/remote/profile/confirmed_ticket_models.dart';
import 'package:mysafar_sdk/src/view/profile/src/my_ticket_widget.dart';

class TicketList extends StatelessWidget {
  final List<ConfirmedTicketsModel> tickets;
  final Future<void> Function()? onRefresh;

  const TicketList({super.key, required this.tickets, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    final Widget child;
    if (tickets.isEmpty) {
      child = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: bottomInset),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.12),
          OrdersStateView(
            iconAsset: Assets.iconsOrderTicketIcon,
            title: "not_found_booked_tickets".tr(),
          ),
        ],
      );
    } else {
      // removePadding'dan oldin olingan — shisha bottom bar balandligi.
      child = MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        child: ListView.separated(
          scrollCacheExtent: ScrollCacheExtent.pixels(100),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 14, 16, 16 + bottomInset),
          itemCount: tickets.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          // Key — yangilanishdan keyin karta holati (taymer, yuklanish)
          // boshqa buyurtmaga o'tib qolmasin (№88). Indeks — takroriy/bo'sh
          // id'larda ham kalit yagona bo'lsin.
          itemBuilder: (context, index) {
            final t = tickets[index];
            return MyTicketWidget(
              key: ValueKey('order-$index-${t.id}-${t.billingId}'),
              ticketsModel: t,
            );
          },
        ),
      );
    }

    if (onRefresh == null) return child;
    return AppRefreshIndicator(onRefresh: onRefresh!, child: child);
  }
}

/// Buyurtmalar sahifasi holatlari (bo'sh / xato / login) uchun umumiy
/// ko'rinish: yumshoq doira ichida ikonka, sarlavha, izoh va tugma.
class OrdersStateView extends StatelessWidget {
  final String iconAsset;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// `true` — xato holati (ikonka qizil tusda).
  final bool isError;

  const OrdersStateView({
    super.key,
    required this.iconAsset,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final Color accent = isError
        ? ProjectTheme.error
        : (isDark ? Colors.white : ProjectTheme.brandColor);
    final Color muted =
        isDark ? ProjectTheme.secondaryTextDark : const Color(0xFF7A849E);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isError
                  ? ProjectTheme.error.withValues(alpha: isDark ? 0.2 : 0.1)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : ProjectTheme.brandColor.withValues(alpha: 0.08)),
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              iconAsset,
              width: 36,
              height: 36,
              colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyLarge?.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: muted,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 22),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: ProjectTheme.brandColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontFamily: 'packages/mysafar_sdk/Gilroy',
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
