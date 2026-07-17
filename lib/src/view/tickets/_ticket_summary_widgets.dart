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

  /// API'dan kelgan tayyor satrni ("3.3M", "12 400" kabi) taqqoslash uchun
  /// songa o'giradi; o'girib bo'lmasa `null` (narx baribir ko'rsatiladi,
  /// faqat "eng arzon" belgilashda qatnashmaydi).
  static double? _parseCompact(String s) {
    String t = s.replaceAll(' ', '').replaceAll(' ', '').toUpperCase();
    double mult = 1;
    if (t.endsWith('M')) {
      mult = 1000000;
      t = t.substring(0, t.length - 1).replaceAll(',', '.');
    } else if (t.endsWith('K')) {
      mult = 1000;
      t = t.substring(0, t.length - 1).replaceAll(',', '.');
    } else {
      t = t.replaceAll(',', '');
    }
    final v = double.tryParse(t);
    return v == null || v <= 0 ? null : v * mult;
  }

  @override
  Widget build(BuildContext context) {
    final dates = _dates();
    final currency = Provider.of<CurrencyProvider>(context).currency;

    // Sana → narx jadvali va ko'rinayotgan oynadagi eng arzon qiymat
    // (u yashil rangda ajratiladi — web'dagi kabi). API narxni tayyor
    // formatlangan satr ko'rinishida beradi (kalendar widgeti bilan bir xil).
    final Map<int, String> priceTextByDay = {};
    final Map<int, double> priceValueByDay = {};
    for (final p in _pricesFor(currency)) {
      final d = p.date;
      final s = (p.sum ?? '').trim();
      if (d == null || s.isEmpty || s == "0") continue;
      final key = d.year * 10000 + d.month * 100 + d.day;
      priceTextByDay[key] = s;
      final v = _parseCompact(s);
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
    return Container(
      height: _DatePriceStrip.height,
      color: t.card,
      child: Row(
        children: [
          _StripArrowButton(
            icon: Icons.chevron_left_rounded,
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
                final int key =
                    date.year * 10000 + date.month * 100 + date.day;
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

  const _StripArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: t.dark ? Colors.white.withAlpha(20) : const Color(0xFFF1F4F9),
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 30,
            height: 40,
            child: Center(
              child: Icon(icon, size: 20, color: t.hi),
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
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [brand, ProjectTheme.blueBg],
                        ),
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
                      style:
                          _TixTheme.style(13.5, FontWeight.w800, priceColor),
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

// ────────────────────────────────────────────────────────────────────
//  KO'RINISH FILTRLARI — web'dagi TO'LIQ "Filtr" sheet'i (accordion)
// ────────────────────────────────────────────────────────────────────

/// Sheet bo'limlari — chip bosilganda mos bo'lim ochiq holda ochiladi.
enum _ViewFilterSection { sort, transfer, baggage, tariff, time, airlines }

/// Chiplardagi barcha ko'rinish-filtr qiymatlari bitta joyda.
/// Sheet nusxa (clone) ustida ishlaydi; "Qo'llash" bosilgandagina sahifa
/// holatiga ko'chiriladi.
class _ViewFilterValues {
  static const double dayMinutes = 1440;

  int sort = 0; // 0-narx, 1-uchish, 2-qo'nish, 3-davomiylik
  bool directOnly = false;
  bool baggageOnly = false;
  bool refundable = false;
  bool exchangeable = false;
  RangeValues depRange = const RangeValues(0, dayMinutes);
  RangeValues arrRange = const RangeValues(0, dayMinutes);
  final Set<String> excludedAirlines = {};

  static bool _isFullRange(RangeValues r) =>
      r.start <= 0 && r.end >= dayMinutes;

  bool get hasTimeFilter => !_isFullRange(depRange) || !_isFullRange(arrRange);

  bool get hasAnyFilter =>
      directOnly ||
      baggageOnly ||
      refundable ||
      exchangeable ||
      hasTimeFilter ||
      excludedAirlines.isNotEmpty;

  void reset() {
    sort = 0;
    directOnly = false;
    baggageOnly = false;
    refundable = false;
    exchangeable = false;
    depRange = const RangeValues(0, dayMinutes);
    arrRange = const RangeValues(0, dayMinutes);
    excludedAirlines.clear();
  }

  void copyFrom(_ViewFilterValues other) {
    sort = other.sort;
    directOnly = other.directOnly;
    baggageOnly = other.baggageOnly;
    refundable = other.refundable;
    exchangeable = other.exchangeable;
    depRange = other.depRange;
    arrRange = other.arrRange;
    excludedAirlines
      ..clear()
      ..addAll(other.excludedAirlines);
  }

  _ViewFilterValues clone() => _ViewFilterValues()..copyFrom(this);

  static String _fmtMinutes(double m) {
    final h = (m ~/ 60).toString().padLeft(2, '0');
    final mm = (m.toInt() % 60).toString().padLeft(2, '0');
    return "$h:$mm";
  }

  static String rangeLabel(RangeValues r) =>
      "${_fmtMinutes(r.start)} – ${_fmtMinutes(r.end)}";

  String sortLabel() => switch (sort) {
        1 => "dep_order".tr(),
        2 => "arr_order".tr(),
        3 => "duration_order".tr(),
        _ => "price_order".tr(),
      };

  String transferLabel() => directOnly ? "only_direct".tr() : "all".tr();

  String baggageLabel() =>
      baggageOnly ? "add_baggage".tr() : "filter_mixed".tr();

  String tariffLabel() {
    if (refundable && exchangeable) return "${"filter_refundable".tr()} +1";
    if (refundable) return "filter_refundable".tr();
    if (exchangeable) return "filter_exchangeable".tr();
    return "all".tr();
  }

  String timeLabel() {
    if (!hasTimeFilter) return "all".tr();
    return rangeLabel(!_isFullRange(depRange) ? depRange : arrRange);
  }
}

/// Web'dagi to'liq "Filtr" sheet'ini ochadi. "Qo'llash" bosilsa yangi
/// qiymatlarni, bekor qilinsa `null` qaytaradi. [initialSection] `null`
/// bo'lsa barcha bo'limlar yig'ilgan holda ochiladi.
Future<_ViewFilterValues?> _showViewFiltersSheet(
  BuildContext context, {
  required _ViewFilterValues initial,
  required _ViewFilterSection? initialSection,
  required List<_AirlineGroup> airlines,
}) {
  return showModalBottomSheet<_ViewFilterValues>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ViewFiltersSheet(
      initial: initial,
      initialSection: initialSection,
      airlines: airlines,
    ),
  );
}

class _ViewFiltersSheet extends StatefulWidget {
  final _ViewFilterValues initial;
  final _ViewFilterSection? initialSection;
  final List<_AirlineGroup> airlines;

  const _ViewFiltersSheet({
    required this.initial,
    required this.initialSection,
    required this.airlines,
  });

  @override
  State<_ViewFiltersSheet> createState() => _ViewFiltersSheetState();
}

class _ViewFiltersSheetState extends State<_ViewFiltersSheet> {
  late final _ViewFilterValues _draft = widget.initial.clone();
  late _ViewFilterSection? _expanded = widget.initialSection;

  void _toggle(_ViewFilterSection s) {
    HapticFeedback.lightImpact();
    setState(() => _expanded = _expanded == s ? null : s);
  }

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    final height = MediaQuery.of(context).size.height * 0.9;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // Pastki system navigatsiya paneli ostida Tozalash/Qo'llash tugmalari
      // qolib ketmasligi uchun (useSafeArea faqat tepani himoya qiladi).
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: t.mid.withAlpha(90),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Sarlavha + yopish tugmasi (web'dagi kabi).
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 10, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "filter_title".tr(),
                      style: _TixTheme.style(20, FontWeight.w800, t.hi),
                    ),
                  ),
                  Material(
                    color: t.line.withAlpha(t.dark ? 40 : 255),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: SizedBox(
                        width: 38,
                        height: 38,
                        child: Icon(Icons.close_rounded, size: 21, color: t.hi),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                children: [
                  _SheetSection(
                    icon: Icons.swap_vert_rounded,
                    title: "order_by_tab".tr(),
                    subtitle: _draft.sortLabel(),
                    expanded: _expanded == _ViewFilterSection.sort,
                    onHeaderTap: () => _toggle(_ViewFilterSection.sort),
                    children: [
                      for (int i = 0; i < 4; i++)
                        _ViewFilterOptionRow(
                          label: [
                            "price_order".tr(),
                            "dep_order".tr(),
                            "arr_order".tr(),
                            "duration_order".tr(),
                          ][i],
                          selected: _draft.sort == i,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() => _draft.sort = i);
                          },
                        ),
                    ],
                  ),
                  _SheetSection(
                    icon: Icons.flight_takeoff_rounded,
                    title: "transfer_tab".tr(),
                    subtitle: _draft.transferLabel(),
                    expanded: _expanded == _ViewFilterSection.transfer,
                    onHeaderTap: () => _toggle(_ViewFilterSection.transfer),
                    children: [
                      _ViewFilterOptionRow(
                        label: "all".tr(),
                        selected: !_draft.directOnly,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _draft.directOnly = false);
                        },
                      ),
                      _ViewFilterOptionRow(
                        label: "only_direct".tr(),
                        selected: _draft.directOnly,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _draft.directOnly = true);
                        },
                      ),
                    ],
                  ),
                  _SheetSection(
                    icon: Icons.luggage_rounded,
                    title: "baggage_tab".tr(),
                    subtitle: _draft.baggageLabel(),
                    expanded: _expanded == _ViewFilterSection.baggage,
                    onHeaderTap: () => _toggle(_ViewFilterSection.baggage),
                    children: [
                      // Web'dagi kabi bitta switch: o'chiq — aralash,
                      // yoniq — faqat bagajli reyslar.
                      _SheetSwitchRow(
                        label: _draft.baggageLabel(),
                        value: _draft.baggageOnly,
                        onChanged: (v) {
                          HapticFeedback.lightImpact();
                          setState(() => _draft.baggageOnly = v);
                        },
                      ),
                    ],
                  ),
                  _SheetSection(
                    icon: Icons.verified_user_outlined,
                    title: "filter_tariff_title".tr(),
                    subtitle: _draft.tariffLabel(),
                    expanded: _expanded == _ViewFilterSection.tariff,
                    onHeaderTap: () => _toggle(_ViewFilterSection.tariff),
                    children: [
                      _ViewFilterOptionRow(
                        label: "filter_refundable".tr(),
                        selected: _draft.refundable,
                        isCheckbox: true,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(
                              () => _draft.refundable = !_draft.refundable);
                        },
                      ),
                      _ViewFilterOptionRow(
                        label: "filter_exchangeable".tr(),
                        selected: _draft.exchangeable,
                        isCheckbox: true,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(
                              () => _draft.exchangeable = !_draft.exchangeable);
                        },
                      ),
                    ],
                  ),
                  _SheetSection(
                    icon: Icons.schedule_rounded,
                    title: "filter_time_title".tr(),
                    subtitle: _draft.timeLabel(),
                    expanded: _expanded == _ViewFilterSection.time,
                    onHeaderTap: () => _toggle(_ViewFilterSection.time),
                    children: [
                      _SheetTimeRange(
                        icon: Icons.flight_takeoff_rounded,
                        label: "filter_dep_time".tr(),
                        values: _draft.depRange,
                        onChanged: (r) => setState(() => _draft.depRange = r),
                      ),
                      const SizedBox(height: 10),
                      _SheetTimeRange(
                        icon: Icons.flight_land_rounded,
                        label: "filter_arr_time".tr(),
                        values: _draft.arrRange,
                        onChanged: (r) => setState(() => _draft.arrRange = r),
                      ),
                    ],
                  ),
                  _SheetSection(
                    icon: Icons.airplane_ticket_outlined,
                    title: "airlines_tab".tr(),
                    subtitle: _draft.excludedAirlines.isEmpty
                        ? "all".tr()
                        : "${widget.airlines.length - _draft.excludedAirlines.length}/${widget.airlines.length}",
                    expanded: _expanded == _ViewFilterSection.airlines,
                    onHeaderTap: () => _toggle(_ViewFilterSection.airlines),
                    showDivider: false,
                    children: [
                      _SheetAirlineRow(
                        title: "all_airlines".tr(),
                        checked: _draft.excludedAirlines.isEmpty,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            if (_draft.excludedAirlines.isEmpty) {
                              _draft.excludedAirlines.addAll(
                                  [for (final a in widget.airlines) a.code]);
                            } else {
                              _draft.excludedAirlines.clear();
                            }
                          });
                        },
                      ),
                      for (final a in widget.airlines)
                        _SheetAirlineRow(
                          code: a.code,
                          title: a.title,
                          checked: !_draft.excludedAirlines.contains(a.code),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              if (!_draft.excludedAirlines.remove(a.code)) {
                                _draft.excludedAirlines.add(a.code);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Pastki tugmalar (web'dagi kabi): Tozalash + Qo'llash.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _SheetFooterButton(
                      label: "filter_clear".tr(),
                      filled: false,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        setState(() => _draft.reset());
                        AnalyticsService().trackButtonTap('filter_reset',
                            extra: {'source': 'sheet'});
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SheetFooterButton(
                      label: "apply".tr(),
                      filled: true,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        AnalyticsService().trackButtonTap('filter_applied',
                            extra: {
                          'sort': _draft.sort,
                          'direct_only': _draft.directOnly,
                          'baggage_only': _draft.baggageOnly,
                          'refundable': _draft.refundable,
                          'exchangeable': _draft.exchangeable,
                          'time_filter': _draft.hasTimeFilter,
                          'excluded_airlines': _draft.excludedAirlines.length,
                          'has_any_filter': _draft.hasAnyFilter,
                        });
                        Navigator.of(context).pop(_draft);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Accordion bo'limi: ikonkali sarlavha (joriy qiymat bilan) va ochilganda
/// ko'rinadigan kontent (web'dagi "Filterlar" bo'limlari kabi).
class _SheetSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool expanded;
  final VoidCallback onHeaderTap;
  final List<Widget> children;
  final bool showDivider;

  const _SheetSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.expanded,
    required this.onHeaderTap,
    required this.children,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onHeaderTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ProjectTheme.brandColor.withAlpha(t.dark ? 46 : 18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 21, color: ProjectTheme.brandColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _TixTheme.style(15.5, FontWeight.w700, t.hi),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _TixTheme.style(12.5, FontWeight.w500, t.mid),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      size: 22, color: t.mid),
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 8),
            child: Column(children: children),
          ),
        if (showDivider) Divider(height: 1, thickness: 1, color: t.line),
      ],
    );
  }
}

/// Bagaj bo'limidagi switch qatori (web'dagi kabi).
class _SheetSwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SheetSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.line, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: _TixTheme.style(14.5, FontWeight.w500, t.hi),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: ProjectTheme.brandColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Vaqt oralig'i slideri: sarlavha + joriy oraliq + slider + shkala
/// (web'dagi "Ketish vaqti / Qo'nish vaqti" bloklari).
class _SheetTimeRange extends StatelessWidget {
  final IconData icon;
  final String label;
  final RangeValues values;
  final ValueChanged<RangeValues> onChanged;

  const _SheetTimeRange({
    required this.icon,
    required this.label,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: t.mid),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: _TixTheme.style(13.5, FontWeight.w600, t.hi),
              ),
            ),
            Text(
              _ViewFilterValues.rangeLabel(values),
              style: _TixTheme.style(13.5, FontWeight.w800, t.hi),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: ProjectTheme.brandColor,
            inactiveTrackColor: t.line,
            thumbColor: Colors.white,
            overlayColor: ProjectTheme.brandColor.withAlpha(26),
            trackHeight: 4,
            rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 10, elevation: 2),
          ),
          child: RangeSlider(
            values: values,
            min: 0,
            max: _ViewFilterValues.dayMinutes,
            divisions: 48, // 30 daqiqalik qadam
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final h in const ["00", "06", "12", "18", "24"])
                Text(h, style: _TixTheme.style(11.5, FontWeight.w500, t.mid)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Aviakompaniyalar bo'limidagi qator: logo + nom + checkbox.
class _SheetAirlineRow extends StatelessWidget {
  final String? code;
  final String title;
  final bool checked;
  final VoidCallback onTap;

  const _SheetAirlineRow({
    this.code,
    required this.title,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            if (code != null) ...[
              _AirlineCircle(code: code!, size: 28),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _TixTheme.style(
                    14, code == null ? FontWeight.w700 : FontWeight.w500, t.hi),
              ),
            ),
            Icon(
              checked
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 22,
              color: checked ? ProjectTheme.brandColor : t.mid.withAlpha(140),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sheet pastidagi tugma: to'ldirilgan (Qo'llash) yoki hoshiyali (Tozalash).
class _SheetFooterButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _SheetFooterButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    return Material(
      color: filled ? ProjectTheme.brandColor : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: filled ? null : Border.all(color: t.line, width: 1.2),
          ),
          child: Text(
            label,
            style: _TixTheme.style(
                15, FontWeight.w700, filled ? Colors.white : t.hi),
          ),
        ),
      ),
    );
  }
}

/// Sheet ichidagi bitta variant qatori (web'dagi kabi: tanlangani ko'k
/// hoshiya bilan ajratiladi, belgi o'ng tomonda).
class _ViewFilterOptionRow extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isCheckbox;
  final VoidCallback onTap;

  const _ViewFilterOptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
    this.isCheckbox = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    final Color border = selected ? ProjectTheme.brandColor : t.line;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? ProjectTheme.brandColor.withAlpha(t.dark ? 46 : 16)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border, width: selected ? 1.4 : 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _TixTheme.style(14.5,
                        selected ? FontWeight.w700 : FontWeight.w500, t.hi),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isCheckbox
                      ? (selected
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded)
                      : (selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded),
                  size: 22,
                  color:
                      selected ? ProjectTheme.brandColor : t.mid.withAlpha(140),
                ),
              ],
            ),
          ),
        ),
      ),
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
    final t = _TixTheme.of(context);
    return Column(
      children: [
        const SizedBox(height: 24),
        SizedBox(
          height: 48,
          width: 48,
          child: Image.asset(Assets.ticketsSearchEmptyIcon),
        ),
        const SizedBox(height: 12),
        Text(
          "not_found_tickets".tr(),
          textAlign: TextAlign.center,
          style: _TixTheme.style(14, FontWeight.w600, t.hi),
        ),
        const SizedBox(height: 14),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onClear();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: ProjectTheme.brandColor, width: 1.2),
              ),
              child: Text(
                "filter_clear".tr(),
                style: _TixTheme.style(
                    13.5, FontWeight.w700, ProjectTheme.brandColor),
              ),
            ),
          ),
        ),
      ],
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
  for (final g in groups) {
    g.flights.sort((a, b) => _flightPriceUzs(a).compareTo(_flightPriceUzs(b)));
  }
  groups.sort((a, b) =>
      _flightPriceUzs(a.cheapest).compareTo(_flightPriceUzs(b.cheapest)));
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

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    final groups = _groupFlightsByAirline(widget.flights);
    if (groups.length < 2) return const SizedBox.shrink();

    final visible = _expanded ? groups : groups.take(_collapsedCount).toList();
    final hiddenCount = groups.length - _collapsedCount;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(24),
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
                    style: _TixTheme.style(15.5, FontWeight.w800, t.hi),
                  ),
                ),
              ),
              if (hiddenCount > 0)
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
            _AirlineSummaryRow(group: visible[i]),
          ],
        ],
      ),
    );
  }
}

class _AirlineSummaryRow extends StatelessWidget {
  final _AirlineGroup group;

  const _AirlineSummaryRow({required this.group});

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
    Navigator.of(context)
        .pushNamed(TicketInfoPage.routeName, arguments: flight);
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
                      style: _TixTheme.style(14.5, FontWeight.w800, _kTixGreen),
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: _kTixGreen.withAlpha(160)),
              ],
            ),
            if (times.isNotEmpty) ...[
              const SizedBox(height: 7),
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
                            GestureDetector(
                              onTap: () => _openFlight(context, e.value),
                              child: Text(
                                e.key,
                                style: _TixTheme.style(
                                  13,
                                  FontWeight.w700,
                                  e.key == cheapestTime ? _kTixGreen : t.hi,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
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
