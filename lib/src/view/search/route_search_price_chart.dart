// ignore_for_file: deprecated_member_use
// part of route_search_page.dart — private widgets

part of 'route_search_page.dart';

/// "Narxlar jadvali" kartasi — mysafar.uz mobil ko'rinishidagi bilan bir xil:
/// sarlavha + "Ochish" hapchasi, ostida yaqin kunlar ustun-grafigi (eng arzoni
/// yashil, ustida narx pufagi), eng pastda eng arzon kun qatori.
///
/// Butun karta bosiladi — to'liq 365 kunlik jadval bottom sheet'da ochiladi.
class _PriceChartCard extends StatelessWidget {
  final TicketDatePriceModel? prices;
  final bool loading;
  final VoidCallback onTap;

  const _PriceChartCard({
    required this.prices,
    required this.loading,
    required this.onTap,
  });

  /// Webda ko'rsatiladigan ustunlar soni.
  static const int _barCount = 16;

  /// Ustun balandligi chegaralari (piksel).
  static const double _barMinH = 14;
  static const double _barMaxH = 50;

  /// Bugundan boshlab narxi bor dastlabki [_barCount] kun.
  List<(DateTime, double)> _window(AppCurrency currency) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final items = <(DateTime, double)>[];
    for (final p in _pricesForCurrency(prices, currency)) {
      final d = p.date;
      final s = (p.sum ?? '').trim();
      if (d == null || s.isEmpty || s == '0') continue;
      if (d.isBefore(today)) continue;
      final v = _parseCompactPrice(s);
      if (v != null) items.add((d, v));
    }
    items.sort((a, b) => a.$1.compareTo(b.$1));
    return items.take(_barCount).toList();
  }

  /// "2.2M" / "551K" — pufakcha uchun ixcham narx.
  static String _compact(double v) {
    if (v >= 1000000) {
      final m = v / 1000000;
      return "${m.toStringAsFixed(m >= 10 ? 0 : 1)}M";
    }
    if (v >= 1000) return "${(v / 1000).round()}K";
    return v.round().toString();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = Provider.of<CurrencyProvider>(context).currency;
    final days = loading ? const <(DateTime, double)>[] : _window(currency);

    // Eng arzon kun (ko'rsatilayotgan oyna ichida) — yashil ustun va
    // pastdagi qator shu kunni ko'rsatadi.
    int cheapIndex = -1;
    for (int i = 0; i < days.length; i++) {
      if (cheapIndex == -1 || days[i].$2 < days[cheapIndex].$2) cheapIndex = i;
    }

    return Material(
      color: isDark ? ProjectTheme.cardColorDark : Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context, isDark),
              const SizedBox(height: 14),
              if (loading)
                const _PriceChartBarsShimmer()
              else if (days.isEmpty)
                const SizedBox(height: 50)
              else
                _bars(days, cheapIndex, isDark: isDark),
              if (!loading && cheapIndex != -1) ...[
                const SizedBox(height: 16),
                _cheapestRow(
                  context,
                  isDark,
                  days[cheapIndex].$1,
                  days[cheapIndex].$2,
                  currency,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Sarlavha qatori: ikonka + nom + "Ochish" hapchasi.
  /// Qorong'i fonda ko'k matn deyarli ko'rinmas edi — tugma to'liq ko'k,
  /// yozuv/ikon oq.
  Widget _header(BuildContext context, bool isDark) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark ? ProjectTheme.brandColor : _Web.iconBoxBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.bar_chart_rounded,
            size: 17,
            color: isDark ? Colors.white : _Web.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            "price_chart_title".tr(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: isDark ? ProjectTheme.textColorDark : _Web.toggleText,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 10, 6),
          decoration: BoxDecoration(
            // Light: och ko'k pill + ko'k matn; dark: to'liq ko'k + oq matn.
            color: isDark ? ProjectTheme.brandColor : _Web.pillBg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "view".tr(),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : _Web.blue,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: isDark ? Colors.white : _Web.blue,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Ustunlar qatori (web: `flex items-end gap-[3px]`, `rounded-t-[4px]`).
  /// Qorong'i rejimda oddiy ustunlar yorqin ko'k — qora fonda aniq ko'rinadi.
  Widget _bars(
    List<(DateTime, double)> days,
    int cheapIndex, {
    required bool isDark,
  }) {
    final double min = days.map((e) => e.$2).reduce((a, b) => a < b ? a : b);
    final double max = days.map((e) => e.$2).reduce((a, b) => a > b ? a : b);
    final double span = max - min;
    // Dark: #5B9CFF (yorqin), light: webdagi och kulrang-ko'k.
    final Color barColor =
        isDark ? const Color(0xFF5B9CFF) : const Color(0xFFDDE5F2);

    return SizedBox(
      height: _barMaxH + 28, // ustunlar + pufakcha uchun joy
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < days.length; i++) ...[
            if (i != 0) const SizedBox(width: 3),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (i == cheapIndex) ...[
                    // Ustun pufakchadan tor — yozuv qo'shni ustunlar ustiga
                    // chiqadi (webdagi `overflow: visible` kabi). OverflowBox
                    // buni ogohlantirishsiz beradi.
                    SizedBox(
                      height: 24,
                      child: OverflowBox(
                        maxWidth: 80,
                        maxHeight: 24,
                        child: _ChartCardBubble(text: _compact(days[i].$2)),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Container(
                    height: span <= 0
                        ? _barMaxH
                        : _barMinH +
                            (days[i].$2 - min) / span * (_barMaxH - _barMinH),
                    decoration: BoxDecoration(
                      color: i == cheapIndex ? _Web.switchOn : barColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
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

  /// Pastki qator: "● ENG ARZON / 2.23M so'm" ... "3 avgust".
  Widget _cheapestRow(
    BuildContext context,
    bool isDark,
    DateTime day,
    double value,
    AppCurrency currency,
  ) {
    return Column(
      children: [
        Divider(
          height: 1,
          thickness: 1,
          color: isDark ? ProjectTheme.borderDark : const Color(0xFFE7EDF6),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: _Web.switchOn,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "cheapest".tr(),
              maxLines: 1,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _Web.switchOn,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "${ElementFormatter.formatNumberWithSpaces(value)} ${currency.label}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? ProjectTheme.textColorDark : _Web.toggleText,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "${day.day} ${ElementFormatter.formatMonth(day.month).toLowerCase()}",
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8C99B3),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Eng arzon ustun ustidagi yashil narx pufakchasi (pastga qaragan uchli).
class _ChartCardBubble extends StatelessWidget {
  final String text;

  const _ChartCardBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: _Web.switchOn,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            text,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 10,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        // Ustunga qaragan kichik uchburchak.
        CustomPaint(
          size: const Size(8, 4),
          painter: _BubbleTailPainter(),
        ),
      ],
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = _Web.switchOn);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Narxlar hali yuklanmagan paytdagi ustunlar skeleti.
class _PriceChartBarsShimmer extends StatelessWidget {
  const _PriceChartBarsShimmer();

  /// Skelet ustunlarining nisbiy balandliklari (0..1) — takrorlanadi.
  static const List<double> _pattern = [
    0.5, 0.72, 0.44, 0.66, 0.9, 0.58, 0.8, 0.48,
    0.62, 0.86, 0.54, 0.7, 0.42, 0.76, 0.6, 0.88,
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: _PriceChartCard._barMaxH + 20,
      child: Shimmer.fromColors(
        baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (int i = 0; i < _pattern.length; i++) ...[
              if (i != 0) const SizedBox(width: 3),
              Expanded(
                child: Container(
                  height: _PriceChartCard._barMaxH * _pattern[i],
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  NARXLAR JADVALI BOTTOM SHEET
// ══════════════════════════════════════════════════════════════════════

/// Grafikdagi bitta kun.
class _ChartDay {
  final DateTime date;
  final double? value; // narx (joriy valyutada), yo'q bo'lsa null

  _ChartDay(this.date, this.value);
}

/// Narxlar jadvali: bugundan boshlab 365 kun. Narxlar mavjud oylik-narx
/// API'sidan (≈30 kun) olinadi — qolgan kunlar "Noma'lum". Narx pufagi
/// gorizontal MARKAZDA qotib turadi: grafik scroll bo'lganda markazga
/// to'g'ri kelgan ustun bo'yicha faqat tepaga-pastga siljiydi.
class _PriceChartSheet extends StatefulWidget {
  final AirPortsModel from;
  final AirPortsModel to;
  final DateTime? initialDate;
  final DateTime? initialEndDate;

  const _PriceChartSheet({
    required this.from,
    required this.to,
    this.initialDate,
    this.initialEndDate,
  });

  @override
  State<_PriceChartSheet> createState() => _PriceChartSheetState();
}

/// Narxlar jadvali sheet'i. Tepadagi tanlagich:
///  • "Bir tomonga" — bitta grafik, bitta sana (avvalgi holat);
///  • "Borish-kelish" — IKKITA grafik (qaytish grafigi teskari yo'nalish
///    narxlari bilan), kalendar singari ikki sana tanlanadi.
/// Natija: DateTime (bir tomonga) yoki PickerDateRange (borish-kelish).
class _PriceChartSheetState extends State<_PriceChartSheet> {
  late bool _round = widget.initialEndDate != null;

  TicketDatePriceModel? _depPrices;
  bool _depLoading = true;

  TicketDatePriceModel? _retPrices;
  bool _retLoading = false;
  bool _retRequested = false;

  _ChartDay? _dep;
  _ChartDay? _ret;

  @override
  void initState() {
    super.initState();
    _loadDep();
    if (_round) _loadRet();
  }

  Future<void> _loadDep() async {
    try {
      final response = await AviaService().getPriceByMonth(
        widget.from.cityIataCode ?? '',
        widget.to.cityIataCode ?? '',
      );
      if (!mounted) return;
      setState(() {
        _depLoading = false;
        if (response is NetworkSuccessResponse) {
          _depPrices = response.data as TicketDatePriceModel;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _depLoading = false);
    }
  }

  /// Qaytish grafigi narxlari — TESKARI yo'nalish (to → from) bo'yicha.
  Future<void> _loadRet() async {
    if (_retRequested) return;
    _retRequested = true;
    setState(() => _retLoading = true);
    try {
      final response = await AviaService().getPriceByMonth(
        widget.to.cityIataCode ?? '',
        widget.from.cityIataCode ?? '',
      );
      if (!mounted) return;
      setState(() {
        _retLoading = false;
        if (response is NetworkSuccessResponse) {
          _retPrices = response.data as TicketDatePriceModel;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _retLoading = false);
    }
  }

  void _setRound(bool round) {
    if (_round == round) return;
    HapticFeedback.lightImpact();
    setState(() => _round = round);
    if (round) _loadRet();
  }

  String _dateLabel(DateTime d) =>
      "${d.day} ${ElementFormatter.formatMonth(d.month).toLowerCase()}";

  /// Tanlash tugmasi bosildi: rejimga qarab natija qaytariladi.
  void _select() {
    HapticFeedback.mediumImpact();
    final dep = _dep;
    if (dep == null) return;
    if (!_round) {
      Navigator.of(context).pop(dep.date);
      return;
    }
    final ret = _ret;
    if (ret == null) return;
    // Qaytish jo'nashdan oldin bo'lsa — tartibini to'g'irlaymiz.
    final DateTime start = dep.date.isBefore(ret.date) ? dep.date : ret.date;
    final DateTime end = dep.date.isBefore(ret.date) ? ret.date : dep.date;
    Navigator.of(context).pop(PickerDateRange(start, end));
  }

  @override
  Widget build(BuildContext context) {
    final currency = Provider.of<CurrencyProvider>(context).currency;
    final dep = _dep;
    final ret = _ret;

    // Tugma yozuvi va (bo'lsa) umumiy narx.
    String buttonDate = dep != null ? _dateLabel(dep.date) : '';
    double? totalPrice = dep?.value;
    if (_round) {
      if (dep != null && ret != null) {
        buttonDate = "${_dateLabel(dep.date)} – ${_dateLabel(ret.date)}";
      }
      totalPrice = (dep?.value != null && ret?.value != null)
          ? dep!.value! + ret!.value!
          : null;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: context.color.primaryContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 10),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(110),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "price_chart_title".tr(),
                  style: context.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Borish / Borish-kelish tanlagichi.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ModeSelector(
                round: _round,
                onChanged: _setRound,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (_round) _chartCaption(context, "depDate".tr()),
                    _PriceChartView(
                      key: const ValueKey('dep-chart'),
                      prices: _depPrices,
                      loading: _depLoading,
                      initialDate: widget.initialDate,
                      currency: currency,
                      onCentered: (day) => setState(() => _dep = day),
                    ),
                    if (_round) ...[
                      _chartCaption(context, "arrDate".tr()),
                      _PriceChartView(
                        key: const ValueKey('ret-chart'),
                        prices: _retPrices,
                        loading: _retLoading,
                        initialDate: widget.initialEndDate,
                        currency: currency,
                        onCentered: (day) => setState(() => _ret = day),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Tanlash tugmasi.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ProjectTheme.blueButtonStyle,
                  onPressed: buttonDate.isEmpty ? null : _select,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "select_date_button"
                            .tr(namedArgs: {"date": buttonDate}),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      if (totalPrice != null)
                        Text(
                          _priceWithSuffix(totalPrice, currency),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartCaption(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// "Bir tomonga / Borish-kelish" segmentli tanlagich.
class _ModeSelector extends StatelessWidget {
  final bool round;
  final ValueChanged<bool> onChanged;

  const _ModeSelector({required this.round, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color trackColor =
        isDark ? Colors.white.withAlpha(20) : const Color(0xFFF1F4F9);

    Widget segment(String label, bool selected, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? (isDark ? ProjectTheme.brandColor : Colors.white)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: selected && !isDark
                  ? [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected && isDark
                    ? Colors.white
                    : context.textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          segment("one_way".tr(), !round, () => onChanged(false)),
          segment("round_trip".tr(), round, () => onChanged(true)),
        ],
      ),
    );
  }
}

/// Bitta narx grafigi: bugundan 365 kun, gorizontal scroll, markazda narx
/// pufagi (markazdagi ustun rangida). Markaz o'zgarganda [onCentered]
/// chaqiriladi.
class _PriceChartView extends StatefulWidget {
  final TicketDatePriceModel? prices;
  final bool loading;
  final DateTime? initialDate;
  final AppCurrency currency;
  final ValueChanged<_ChartDay> onCentered;

  const _PriceChartView({
    super.key,
    required this.prices,
    required this.loading,
    required this.initialDate,
    required this.currency,
    required this.onCentered,
  });

  @override
  State<_PriceChartView> createState() => _PriceChartViewState();
}

class _PriceChartViewState extends State<_PriceChartView> {
  static const int _daysCount = 365;
  static const double _itemExtent = 46;

  final ScrollController _scroll = ScrollController();
  int _centered = 0;

  /// Boshlang'ich sanaga sakrash hali bajarilmadi. MUHIM: yuklanish paytida
  /// ListView hali qurilmagan (hasClients=false) bo'ladi — sakrashni ro'yxat
  /// chizilgach bajaramiz, aks holda grafik 0-kunda qolib ketardi.
  bool _pendingJump = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    final initial = widget.initialDate;
    if (initial != null) {
      final idx = initial.difference(_today).inDays;
      if (idx > 0 && idx < _daysCount) {
        _centered = idx;
        _pendingJump = true;
      }
    }
    // Boshlang'ich markaz qiymatini ota widget'ga yetkazamiz.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onCentered(_dayAt(_centered));
    });
  }

  /// Kutilayotgan sakrashni ro'yxat chizilgan kadrdan keyin bajaradi.
  void _tryPendingJump() {
    if (!_pendingJump) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pendingJump) return;
      if (_scroll.hasClients) {
        _pendingJump = false;
        _scroll.jumpTo(_centered * _itemExtent);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _PriceChartView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Narxlar keldi/valyuta o'zgardi — markaz qiymatini yangilaymiz.
    if (oldWidget.prices != widget.prices ||
        oldWidget.currency != widget.currency) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onCentered(_dayAt(_centered));
      });
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final idx = (_scroll.offset / _itemExtent).round().clamp(0, _daysCount - 1);
    if (idx != _centered) {
      setState(() => _centered = idx);
      widget.onCentered(_dayAt(idx));
    }
  }

  static int _key(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  /// 365 kunlik jadval kunlari (narxi bo'lganlar to'ldirilgan).
  List<_ChartDay> _buildDays(AppCurrency currency) {
    final Map<int, double> byDay = {};
    for (final p in _pricesForCurrency(widget.prices, currency)) {
      final d = p.date;
      final s = (p.sum ?? '').trim();
      if (d == null || s.isEmpty || s == '0') continue;
      final v = _parseCompactPrice(s);
      if (v != null) byDay[d.year * 10000 + d.month * 100 + d.day] = v;
    }
    final start = _today;
    return [
      for (int i = 0; i < _daysCount; i++)
        _ChartDay(
          start.add(Duration(days: i)),
          byDay[_key(start.add(Duration(days: i)))],
        ),
    ];
  }

  _ChartDay _dayAt(int index) {
    final days = _buildDays(widget.currency);
    return days[index.clamp(0, days.length - 1)];
  }

  @override
  Widget build(BuildContext context) {
    final currency = widget.currency;
    final days = _buildDays(currency);
    final _ChartDay centeredDay = days[_centered];

    double minV = double.infinity, maxV = 0;
    for (final d in days) {
      final v = d.value;
      if (v == null) continue;
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }
    const double minBar = 34, maxBar = 120, unknownBar = 14;
    double barHeight(_ChartDay d) {
      final v = d.value;
      if (v == null) return unknownBar;
      if (maxV <= minV) return (minBar + maxBar) / 2;
      return minBar + (v - minV) / (maxV - minV) * (maxBar - minBar);
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color unknownColor =
        isDark ? Colors.white.withAlpha(40) : const Color(0xFFE4E8F0);
    // ARZON kunlar — yashil; QIMMATLARI — ko'k (dark'da yorqinroq, aks holda
    // qora fonda brand ko'k deyarli ko'rinmaydi).
    const Color cheapColor = Color(0xFF22C55E);
    final Color expensiveColor =
        isDark ? const Color(0xFF5B9CFF) : ProjectTheme.brandColor;
    final double cheapThreshold =
        maxV > minV ? minV + (maxV - minV) / 3 : double.infinity;
    Color colorOf(_ChartDay d) {
      final v = d.value;
      if (v == null) return unknownColor;
      return v <= cheapThreshold ? cheapColor : expensiveColor;
    }

    const double chartHeight = 150;
    const double labelsHeight = 40;
    final double centeredBarH = barHeight(centeredDay);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Oy nomi — markazdagi kunga qarab.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              ElementFormatter.formatMonth(centeredDay.date.month),
              style: context.textTheme.headlineSmall?.copyWith(fontSize: 13),
            ),
          ),
        ),
        SizedBox(
          height: chartHeight + labelsHeight + 46,
          child: widget.loading
              ? const _ChartShimmer()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    // Ro'yxat endi chiziladi — kutilayotgan boshlang'ich
                    // sakrashni shu kadrdan keyin bajaramiz.
                    _tryPendingJump();
                    final double sidePad =
                        (constraints.maxWidth - _itemExtent) / 2;
                    return Stack(
                      children: [
                        Positioned.fill(
                          top: 46,
                          child: ListView.builder(
                            controller: _scroll,
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: sidePad),
                            itemExtent: _itemExtent,
                            itemCount: days.length,
                            itemBuilder: (context, index) {
                              final day = days[index];
                              final bool isCentered = index == _centered;
                              final Color barColor = colorOf(day);
                              final Color centeredLabelColor = day.value != null
                                  ? barColor
                                  : (context.textTheme.bodyMedium?.color ??
                                      expensiveColor);
                              return Column(
                                children: [
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 150),
                                        width: _itemExtent - 8,
                                        height: barHeight(day),
                                        decoration: BoxDecoration(
                                          color: barColor,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: labelsHeight,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "${day.date.day}",
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: isCentered
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            color: isCentered
                                                ? centeredLabelColor
                                                : context.textTheme.bodyMedium
                                                    ?.color,
                                          ),
                                        ),
                                        Text(
                                          _weekDayShort(day.date),
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: isCentered
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isCentered
                                                ? centeredLabelColor
                                                : context.textTheme
                                                    .headlineSmall?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        // Narx pufagi — DOIM markazda, rangi markazdagi
                        // ustunga mos.
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOut,
                          left: 0,
                          right: 0,
                          top: 46 +
                              (chartHeight - centeredBarH)
                                  .clamp(0, chartHeight) -
                              40,
                          child: Center(
                            child: _PriceBubble(
                              text: centeredDay.value != null
                                  ? _priceWithSuffix(centeredDay.value!, currency)
                                  : "price_unknown".tr(),
                              color: centeredDay.value != null
                                  ? colorOf(centeredDay)
                                  : Colors.grey.withAlpha(200),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Grafik yuklanayotganda ko'rsatiladigan shimmer — har xil balandlikdagi
/// ustunlar bilan haqiqiy jadval shaklini takrorlaydi.
class _ChartShimmer extends StatelessWidget {
  const _ChartShimmer();

  /// Ustun balandliklari (px) — "tirik" grafik taassurotini beradigan
  /// aralash naqsh.
  static const List<double> _barHeights = [
    52,
    88,
    40,
    110,
    72,
    58,
    96,
    46,
    120,
    66,
    84,
    50
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 46, 16, 0),
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final h in _barHeights) ...[
                    Expanded(
                      child: Container(
                        height: h,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Kun yozuvlari o'rnidagi kichik chiziqchalar.
            Row(
              children: [
                for (int i = 0; i < _barHeights.length; i++)
                  Expanded(
                    child: Container(
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// Markazdagi narx pufagi — rangi markazda to'xtagan ustun rangiga mos
/// (arzon — yashil, qimmat — ko'k, noma'lum — kulrang).
class _PriceBubble extends StatelessWidget {
  final String text;
  final Color color;

  const _PriceBubble({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final Color bg = color;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        // Pastga qaragan uchburchak (pufak "dumi").
        CustomPaint(
          size: const Size(14, 7),
          painter: _BubbleArrowPainter(bg),
        ),
      ],
    );
  }
}

class _BubbleArrowPainter extends CustomPainter {
  final Color color;

  _BubbleArrowPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _BubbleArrowPainter old) => old.color != color;
}

// ══════════════════════════════════════════════════════════════════════
//  ENG ARZON KUNLAR
// ══════════════════════════════════════════════════════════════════════

/// Oylik narxlardan bugundan keyingi eng arzon 3 kunni ro'yxat qilib
/// ko'rsatadi; qator bosilganda o'sha kun bir tomonlama sana sifatida
/// tanlanadi. Ma'lumot bo'lmasa blok o'zini yashiradi.
