part of 'ticket_page.dart';

// ════════════════════════════════════════════════════════════════════
//  KO'RINISH FILTRLARI
//  • _RecViewFilterBar — appbar ostidagi chiplar: har biri o'z filtrining
//    joriy qiymatini ko'rsatadi, faol bo'lsa brend rangda ajraladi.
//  • _ViewFiltersSheet — to'liq balandlikdagi "Filtr" oynasi. Oddiy va
//    tushunarli tuzilma: saralash — radio ro'yxat, almashishlar — segment,
//    bagaj/tarif — izohli switch'lar (har birida "N ta reys"), vaqt — kun
//    qismlari (tun/ertalab/kunduzi/kechqurun). Pastdagi tugma natija sonini
//    jonli ko'rsatadi; natija bo'lmasa bosilmaydi.
// ════════════════════════════════════════════════════════════════════

/// Sheet bo'limlari — chip bosilganda mos bo'limga suriladi.
enum _ViewFilterSection { sort, transfer, baggage, tariff, time, airlines }

/// Kun qismlari — vaqt filtri shular bo'yicha (bir nechtasini tanlash mumkin).
enum _DayPeriod {
  night(0, 360, 'filter_period_night', Assets.ticketsFilterPeriodNightIcon),
  morning(
      360, 720, 'filter_period_morning', Assets.ticketsFilterPeriodMorningIcon),
  day(720, 1080, 'filter_period_day', Assets.ticketsFilterPeriodDayIcon),
  evening(1080, 1440, 'filter_period_evening',
      Assets.ticketsFilterPeriodEveningIcon);

  const _DayPeriod(this.startMinute, this.endMinute, this.labelKey, this.icon);

  final int startMinute;
  final int endMinute;
  final String labelKey;
  final String icon;

  String get label => labelKey.tr();

  /// "06–12" ko'rinishidagi soat oralig'i.
  String get hours =>
      "${(startMinute ~/ 60).toString().padLeft(2, '0')}–${(endMinute ~/ 60).toString().padLeft(2, '0')}";

  static _DayPeriod ofMinutes(int minutes) => _DayPeriod.values.firstWhere(
        (p) => minutes < p.endMinute,
        orElse: () => _DayPeriod.evening,
      );
}

/// Chiplardagi barcha ko'rinish-filtr qiymatlari bitta joyda.
/// Sheet nusxa (clone) ustida ishlaydi; "Ko'rsatish" bosilgandagina sahifa
/// holatiga ko'chiriladi.
class _ViewFilterValues {
  int sort = 0; // 0-narx, 1-uchish, 2-qo'nish, 3-davomiylik
  bool directOnly = false;
  bool baggageOnly = false;
  bool refundable = false;
  bool exchangeable = false;
  final Set<_DayPeriod> depPeriods = {};
  final Set<_DayPeriod> arrPeriods = {};
  final Set<String> excludedAirlines = {};

  /// Hech biri yoki hammasi tanlangan bo'lsa — filtr yo'q.
  static bool _periodsActive(Set<_DayPeriod> s) =>
      s.isNotEmpty && s.length < _DayPeriod.values.length;

  static bool matchesPeriods(Set<_DayPeriod> s, int? minutes) {
    if (!_periodsActive(s) || minutes == null) return true;
    return s.contains(_DayPeriod.ofMinutes(minutes));
  }

  bool get hasDepFilter => _periodsActive(depPeriods);
  bool get hasArrFilter => _periodsActive(arrPeriods);
  bool get hasTimeFilter => hasDepFilter || hasArrFilter;

  bool get hasAnyFilter =>
      directOnly ||
      baggageOnly ||
      refundable ||
      exchangeable ||
      hasTimeFilter ||
      excludedAirlines.isNotEmpty;

  /// Saralash ham, filtrlar ham standart holatda.
  bool get isDefault => sort == 0 && !hasAnyFilter;

  /// Faol filtrlar soni (saralash hisobga olinmaydi) — appbar belgisi uchun.
  int get activeCount => [
        directOnly,
        baggageOnly,
        refundable,
        exchangeable,
        hasDepFilter,
        hasArrFilter,
        excludedAirlines.isNotEmpty,
      ].where((e) => e).length;

  void reset() {
    sort = 0;
    directOnly = false;
    baggageOnly = false;
    refundable = false;
    exchangeable = false;
    depPeriods.clear();
    arrPeriods.clear();
    excludedAirlines.clear();
  }

  void copyFrom(_ViewFilterValues other) {
    sort = other.sort;
    directOnly = other.directOnly;
    baggageOnly = other.baggageOnly;
    refundable = other.refundable;
    exchangeable = other.exchangeable;
    depPeriods
      ..clear()
      ..addAll(other.depPeriods);
    arrPeriods
      ..clear()
      ..addAll(other.arrPeriods);
    excludedAirlines
      ..clear()
      ..addAll(other.excludedAirlines);
  }

  _ViewFilterValues clone() => _ViewFilterValues()..copyFrom(this);

  static const sortKeys = [
    "price_order",
    "dep_order",
    "arr_order",
    "duration_order",
  ];

  String sortLabel() => sortKeys[sort.clamp(0, sortKeys.length - 1)].tr();

  String tariffLabel() {
    if (refundable && exchangeable) return "${"filter_refundable".tr()} +1";
    if (refundable) return "filter_refundable".tr();
    if (exchangeable) return "filter_exchangeable".tr();
    return "filter_tariff_title".tr();
  }

  /// Tanlangan kun qismlari: "Ertalab, Kunduzi" (tartib bo'yicha).
  static String periodsLabel(Set<_DayPeriod> s) =>
      _DayPeriod.values.where(s.contains).map((p) => p.label).join(', ');

  String timeLabel() {
    final parts = [
      if (hasDepFilter) ...depPeriods,
      if (hasArrFilter) ...arrPeriods,
    ];
    if (parts.isEmpty) return "filter_time_title".tr();
    final first = _DayPeriod.values.firstWhere(parts.contains).label;
    return parts.length > 1 ? "$first +${parts.length - 1}" : first;
  }
}

/// SVG ikonka — joriy rangga bo'yaladi.
class _FilterIcon extends StatelessWidget {
  final String asset;
  final double size;
  final Color color;

  const _FilterIcon(this.asset, {this.size = 20, required this.color});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
//  CHIPLAR QATORI
// ────────────────────────────────────────────────────────────────────

/// Appbar ostidagi filter chiplari. Bosilganda to'liq sheet mos bo'limga
/// surilgan holda ochiladi; biror filtr faol bo'lsa boshida "Tozalash".
class _RecViewFilterBar extends StatelessWidget implements PreferredSizeWidget {
  final _ViewFilterValues values;
  final void Function(_ViewFilterSection section) onOpen;
  final VoidCallback onClear;

  const _RecViewFilterBar({
    required this.values,
    required this.onOpen,
    required this.onClear,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final v = values;
    final chips = <Widget>[
      if (!v.isDefault)
        _RecFilterChip(
          icon: Assets.ticketsFilterClearIcon,
          label: "filter_clear".tr(),
          active: false,
          showChevron: false,
          onTap: onClear,
        ),
      _RecFilterChip(
        icon: Assets.ticketsFilterSortIcon,
        label: v.sortLabel(),
        active: v.sort != 0,
        onTap: () => onOpen(_ViewFilterSection.sort),
      ),
      _RecFilterChip(
        icon: Assets.ticketsFilterTransferIcon,
        label: v.directOnly ? "only_direct".tr() : "transfer_tab".tr(),
        active: v.directOnly,
        onTap: () => onOpen(_ViewFilterSection.transfer),
      ),
      _RecFilterChip(
        icon: Assets.ticketsFilterBaggageIcon,
        label: v.baggageOnly ? "add_baggage".tr() : "baggage_tab".tr(),
        active: v.baggageOnly,
        onTap: () => onOpen(_ViewFilterSection.baggage),
      ),
      _RecFilterChip(
        icon: Assets.ticketsFilterTariffIcon,
        label: v.tariffLabel(),
        active: v.refundable || v.exchangeable,
        onTap: () => onOpen(_ViewFilterSection.tariff),
      ),
      _RecFilterChip(
        icon: Assets.ticketsFilterTimeIcon,
        label: v.timeLabel(),
        active: v.hasTimeFilter,
        onTap: () => onOpen(_ViewFilterSection.time),
      ),
      _RecFilterChip(
        icon: Assets.iconsRecentPlaneIcon,
        label: "airlines_tab".tr(),
        active: v.excludedAirlines.isNotEmpty,
        onTap: () => onOpen(_ViewFilterSection.airlines),
      ),
    ];

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 9, 16, 9),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }
}

/// Bitta filter chipi: ikonka + joriy qiymat + pastga strelka.
class _RecFilterChip extends StatelessWidget {
  final String icon;
  final String label;
  final bool active;
  final bool showChevron;
  final VoidCallback onTap;

  const _RecFilterChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    final Color brand = ProjectTheme.brandColor;
    final Color bg = active ? brand.withAlpha(t.dark ? 56 : 18) : t.tonal;
    final Color fg = active ? (t.dark ? Colors.white : brand) : t.hi;

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: active ? brand.withAlpha(t.dark ? 170 : 120) : bg,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: EdgeInsets.only(left: 11, right: showChevron ? 8 : 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FilterIcon(icon, size: 17, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                maxLines: 1,
                style: _TixTheme.style(13, FontWeight.w700, fg),
              ),
              if (showChevron) ...[
                const SizedBox(width: 3),
                _FilterIcon(
                  Assets.iconsFormChevronDownIcon,
                  size: 15,
                  color: fg.withAlpha(active ? 255 : 150),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
//  TO'LIQ "FILTR" SHEET'I
// ────────────────────────────────────────────────────────────────────

/// To'liq "Filtr" sheet'ini ochadi. Natija tugmasi bosilsa yangi qiymatlarni,
/// yopilsa `null` qaytaradi. [initialSection] berilsa sheet o'sha bo'limga
/// surilgan holda ochiladi. [countResults] — qiymatlar bo'yicha nechta reys
/// qolishini hisoblaydi (tugma va izohlardagi sonlar uchun).
Future<_ViewFilterValues?> _showViewFiltersSheet(
  BuildContext context, {
  required _ViewFilterValues initial,
  required _ViewFilterSection? initialSection,
  required List<_AirlineGroup> airlines,
  required int Function(_ViewFilterValues values) countResults,
}) {
  return showSdkFullHeightSheet<_ViewFilterValues>(
    context: context,
    builder: (context, controller) => _ViewFiltersSheet(
      initial: initial,
      initialSection: initialSection,
      airlines: airlines,
      countResults: countResults,
      scrollController: controller,
    ),
  );
}

class _ViewFiltersSheet extends StatefulWidget {
  final _ViewFilterValues initial;
  final _ViewFilterSection? initialSection;
  final List<_AirlineGroup> airlines;
  final int Function(_ViewFilterValues values) countResults;
  final ScrollController scrollController;

  const _ViewFiltersSheet({
    required this.initial,
    required this.initialSection,
    required this.airlines,
    required this.countResults,
    required this.scrollController,
  });

  @override
  State<_ViewFiltersSheet> createState() => _ViewFiltersSheetState();
}

class _ViewFiltersSheetState extends State<_ViewFiltersSheet> {
  static const double _hPadding = 16;

  /// Aviakompaniyalar ro'yxati boshida nechta qator ko'rinadi.
  static const int _collapsedAirlines = 6;

  late final _ViewFilterValues _draft = widget.initial.clone();

  final Map<_ViewFilterSection, GlobalKey> _sectionKeys = {
    for (final s in _ViewFilterSection.values)
      s: GlobalKey(debugLabel: 'filter_${s.name}'),
  };

  /// Ro'yxat surilganda sarlavha ostida chiziq ko'rsatiladi.
  final ValueNotifier<bool> _isScrolled = ValueNotifier(false);

  late bool _airlinesExpanded;

  // Jonli sonlar: umumiy natija va har bir variant yoqilgandagi natija.
  int _resultCount = 0;
  int _allTransfersCount = 0;
  int _directCount = 0;
  int _baggageCount = 0;
  int _refundCount = 0;
  int _exchangeCount = 0;

  @override
  void initState() {
    super.initState();
    _recount();
    // Yashirin qismda o'chirilgan aviakompaniya bo'lsa ro'yxat ochiq turadi.
    _airlinesExpanded = widget.airlines
        .skip(_collapsedAirlines)
        .any((a) => _draft.excludedAirlines.contains(a.code));

    final section = widget.initialSection;
    if (section != null && section != _ViewFilterSection.sort) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(section));
    }
  }

  @override
  void dispose() {
    _isScrolled.dispose();
    super.dispose();
  }

  void _recount() {
    int count(void Function(_ViewFilterValues v) change) {
      final values = _draft.clone();
      change(values);
      return widget.countResults(values);
    }

    _resultCount = widget.countResults(_draft);
    _allTransfersCount = count((v) => v.directOnly = false);
    _directCount = count((v) => v.directOnly = true);
    _baggageCount = count((v) => v.baggageOnly = true);
    _refundCount = count((v) => v.refundable = true);
    _exchangeCount = count((v) => v.exchangeable = true);
  }

  /// Qiymatni o'zgartiradi va sonlarni qayta hisoblaydi.
  void _update(VoidCallback change) {
    HapticFeedback.selectionClick();
    setState(() {
      change();
      _recount();
    });
  }

  void _scrollTo(_ViewFilterSection section) {
    final ctx = _sectionKeys[section]?.currentContext;
    if (!mounted || ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    AnalyticsService()
        .trackButtonTap('filter_reset', extra: {'source': 'sheet'});
    setState(() {
      _draft.reset();
      _recount();
    });
  }

  void _apply() {
    HapticFeedback.mediumImpact();
    AnalyticsService().trackButtonTap('filter_applied', extra: {
      'sort': _draft.sort,
      'direct_only': _draft.directOnly,
      'baggage_only': _draft.baggageOnly,
      'refundable': _draft.refundable,
      'exchangeable': _draft.exchangeable,
      'time_filter': _draft.hasTimeFilter,
      'excluded_airlines': _draft.excludedAirlines.length,
      'has_any_filter': _draft.hasAnyFilter,
      'result_count': _resultCount,
    });
    Navigator.of(context).pop(_draft);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    final Color sheetColor =
        t.dark ? ProjectTheme.cardColorDark : ProjectTheme.cardColorLight;

    return Scaffold(
      backgroundColor: sheetColor,
      body: Column(
        children: [
          _buildHeader(t),
          ValueListenableBuilder<bool>(
            valueListenable: _isScrolled,
            builder: (context, scrolled, _) => AnimatedOpacity(
              opacity: scrolled ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: Divider(height: 1, thickness: 1, color: t.line),
            ),
          ),
          Expanded(
            child: NotificationListener<ScrollUpdateNotification>(
              onNotification: (n) {
                if (n.depth == 0) _isScrolled.value = n.metrics.pixels > 0;
                return false;
              },
              // SingleChildScrollView — barcha bo'limlar quriladi, shuning
              // uchun chipdan kelganda istalgan bo'limga surish mumkin.
              child: SingleChildScrollView(
                controller: widget.scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(_hPadding, 0, _hPadding, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _section(
                      _ViewFilterSection.sort,
                      title: "order_by_tab".tr(),
                      child: _buildSort(),
                    ),
                    _section(
                      _ViewFilterSection.transfer,
                      title: "transfer_tab".tr(),
                      child: _FilterSegmented(
                        selected: _draft.directOnly ? 1 : 0,
                        options: [
                          ("all".tr(), _allTransfersCount),
                          ("only_direct".tr(), _directCount),
                        ],
                        onChanged: (i) =>
                            _update(() => _draft.directOnly = i == 1),
                      ),
                    ),
                    _section(
                      _ViewFilterSection.baggage,
                      title: "filter_conditions_title".tr(),
                      child: _buildConditions(),
                    ),
                    _section(
                      _ViewFilterSection.time,
                      title: "filter_time_title".tr(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _FilterPeriodPicker(
                            icon: Assets.ticketsFilterTakeoffIcon,
                            label: "filter_dep_time".tr(),
                            selected: _draft.depPeriods,
                            onToggle: (p) => _update(() {
                              if (!_draft.depPeriods.remove(p)) {
                                _draft.depPeriods.add(p);
                              }
                            }),
                          ),
                          const SizedBox(height: 18),
                          _FilterPeriodPicker(
                            icon: Assets.ticketsFilterLandingIcon,
                            label: "filter_arr_time".tr(),
                            selected: _draft.arrPeriods,
                            onToggle: (p) => _update(() {
                              if (!_draft.arrPeriods.remove(p)) {
                                _draft.arrPeriods.add(p);
                              }
                            }),
                          ),
                        ],
                      ),
                    ),
                    if (widget.airlines.length > 1)
                      _section(
                        _ViewFilterSection.airlines,
                        title: "airlines_tab".tr(),
                        trailing: _draft.excludedAirlines.isEmpty
                            ? null
                            : "${_selectedAirlinesCount()}/${widget.airlines.length}",
                        child: _buildAirlines(),
                      ),
                  ],
                ),
              ),
            ),
          ),
          _buildFooter(t, sheetColor),
        ],
      ),
    );
  }

  Widget _buildHeader(_TixTheme t) {
    final bool canReset = !_draft.isDefault;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 92),
              child: Text(
                "filter_title".tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _TixTheme.style(17, FontWeight.w700, t.hi),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: _FilterIcon(
                  Assets.iconsPlaceCloseIcon,
                  size: 24,
                  color: t.hi,
                ),
              ),
            ),
            // "Tozalash" — faqat standart qiymatlardan farq qilganda.
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                opacity: canReset ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: IgnorePointer(
                  ignoring: !canReset,
                  child: TextButton(
                    onPressed: _reset,
                    style: TextButton.styleFrom(
                      foregroundColor: ProjectTheme.brandColor,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(48, 40),
                    ),
                    child: Text(
                      "filter_clear".tr(),
                      maxLines: 1,
                      style: _TixTheme.style(
                        15,
                        FontWeight.w600,
                        t.dark
                            ? ProjectTheme.linkDark
                            : ProjectTheme.brandColor,
                      ),
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

  /// "N ta reysni ko'rsatish" — natija bo'lmasa bosilmaydi va nima uchunligini
  /// aytadi (bo'sh ro'yxatga olib kelmaslik uchun).
  Widget _buildFooter(_TixTheme t, Color sheetColor) {
    final bool hasResults = _resultCount > 0;
    final Color brand = ProjectTheme.brandColor;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: sheetColor,
        border: Border(top: BorderSide(color: t.line)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            _hPadding, 12, _hPadding, 12 + context.bottomPadding),
        child: SizedBox(
          height: 52,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: hasResults
                  ? brand
                  : (t.dark ? Colors.white.withAlpha(24) : t.tonal),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: hasResults ? _apply : null,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: Text(
                      hasResults
                          ? "filter_show_results"
                              .tr(namedArgs: {"count": "$_resultCount"})
                          : "filter_no_results".tr(),
                      key: ValueKey(_resultCount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _TixTheme.style(
                        16,
                        FontWeight.w700,
                        hasResults ? Colors.white : t.mid,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sections
  // ---------------------------------------------------------------------------

  Widget _section(
    _ViewFilterSection section, {
    required String title,
    required Widget child,
    String? trailing,
  }) {
    final t = _TixTheme.of(context);
    return Padding(
      key: _sectionKeys[section],
      padding:
          EdgeInsets.only(top: section == _ViewFilterSection.sort ? 8 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _TixTheme.style(16, FontWeight.w800, t.hi),
                  ),
                ),
                if (trailing != null)
                  Text(
                    trailing,
                    style: _TixTheme.style(13.5, FontWeight.w700, t.mid),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildSort() {
    const icons = [
      Assets.ticketsFilterPriceIcon,
      Assets.ticketsFilterTakeoffIcon,
      Assets.ticketsFilterLandingIcon,
      Assets.ticketsFilterDurationIcon,
    ];
    return _FilterGroupCard(
      children: [
        for (int i = 0; i < icons.length; i++)
          _FilterRadioRow(
            icon: icons[i],
            label: _ViewFilterValues.sortKeys[i].tr(),
            selected: _draft.sort == i,
            onTap: () {
              if (_draft.sort != i) _update(() => _draft.sort = i);
            },
          ),
      ],
    );
  }

  /// Bagaj va tarif shartlari — har bir switch ostida yoqilsa nechta reys
  /// qolishi yoziladi.
  Widget _buildConditions() {
    String flights(int n) =>
        "filter_flights_count".tr(namedArgs: {"count": "$n"});
    return _FilterGroupCard(
      children: [
        _FilterToggleRow(
          icon: Assets.ticketsFilterBaggageIcon,
          label: "add_baggage".tr(),
          subtitle: flights(_baggageCount),
          value: _draft.baggageOnly,
          onChanged: (v) => _update(() => _draft.baggageOnly = v),
        ),
        KeyedSubtree(
          key: _sectionKeys[_ViewFilterSection.tariff],
          child: _FilterToggleRow(
            icon: Assets.ticketsFilterRefundIcon,
            label: "filter_refundable".tr(),
            subtitle: flights(_refundCount),
            value: _draft.refundable,
            onChanged: (v) => _update(() => _draft.refundable = v),
          ),
        ),
        _FilterToggleRow(
          icon: Assets.ticketsFilterExchangeIcon,
          label: "filter_exchangeable".tr(),
          subtitle: flights(_exchangeCount),
          value: _draft.exchangeable,
          onChanged: (v) => _update(() => _draft.exchangeable = v),
        ),
      ],
    );
  }

  int _selectedAirlinesCount() => widget.airlines
      .where((a) => !_draft.excludedAirlines.contains(a.code))
      .length;

  Widget _buildAirlines() {
    final airlines = widget.airlines;
    final currency = Provider.of<CurrencyProvider>(context);
    // Bitta qatorni yashirish uchun "yana 1 ta" tugmasi ortiqcha.
    final bool canCollapse = airlines.length > _collapsedAirlines + 1;
    final visible = canCollapse && !_airlinesExpanded
        ? airlines.take(_collapsedAirlines)
        : airlines;
    final int selected = _selectedAirlinesCount();
    final _CheckState allState = selected == airlines.length
        ? _CheckState.checked
        : (selected == 0 ? _CheckState.unchecked : _CheckState.partial);

    return _FilterGroupCard(
      children: [
        _FilterAirlineRow(
          title: "all_airlines".tr(),
          state: allState,
          onTap: () => _update(() {
            if (allState == _CheckState.checked) {
              _draft.excludedAirlines
                  .addAll([for (final a in airlines) a.code]);
            } else {
              _draft.excludedAirlines.clear();
            }
          }),
        ),
        for (final a in visible)
          _FilterAirlineRow(
            code: a.code,
            title: a.title,
            price: currency.getElementPrice(a.cheapest.price),
            state: _draft.excludedAirlines.contains(a.code)
                ? _CheckState.unchecked
                : _CheckState.checked,
            onTap: () => _update(() {
              if (!_draft.excludedAirlines.remove(a.code)) {
                _draft.excludedAirlines.add(a.code);
              }
            }),
          ),
        if (canCollapse)
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _airlinesExpanded = !_airlinesExpanded);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _airlinesExpanded
                        ? "ticket_show_less".tr()
                        : "ticket_show_more_count".tr(namedArgs: {
                            "count": "${airlines.length - _collapsedAirlines}"
                          }),
                    style: _TixTheme.style(
                        14, FontWeight.w700, ProjectTheme.brandColor),
                  ),
                  const SizedBox(width: 2),
                  AnimatedRotation(
                    turns: _airlinesExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: _FilterIcon(
                      Assets.iconsFormChevronDownIcon,
                      size: 16,
                      color: ProjectTheme.brandColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────
//  SHEET BO'LAKLARI
// ────────────────────────────────────────────────────────────────────

/// Hoshiyali guruh kartasi — qatorlar orasida ingichka ajratkich.
class _FilterGroupCard extends StatelessWidget {
  final List<Widget> children;

  const _FilterGroupCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.line),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: 50,
                color: t.line,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Saralash varianti: ikonka + nom + radio doira; butun qator bosiladi.
class _FilterRadioRow extends StatelessWidget {
  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterRadioRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    final Color brand = ProjectTheme.brandColor;
    final Color accent = t.dark ? Colors.white : brand;

    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          child: Row(
            children: [
              _FilterIcon(icon, size: 22, color: selected ? accent : t.mid),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _TixTheme.style(
                    15,
                    selected ? FontWeight.w700 : FontWeight.w600,
                    t.hi,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? brand
                        : (t.dark
                            ? Colors.white.withAlpha(80)
                            : const Color(0xFFC5CCDA)),
                    width: selected ? 6.5 : 1.6,
                  ),
                  // Oq markaz faqat tanlanganda — dark'da bo'sh doira oq
                  // to'ldirilgan bo'lib, "tanlangan"dek ko'rinmasin.
                  color: selected ? Colors.white : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ikki (yoki undan ko'p) variantli segment boshqaruvi — tanlov ostida
/// siljuvchi oq "pill"; har bir variant yonida reyslar soni.
class _FilterSegmented extends StatelessWidget {
  final List<(String label, int count)> options;
  final int selected;
  final ValueChanged<int> onChanged;

  const _FilterSegmented({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.tonal,
        borderRadius: BorderRadius.circular(14),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double w = constraints.maxWidth / options.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: w * selected,
                top: 0,
                bottom: 0,
                width: w,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: t.dark ? Colors.white.withAlpha(36) : Colors.white,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: t.dark
                        ? null
                        : const [
                            BoxShadow(
                              color: Color(0x1A16244A),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  children: [
                    for (int i = 0; i < options.length; i++)
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: i == selected ? null : () => onChanged(i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    options[i].$1,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _TixTheme.style(
                                      14,
                                      i == selected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      i == selected ? t.hi : t.mid,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "${options[i].$2}",
                                  style: _TixTheme.style(
                                      12.5, FontWeight.w600, t.mid),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Ikonka + nom (+ izoh) + switch; butun qator bosiladi.
class _FilterToggleRow extends StatelessWidget {
  final String icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _FilterToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        child: Row(
          children: [
            _FilterIcon(icon, size: 22, color: value ? t.hi : t.mid),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: _TixTheme.style(15, FontWeight.w600, t.hi),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: _TixTheme.style(12.5, FontWeight.w500, t.mid),
                    ),
                  ],
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              activeThumbColor: Colors.white,
              activeTrackColor: ProjectTheme.brandColor,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor:
                  t.dark ? Colors.white.withAlpha(40) : const Color(0xFFDDE3EE),
              trackOutlineColor:
                  const WidgetStatePropertyAll(Colors.transparent),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

/// Jo'nash yoki qo'nish vaqti: sarlavha (+ tanlov xulosasi) va to'rtta kun
/// qismi kartasi. Bir nechtasini tanlash mumkin; hech biri tanlanmasa —
/// "Istalgan vaqt".
class _FilterPeriodPicker extends StatelessWidget {
  final String icon;
  final String label;
  final Set<_DayPeriod> selected;
  final ValueChanged<_DayPeriod> onToggle;

  const _FilterPeriodPicker({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    final bool active = _ViewFilterValues._periodsActive(selected);
    final Color accent = t.dark ? Colors.white : ProjectTheme.brandColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _FilterIcon(icon, size: 20, color: t.hi),
            const SizedBox(width: 8),
            Text(
              label,
              style: _TixTheme.style(14.5, FontWeight.w700, t.hi),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                active
                    ? _ViewFilterValues.periodsLabel(selected)
                    : "filter_any_time".tr(),
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _TixTheme.style(
                  13,
                  FontWeight.w600,
                  active ? accent : t.mid,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final p in _DayPeriod.values) ...[
              if (p != _DayPeriod.night) const SizedBox(width: 8),
              Expanded(
                child: _PeriodTile(
                  period: p,
                  selected: selected.contains(p),
                  onTap: () => onToggle(p),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _PeriodTile extends StatelessWidget {
  final _DayPeriod period;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodTile({
    required this.period,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    final Color brand = ProjectTheme.brandColor;
    final Color fg = selected ? (t.dark ? Colors.white : brand) : t.hi;

    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: selected ? brand.withAlpha(t.dark ? 56 : 16) : t.tonal,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? brand : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12.5),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Column(
                children: [
                  _FilterIcon(period.icon, size: 22, color: fg),
                  const SizedBox(height: 6),
                  Text(
                    period.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _TixTheme.style(
                      12.5,
                      selected ? FontWeight.w700 : FontWeight.w600,
                      fg,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    period.hours,
                    maxLines: 1,
                    style: _TixTheme.style(11, FontWeight.w500, t.mid),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _CheckState { checked, unchecked, partial }

/// Aviakompaniya qatori: logo + nom (+ eng arzon narx) + checkbox.
/// [code] berilmasa — "Barcha aviakompaniyalar" qatori.
class _FilterAirlineRow extends StatelessWidget {
  final String? code;
  final String title;
  final String? price;
  final _CheckState state;
  final VoidCallback onTap;

  const _FilterAirlineRow({
    this.code,
    required this.title,
    this.price,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    final Color brand = ProjectTheme.brandColor;
    final bool on = state != _CheckState.unchecked;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            if (code != null) ...[
              _AirlineCircle(code: code!, size: 32),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _TixTheme.style(
                      14.5,
                      code == null ? FontWeight.w700 : FontWeight.w600,
                      t.hi,
                    ),
                  ),
                  if (price != null && price!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      price!,
                      maxLines: 1,
                      style: _TixTheme.style(
                        12.5,
                        FontWeight.w700,
                        t.dark ? const Color(0xFF34D399) : _kTixGreen,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: on ? brand : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: on
                    ? null
                    : Border.all(
                        color: t.dark
                            ? Colors.white.withAlpha(80)
                            : const Color(0xFFC5CCDA),
                        width: 1.6,
                      ),
              ),
              child: on
                  ? Icon(
                      state == _CheckState.partial
                          ? Icons.remove_rounded
                          : Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
