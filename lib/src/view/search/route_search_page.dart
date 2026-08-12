import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show HapticFeedback, SystemUiOverlayStyle;
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
import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart' show ProjectDialogs;
import 'package:mysafar_sdk/src/core/tools/project_utils.dart' show ProjectUtils;
import 'package:mysafar_sdk/src/core/tools/sdk_sheets.dart';
import 'package:mysafar_sdk/src/core/widgets/toast_widget.dart';
import 'package:mysafar_sdk/src/cubit/search/route_search_cubit.dart'
    show RouteSearchCubit, RouteSearchState, RouteLeg;
import 'package:mysafar_sdk/src/model/remote/avia/airports_model.dart'
    show AirPortsModel;
import 'package:mysafar_sdk/src/model/remote/avia/ticket_date_price_model.dart'
    show TicketDatePriceModel, DatePrice;
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart';
import 'package:mysafar_sdk/src/service/avia_service.dart' show AviaService;
import 'package:mysafar_sdk/src/service/fornex/fornex_repository.dart'
    show FornexRepository;
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightElement, FlightSegment, Arr;
import 'package:mysafar_sdk/src/view/tickets/ticket_info_page.dart'
    show TicketInfoPage;
import 'package:mysafar_sdk/src/view/tickets/ticket_page.dart'
    show RecommendationsTicketPage;
import 'package:provider/provider.dart' show Provider;
import 'package:shimmer/shimmer.dart' show Shimmer;
import 'package:syncfusion_flutter_datepicker/datepicker.dart'
    show PickerDateRange;
import 'dart:math' as math;

part 'route_search_header.dart';
part 'route_search_multiway.dart';
part 'route_search_price_chart.dart';
part 'route_search_best_offers.dart';

/// Yo'nalish qidiruv oynasi — bosh sahifada "qayerdan → qayerga"
/// tanlangach ochiladigan alohida sahifa. Tuzilishi mysafar.uz mobil
/// ko'rinishi bilan bir xil:
///  • tepada oq qidiruv kartasi (from/to + almashtirish, sana,
///    yo'lovchilar), filtr kalitlari va oltin qidirish tugmasi;
///  • "Narxlar jadvali" — yaqin kunlar ustun-grafigi; bosilganda
///    365 kunlik to'liq jadval bottom sheet'da ochiladi;
///  • "Eng yaxshi takliflar" — eng arzon kunga topilgan aniq reyslar
///    (gorizontal kartalar; bosilganda o'sha sana bo'yicha natijalar).
class RouteSearchPage extends StatelessWidget {
  final AirPortsModel from;
  final AirPortsModel to;

  /// Destination CTA dan kelganda eng arzon kun oldindan tanlanadi.
  final DateTime? initialDate;
  final DateTime? initialEndDate;

  const RouteSearchPage({
    super.key,
    required this.from,
    required this.to,
    this.initialDate,
    this.initialEndDate,
  });

  @override
  Widget build(BuildContext context) {
    // Cubit get_it orqali quriladi (from/to param bilan); sahifa yopilganda
    // BlocProvider uni avtomatik `close` qiladi.
    return BlocProvider<RouteSearchCubit>(
      create: (_) {
        final cubit = RouteSearchCubit(
          from: from,
          to: to,
          aviaService: AviaService(),
          fornexRepository: FornexRepository(),
        );
        if (initialDate != null) {
          cubit.setDates(initialDate!, initialEndDate);
        }
        return cubit;
      },
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

class _RouteSearchViewState extends State<_RouteSearchView>
    with SingleTickerProviderStateMixin {
  RouteSearchCubit get _cubit => context.read<RouteSearchCubit>();

  final ScrollController _scrollController = ScrollController();

  /// Rejim tabi: 0 — oddiy qidiruv, 1 — murakkab marshrut.
  late final TabController _tabController;

  /// AppBar fonining to'yinganligi (0..1). Hero ko'k bo'lgani uchun status
  /// bar ikonkalari doim oq — scroll qilinganda ostidagi och fon ko'rinmasligi
  /// uchun AppBar asta ko'k rangga to'ladi (bosh sahifadagi bilan bir xil).
  final ValueNotifier<double> _headerColorT = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final bool multi = _tabController.index == 1;
    if (_cubit.state.multiMode == multi) return;
    HapticFeedback.selectionClick();
    AnalyticsService()
        .trackButtonTap(multi ? 'route_tab_multiway' : 'route_tab_simple');
    _cubit.setMultiMode(multi);
  }

  void _onScroll() {
    final double t = (_scrollController.offset / 120).clamp(0.0, 1.0);
    if ((t - _headerColorT.value).abs() > 0.01 || t == 0 || t == 1) {
      _headerColorT.value = t;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _headerColorT.dispose();
    super.dispose();
  }

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

  // ── Murakkab marshrut tanlovlari ──────────────────────────────────────

  Future<void> _pickLegCity(int index, int directionType) async {
    final r = await ProjectDialogs.showCitySearchPicker(context, directionType);
    if (!mounted || r == null) return;
    directionType == 0 ? _cubit.setLegFrom(index, r) : _cubit.setLegTo(index, r);
  }

  Future<void> _pickLegDate(int index) async {
    final leg = _cubit.state.legs[index];
    final r = await ProjectDialogs.showCalendartPicker(
      context,
      0,
      leg.date != null ? PickerDateRange(leg.date, null) : null,
      leg.from,
      leg.to,
    );
    if (!mounted || r == null || r.startDate == null) return;
    _cubit.setLegDate(index, r.startDate!);
  }

  void _addLeg() {
    _cubit.addLeg();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        (_scrollController.offset + 150)
            .clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _removeLeg(int index) => _cubit.removeLeg(index);

  /// Narxlar jadvali bottom sheet'ini ochadi. "Bir tomonga" rejimida bitta
  /// sana (DateTime), "Borish-kelish"da esa ikkala sana (PickerDateRange)
  /// qaytadi — kalendar bilan bir xil semantika.
  Future<void> _openPriceChart() async {
    HapticFeedback.lightImpact();
    AnalyticsService().trackButtonTap('route_price_chart');
    final s = _cubit.state;
    final picked = await showSdkModalBottomSheet<Object>(
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

  /// Taklif kartasi bosilganda o'sha chipta batafsil sahifasini ochadi.
  void _openOffer(FlightElement flight) {
    HapticFeedback.lightImpact();
    AnalyticsService().trackButtonTap('best_offer_tap');

    // MySafar'ga mos: best offers bosilganda aynan o'sha eng arzon kunni
    // state'da tanlaymiz va TicketInfoPage uchun request params'ni
    // `ProjectUtils.params`ga o'rnatamiz.
    final day = _cubit.state.offersDate ?? _cubit.state.date;
    final safeDay = day ?? DateTime.now();
    _cubit.pickDay(safeDay);
    ProjectUtils.setRecommendationParams(_cubit.buildRequest());

    TicketInfoPage.show(context, flight);
  }

  // ── Qidiruv ───────────────────────────────────────────────────────────

  void _search() {
    final state = _cubit.state;
    if (state.multiMode) {
      _searchMulti();
      return;
    }
    // Webda tugma doim faol — sana tanlanmagan bo'lsa ogohlantiramiz
    // (bosh sahifadagi forma bilan bir xil xatti-harakat).
    if (!state.hasDate) {
      showToastMessage("home_fill_search".tr());
      return;
    }
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

  void _searchMulti() {
    final String? error = _cubit.validateLegs();
    if (error != null) {
      showToastMessage(error.tr());
      return;
    }
    HapticFeedback.mediumImpact();
    final params = _cubit.buildMultiRequest();
    ProjectUtils.setRecommendationParams(params);
    Navigator.pushNamed(
      context,
      RecommendationsTicketPage.routeName,
      arguments: params,
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────

  /// Sana katakchasi matni — tanlanmagan bo'lsa web'dagidek "Sanani tanlang".
  String _dateFieldText(RouteSearchState s) {
    final d = s.date;
    if (d == null) return "choice_date".tr();
    final String dep =
        "${d.day} ${ElementFormatter.formatMonth(d.month).toLowerCase()}";
    final e = s.endDate;
    if (e == null) return dep;
    return "$dep – ${e.day} ${ElementFormatter.formatMonth(e.month).toLowerCase()}";
  }

  /// Yo'lovchilar katakchasi — web faqat sonini ko'rsatadi ("1 yo'lovchi").
  String _paxFieldText(RouteSearchState s) =>
      "passengers_count".tr(namedArgs: {"count": "${s.passengerCount}"});

  /// Qidiruv bloki: oq karta (qayerdan/qayerga/sana/yo'lovchilar), filtr
  /// kalitlari va oltin qidirish tugmasi. Web bilan bir xil, faqat orqa fon
  /// ko'k gradient emas — sahifa fonida turadi.
  Widget _hero(BuildContext context, RouteSearchState state) {
    final double topInset = MediaQuery.of(context).padding.top;
    const double appBarH = 36;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, topInset + appBarH, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RouteModeTabBar(controller: _tabController),
          const SizedBox(height: 10),
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (currentChild, previousChildren) => Stack(
                alignment: Alignment.topCenter,
                children: [
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              ),
              transitionBuilder: (child, animation) {
                final bool isMultiChild = child.key == const ValueKey('multi');
                final bool isIncoming = isMultiChild == state.multiMode;
                final double beginDx = isIncoming
                    ? (state.multiMode ? 0.12 : -0.12)
                    : (state.multiMode ? -0.12 : 0.12);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(beginDx, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: state.multiMode
                  ? KeyedSubtree(
                      key: const ValueKey('multi'),
                      child: _MultiRouteCard(
                        legs: state.legs,
                        paxText: _paxFieldText(state),
                        canAdd: state.canAddLeg,
                        canRemove: state.canRemoveLeg,
                        onFromTap: (i) => _pickLegCity(i, 0),
                        onToTap: (i) => _pickLegCity(i, 1),
                        onDateTap: _pickLegDate,
                        onRemove: _removeLeg,
                        onAdd: _addLeg,
                        onPaxTap: _pickPassengers,
                      ),
                    )
                  : KeyedSubtree(
                      key: const ValueKey('simple'),
                      child: _WebSearchCard(
                        from: state.from,
                        to: state.to,
                        dateText: _dateFieldText(state),
                        dateIsPlaceholder: state.date == null,
                        paxText: _paxFieldText(state),
                        onFromTap: () => _pickCity(0),
                        onToTap: () => _pickCity(1),
                        onSwap: _swap,
                        onDateTap: _pickDate,
                        onPaxTap: _pickPassengers,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: _WebTogglePill(
                    label: "home_direct_flight".tr(),
                    value: state.direct,
                    onChanged: (v) => _cubit.setFilters(
                      direct: v,
                      baggage: state.baggage,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _WebTogglePill(
                    label: "home_with_baggage".tr(),
                    value: state.baggage,
                    onChanged: (v) => _cubit.setFilters(
                      direct: state.direct,
                      baggage: v,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _WebSearchButton(onTap: _search),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? ProjectTheme.backgroundDark : _Web.pageBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 36,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleSpacing: 0,
        leadingWidth: 52,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: _HeroBackButton(onTap: () => Navigator.of(context).maybePop()),
        ),
        // Scroll bo'lganda sahifa foniga to'ladi — kontent status bar ostidan
        // ko'rinib qolmaydi.
        flexibleSpace: ValueListenableBuilder<double>(
          valueListenable: _headerColorT,
          builder: (_, t, __) => ColoredBox(
            color: Color.lerp(
              Colors.transparent,
              isDark ? ProjectTheme.backgroundDark : _Web.pageBg,
              t,
            )!,
          ),
        ),
      ),
      body: BlocBuilder<RouteSearchCubit, RouteSearchState>(
        builder: (context, state) {
          // Device home indicator / nav bar ostida kontent qolmasin.
          final double bottomInset = MediaQuery.paddingOf(context).bottom;
          return SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.only(bottom: bottomInset + 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _hero(context, state),
                AnimatedSize(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: state.multiMode
                      ? const SizedBox(width: double.infinity)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                              child: _PriceChartCard(
                                prices: state.monthPrices,
                                loading: state.monthLoading,
                                onTap: _openPriceChart,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _BestOffersSection(
                              offers: state.offers,
                              loading: state.offersLoading,
                              date: state.offersDate,
                              onTap: _openOffer,
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

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
