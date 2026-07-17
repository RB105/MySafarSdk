import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_bloc/flutter_bloc.dart'
    show BlocProvider, BlocBuilder, ReadContext;
import 'package:mysafar_sdk/src/core/config/response_config.dart'
    show NetworkSuccessResponse;
import 'package:mysafar_sdk/src/core/enum/currency.dart'
    show AppCurrency, AppCurrencyExtension;
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart' show ProjectTheme;
import 'package:mysafar_sdk/src/core/tools/currency_provider.dart'
    show CurrencyProvider;
import 'package:mysafar_sdk/src/core/tools/formatters.dart' show ElementFormatter;
import 'package:mysafar_sdk/src/core/tools/lang_helper.dart' show dataLang;
import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart' show ProjectDialogs;
import 'package:mysafar_sdk/src/core/tools/project_utils.dart' show ProjectUtils;
import 'package:mysafar_sdk/src/core/widgets/toast_widget.dart';
import 'package:mysafar_sdk/src/cubit/search/route_search_cubit.dart'
    show RouteSearchCubit, RouteSearchState;
import 'package:mysafar_sdk/src/model/remote/avia/airports_model.dart'
    show AirPortsModel;
import 'package:mysafar_sdk/src/model/remote/avia/ticket_date_price_model.dart'
    show TicketDatePriceModel, DatePrice;
import 'package:mysafar_sdk/src/model/remote/destination/destination_detail_model.dart'
    show DestinationDetailModel, DestLocalizedText;
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart';
import 'package:mysafar_sdk/src/service/avia_service.dart' show AviaService;
import 'package:mysafar_sdk/src/service/fornex/fornex_repository.dart'
    show FornexRepository;
import 'package:mysafar_sdk/src/view/tickets/ticket_page.dart'
    show RecommendationsTicketPage;
import 'package:provider/provider.dart' show Provider, Consumer;
import 'package:shimmer/shimmer.dart' show Shimmer;
import 'package:syncfusion_flutter_datepicker/datepicker.dart'
    show PickerDateRange;

/// Yo'nalish qidiruv oynasi — bosh sahifada "qayerdan → qayerga" tanlangach
/// ochiladigan alohida sahifa (Aviasales uslubi, loyiha dizayniga
/// moslashtirilgan):
///  • tepada yo'nalish kartasi (orqaga, from/to, almashtirish);
///  • chiplar: Sanalar / yo'lovchi+klass / Filtrlar;
///  • tezkor sana chiplar: Bugun / Ertaga / Dam olish / Kelasi hafta;
///  • "Narxlar jadvali" — pastdan chiqadigan bottom sheet: bugundan 365
///    kunlik grafik, narx pufagi doim MARKAZDA turadi (grafik scroll
///    bo'lganda balandligi bo'yicha tepaga-pastga "o'ynaydi"), narxi yo'q
///    kunlarda "Noma'lum" ko'rsatiladi;
///  • "Eng arzon kunlar" — oylik narxlardan top-3 arzon kun (bir bosishda
///    sana tanlanadi);
///  • "{Shahar} haqida" — yo'nalish v1 bazasida bo'lsa tezkor ma'lumot
///    kartalari va tafsilot sahifasiga o'tish;
///  • sana tanlangach (grafikdan yoki kalendardan) qidirish tugmasi paydo
///    bo'ladi — bosilganda mavjud chipta natijalari sahifasi ochiladi.
class RouteSearchPage extends StatelessWidget {
  final AirPortsModel from;
  final AirPortsModel to;

  const RouteSearchPage({super.key, required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RouteSearchCubit>(
      create: (_) => RouteSearchCubit(
        from: from,
        to: to,
        aviaService: AviaService(),
        fornexRepository: FornexRepository(),
      ),
      child: const _RouteSearchView(),
    );
  }
}

/// Sahifaning ko'rinish (view) qatlami — biznes-holat [RouteSearchCubit]da.
/// Bu widget faqat holatni chizadi va foydalanuvchi tanlovlarini (dialog
/// natijalarini) cubit'ga uzatadi; o'zida saqlanadigan holat yo'q.
class _RouteSearchView extends StatefulWidget {
  const _RouteSearchView();

  @override
  State<_RouteSearchView> createState() => _RouteSearchViewState();
}

class _RouteSearchViewState extends State<_RouteSearchView> {
  RouteSearchCubit get _cubit => context.read<RouteSearchCubit>();

  // ── Tanlash oynalari (mavjud dialoglar qayta ishlatiladi) ─────────────

  Future<void> _pickCity(int directionType) async {
    final r = await ProjectDialogs.showCitySearchPicker(context, directionType);
    if (!mounted || r == null) return;
    directionType == 0 ? _cubit.setFrom(r) : _cubit.setTo(r);
  }

  void _swap() {
    HapticFeedback.lightImpact();
    _cubit.swap();
  }

  Future<void> _pickDate() async {
    final s = _cubit.state;
    // type 1 — borish-QAYTISH rejimi: bitta sana ham, ikkitasi ham
    // tanlanishi mumkin (bosh sahifa formasi bilan bir xil).
    final r = await ProjectDialogs.showCalendartPicker(
      context,
      1,
      s.date != null ? PickerDateRange(s.date, s.endDate) : null,
      s.from,
      s.to,
    );
    if (!mounted || r == null || r.startDate == null) return;
    _cubit.setDates(r.startDate!, r.endDate);
  }

  Future<void> _pickPassengers() async {
    final s = _cubit.state;
    final r = await ProjectDialogs.showPassengerCountPicker(
        context, {"adt": s.adt, "chd": s.chd, "inf": s.inf, "klass": s.klass});
    if (!mounted || r == null) return;
    _cubit.setPassengers(
      adt: r['adt'] ?? 1,
      chd: r['chd'] ?? 0,
      inf: r['inf'] ?? 0,
      klass: r['klass'] ?? 'a',
    );
  }

  /// Filtrlar sheet'i — loyihada mavjud ikki filtr: to'g'ri reys va bagaj.
  Future<void> _openFilters() async {
    final s = _cubit.state;
    bool direct = s.direct;
    bool baggage = s.baggage;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        // SwitchListTile Material ancestor talab qiladi: Container+color
        // (DecoratedBox) ink splash'ni yashiradi va SDK debug ErrorWidget
        // qizil ekranga o'tkazadi. Mobile ko'rinishi saqlanadi.
        builder: (sheetContext, setSheetState) => Material(
          color: sheetContext.color.primaryContainer,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(110),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "filter_title".tr(),
                    style: sheetContext.textTheme.displayLarge
                        ?.copyWith(fontWeight: FontWeight.w800, fontSize: 19),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeTrackColor: ProjectTheme.brandColor,
                    title: Text("home_direct_flight".tr(),
                        style: sheetContext.textTheme.bodyMedium),
                    value: direct,
                    onChanged: (v) => setSheetState(() => direct = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeTrackColor: ProjectTheme.brandColor,
                    title: Text("home_with_baggage".tr(),
                        style: sheetContext.textTheme.bodyMedium),
                    value: baggage,
                    onChanged: (v) => setSheetState(() => baggage = v),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ProjectTheme.blueButtonStyle,
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: Text(
                        "apply".tr(),
                        style: sheetContext.textTheme.bodyMedium
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (!mounted) return;
    _cubit.setFilters(direct: direct, baggage: baggage);
  }

  /// Narxlar jadvali bottom sheet'ini ochadi. "Bir tomonga" rejimida bitta
  /// sana (DateTime), "Borish-kelish"da esa ikkala sana (PickerDateRange)
  /// qaytadi — kalendar bilan bir xil semantika.
  Future<void> _openPriceChart() async {
    HapticFeedback.lightImpact();
    AnalyticsService().trackButtonTap('route_price_chart');
    final s = _cubit.state;
    final picked = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PriceChartSheet(
        from: s.from,
        to: s.to,
        initialDate: s.date,
        initialEndDate: s.endDate,
      ),
    );
    if (!mounted || picked == null) return;
    if (picked is PickerDateRange) {
      final start = picked.startDate;
      if (start != null) _cubit.setDates(start, picked.endDate);
    } else if (picked is DateTime) {
      // Bir tomonlama tanlandi — qaytish tozalanadi.
      _cubit.pickDay(picked);
    }
  }

  // ── Tezkor sana chiplar ───────────────────────────────────────────────

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Eng yaqin dam olish kuni: bugun shanba/yakshanba bo'lsa — bugun,
  /// aks holda shu haftaning shanbasi.
  static DateTime get _weekend {
    final t = _today;
    if (t.weekday >= DateTime.saturday) return t;
    return t.add(Duration(days: DateTime.saturday - t.weekday));
  }

  /// Kelasi hafta dushanbasi.
  static DateTime get _nextMonday =>
      _today.add(Duration(days: 8 - _today.weekday));

  /// Chiplar ro'yxati — bir xil sanaga tushib qolganlari (masalan, shanba
  /// kuni "Bugun" va "Dam olish") takrorlanmaydi.
  List<(String, IconData, DateTime)> get _quickDates {
    final seen = <int>{};
    final items = <(String, IconData, DateTime)>[];
    for (final (label, icon, date) in [
      ("quick_today".tr(), Icons.today_rounded, _today),
      (
        "quick_tomorrow".tr(),
        Icons.event_rounded,
        _today.add(const Duration(days: 1))
      ),
      ("quick_weekend".tr(), Icons.wb_sunny_rounded, _weekend),
      ("quick_next_week".tr(), Icons.next_week_rounded, _nextMonday),
    ]) {
      final key = date.year * 10000 + date.month * 100 + date.day;
      if (seen.add(key)) items.add((label, icon, date));
    }
    return items;
  }

  /// Tezkor chip yoki "Eng arzon kunlar" qatoridan BIR TOMONLAMA sana
  /// tanlash (qaytish sanasi tozalanadi).
  void _pickDay(DateTime day, String analyticsTag) {
    HapticFeedback.selectionClick();
    AnalyticsService().trackButtonTap(analyticsTag);
    _cubit.pickDay(day);
  }

  /// "Batafsil" — mavjud yo'nalish tafsiloti sahifasi. Router listItem
  /// kutadi — tafsilot modelidan minimal element quriladi (sahifaning o'zi
  /// slug bo'yicha keshlangan tafsilotni darhol oladi).
  void _openDestinationDetails() {
    final d = _cubit.state.destInfo;
    if (d == null) return;
    HapticFeedback.lightImpact();
    AnalyticsService().trackButtonTap('route_destination_details');
    showToastMessage('destination_details_unavailable'.tr());
  }

  // ── Qidiruv ───────────────────────────────────────────────────────────

  void _search() {
    final state = _cubit.state;
    if (!state.hasDate) return;
    if (state.isSameAirport) {
      showToastMessage("same_airport_warning".tr());
      return;
    }
    HapticFeedback.mediumImpact();
    // `ticket_searched` eventi endi TicketCubit'da — so'rov servicega
    // ketayotgan paytda yuboriladi (bu yerda takrorlanmaydi).
    final params = _cubit.buildRequest();
    ProjectUtils.setRecommendationParams(params);
    Navigator.pushNamed(
      context,
      RecommendationsTicketPage.routeName,
      arguments: params,
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────

  String _dateChipLabel(RouteSearchState s) {
    final d = s.date;
    if (d == null) return "dates".tr();
    final String dep =
        "${d.day} ${ElementFormatter.formatMonth(d.month).toLowerCase()}";
    final e = s.endDate;
    if (e == null) return dep;
    return "$dep – ${e.day} ${ElementFormatter.formatMonth(e.month).toLowerCase()}";
  }

  String _paxChipLabel(RouteSearchState s) {
    final klassName = switch (s.klass) {
      'e' => "klass_e".tr(),
      'b' => "klass_b".tr(),
      _ => "klass_a".tr(),
    };
    return "${s.passengerCount}, $klassName";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<RouteSearchCubit, RouteSearchState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RouteHeaderCard(
                    from: state.from,
                    to: state.to,
                    onBack: () => Navigator.of(context).maybePop(),
                    onFromTap: () => _pickCity(0),
                    onToTap: () => _pickCity(1),
                    onSwap: _swap,
                  ),
                  const SizedBox(height: 12),
                  // Chiplar: Sanalar / yo'lovchi+klass / Filtrlar.
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _RouteChip(
                          icon: Icons.calendar_month_rounded,
                          label: _dateChipLabel(state),
                          active: state.date != null,
                          medium: true,
                          onTap: _pickDate,
                        ),
                        const SizedBox(width: 8),
                        _RouteChip(
                          icon: Icons.person_outline_rounded,
                          label: _paxChipLabel(state),
                          active: false,
                          medium: true,
                          onTap: _pickPassengers,
                        ),
                        const SizedBox(width: 8),
                        _RouteChip(
                          icon: Icons.tune_rounded,
                          label: "filter_title".tr(),
                          active: state.direct || state.baggage,
                          medium: true,
                          onTap: _openFilters,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Tezkor sana chiplar — bir bosishda bir tomonlama sana.
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final (label, icon, date) in _quickDates) ...[
                          _RouteChip(
                            icon: icon,
                            label: label,
                            active: state.endDate == null &&
                                _isSameDay(state.date, date),
                            onTap: () => _pickDay(date, 'route_quick_date'),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  // Sana tanlangach qidirish tugmasi (narx jadvali tepasida).
                  if (state.hasDate) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ProjectTheme.blueButtonStyle,
                        onPressed: _search,
                        child: Text(
                          "home_search_ticket".tr(),
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                  Text(
                    "how_to_get_title".tr(),
                    style: context.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // "Narxlar jadvali" — bottom sheet ochadigan chip.
                  _RouteChip(
                    icon: Icons.bar_chart_rounded,
                    label: "price_chart_title".tr(),
                    active: false,
                    big: true,
                    onTap: _openPriceChart,
                  ),
                  const SizedBox(height: 12),
                  // Eng arzon kunlar — oylik narxlardan top-3 (bosilsa sana
                  // tanlanadi va qidirish tugmasi chiqadi).
                  _CheapestDaysCard(
                    prices: state.monthPrices,
                    loading: state.monthLoading,
                    selected: state.endDate == null ? state.date : null,
                    onPick: (day) => _pickDay(day, 'route_cheapest_day'),
                  ),
                  // "{Shahar} haqida" — yo'nalish v1 bazasida bo'lsa.
                  if (state.destInfo != null) ...[
                    const SizedBox(height: 24),
                    _DestinationInfoCard(
                      detail: state.destInfo!,
                      onDetails: _openDestinationDetails,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Bir xil kunmi (null-xavfsiz, faqat sana qismi solishtiriladi).
bool _isSameDay(DateTime? a, DateTime b) =>
    a != null && a.year == b.year && a.month == b.month && a.day == b.day;

// Quyidagi yordamchilar narxlar jadvali sheet'i va "Eng arzon kunlar"
// blokida birgalikda ishlatiladi.

/// API'dan kelgan ixcham narx satrini ("551 571", "2.3M") songa o'giradi.
double? _parseCompactPrice(String s) {
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

/// Joriy valyutaga mos kun-narx ro'yxati.
List<DatePrice> _pricesForCurrency(
    TicketDatePriceModel? m, AppCurrency currency) {
  if (m == null) return const [];
  return switch (currency) {
        AppCurrency.uzs => m.uzsPrices,
        AppCurrency.rub => m.rubPrices,
        AppCurrency.usd => m.usdPrices,
      } ??
      const [];
}

/// "551 571 UZSdan" — narx + valyuta + home_price_from qo'shimchasi.
String _priceWithSuffix(double v, AppCurrency currency) {
  final parts =
      "home_price_from".tr(namedArgs: {"price": "\u0001"}).split('\u0001');
  final suffix = parts.length > 1 ? parts.last : '';
  return "${ElementFormatter.formatNumberWithSpaces(v)} "
      "${currency.label}$suffix";
}

/// Haftaning qisqa kun nomi.
String _weekDayShort(DateTime d) => switch (d.weekday) {
      1 => "mon".tr(),
      2 => "tue".tr(),
      3 => "wed".tr(),
      4 => "thu".tr(),
      5 => "fri".tr(),
      6 => "sat".tr(),
      7 => "sun".tr(),
      _ => "",
    };

/// Tepadagi yo'nalish kartasi: orqaga + from/to maydonlari + almashtirish.
class _RouteHeaderCard extends StatelessWidget {
  final AirPortsModel from;
  final AirPortsModel to;
  final VoidCallback onBack;
  final VoidCallback onFromTap;
  final VoidCallback onToTap;
  final VoidCallback onSwap;

  const _RouteHeaderCard({
    required this.from,
    required this.to,
    required this.onBack,
    required this.onFromTap,
    required this.onToTap,
    required this.onSwap,
  });

  Widget _field(BuildContext context, String? title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          title?.isNotEmpty == true ? title! : "—",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.color.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: context.shadowDown,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 22),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field(context, from.cityName, onFromTap),
                Divider(
                    height: 1, thickness: 1, color: ProjectTheme.borderLight),
                _field(context, to.cityName, onToTap),
              ],
            ),
          ),
          IconButton(
            onPressed: onSwap,
            icon: Icon(Icons.swap_vert_rounded,
                size: 22, color: ProjectTheme.brandColor),
          ),
        ],
      ),
    );
  }
}

/// Chip: ikonka + yozuv (faol bo'lsa brand tusda).
class _RouteChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  /// Katta prominent chip (Narxlar jadvali) — brend doira ichida ikonka.
  final bool big;

  /// O'rta o'lcham — asosiy qator (Sanalar / yo'lovchilar / Filtr) uchun;
  /// oddiy (tezkor sana) chiplaridan biroz kattaroq.
  final bool medium;
  final VoidCallback onTap;

  const _RouteChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.big = false,
    this.medium = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = active
        ? ProjectTheme.brandColor.withAlpha(isDark ? 60 : 26)
        : (isDark ? Colors.white.withAlpha(20) : const Color(0xFFF1F4F9));
    final Color fg = active
        ? (isDark ? Colors.white : ProjectTheme.brandColor)
        : (isDark ? Colors.white : const Color(0xFF16244A));

    // O'lchamlar: big > medium > oddiy.
    final double radius = big ? 16 : (medium ? 14 : 12);
    final double hPad = big ? 16 : (medium ? 14 : 12);
    final double vPad = big ? 14 : (medium ? 9 : 0);
    final double iconSize = big ? 17 : (medium ? 19 : 16);
    final double fontSize = big ? 14.5 : (medium ? 14.5 : 13);
    final double gap = big ? 10 : (medium ? 8 : 6);
    final double iconBox = big ? 30 : iconSize;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: iconBox,
                height: iconBox,
                alignment: Alignment.center,
                decoration: big
                    ? BoxDecoration(
                        color: ProjectTheme.brandColor,
                        borderRadius: BorderRadius.circular(15),
                      )
                    : null,
                child: Icon(icon,
                    size: big ? 17 : iconSize, color: big ? Colors.white : fg),
              ),
              SizedBox(width: gap),
              Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: fg,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
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
        isDark ? Colors.white.withAlpha(26) : const Color(0xFFE4E8F0);
    // ARZON kunlar — yashil, QIMMATLARI — ko'k.
    const Color cheapColor = Color(0xFF22C55E);
    final Color expensiveColor = ProjectTheme.brandColor;
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
class _CheapestDaysCard extends StatelessWidget {
  final TicketDatePriceModel? prices;
  final bool loading;
  final DateTime? selected;
  final ValueChanged<DateTime> onPick;

  const _CheapestDaysCard({
    required this.prices,
    required this.loading,
    required this.selected,
    required this.onPick,
  });

  static const int _maxDays = 3;

  /// Grafikdagi "arzon" ustunlar rangi bilan bir xil.
  static const Color _cheapColor = Color(0xFF22C55E);

  /// Bugundan boshlab narxi bor kunlar — narx o'sishi (teng bo'lsa sana)
  /// tartibida, eng arzon [_maxDays] tasi.
  List<(DateTime, double)> _cheapest(AppCurrency currency) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entries = <(DateTime, double)>[];
    for (final p in _pricesForCurrency(prices, currency)) {
      final d = p.date;
      final s = (p.sum ?? '').trim();
      if (d == null || s.isEmpty || s == '0') continue;
      if (d.isBefore(today)) continue;
      final v = _parseCompactPrice(s);
      if (v != null) entries.add((d, v));
    }
    entries.sort((a, b) {
      final c = a.$2.compareTo(b.$2);
      return c != 0 ? c : a.$1.compareTo(b.$1);
    });
    return entries.take(_maxDays).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const _CheapestDaysShimmer();

    final currency = Provider.of<CurrencyProvider>(context).currency;
    final days = _cheapest(currency);
    if (days.isEmpty) return const SizedBox.shrink();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.color.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: context.shadowDown,
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.trending_down_rounded,
                    size: 18, color: _cheapColor),
                const SizedBox(width: 6),
                Text(
                  "cheapest_days_title".tr(),
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          for (int i = 0; i < days.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: ProjectTheme.borderLight,
              ),
            _dayRow(context, days[i].$1, days[i].$2, currency),
          ],
        ],
      ),
    );
  }

  Widget _dayRow(
      BuildContext context, DateTime date, double price, AppCurrency currency) {
    final bool isSelected = _isSameDay(selected, date);
    return InkWell(
      onTap: () => onPick(date),
      child: Container(
        color: isSelected
            ? ProjectTheme.brandColor.withAlpha(16)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Expanded(
              child: Text(
                "${date.day} "
                "${ElementFormatter.formatMonth(date.month).toLowerCase()}, "
                "${_weekDayShort(date)}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 14.5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _priceWithSuffix(price, currency),
              style: const TextStyle(
                color: _cheapColor,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_circle_rounded,
                  size: 18, color: ProjectTheme.brandColor),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Eng arzon kunlar" yuklanayotganda karta shaklidagi shimmer qatorlar.
class _CheapestDaysShimmer extends StatelessWidget {
  const _CheapestDaysShimmer();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    Widget line(int flex) => Expanded(
          flex: flex,
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        color: context.color.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: context.shadowDown,
      ),
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
        child: Column(
          children: [
            for (int i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              Row(
                children: [
                  line(5),
                  const Spacer(flex: 2),
                  line(3),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  YO'NALISH HAQIDA
// ══════════════════════════════════════════════════════════════════════

/// "Qayerga" shahri haqida qisqa blok: sarlavha (+reyting), 2×2 tezkor
/// ma'lumot kartalari (parvoz vaqti, mavsum, muddat, viza — tafsilot
/// sahifasidagi grid uslubida) va "Batafsil" tugmasi.
class _DestinationInfoCard extends StatelessWidget {
  final DestinationDetailModel detail;
  final VoidCallback onDetails;

  const _DestinationInfoCard({required this.detail, required this.onDetails});

  String _lt(DestLocalizedText t) => t.byLang(dataLang());

  /// Tanlangan valyutadagi narx — avval hero, bo'lmasa avia blokidan.
  int _priceOf(AppCurrency currency) {
    final h = detail.hero;
    final a = detail.aviaBlock;
    int pick(int hero, int avia) => hero > 0 ? hero : avia;
    return switch (currency) {
      AppCurrency.uzs => pick(h?.priceUzs ?? 0, a?.priceUzs ?? 0),
      AppCurrency.rub => pick(h?.priceRub ?? 0, a?.priceRub ?? 0),
      AppCurrency.usd => pick(h?.priceUsd ?? 0, a?.priceUsd ?? 0),
    };
  }

  /// "narxi 2 512 802 UZSdan" — raqam qalin brend tusda, qolgani kulrang.
  /// Valyuta o'zgarsa avtomatik yangilanadi (Consumer).
  Widget _priceSection(BuildContext context) {
    return Consumer<CurrencyProvider>(
      builder: (context, provider, _) {
        final int amount = _priceOf(provider.currency);
        if (amount <= 0) return const SizedBox.shrink();

        // "home_price_from" shablonini {price} bo'yicha ikkiga bo'lamiz.
        final parts =
            "home_price_from".tr(namedArgs: {"price": ""}).split('');
        final prefix = parts.isNotEmpty ? parts.first : '';
        final suffix = parts.length > 1 ? parts.last : '';
        final grey = context.textTheme.headlineSmall?.copyWith(fontSize: 13.5);

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("home_price_label".tr(), style: grey),
              const SizedBox(width: 6),
              Flexible(
                child: Text.rich(
                  TextSpan(children: [
                    if (prefix.isNotEmpty) TextSpan(text: prefix, style: grey),
                    TextSpan(
                      text: ElementFormatter.formatNumberWithSpaces(amount),
                      style: context.textTheme.labelMedium?.copyWith(
                        fontSize: 18,
                        color: ProjectTheme.brandColor,
                      ),
                    ),
                    TextSpan(
                        text: ' ${provider.currency.label}$suffix', style: grey),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = detail.quickInfo;
    final items = <(IconData, String, String)>[
      if (q != null && q.flightDuration.isNotEmpty)
        (Icons.schedule_rounded, "dest_flight_duration".tr(), q.flightDuration),
      if (q != null && !q.bestSeason.isEmpty)
        (
          Icons.calendar_month_rounded,
          "dest_best_season".tr(),
          _lt(q.bestSeason)
        ),
      if (q != null && !q.recommendedDuration.isEmpty)
        (
          Icons.place_outlined,
          "dest_recommended_duration".tr(),
          _lt(q.recommendedDuration)
        ),
      if (q != null && !q.visaRequirement.isEmpty)
        (Icons.verified_user_outlined, "dest_visa".tr(), _lt(q.visaRequirement)),
    ];
    final String about =
        detail.about == null ? '' : _lt(detail.about!.description);

    // Ko'rsatishga arziydigan kontent bo'lmasa blok chiqmaydi.
    if (items.isEmpty && about.isEmpty) return const SizedBox.shrink();

    final String city = _lt(detail.name);
    final double rating = detail.hero?.rating ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "about_city_title".tr(namedArgs: {"city": city}),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ),
            if (rating > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300).withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 15, color: Color(0xFFFFB300)),
                    const SizedBox(width: 3),
                    Text(
                      rating.toStringAsFixed(1),
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        // Narx — tanlangan valyutada (hero yoki avia blokidan).
        _priceSection(context),
        const SizedBox(height: 12),
        if (items.isNotEmpty)
          _quickInfoGrid(context, items)
        else
          Text(
            about,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodyMedium
                ?.copyWith(height: 1.5, fontSize: 13.5),
          ),
        const SizedBox(height: 12),
        // "Batafsil" — yo'nalish tafsiloti sahifasiga o'tish.
        Material(
          color: ProjectTheme.brandColor.withAlpha(22),
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onDetails,
            child: SizedBox(
              height: 46,
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "details".tr(),
                    style: TextStyle(
                      color: ProjectTheme.brandColor,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded,
                      size: 18, color: ProjectTheme.brandColor),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 2×2 tezkor ma'lumot kartalari (tafsilot sahifasidagi grid uslubida).
  Widget _quickInfoGrid(
      BuildContext context, List<(IconData, String, String)> items) {
    Widget card((IconData, String, String) item) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.color.primaryContainer,
            borderRadius: BorderRadius.circular(16),
            boxShadow: context.shadowDown,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.$1, size: 20, color: ProjectTheme.brandColor),
              const SizedBox(height: 8),
              Text(item.$2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.headlineSmall
                      ?.copyWith(fontSize: 12.5)),
              const SizedBox(height: 3),
              Text(item.$3,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700, fontSize: 13.5)),
            ],
          ),
        );

    return Column(
      children: [
        for (int i = 0; i < items.length; i += 2)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: card(items[i])),
                  const SizedBox(width: 12),
                  Expanded(
                    child: i + 1 < items.length
                        ? card(items[i + 1])
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
