import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/extension/date_time_ext.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/tools/formatters.dart'
    show ElementFormatter;
import 'package:mysafar_sdk/src/cubit/main/datePicker/date_picker_cubit.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/model/remote/avia/airports_model.dart'
    show AirPortsModel;
import 'package:syncfusion_flutter_datepicker/datepicker.dart'
    show PickerDateRange;

/// Qaysi sana maydoni tanlanmoqda — kalendardagi keyingi bosish shunga yoziladi.
enum _Focus { departure, returnDate, none }

/// Sana tanlash oynasi.
///
/// [type]: 0 — bir tomonga, 1 — borib-kelish (oraliq), 2 — murakkab marshrut
/// (bitta sana, narxlarsiz). Natija — [PickerDateRange]; bitta sanada
/// `endDate` doim `null`.
class DateCalendarWidget extends StatefulWidget {
  final int type;
  final PickerDateRange? params;
  final AirPortsModel? fromDir;
  final AirPortsModel? toDir;

  /// Sheet'ning `DraggableScrollableSheet` controller'i — ro'yxat eng tepada
  /// bo'lganda pastga tortib yopish shu orqali ishlaydi.
  final ScrollController? scrollController;

  const DateCalendarWidget({
    super.key,
    required this.type,
    required this.params,
    this.fromDir,
    this.toDir,
    this.scrollController,
  });

  @override
  State<DateCalendarWidget> createState() => _DateCalendarWidgetState();
}

class _DateCalendarWidgetState extends State<DateCalendarWidget> {
  static const double _hPadding = 16;
  static const int _monthCount = 12;
  static const double _monthTitleHeight = 52;
  static const double _rowHeight = 54;
  static const double _monthBottomGap = 8;

  static const _monthKeys = [
    'january', 'february', 'march', 'april', 'may', 'june', //
    'july', 'august', 'september', 'october', 'november', 'december',
  ];
  static const _weekdayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

  ScrollController? _ownController;
  ScrollController get _scrollController =>
      widget.scrollController ?? (_ownController ??= ScrollController());

  /// Ro'yxat surilganda hafta kunlari ostida chiziq ko'rsatiladi.
  final ValueNotifier<bool> _isScrolled = ValueNotifier(false);

  late final DateTime _today;
  late final DateTime _firstMonth;

  DateTime? _start;
  DateTime? _end;
  _Focus _focus = _Focus.departure;

  /// Kun bo'yicha ixcham narx ("2.88M") — cellBuilder har katakda ro'yxatni
  /// qayta aylanmasligi uchun.
  Map<DateTime, String> _priceByDate = const {};

  /// Eng arzon narxli kunlar — yashil rangda ajratiladi.
  Set<DateTime> _cheapestDays = const {};

  bool get _isRange => widget.type == 1;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _firstMonth = DateTime(now.year, now.month);

    final start = _dateOnly(widget.params?.startDate);
    final end = _isRange ? _dateOnly(widget.params?.endDate) : null;
    // Eskirgan (o'tib ketgan) sanalar tanlov sifatida tiklanmaydi.
    if (start != null && !start.isBefore(_today)) {
      _start = start;
      if (end != null && !end.isBefore(start)) _end = end;
    }
    _focus = _initialFocus();

    if (_start != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _jumpToMonth(_start!));
    }
  }

  @override
  void dispose() {
    _ownController?.dispose();
    _isScrolled.dispose();
    super.dispose();
  }

  _Focus _initialFocus() {
    if (!_isRange || _start == null) return _Focus.departure;
    return _end == null ? _Focus.returnDate : _Focus.none;
  }

  // ---------------------------------------------------------------------------
  // Selection
  // ---------------------------------------------------------------------------

  void _onDayTap(DateTime day) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_isRange) {
        _start = day;
        return;
      }
      switch (_focus) {
        case _Focus.departure:
          _start = day;
          if (_end != null && _end!.isBefore(day)) _end = null;
          _focus = _end == null ? _Focus.returnDate : _Focus.none;
        case _Focus.returnDate:
          if (_start == null || day.isBefore(_start!)) {
            _start = day;
            _end = null;
          } else {
            _end = day;
            _focus = _Focus.none;
          }
        case _Focus.none:
          // To'liq oraliqdan keyingi bosish — yangi oraliq boshlanadi.
          _start = day;
          _end = null;
          _focus = _Focus.returnDate;
      }
    });
  }

  void _focusDeparture() {
    if (!_isRange || _focus == _Focus.departure) return;
    HapticFeedback.selectionClick();
    setState(() => _focus = _Focus.departure);
  }

  void _focusReturn() {
    if (_focus == _Focus.returnDate) return;
    HapticFeedback.selectionClick();
    setState(
        () => _focus = _start == null ? _Focus.departure : _Focus.returnDate);
  }

  void _clearDeparture() {
    HapticFeedback.selectionClick();
    setState(() {
      _start = null;
      _end = null;
      _focus = _Focus.departure;
    });
  }

  void _clearReturn() {
    HapticFeedback.selectionClick();
    setState(() {
      _end = null;
      _focus = _Focus.returnDate;
    });
  }

  void _submit() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(PickerDateRange(_start, _isRange ? _end : null));
  }

  // ---------------------------------------------------------------------------
  // Prices
  // ---------------------------------------------------------------------------

  void _onPricesLoaded(DatePickerFilledState state) {
    final prices = <DateTime, String>{};
    final values = <DateTime, double>{};
    for (final element in state.datePrice.uzsPrices ?? const []) {
      final date = _dateOnly(element.date);
      final value = ElementFormatter.parsePrice(element.sum);
      if (date == null || value == null) continue;
      // API xom summa beradi — katakchada ixcham ko'rinadi ("2.88M").
      prices[date] = ElementFormatter.compactPrice(element.sum);
      values[date] = value;
    }

    var cheapest = <DateTime>{};
    if (values.length > 1) {
      final min = values.values.reduce((a, b) => a < b ? a : b);
      cheapest = {
        for (final e in values.entries)
          if (e.value == min) e.key
      };
    }

    setState(() {
      _priceByDate = prices;
      _cheapestDays = cheapest;
    });
  }

  // ---------------------------------------------------------------------------
  // Month geometry
  // ---------------------------------------------------------------------------

  DateTime _monthAt(int index) =>
      DateTime(_firstMonth.year, _firstMonth.month + index);

  /// Oy boshidagi bo'sh kataklar soni (hafta dushanbadan boshlanadi).
  int _leadingBlanks(DateTime month) => month.weekday - 1;

  int _daysIn(DateTime month) => DateTime(month.year, month.month + 1, 0).day;

  int _rowsIn(DateTime month) =>
      ((_leadingBlanks(month) + _daysIn(month)) / 7).ceil();

  double _monthExtent(int index) =>
      _monthTitleHeight +
      _rowsIn(_monthAt(index)) * _rowHeight +
      _monthBottomGap;

  void _jumpToMonth(DateTime date) {
    if (!mounted || !_scrollController.hasClients) return;
    final index =
        (date.year - _firstMonth.year) * 12 + date.month - _firstMonth.month;
    if (index <= 0 || index >= _monthCount) return;
    var offset = 0.0;
    for (var i = 0; i < index; i++) {
      offset += _monthExtent(i);
    }
    final position = _scrollController.position;
    _scrollController.jumpTo(offset.clamp(0.0, position.maxScrollExtent));
  }

  // ---------------------------------------------------------------------------
  // Colors
  // ---------------------------------------------------------------------------

  Color get _sheetColor => context.isDarkMode
      ? ProjectTheme.cardColorDark
      : ProjectTheme.cardColorLight;

  Color get _textColor => context.isDarkMode
      ? ProjectTheme.textColorDark
      : ProjectTheme.textColorLight;

  Color get _secondaryColor => context.isDarkMode
      ? ProjectTheme.secondaryTextDark
      : ProjectTheme.secondaryTextLight;

  Color get _hintColor => context.isDarkMode
      ? ProjectTheme.disabledTextDark
      : ProjectTheme.disabledTextLight;

  Color get _borderColor =>
      context.isDarkMode ? ProjectTheme.borderDark : ProjectTheme.borderLight;

  Color get _rangeColor =>
      ProjectTheme.brandColor.withAlpha(context.isDarkMode ? 70 : 28);

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DatePickerCubit(
        fromWhere: widget.fromDir,
        toWhere: widget.toDir,
        flightType: widget.type,
      ),
      child: BlocListener<DatePickerCubit, DatePickerState>(
        listener: (context, state) {
          if (state is DatePickerFilledState) _onPricesLoaded(state);
        },
        child: Scaffold(
          backgroundColor: _sheetColor,
          body: Column(
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(_hPadding, 8, _hPadding, 0),
                child: _buildDateFields(),
              ),
              _buildWeekdays(),
              ValueListenableBuilder<bool>(
                valueListenable: _isScrolled,
                builder: (context, scrolled, _) => AnimatedOpacity(
                  opacity: scrolled ? 1 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Divider(height: 1, thickness: 1, color: _borderColor),
                ),
              ),
              Expanded(
                child: NotificationListener<ScrollUpdateNotification>(
                  onNotification: (n) {
                    if (n.depth == 0) _isScrolled.value = n.metrics.pixels > 0;
                    return false;
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: _hPadding),
                    itemCount: _monthCount,
                    itemExtentBuilder: (index, _) => _monthExtent(index),
                    itemBuilder: (context, index) =>
                        _buildMonth(_monthAt(index)),
                  ),
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final from = widget.fromDir?.cityName?.trim() ?? '';
    final to = widget.toDir?.cityName?.trim() ?? '';
    final hasRoute = from.isNotEmpty && to.isNotEmpty;
    final subtitleStyle = context.textTheme.bodyMedium?.copyWith(
      color: _secondaryColor,
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.2,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: SizedBox(
        height: 52,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 52),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'date_calendar_title'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: _textColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (hasRoute) ...[
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(from,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: subtitleStyle),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _svg(Assets.iconsCalendarRouteArrowIcon,
                              size: 14, color: _secondaryColor),
                        ),
                        Flexible(
                          child: Text(to,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: subtitleStyle),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: _svg(Assets.iconsPlaceCloseIcon, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFields() {
    final selectHint = 'select'.tr();
    return _DateSegments(
      // To'liq oraliqdan keyin hech bir maydon faol emas — linza yashiriladi.
      activeIndex: switch (_focus) {
        _Focus.departure => 0,
        _Focus.returnDate => 1,
        _Focus.none => null,
      },
      segments: [
        _DateSegment(
          iconAsset: Assets.iconsCalendarDepartureIcon,
          label: 'depDate'.tr(),
          date: _start,
          placeholder: selectHint,
          onTap: _focusDeparture,
          onClear: _start == null ? null : _clearDeparture,
        ),
        if (_isRange)
          _DateSegment(
            iconAsset: Assets.iconsCalendarReturnIcon,
            label: 'arrDate'.tr(),
            date: _end,
            // Qaytish ixtiyoriy: faol bo'lmasa "Qaytishsiz" deb ko'rsatiladi.
            placeholder: _focus == _Focus.returnDate
                ? selectHint
                : 'calendar_no_return'.tr(),
            onTap: _focusReturn,
            onClear: _end == null ? null : _clearReturn,
          ),
      ],
      formatDay: (date) => date.dateWithMonthLowerCase,
      formatWeekday: (date) => _capitalize(_weekdayKeys[date.weekday - 1].tr()),
    );
  }

  Widget _buildWeekdays() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPadding, 16, _hPadding, 8),
      child: Row(
        children: [
          for (final key in _weekdayKeys)
            Expanded(
              child: Text(
                _capitalize(key.tr()),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: _secondaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMonth(DateTime month) {
    final blanks = _leadingBlanks(month);
    final days = _daysIn(month);
    final rows = _rowsIn(month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _monthTitleHeight,
          child: Align(
            alignment: const Alignment(-1, 0.4),
            child: Text(
              '${_monthKeys[month.month - 1].tr()} ${month.year}',
              style: context.textTheme.labelMedium?.copyWith(
                color: _textColor,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        for (var row = 0; row < rows; row++)
          SizedBox(
            height: _rowHeight,
            child: Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: () {
                      final day = row * 7 + col - blanks + 1;
                      if (day < 1 || day > days) return const SizedBox.shrink();
                      return _buildDay(
                        DateTime(month.year, month.month, day),
                        col: col,
                        isMonthEdgeStart: day == 1,
                        isMonthEdgeEnd: day == days,
                      );
                    }(),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDay(
    DateTime date, {
    required int col,
    required bool isMonthEdgeStart,
    required bool isMonthEdgeEnd,
  }) {
    final isPast = date.isBefore(_today);
    final isStart = _start?.isSame(date) ?? false;
    final isEnd = _end?.isSame(date) ?? false;
    final isSelected = isStart || isEnd;
    final hasRange = _start != null && _end != null && !_start!.isSame(_end);
    final isBetween = hasRange && date.isAfter(_start!) && date.isBefore(_end!);
    final isToday = date.isSame(_today);
    final price = isPast ? null : _priceByDate[date];
    final isCheapest = _cheapestDays.contains(date);

    // Oraliq tasmasi: boshlanish katagida o'ng yarmi, tugashida chap yarmi,
    // oradagi kunlarda to'liq. Hafta/oy chetida yumaloqlanadi.
    Widget? band;
    if (isBetween || (hasRange && isSelected)) {
      const radius = Radius.circular(12);
      final roundLeft = col == 0 || isMonthEdgeStart;
      final roundRight = col == 6 || isMonthEdgeEnd;
      band = Positioned(
        top: 3,
        bottom: 3,
        left: 0,
        right: 0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: isStart
                  ? const SizedBox.shrink()
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        color: _rangeColor,
                        borderRadius: roundLeft
                            ? const BorderRadius.horizontal(left: radius)
                            : null,
                      ),
                    ),
            ),
            Expanded(
              child: isEnd
                  ? const SizedBox.shrink()
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        color: _rangeColor,
                        borderRadius: roundRight
                            ? const BorderRadius.horizontal(right: radius)
                            : null,
                      ),
                    ),
            ),
          ],
        ),
      );
    }

    final Color dayColor;
    if (isSelected) {
      dayColor = Colors.white;
    } else if (isPast) {
      dayColor = _hintColor;
    } else if (isToday) {
      dayColor =
          context.isDarkMode ? ProjectTheme.linkDark : ProjectTheme.brandColor;
    } else {
      dayColor = _textColor;
    }

    final Color priceColor;
    if (isSelected) {
      priceColor = Colors.white.withValues(alpha: 0.85);
    } else if (isCheapest) {
      priceColor = ProjectTheme.success;
    } else {
      priceColor = _secondaryColor;
    }

    return Semantics(
      button: !isPast,
      selected: isSelected,
      label: _formatDate(date),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isPast ? null : () => _onDayTap(date),
        child: Stack(
          children: [
            if (band != null) band,
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ProjectTheme.brandColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${date.day}',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: dayColor,
                          fontSize: 16,
                          height: 1.2,
                          fontWeight: isSelected || isToday
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      if (price != null)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            price,
                            maxLines: 1,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: priceColor,
                              fontSize: 10.5,
                              height: 1.3,
                              fontWeight: isCheapest
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
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

  Widget _buildBottomBar() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _sheetColor,
        border: Border(top: BorderSide(color: _borderColor)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          _hPadding,
          12,
          _hPadding,
          12 + context.bottomPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.bottomCenter,
              child: _priceByDate.isEmpty
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'calendar_prices_hint'.tr(),
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: _secondaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
            ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _start == null ? null : _submit,
                style: ProjectTheme.blueButtonStyle.copyWith(
                  elevation: const WidgetStatePropertyAll(0),
                ),
                child: Text(
                  'done'.tr(),
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// "Pn, 14 Sen" ko'rinishida.
  String _formatDate(DateTime date) =>
      '${_capitalize(_weekdayKeys[date.weekday - 1].tr())}, '
      '${date.dateWithMonthLowerCase}';

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  DateTime? _dateOnly(DateTime? d) =>
      d == null ? null : DateTime(d.year, d.month, d.day);

  Widget _svg(String asset, {double size = 24, Color? color}) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color ?? _textColor, BlendMode.srcIn),
    );
  }
}

class _DateSegment {
  final String iconAsset;
  final String label;
  final DateTime? date;
  final String placeholder;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateSegment({
    required this.iconAsset,
    required this.label,
    required this.date,
    required this.placeholder,
    required this.onTap,
    required this.onClear,
  });
}

/// "Jo'nash" / "Qaytish" kartasi: och trek ustida faol maydon ostida
/// sirg'aluvchi oq "linza" — kalendardagi keyingi bosish shu maydonga yoziladi.
/// Yo'nalish qidiruv sahifasidagi segment tanlagich bilan bir xil xarakter.
class _DateSegments extends StatelessWidget {
  final List<_DateSegment> segments;

  /// `null` — hech bir maydon faol emas (linza yashiriladi).
  final int? activeIndex;
  final String Function(DateTime date) formatDay;
  final String Function(DateTime date) formatWeekday;

  const _DateSegments({
    required this.segments,
    required this.activeIndex,
    required this.formatDay,
    required this.formatWeekday,
  });

  static const double _height = 68;
  static const double _inset = 4;
  static const double _radius = 18;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final track = isDark ? Colors.white.withAlpha(20) : const Color(0xFFEDF1F7);
    final lens = isDark ? ProjectTheme.inputColorDark : Colors.white;
    final count = segments.length;
    // Linza yashirilganda ham oxirgi joyida so'nadi (sakramaydi).
    final lensIndex = activeIndex ?? count - 1;

    return Container(
      height: _height,
      padding: const EdgeInsets.all(_inset),
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / count;
          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 420),
                curve: const Cubic(0.25, 1.1, 0.4, 1.0),
                alignment: Alignment(
                    count == 1 ? 0 : -1 + 2 * lensIndex / (count - 1), 0),
                child: AnimatedOpacity(
                  opacity: activeIndex == null ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: segmentWidth,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: lens,
                      borderRadius: BorderRadius.circular(_radius - _inset),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withAlpha(60)
                              : const Color(0x1F0A2540),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Linza yo'q paytda maydonlarni ajratuvchi ingichka chiziq.
              if (count == 2)
                Center(
                  child: AnimatedOpacity(
                    opacity: activeIndex == null ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 1,
                      height: 32,
                      color: isDark
                          ? Colors.white.withAlpha(30)
                          : const Color(0xFFD9E0EA),
                    ),
                  ),
                ),
              Row(
                children: [
                  for (var i = 0; i < count; i++)
                    Expanded(
                      child: _DateSegmentView(
                        segment: segments[i],
                        isActive: i == activeIndex,
                        formatDay: formatDay,
                        formatWeekday: formatWeekday,
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DateSegmentView extends StatelessWidget {
  final _DateSegment segment;
  final bool isActive;
  final String Function(DateTime date) formatDay;
  final String Function(DateTime date) formatWeekday;

  const _DateSegmentView({
    required this.segment,
    required this.isActive,
    required this.formatDay,
    required this.formatWeekday,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final base = context.textTheme.bodyMedium!;
    final textColor =
        isDark ? ProjectTheme.textColorDark : ProjectTheme.textColorLight;
    final secondary = isDark
        ? ProjectTheme.secondaryTextDark
        : ProjectTheme.secondaryTextLight;
    final hint =
        isDark ? ProjectTheme.disabledTextDark : ProjectTheme.disabledTextLight;
    final accent = isDark ? ProjectTheme.linkDark : ProjectTheme.brandColor;
    final date = segment.date;

    final Widget value;
    if (date == null) {
      value = Text(
        segment.placeholder,
        key: ValueKey('placeholder-${segment.placeholder}'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: base.copyWith(
          color: isActive ? accent : hint,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
      );
    } else {
      value = Row(
        key: ValueKey(date),
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Flexible(
            child: Text(
              formatDay(date),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: base.copyWith(
                color: textColor,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            formatWeekday(date),
            maxLines: 1,
            style: base.copyWith(
              color: secondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
        ],
      );
    }

    return Semantics(
      button: true,
      selected: isActive,
      label: segment.label,
      value: date == null
          ? segment.placeholder
          : '${formatWeekday(date)}, ${formatDay(date)}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: segment.onTap,
        child: Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: segment.onClear == null ? 12 : 0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(
                          segment.iconAsset,
                          width: 14,
                          height: 14,
                          colorFilter: ColorFilter.mode(
                            isActive ? accent : secondary,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            segment.label.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: base.copyWith(
                              color: isActive ? accent : secondary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.42,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.centerLeft,
                        children: [...previous, if (current != null) current],
                      ),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, 0.25),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: value,
                    ),
                  ],
                ),
              ),
              if (segment.onClear != null)
                SizedBox.square(
                  dimension: 40,
                  child: IconButton(
                    onPressed: segment.onClear,
                    padding: EdgeInsets.zero,
                    tooltip:
                        MaterialLocalizations.of(context).deleteButtonTooltip,
                    icon: Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? Colors.white.withAlpha(28)
                            : const Color(0xFFE3E8F0),
                      ),
                      child: SvgPicture.asset(
                        Assets.iconsPlaceCloseIcon,
                        width: 12,
                        height: 12,
                        colorFilter: ColorFilter.mode(
                          isDark ? textColor : const Color(0xFF5B6B85),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
