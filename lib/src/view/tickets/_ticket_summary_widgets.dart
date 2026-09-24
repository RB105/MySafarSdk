part of 'ticket_page.dart';

// ════════════════════════════════════════════════════════════════════
//  WEB (mysafar.uz) MOBIL DIZAYNIDAN OLINGAN BLOKLAR:
//  • _DatePriceStrip — sana-narx lentasi (qo'shni kunlarning eng arzon
//    narxi; bosilganda o'sha sana bilan qayta qidiradi). Ranglari sahifa
//    UI'siga mos (oq/qorong'u karta, brand tanlov, yashil eng arzon);
//    ikki chetidagi strelkalar lentani varaqlaydi.
//  • _AirlinesSummaryCard — "Aviakompaniyalar bo'yicha" jamlama kartasi:
//    har bir aviakompaniyaning eng arzon narxi (yashil) va jo'nash vaqtlari;
//    bosilganda o'sha reys tafsilotiga o'tadi.
// ════════════════════════════════════════════════════════════════════

/// Web'dagi yashil aksent (eng arzon narx, "To'g'ri" va h.k.).
const Color _kTixGreen = Color(0xFF16A34A);

// ────────────────────────────────────────────────────────────────────
//  SANA-NARX LENTASI
// ────────────────────────────────────────────────────────────────────

class _DatePriceStrip extends StatefulWidget {
  /// Lenta balandligi — pinned header delegate ham shundan foydalanadi.
  static const double height = 76;

  /// Hozir tanlangan (qidirilayotgan) sana.
  final DateTime selected;

  /// Oylik eng arzon narxlar (API'dan kelguncha `null` bo'lishi mumkin —
  /// bunda lenta faqat sanalarni ko'rsatadi).
  final TicketDatePriceModel? monthPrices;

  final ValueChanged<DateTime> onDateTap;

  const _DatePriceStrip({
    required this.selected,
    required this.monthPrices,
    required this.onDateTap,
  });

  @override
  State<_DatePriceStrip> createState() => _DatePriceStripState();
}

class _DatePriceStripState extends State<_DatePriceStrip> {
  static const double _itemWidth = 104;

  final ScrollController _scroll = ScrollController();

  /// Tanlangan kun faqat birinchi ko'rsatishda va sana o'zgarganda
  /// markazlanadi — har rebuild'da emas (aks holda natijalar kelganda
  /// foydalanuvchi aylantirgan joyidan sakrab ketadi).
  bool _needsCenter = true;

  @override
  void didUpdateWidget(covariant _DatePriceStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameDay(oldWidget.selected, widget.selected)) {
      _needsCenter = true;
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Ko'rsatiladigan kunlar oynasi: tanlangan sanadan bir hafta oldin
  /// (lekin bugundan erta emas) va ikki hafta keyin.
  List<DateTime> _dates() {
    final today = DateTime.now();
    final DateTime floor = DateTime(today.year, today.month, today.day);
    DateTime start = widget.selected.subtract(const Duration(days: 7));
    if (start.isBefore(floor)) start = floor;
    return [
      for (int i = 0; i <= 21; i++) start.add(Duration(days: i)),
    ];
  }

  /// Tanlangan sana lenta markazida turishi uchun siljish (kenglik —
  /// strelkalar hisobga olingan haqiqiy ko'rinish oynasidan olinadi).
  void _centerSelected(List<DateTime> dates) {
    final idx = dates.indexWhere((d) => _sameDay(d, widget.selected));
    if (idx < 0 || !_scroll.hasClients) return;
    final double viewWidth = _scroll.position.viewportDimension;
    final target = (idx * _itemWidth) - (viewWidth - _itemWidth) / 2;
    final double offset = target.clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  /// Chekka strelka bosilganda lentani taxminan uch kunga suradi.
  void _scrollBy(double delta) {
    if (!_scroll.hasClients) return;
    HapticFeedback.lightImpact();
    final double target =
        (_scroll.offset + delta).clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.animateTo(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Joriy valyutadagi kunlik narxlar ro'yxati.
  List<DatePrice> _pricesFor(AppCurrency currency) {
    final m = widget.monthPrices;
    if (m == null) return const [];
    switch (currency) {
      case AppCurrency.uzs:
        return m.uzsPrices ?? const [];
      case AppCurrency.rub:
        return m.rubPrices ?? const [];
      case AppCurrency.usd:
        return m.usdPrices ?? const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final dates = _dates();
    final currency = Provider.of<CurrencyProvider>(context).currency;

    // Sana → narx jadvali va ko'rinayotgan oynadagi eng arzon qiymat
    // (u yashil rangda ajratiladi — web'dagi kabi). API xom summa
    // qaytaradi — ixcham "2.88M" ko'rinishiga o'giramiz.
    final Map<int, String> priceTextByDay = {};
    final Map<int, double> priceValueByDay = {};
    for (final p in _pricesFor(currency)) {
      final d = p.date;
      final s = (p.sum ?? '').trim();
      if (d == null || s.isEmpty || s == "0") continue;
      final key = d.year * 10000 + d.month * 100 + d.day;
      priceTextByDay[key] = ElementFormatter.compactPrice(s);
      final v = ElementFormatter.parsePrice(s);
      if (v != null) priceValueByDay[key] = v;
    }
    double? minVisible;
    for (final d in dates) {
      final v = priceValueByDay[d.year * 10000 + d.month * 100 + d.day];
      if (v != null && (minVisible == null || v < minVisible)) minVisible = v;
    }

    if (_needsCenter) {
      _needsCenter = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _centerSelected(dates);
        }
      });
    }

    final t = _TixTheme.of(context);
    // Lenta balandligi qat'iy (pinned appbar tarkibida) — katta tizim
    // shriftida sana/narx qatorlari sig'may qolmasligi uchun matn
    // kattalashishi cheklanadi.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: _buildStrip(t, dates, priceTextByDay, priceValueByDay, minVisible),
    );
  }

  Widget _buildStrip(
    _TixTheme t,
    List<DateTime> dates,
    Map<int, String> priceTextByDay,
    Map<int, double> priceValueByDay,
    double? minVisible,
  ) {
    return Container(
      height: _DatePriceStrip.height,
      color: t.card,
      child: Row(
        children: [
          _StripArrowButton(
            icon: Icons.chevron_left_rounded,
            semanticLabel: "a11y_previous_dates".tr(),
            onTap: () => _scrollBy(-_itemWidth * 3),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
              itemExtent: _itemWidth,
              itemCount: dates.length,
              itemBuilder: (context, index) {
                final date = dates[index];
                final bool isSelected = _sameDay(date, widget.selected);
                final int key = date.year * 10000 + date.month * 100 + date.day;
                final double? v = priceValueByDay[key];
                final bool isCheapest = v != null && v <= (minVisible ?? -1);
                return _DateStripItem(
                  date: date,
                  price: priceTextByDay[key],
                  isSelected: isSelected,
                  isCheapest: isCheapest,
                  showDivider: index != 0,
                  onTap: isSelected
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          AnalyticsService()
                              .trackButtonTap('ticket_date_strip');
                          widget.onDateTap(date);
                        },
                );
              },
            ),
          ),
          _StripArrowButton(
            icon: Icons.chevron_right_rounded,
            semanticLabel: "a11y_next_dates".tr(),
            onTap: () => _scrollBy(_itemWidth * 3),
          ),
        ],
      ),
    );
  }
}

/// Lenta chetidagi varaqlash strelkasi — filter chiplari bilan bir xil
/// tusdagi kichik tugma; bosilganda lenta bir necha kunga suriladi.
class _StripArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  /// Ekran o'quvchi uchun tugma nomi.
  final String semanticLabel;

  const _StripArrowButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      // Chetdagi 4 dp ham bosiladi — bosish maydoni 44×48 dp (№32).
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            color:
                t.dark ? Colors.white.withAlpha(20) : const Color(0xFFF1F4F9),
            borderRadius: BorderRadius.circular(10),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                width: 36,
                height: 48,
                child: Center(
                  child: Icon(icon, size: 20, color: t.hi),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateStripItem extends StatelessWidget {
  final DateTime date;
  final String? price;
  final bool isSelected;
  final bool isCheapest;
  final bool showDivider;
  final VoidCallback? onTap;

  const _DateStripItem({
    required this.date,
    required this.price,
    required this.isSelected,
    required this.isCheapest,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    final Color brand = ProjectTheme.brandColor;
    final String dateLabel =
        "${date.day} ${ElementFormatter.formatMonth(date.month).toLowerCase()}";

    // Tanlangan kun — ilovaning "tanlov" tili: to'liq brand gradient pill,
    // oq matn (tab indikatori kabi). Shaffof tint qorong'u temada xira
    // ko'ringani uchun ishlatilmaydi. Eng arzon narx — yashil aksent.
    final Color green = t.dark ? const Color(0xFF34D399) : _kTixGreen;
    final Color dateColor = isSelected ? Colors.white.withAlpha(235) : t.mid;
    final Color priceColor =
        isSelected ? Colors.white : (isCheapest ? green : t.hi);

    return Row(
      children: [
        // Kunlar orasidagi ingichka ajratkich (web'dagi kabi).
        if (showDivider)
          Container(width: 1, height: 28, color: t.line)
        else
          const SizedBox(width: 1),
        Expanded(
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Ink(
                decoration: isSelected
                    ? BoxDecoration(
                        color: brand,
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dateLabel,
                      maxLines: 1,
                      style: _TixTheme.style(12, FontWeight.w600, dateColor),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      price ?? "—",
                      maxLines: 1,
                      style: _TixTheme.style(13.5, FontWeight.w800, priceColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Ko'rinish filtrlari hech reys qoldirmaganda ko'rsatiladigan holat:
/// xabar + filtrlarni tozalash tugmasi.
class _FilteredEmptyView extends StatelessWidget {
  final VoidCallback onClear;

  const _FilteredEmptyView({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return _TicketsEmptyView(
      title: "not_found_tickets".tr(),
      actionLabel: "filter_clear".tr(),
      onAction: () {
        HapticFeedback.lightImpact();
        onClear();
      },
    );
  }
}

/// Natija yo'q holati: yumshoq doira ichida qidiruv ikonkasi, sarlavha,
/// ixtiyoriy izoh va tugma.
class _TicketsEmptyView extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _TicketsEmptyView({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    final brand = ProjectTheme.brandColor;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.dark
                  ? Colors.white.withValues(alpha: 0.08)
                  : brand.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              Assets.iconsPlaceEmptySearchIcon,
              width: 32,
              height: 32,
              colorFilter: ColorFilter.mode(
                t.dark ? Colors.white : brand,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: _TixTheme.style(16, FontWeight.w700, t.hi, height: 1.3),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: _TixTheme.style(13.5, FontWeight.w500, t.mid, height: 1.4),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            SizedBox(
              height: 44,
              child: FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: t.dark
                      ? Colors.white.withValues(alpha: 0.10)
                      : brand.withValues(alpha: 0.10),
                  foregroundColor: t.dark ? Colors.white : brand,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: _TixTheme.style(
                      14, FontWeight.w700, t.dark ? Colors.white : brand),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
//  "AVIAKOMPANIYALAR BO'YICHA" JAMLAMA KARTASI
// ────────────────────────────────────────────────────────────────────

/// Bitta aviakompaniya guruhi: reyslari narx bo'yicha saralangan.
class _AirlineGroup {
  final String code;
  final String title;
  final List<FlightElement> flights;

  _AirlineGroup({required this.code, required this.title})
      : flights = <FlightElement>[];

  FlightElement get cheapest => flights.first;
}

/// Reyslarni birinchi segment aviakompaniyasi bo'yicha guruhlaydi;
/// guruhlar ham, ichidagi reyslar ham narx bo'yicha o'sish tartibida.
List<_AirlineGroup> _groupFlightsByAirline(List<FlightElement> flights) {
  final Map<String, _AirlineGroup> map = {};
  for (final f in flights) {
    final segs = f.segments;
    if (segs == null || segs.isEmpty) continue;
    final carrier = segs.first.carrier;
    if (carrier.code.isEmpty) continue;
    map
        .putIfAbsent(carrier.code,
            () => _AirlineGroup(code: carrier.code, title: carrier.title))
        .flights
        .add(f);
  }
  final groups = map.values.where((g) => g.flights.isNotEmpty).toList();
  // Narx bir marta o'qilgan (keshlangan) son — taqqoslashda matn qayta
  // parse qilinmaydi.
  for (final g in groups) {
    g.flights.sort((a, b) => a.sortPrice.compareTo(b.sortPrice));
  }
  groups.sort((a, b) => a.cheapest.sortPrice.compareTo(b.cheapest.sortPrice));
  return groups;
}

class _AirlinesSummaryCard extends StatefulWidget {
  final List<FlightElement> flights;

  const _AirlinesSummaryCard({required this.flights});

  @override
  State<_AirlinesSummaryCard> createState() => _AirlinesSummaryCardState();
}

class _AirlinesSummaryCardState extends State<_AirlinesSummaryCard> {
  /// Boshida nechta aviakompaniya ko'rsatiladi (qolganlari yig'ilgan).
  static const int _collapsedCount = 3;

  bool _expanded = false;

  /// Guruhlash faqat reyslar ro'yxati o'zgarganda qayta hisoblanadi (har
  /// rebuild'da emas).
  final ListResultMemo<List<_AirlineGroup>> _groupsMemo =
      ListResultMemo<List<_AirlineGroup>>();

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    final groups = _groupsMemo.get(
        widget.flights, null, () => _groupFlightsByAirline(widget.flights));
    if (groups.length < 2) return const SizedBox.shrink();

    final visible = _expanded ? groups : groups.take(_collapsedCount).toList();
    final hiddenCount = groups.length - _collapsedCount;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: t.cardShadow,
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "airlines_by_title".tr(),
                    maxLines: 1,
                    style: _TixTheme.style(15.5, FontWeight.w700, t.hi),
                  ),
                ),
              ),
              if (hiddenCount > 0)
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    // Bosish maydoni ≥44dp bo'lsin.
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                    child: Row(
                      children: [
                        Text(
                          _expanded
                              ? "ticket_show_less".tr()
                              : "ticket_show_more_count"
                                  .tr(namedArgs: {"count": "$hiddenCount"}),
                          style: _TixTheme.style(
                              13, FontWeight.w700, ProjectTheme.brandColor),
                        ),
                        Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: ProjectTheme.brandColor,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (int i = 0; i < visible.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: t.line),
            _AirlineSummaryRow(
                group: visible[i],
                // Faqat UZS narxli guruh "eng arzon" rangida (№82).
                isCheapest: i == 0 && visible[i].cheapest.hasUzsSortPrice),
          ],
        ],
      ),
    );
  }
}

class _AirlineSummaryRow extends StatelessWidget {
  final _AirlineGroup group;

  /// Eng arzon aviakompaniya (ro'yxatda birinchi) — narxi yashil.
  final bool isCheapest;

  const _AirlineSummaryRow({required this.group, this.isCheapest = false});

  /// "HH:mm" → daqiqa (saralash uchun; xato format oxiriga tushadi).
  static int _timeMinutes(String t) {
    final parts = t.split(':');
    if (parts.length < 2) return 1 << 20;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return 1 << 20;
    return h * 60 + m;
  }

  /// Guruh reyslarining jo'nash vaqtlari (takrorsiz, vaqt tartibida) va
  /// ularga mos reys. Eng arzon reys vaqti yashil ko'rsatiladi.
  List<MapEntry<String, FlightElement>> _depTimes() {
    final seen = <String>{};
    final result = <MapEntry<String, FlightElement>>[];
    for (final f in group.flights) {
      final segs = f.getSegmentsByDirection(0);
      if (segs.isEmpty) continue;
      final time = ElementFormatter.formatTime(segs.first.dep.time ?? '');
      if (time.isEmpty || !seen.add(time)) continue;
      result.add(MapEntry(time, f));
    }
    result.sort((a, b) => _timeMinutes(a.key).compareTo(_timeMinutes(b.key)));
    return result;
  }

  /// Eng arzon reysning jo'nash sanasi: "24 iyul".
  String _depDateLabel() {
    final segs = group.cheapest.getSegmentsByDirection(0);
    if (segs.isEmpty) return '';
    final raw = segs.first.dep.date ?? '';
    final parts = raw.contains('-') ? raw.split('-') : raw.split('.');
    if (parts.length != 3) return raw;
    // yyyy-MM-dd bo'lsa ham, dd.MM.yyyy bo'lsa ham qo'llaymiz.
    final bool yearFirst = parts[0].length == 4;
    final day = int.tryParse(yearFirst ? parts[2] : parts[0]);
    final month = int.tryParse(parts[1]);
    if (day == null || month == null) return raw;
    return "$day ${ElementFormatter.formatMonth(month).toLowerCase()}";
  }

  void _openFlight(BuildContext context, FlightElement flight) {
    HapticFeedback.lightImpact();
    AnalyticsService().trackButtonTap('ticket_airline_summary');
    TicketInfoPage.show(context, flight);
  }

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    final cheapest = group.cheapest;
    final price =
        Provider.of<CurrencyProvider>(context).getElementPrice(cheapest.price);
    final times = _depTimes();
    final String cheapestTime = times.isEmpty
        ? ''
        : times
            .firstWhere((e) => identical(e.value, cheapest),
                orElse: () => times.first)
            .key;

    return InkWell(
      onTap: () => _openFlight(context, cheapest),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _AirlineCircle(code: group.code, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _TixTheme.style(14, FontWeight.w700, t.hi),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      price,
                      maxLines: 1,
                      style: _TixTheme.style(14.5, FontWeight.w800,
                          isCheapest ? _kTixGreen : t.hi),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                SvgPicture.asset(
                  Assets.iconsBookingChevronRightIcon,
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(t.mid, BlendMode.srcIn),
                ),
              ],
            ),
            if (times.isNotEmpty) ...[
              // Oraliq vaqt chiplarining 44 dp bosish maydoni ichida (№32).
              Row(
                children: [
                  Text(
                    _depDateLabel(),
                    style: _TixTheme.style(12.5, FontWeight.w500, t.mid),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final e in times.take(5)) ...[
                            _TimeChip(
                              label: e.key,
                              highlighted: e.key == cheapestTime,
                              onTap: () => _openFlight(context, e.value),
                            ),
                            const SizedBox(width: 6),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Aviakompaniya qatoridagi bosiladigan jo'nash vaqti chipi.
class _TimeChip extends StatelessWidget {
  final String label;
  final bool highlighted;
  final VoidCallback onTap;

  const _TimeChip({
    required this.label,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    // Chip ko'rinishi ixcham, bosish maydoni esa ≥44 dp (№32): atrofidagi
    // shaffof maydon ham shu reysni ochadi.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
        child: Center(
          widthFactor: 1,
          child: _chip(t),
        ),
      ),
    );
  }

  Widget _chip(_TixTheme t) {
    return Material(
      color: highlighted ? _kTixGreen.withAlpha(t.dark ? 50 : 26) : t.tonal,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          child: Text(
            label,
            style: _TixTheme.style(
              12.5,
              FontWeight.w700,
              highlighted ? _kTixGreen : t.hi,
            ),
          ),
        ),
      ),
    );
  }
}
