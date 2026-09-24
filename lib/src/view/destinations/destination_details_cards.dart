part of 'destination_details_page.dart';

/// "Arzon aviachiptalar" — yo'nalish va eng arzon sana haqidagi ma'lumot
/// kartasi. Qidiruv tugmasi endi pastdagi doimiy panelda (takrorlanmaydi).
class _AviaRouteCard extends StatelessWidget {
  final DestinationDetailModel detail;
  final String Function(DestLocalizedText) lt;

  const _AviaRouteCard({required this.detail, required this.lt});

  /// `2026-04-12` → `12 aprel`; sana noto'g'ri bo'lsa bo'sh qator.
  static String _cheapDate(DestinationDetailModel detail) {
    final raw = detail.aviaBlock?.date.isNotEmpty == true
        ? detail.aviaBlock!.date
        : (detail.hero?.date ?? '');
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '';
    return "${parsed.day} ${ElementFormatter.formatMonth(parsed.month)}";
  }

  @override
  Widget build(BuildContext context) {
    final t = _DestTheme.of(context);
    final avia = detail.aviaBlock;
    final String from =
        avia != null && avia.fromIata.isNotEmpty ? avia.fromIata : 'TAS';
    final String to = avia != null && avia.toIata.isNotEmpty
        ? avia.toIata
        : detail.airportCode;
    final String date = _cheapDate(detail);

    return _DestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _DestIconTile(Assets.iconsDestTicketIcon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "dest_cheap_flights".tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: "packages/mysafar_sdk/Gilroy",
                        color: t.text,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (to.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        "$from → $to",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: "packages/mysafar_sdk/Gilroy",
                          color: t.muted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (avia != null && !avia.description.isEmpty) ...[
            const SizedBox(height: 12),
            Text(
              lt(avia.description),
              style: TextStyle(
                fontFamily: "packages/mysafar_sdk/Gilroy",
                color: t.text,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                height: 1.55,
              ),
            ),
          ],
          if (date.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: t.tonal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    Assets.iconsDestStayIcon,
                    width: 15,
                    height: 15,
                    colorFilter: ColorFilter.mode(t.muted, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    date,
                    style: TextStyle(
                      fontFamily: "packages/mysafar_sdk/Gilroy",
                      color: t.text,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Kontakt kartasi: faqat partner `init` da aniq bergan telefon / Telegram.
/// Default MySafar kontaktlari bu yerda ishlatilmaydi.
class _ContactCard extends StatelessWidget {
  final void Function(String uri) onOpen;

  const _ContactCard({required this.onOpen});

  String get _messageKey {
    final hasPhone = MySafarSdk.config.partnerSupportPhone != null;
    final hasTelegram = MySafarSdk.config.partnerSupportTelegramUrl != null;
    if (hasPhone && hasTelegram) return 'dest_contact_call_or_telegram';
    if (hasPhone) return 'dest_contact_call_only';
    return 'dest_contact_telegram_only';
  }

  /// `https://t.me/foo` → `@foo` (UI uchun qisqa yorliq).
  String _telegramLabel(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return '@${uri.pathSegments.first}';
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final t = _DestTheme.of(context);
    final phone = MySafarSdk.config.partnerSupportPhone;
    final telegramUrl = MySafarSdk.config.partnerSupportTelegramUrl;

    return _DestCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _DestIconTile(Assets.iconsProfileSupportIcon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _messageKey.tr(),
                  style: TextStyle(
                    fontFamily: "packages/mysafar_sdk/Gilroy",
                    color: t.text,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          if (phone != null) ...[
            const SizedBox(height: 12),
            _ContactRow(
              icon: Assets.iconsDialogPhoneIcon,
              label: phone,
              onTap: () => onOpen('tel:${phone.replaceAll(' ', '')}'),
            ),
          ],
          if (telegramUrl != null) ...[
            const SizedBox(height: 8),
            _ContactRow(
              icon: Assets.iconsTelegramIcon,
              label: _telegramLabel(telegramUrl),
              onTap: () => onOpen(telegramUrl),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bosiladigan kontakt qatori (tonal fon + chevron).
class _ContactRow extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = _DestTheme.of(context);
    return Material(
      color: t.tonal,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              SvgPicture.asset(
                icon,
                width: 19,
                height: 19,
                colorFilter:
                    ColorFilter.mode(ProjectTheme.brandColor, BlendMode.srcIn),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: "packages/mysafar_sdk/Gilroy",
                    color: t.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SvgPicture.asset(
                Assets.iconsBookingChevronRightIcon,
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(t.muted, BlendMode.srcIn),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pastki doimiy panel: narx + "Chiptalarni qidirish". Tugma bron
/// oynasidagi tugma bilan bir xil (54dp, radius 16, bosilganda kichrayadi).
class _DestSearchBar extends StatefulWidget {
  final int price;
  final AppCurrency currency;
  final VoidCallback onSearch;

  const _DestSearchBar({
    required this.price,
    required this.currency,
    required this.onSearch,
  });

  @override
  State<_DestSearchBar> createState() => _DestSearchBarState();
}

class _DestSearchBarState extends State<_DestSearchBar> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final t = _DestTheme.of(context);
    final brand = ProjectTheme.brandColor;
    final String label = "dest_search_tickets".tr();

    final Widget button = Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) {
          _setPressed(false);
          widget.onSearch();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: brand,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: brand.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Uzun tarjima yoki katta tizim shriftida matn qirqilmaydi —
                // kichrayadi (tugma balandligi o'zgarmaydi).
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: const TextStyle(
                        fontFamily: "packages/mysafar_sdk/Gilroy",
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SvgPicture.asset(
                  Assets.iconsBookingArrowRightIcon,
                  width: 20,
                  height: 20,
                  colorFilter:
                      const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: t.isDark ? 0.35 : 0.07),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: widget.price > 0
              ? Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "dest_price_title".tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: "packages/mysafar_sdk/Gilroy",
                              color: t.muted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Uzun summa (so'mda) sig'masa kichrayadi.
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: _priceFromLine(
                              context,
                              amount: widget.price,
                              currency: widget.currency,
                              boldColor: t.text,
                              greyColor: t.muted,
                              fontSize: 21,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(flex: 6, child: button),
                  ],
                )
              : SizedBox(width: double.infinity, child: button),
        ),
      ),
    );
  }
}

/// Ma'lumot kelguncha ko'rsatiladigan skelet — bo'sh ekran o'rniga sahifa
/// tuzilishi darhol ko'rinadi.
class _DestSkeleton extends StatelessWidget {
  const _DestSkeleton();

  @override
  Widget build(BuildContext context) {
    final t = _DestTheme.of(context);

    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: t.tonal,
            borderRadius: BorderRadius.circular(8),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DestCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (int row = 0; row < 2; row++) ...[
                  if (row > 0) Divider(height: 1, thickness: 1, color: t.line),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (int col = 0; col < 2; col++) ...[
                          if (col > 0)
                            VerticalDivider(
                                width: 1, thickness: 1, color: t.line),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  bar(36, 36),
                                  const SizedBox(height: 10),
                                  bar(70, 10),
                                  const SizedBox(height: 7),
                                  bar(100, 12),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _DestCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(140, 16),
                const SizedBox(height: 14),
                bar(double.infinity, 11),
                const SizedBox(height: 8),
                bar(double.infinity, 11),
                const SizedBox(height: 8),
                bar(180, 11),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _DestCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (int i = 0; i < 3; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 82),
                      child: Divider(height: 1, thickness: 1, color: t.line),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: t.tonal,
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              bar(120, 12),
                              const SizedBox(height: 8),
                              bar(double.infinity, 10),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Xatolik holati — yangi UI uslubidagi markazlashgan blok.
class _DestErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _DestErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final t = _DestTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: t.tonal,
                borderRadius: BorderRadius.circular(22),
              ),
              child: SvgPicture.asset(
                Assets.iconsDialogNetworkIcon,
                width: 30,
                height: 30,
                colorFilter: ColorFilter.mode(t.muted, BlendMode.srcIn),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              "error_occurred".tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "packages/mysafar_sdk/Gilroy",
                color: t.text,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Material(
              color: ProjectTheme.brandColor,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onRetry,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                  child: Text(
                    "retry".tr(),
                    style: const TextStyle(
                      fontFamily: "packages/mysafar_sdk/Gilroy",
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
