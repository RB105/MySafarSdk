import 'dart:io' show File;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mysafar_sdk/src/api/user_data.dart' show MySafarUzsCard;
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/tools/app_cache_manager.dart';
import 'package:mysafar_sdk/src/core/tools/project_assets.dart';
import 'package:mysafar_sdk/src/core/tools/sdk_sheets.dart';
import 'package:mysafar_sdk/src/core/widgets/sdk_dialog.dart'
    show SdkDialogCloseButton, SdkSheetFrame;
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/view/booking/widget/booking_form_fields.dart'
    show BookingFormStyle;

/// Kartalar sheet'idagi tanlov. [card] `null` — "Boshqa karta" (karta
/// ma'lumotlari to'lov sahifasida qo'lda kiritiladi).
class SavedCardChoice {
  const SavedCardChoice.card(MySafarUzsCard this.card);
  const SavedCardChoice.otherCard() : card = null;

  final MySafarUzsCard? card;

  bool get isOtherCard => card == null;
}

/// Host bergan UZS kartalar ro'yxati + "Boshqa karta" qatori. Qator bosilishi
/// bilan sheet yopiladi va tanlov qaytadi; yopib yuborilsa `null`.
Future<SavedCardChoice?> showSavedCardsSheet(
  BuildContext context, {
  required List<MySafarUzsCard> cards,
}) {
  return showSdkModalBottomSheet<SavedCardChoice>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => SdkSheetFrame(child: _SavedCardsSheetBody(cards: cards)),
  );
}

class _SavedCardsSheetBody extends StatelessWidget {
  const _SavedCardsSheetBody({required this.cards});

  final List<MySafarUzsCard> cards;

  void _select(BuildContext context, SavedCardChoice choice) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(choice);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'saved_cards_title'.tr(),
                    style: context.textTheme.bodyLarge
                        ?.copyWith(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'saved_cards_subtitle'.tr(),
                    style: context.textTheme.bodySmall?.copyWith(
                      fontSize: 13.5,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: BookingFormStyle.label(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const SdkDialogCloseButton(),
          ],
        ),
        const SizedBox(height: 18),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _SavedCardTile(
              card: cards[i],
              onTap: () => _select(context, SavedCardChoice.card(cards[i])),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _OtherCardTile(
          onTap: () => _select(context, const SavedCardChoice.otherCard()),
        ),
      ],
    );
  }
}

/// Sheet qatori — kartalar va "Boshqa karta" uchun bir xil o'lcham va uslub.
class _SheetOptionTile extends StatelessWidget {
  const _SheetOptionTile({
    required this.leading,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  static const double height = 72;

  final Widget leading;
  final Widget title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Material(
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : const Color(0xFFF3F6FA),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 10, 0),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: BookingFormStyle.label(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 10),
                  trailing!,
                ],
                const SizedBox(width: 6),
                SvgPicture.asset(
                  Assets.iconsBookingChevronRightIcon,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    BookingFormStyle.hint(context),
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Karta logotipi plitkasi (56×40). Logotiplar yorug' fon uchun chizilgan —
/// dark temada ham oq plitka.
class _LogoTile extends StatelessWidget {
  const _LogoTile({required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: color == null
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

class _SavedCardTile extends StatelessWidget {
  const _SavedCardTile({required this.card, required this.onTap});

  final MySafarUzsCard card;
  final VoidCallback onTap;

  bool get _isHumo => card.cardNumberDigits.startsWith('9860');

  String get _processingName => _isHumo ? 'HUMO' : 'Uzcard';

  String get _last4 {
    final digits = card.cardNumberDigits;
    return digits.substring(digits.length - 4);
  }

  @override
  Widget build(BuildContext context) {
    final owner = card.displayOwner;
    final balance = card.balance;

    return Semantics(
      button: true,
      label: '$_processingName $_last4',
      child: _SheetOptionTile(
        onTap: onTap,
        leading: _LogoTile(
          child: _CardLogo(
            url: card.cardLogoUrl,
            fallbackAsset: _isHumo
                ? ProjectAssets.bookingHumologo
                : ProjectAssets.bookingUzkardlogo,
          ),
        ),
        title: Text(
          '•••• $_last4',
          maxLines: 1,
          style: context.textTheme.bodyLarge?.copyWith(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        subtitle: owner ?? _processingName,
        trailing: balance == null ? null : _Balance(amount: balance),
      ),
    );
  }
}

class _Balance extends StatelessWidget {
  const _Balance({required this.amount});

  final num amount;

  /// `1250000.5` → `1 250 000`. Tiyinlar ro'yxatda ko'rsatilmaydi.
  String get _formatted => amount
      .floor()
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ');

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 140),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text.rich(
          TextSpan(
            text: _formatted,
            style: context.textTheme.bodyLarge?.copyWith(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            children: [
              TextSpan(
                text: ' ${'uzs_currency'.tr()}',
                style: context.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: BookingFormStyle.label(context),
                ),
              ),
            ],
          ),
          maxLines: 1,
        ),
      ),
    );
  }
}

class _OtherCardTile extends StatelessWidget {
  const _OtherCardTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = ProjectTheme.brandColor;
    final isDark = context.isDarkMode;
    final accent = isDark ? Colors.white : brand;
    return _SheetOptionTile(
      onTap: onTap,
      leading: _LogoTile(
        color: isDark
            ? Colors.white.withValues(alpha: 0.10)
            : brand.withValues(alpha: 0.10),
        child: SvgPicture.asset(
          Assets.iconsOrderCardIcon,
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
        ),
      ),
      title: Text(
        'saved_cards_other'.tr(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.bodyLarge?.copyWith(
          fontSize: 16.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: 'saved_cards_other_hint'.tr(),
    );
  }
}

/// Host bergan logotip URL'i (`.svg` — diskda keshlanib; boshqalari —
/// [CachedNetworkImage]). URL bo'lmasa, yuklanayotganda yoki xato bo'lsa —
/// SDK'dagi UzCard / Humo logotipi.
class _CardLogo extends StatelessWidget {
  const _CardLogo({required this.url, required this.fallbackAsset});

  final String? url;
  final String fallbackAsset;

  @override
  Widget build(BuildContext context) {
    final fallback = Image.asset(
      fallbackAsset,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
    final link = url?.trim() ?? '';
    final uri = Uri.tryParse(link);
    if (uri == null || !uri.hasScheme || !uri.scheme.startsWith('http')) {
      return fallback;
    }

    if (uri.path.toLowerCase().endsWith('.svg')) {
      return FutureBuilder<File>(
        future: AppCacheManager.instance.getSingleFile(link),
        builder: (context, snapshot) {
          final file = snapshot.data;
          if (file == null) return fallback;
          return SvgPicture.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => fallback,
          );
        },
      );
    }

    return CachedNetworkImage(
      cacheManager: AppCacheManager.instance,
      imageUrl: link,
      fit: BoxFit.contain,
      memCacheHeight: 160,
      placeholder: (_, __) => fallback,
      errorWidget: (_, __, ___) => fallback,
    );
  }
}
