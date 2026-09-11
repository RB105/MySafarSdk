import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show HapticFeedback, SystemUiOverlayStyle;
import 'package:flutter_bloc/flutter_bloc.dart'
    show BlocProvider, BlocBuilder, ReadContext;
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
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
///  • "Narxlar jadvali" — yaqin kunlar ustun-grafigi; kartani bosganda
///    365 kunlik to'liq jadval bottom sheet'da ochiladi;
///  • "Eng yaxshi takliflar" — eng arzon kunga topilgan aniq reyslar
///    (gorizontal kartalar; bosilganda o'sha sana bo'yicha natijalar).
///
/// Bosh sahifadan kelganda ([autoPromptDatePassengers]): avval kalendar,
/// keyin yo'lovchilar ochiladi — qidiruv faqat "Bilet izlash" da.
class RouteSearchPage extends StatelessWidget {
  final AirPortsModel from;
  final AirPortsModel to;

  /// Destination CTA dan kelganda eng arzon kun oldindan tanlanadi.
  final DateTime? initialDate;
  final DateTime? initialEndDate;

  /// Bosh sahifadan yo'nalish tanlangach: sana → yo'lovchi ketma-ket ochiladi.
  /// "Bilet izlash" bosilmaguncha qidiruv boshlanmaydi.
  final bool autoPromptDatePassengers;

  const RouteSearchPage({
    super.key,
    required this.from,
    required this.to,
    this.initialDate,
    this.initialEndDate,
    this.autoPromptDatePassengers = false,
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
      child: _RouteSearchView(
        autoPromptDatePassengers: autoPromptDatePassengers,
      ),
    );
  }
}

/// Sahifaning ko'rinish (view) qatlami — biznes-holat [RouteSearchCubit]da.
/// Bu widget faqat holatni chizadi va foydalanuvchi tanlovlarini (dialog
/// natijalarini) cubit'ga uzatadi; o'zida saqlanadigan holat yo'q.
class _RouteSearchView extends StatefulWidget {
  const _RouteSearchView({this.autoPromptDatePassengers = false});

  final bool autoPromptDatePassengers;

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
    // Bosh sahifadan kelganda: sana → yo'lovchi (price chart emas).
    if (widget.autoPromptDatePassengers) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (MySafarSdk.config.enableMultiSearch && _cubit.state.multiMode) {
          return;
        }
        _runDatePassengerFlow();
      });
    }
  }

  void _onTabChanged() {
    if (!MySafarSdk.config.enableMultiSearch) return;
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

  /// Sana → yo'lovchi yo'riqli oqim. Qidiruv faqat "Bilet izlash" da.
  Future<void> _runDatePassengerFlow() async {
    final datePicked = await _pickDate();
    if (!mounted || !datePicked) return;
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    await _pickPassengers();
  }

  /// Sana tanlash (kalendar). Muvaffaqiyatli tanlansa `true`.
  Future<bool> _pickDate() async {
    final s = _cubit.state;
    final r = await ProjectDialogs.showCalendartPicker(
      context,
      1,
      s.date != null ? PickerDateRange(s.date, s.endDate) : null,
      s.from,
      s.to,
    );
    if (!mounted || r == null || r.startDate == null) return false;
    if (r.endDate != null) {
      _cubit.setDates(r.startDate!, r.endDate);
    } else {
      _cubit.pickDay(r.startDate!);
    }
    return true;
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

  /// Narxlar jadvali bottom sheet'ini ochadi. MySafar'dagi kabi: sana(lar)
  /// tanlanadi, filtrlar qo'llanadi va "Bilet topish" qidiruvni boshlaydi.
  Future<void> _openPriceChart() async {
    HapticFeedback.lightImpact();
    AnalyticsService().trackButtonTap('route_price_chart');
    final s = _cubit.state;
    final picked = await showSdkModalBottomSheet<_PriceChartPick>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PriceChartSheet(
        from: s.from,
        to: s.to,
        initialDate: s.date,
        initialEndDate: s.endDate,
        direct: s.direct,
        baggage: s.baggage,
        adt: s.adt,
        chd: s.chd,
        inf: s.inf,
        klass: s.klass,
      ),
    );
    if (!mounted || picked == null) return;
    _cubit.setFilters(direct: picked.direct, baggage: picked.baggage);
    if (picked.end != null) {
      _cubit.setDates(picked.start, picked.end);
    } else {
      _cubit.pickDay(picked.start);
    }
    _search();
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
    if (MySafarSdk.config.enableMultiSearch && state.multiMode) {
      _searchMulti();
      return;
    }
    // Webda tugma doim faol — sana tanlanmagan bo'lsa ogohlantiramiz
    // (bosh sahifadagi forma bilan bir xil xatti-harakat).
    if (!state.hasDate) {
      showToastTr("home_fill_search");
      return;
    }
    if (state.isSameAirport) {
      showToastTr("same_airport_warning");
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
      showToastTr(error);
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

  /// Light: ko'k hero (MySafar). Dark: qora fon + dark karta (MySafar dark).
  Widget _hero(BuildContext context, RouteSearchState state) {
    final double topInset = MediaQuery.of(context).padding.top;
    const double appBarH = 36;
    final bool enableMulti = MySafarSdk.config.enableMultiSearch;
    final bool multiMode = enableMulti && state.multiMode;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (enableMulti) ...[
          _RouteModeTabBar(controller: _tabController),
          const SizedBox(height: 10),
        ],
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
              final bool isIncoming = isMultiChild == multiMode;
              final double beginDx = isIncoming
                  ? (multiMode ? 0.12 : -0.12)
                  : (multiMode ? -0.12 : 0.12);
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
            child: multiMode
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
        const SizedBox(height: 10),
        Row(
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
        const SizedBox(height: 12),
        _WebSearchButton(onTap: _search),
      ],
    );

    if (isDark) {
      // MySafar dark: ko'k shell yo'q — qora sahifa ustida dark karta.
      return Padding(
        padding: EdgeInsets.fromLTRB(16, topInset + appBarH, 16, 8),
        child: body,
      );
    }

    // MySafar light: ko'k hero, pastki burchaklari yumaloq.
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ProjectTheme.brandColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(16, topInset + appBarH, 16, 16),
      child: body,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg =
        isDark ? ProjectTheme.backgroundDark : _Web.pageBg;
    final Color appBarFill =
        isDark ? ProjectTheme.backgroundDark : ProjectTheme.brandColor;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDark ? Brightness.light : Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: pageBg,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 36,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          titleSpacing: 0,
          leadingWidth: 52,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child:
                _HeroBackButton(onTap: () => Navigator.of(context).maybePop()),
          ),
          flexibleSpace: ValueListenableBuilder<double>(
            valueListenable: _headerColorT,
            builder: (_, t, __) => ColoredBox(
              color: Color.lerp(Colors.transparent, appBarFill, t)!,
            ),
          ),
        ),
        body: BlocBuilder<RouteSearchCubit, RouteSearchState>(
          builder: (context, state) {
            final double bottomInset = MediaQuery.paddingOf(context).bottom;
            return SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.only(bottom: bottomInset + 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _hero(context, state),
                  const SizedBox(height: 16),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: (MySafarSdk.config.enableMultiSearch &&
                            state.multiMode)
                        ? const SizedBox(width: double.infinity)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 0),
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
      ),
    );
  }
}

// Quyidagi yordamchilar narxlar jadvali sheet'i va "Eng arzon kunlar"
// blokida birgalikda ishlatiladi.

/// API'dan kelgan ixcham narx satrini ("551 571", "2.3M") songa o'giradi.
double? _parseCompactPrice(String s) => ElementFormatter.parsePrice(s);

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
