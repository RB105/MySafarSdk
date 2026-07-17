import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter/services.dart'
    show HapticFeedback, SystemUiOverlayStyle;
import 'package:mysafar_sdk/src/core/config/response_config.dart'
    show NetworkSuccessResponse;
import 'package:mysafar_sdk/src/core/enum/currency.dart' show AppCurrency;
import 'package:mysafar_sdk/src/core/extension/context_ext.dart' show SizeContext;
import 'package:mysafar_sdk/src/core/styles/theme.dart' show ProjectTheme;
import 'package:mysafar_sdk/src/core/tools/currency_provider.dart'
    show CurrencyProvider;
import 'package:mysafar_sdk/src/model/remote/avia/ticket_date_price_model.dart'
    show TicketDatePriceModel, DatePrice;
import 'package:mysafar_sdk/src/service/avia_service.dart' show AviaService;
import 'package:mysafar_sdk/src/core/tools/app_cache_manager.dart' show AppCacheManager;
import 'package:mysafar_sdk/src/core/tools/formatters.dart';
import 'package:mysafar_sdk/src/core/tools/project_assets.dart' show ProjectAssets;
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart';
import 'package:mysafar_sdk/src/generated/assets.dart' show Assets;
import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart' show ProjectDialogs;
import 'package:mysafar_sdk/src/cubit/tickets/tickets_cubit.dart';
import 'package:mysafar_sdk/src/model/local/recom_req_model.dart'
    show RecommendationRequestBody;
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightElement, FlightSegment;
import 'package:flutter_bloc/flutter_bloc.dart' show BlocConsumer, BlocProvider;
import 'package:flutter_svg/flutter_svg.dart' show SvgPicture;
import 'package:mysafar_sdk/src/view/tickets/ticket_info_page.dart';
import 'package:provider/provider.dart' show Provider;
import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';

import 'my_safar_ticket_shimmer.dart';

part '_tickets_container_widgets.dart';

part '_ticket_loading_widget.dart';

part '_ticket_summary_widgets.dart';

class RecommendationsTicketPage extends StatefulWidget {
  final RecommendationRequestBody requestBody;

  const RecommendationsTicketPage({super.key, required this.requestBody});

  static const routeName = '/tickets';

  @override
  State<RecommendationsTicketPage> createState() =>
      _RecommendationsTicketPageState();
}

class _RecommendationsTicketPageState extends State<RecommendationsTicketPage> {
  // ── Yuklash indikatori holati ──────────────────────────────────────────
  // Yuklash boshlanganda indikator sekin to'ladi; natija kelganda tezda 100%
  // ga to'lib, so'ng o'chadi. `_finishing` — natija kelgandan keyin tugallanish
  // animatsiyasi o'ynalishi uchun indikatorni ko'rinishda ushlab turadi.
  bool _prevLoading = false;
  bool _finishing = false;

  // ── Narx eskirishi ogohlantirishi ─────────────────────────────────────
  // Foydalanuvchi natijalar ekranida uzoq (5 daqiqa) tursa, bilet narxlari
  // eskirgan bo'lishi mumkin. Shu sababli ogohlantiruvchi dialog ko'rsatib,
  // xuddi shu parametrlar bilan qaytadan qidirishni taklif qilamiz.
  //
  // MUHIM: dialog FAQAT shu sahifa ekranda ko'rinib turganda chiqsin.
  // Foydalanuvchi boshqa ekranga (masalan, bilet tafsilotlari) o'tib ketsa,
  // taymer ishlashda davom etadi, lekin dialog ko'rsatilmaydi — sahifaga
  // qaytib kelgandagina chiqadi. Buni har safar `ModalRoute.isCurrent` orqali
  // tekshiramiz (navigator stack holatidan; observer kerak emas).
  static const Duration _priceRefreshTimeout = Duration(minutes: 5);
  // Sahifa ko'rinmay turganda dialogni ko'rsatish o'rniga shuncha vaqtdan keyin
  // qayta tekshiramiz (sahifaga qaytishni "kutish" intervali).
  static const Duration _visibilityRecheck = Duration(milliseconds: 500);
  Timer? _priceRefreshTimer;
  bool _refreshDialogOpen = false;

  // ── Sana-narx lentasi (web mobil dizayni) ─────────────────────────────
  // Qo'shni kunlarning eng arzon narxlari appbar ostidagi to'q ko'k lentada
  // ko'rsatiladi; boshqa kun bosilsa, o'sha sana bilan qayta qidiriladi.
  // Narxlar mavjud oylik-kalendar API'sidan olinadi; kelmasa lenta faqat
  // sanalar bilan ishlayveradi. Faqat bir tomonlama (one-way) qidiruvda.
  TicketDatePriceModel? _monthPrices;

  bool get _showDateStrip =>
      (widget.requestBody.flight_Type ?? 0) == 0 &&
      _selectedStripDate() != null;

  @override
  void initState() {
    super.initState();
    _loadMonthPrices();
  }

  Future<void> _loadMonthPrices() async {
    if ((widget.requestBody.flight_Type ?? 0) != 0) return;
    final segments = widget.requestBody.segments;
    if (segments == null || segments.isEmpty) return;
    final from = segments.first.from?.cityIataCode ?? '';
    final to = segments.first.to?.cityIataCode ?? '';
    if (from.isEmpty || to.isEmpty) return;
    try {
      final response = await AviaService().getPriceByMonth(from, to);
      if (!mounted) return;
      if (response is NetworkSuccessResponse) {
        setState(
            () => _monthPrices = response.data as TicketDatePriceModel);
      }
    } catch (_) {
      // Narxlarsiz ham lenta ishlayveradi.
    }
  }

  /// Birinchi segment sanasi ("24.7.2026" yoki "24-07-2026" ko'rinishida).
  DateTime? _selectedStripDate() {
    final segments = widget.requestBody.segments;
    final raw =
        (segments == null || segments.isEmpty) ? '' : segments.first.date ?? '';
    if (raw.isEmpty) return null;
    final parts = raw.contains('-') ? raw.split('-') : raw.split('.');
    if (parts.length != 3) return null;
    // yyyy-MM-dd formati ham qo'llab-quvvatlanadi.
    final bool yearFirst = parts[0].length == 4;
    final day = int.tryParse(yearFirst ? parts[2] : parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(yearFirst ? parts[0] : parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  // ── Web-uslub ko'rinish filtrlari (chiplar qatori) ────────────────────
  // Saytdagi kabi appbar ostidagi chiplar: Saralash / Almashishlar / Bagaj /
  // Tarif qoidalari. Serverga qayta so'rov YUBORILMAYDI — yuklangan ro'yxatga
  // darhol qo'llanadi (web ham shunday ishlaydi). To'liq server filtri esa
  // avvalgidek appbar'dagi filter tugmasida qoladi.
  final _ViewFilterValues _viewFilters = _ViewFilterValues();

  int get _viewSort => _viewFilters.sort;

  void _clearViewFilters() {
    setState(() => _viewFilters.reset());
    AnalyticsService()
        .trackButtonTap('filter_reset', extra: {'source': 'empty_view'});
  }

  /// Reys barcha yo'nalishlarda almashishsizmi.
  static bool _isDirectFlight(FlightElement f) {
    final dirs = f.segmentsDirection?.length ?? 1;
    for (int i = 0; i < dirs; i++) {
      if (f.getTransferCount(i) > 0) return false;
    }
    return true;
  }

  /// Reysning kun ichidagi jo'nash/qo'nish daqiqasi (birinchi yo'nalish).
  /// Aniqlab bo'lmasa `null` — bunday reys vaqt filtridan chiqarilmaydi.
  static int? _minutesOfDay(String? time) {
    final t = (time ?? '').split(':');
    if (t.length < 2) return null;
    final h = int.tryParse(t[0]);
    final m = int.tryParse(t[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  static bool _inTimeRange(int? minutes, RangeValues range) {
    if (range.start <= 0 && range.end >= _ViewFilterValues.dayMinutes) {
      return true;
    }
    if (minutes == null) return true;
    return minutes >= range.start && minutes <= range.end;
  }

  /// Ko'rinish filtrlarini yuklangan ro'yxatga qo'llaydi (saralash emas —
  /// u [_AnimatedFlightList] ichida, FLIP animatsiyasi bilan bajariladi).
  List<FlightElement> _applyViewFilters(List<FlightElement> src) {
    final v = _viewFilters;
    if (!v.hasAnyFilter) return src;
    return [
      for (final f in src)
        if ((!v.directOnly || _isDirectFlight(f)) &&
            (!v.baggageOnly || (f.isBaggage ?? false)) &&
            (!v.refundable || f.isRefund == true) &&
            (!v.exchangeable || f.isExchangeable()) &&
            _matchesTimeAndAirline(f, v))
          f
    ];
  }

  static bool _matchesTimeAndAirline(FlightElement f, _ViewFilterValues v) {
    final segs = f.getSegmentsByDirection(0);
    if (segs.isEmpty) return true;
    if (v.excludedAirlines.contains(segs.first.carrier.code)) return false;
    return _inTimeRange(_minutesOfDay(segs.first.dep.time), v.depRange) &&
        _inTimeRange(_minutesOfDay(segs.last.arr.time), v.arrRange);
  }

  /// Chip yoki appbar'dagi filter tugmasi bosilganda web'dagi kabi TO'LIQ
  /// "Filtr" sheet'i ochiladi — chip bosilganda o'sha bo'lim ochiq holda,
  /// filter tugmasida esa barcha bo'limlar yig'ilgan holda ([section] `null`).
  /// Qo'llash bosilgandagina qiymatlar ro'yxatga qo'llanadi.
  Future<void> _openViewFilters(
      TicketCubit cubit, _ViewFilterSection? section) async {
    HapticFeedback.lightImpact();
    AnalyticsService().trackButtonTap('ticket_view_filters');
    final airlines = _groupFlightsByAirline(
        cubit.overAllData?.recommedations?.flights ?? const []);
    final result = await _showViewFiltersSheet(
      context,
      initial: _viewFilters,
      initialSection: section,
      airlines: airlines,
    );
    if (result != null && mounted) {
      setState(() => _viewFilters.copyFrom(result));
    }
  }

  /// Lentada boshqa kun tanlandi: segment sanasini (asl ajratkich uslubini
  /// saqlagan holda) yangilab, xuddi shu parametrlar bilan qayta qidiramiz.
  void _onStripDateTap(TicketCubit cubit, DateTime date) {
    final segments = widget.requestBody.segments;
    if (segments == null || segments.isEmpty) return;
    final segment = segments.first;
    final bool dashed = (segment.date ?? '').contains('-');
    segment.date = dashed
        ? "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}"
        : "${date.day}.${date.month}.${date.year}";
    setState(() {});
    cubit.add(GetRecommendationsEvent(cubit.filterReqBody));
  }

  // ── Har saralanishda eng arzonni ko'rsatish ───────────────────────────
  // Natijalar 3 ta manbadan bosqichma-bosqich keladi va ro'yxat har safar narx
  // bo'yicha qayta saralanadi (eng arzon tepaga) — oxirgi manbani kutmasdan.
  // Agar foydalanuvchi shu paytgacha pastga scroll qilib ketgan bo'lsa, yangi
  // eng arzonni sezmay qoladi. Shuning uchun har bir manba kelganda (2-, 3-...),
  // user tepada bo'lmasa, ro'yxatni silliq tepaga suramiz.
  //
  // Bunda kartalarni qayta tartiblovchi FLIP animatsiyasi scroll bilan bir
  // vaqtda to'qnashmasligi uchun, shu bitta yangilanishda FLIP o'tkazib
  // yuboriladi (`_reorderSuppressed`) — ro'yxat tekis saralangan holda suriladi.
  bool _reorderSuppressed = false;
  // NestedScrollView body'sining ichki (koordinatsiyalangan) scroll controlleri.
  ScrollController? _innerScroll;

  /// Eski taymerni bekor qilib, 5 daqiqalik yangi taymerni ishga tushiradi.
  void _restartPriceRefreshTimer(TicketCubit cubit) {
    _priceRefreshTimer?.cancel();
    _priceRefreshTimer =
        Timer(_priceRefreshTimeout, () => _onPriceRefreshTimeout(cubit));
  }

  /// 5 daqiqa o'tgach ishlaydi: ogohlantirish dialogini ko'rsatadi va
  /// foydalanuvchi tasdiqlasa, xuddi shu parametrlar bilan qayta qidiradi.
  Future<void> _onPriceRefreshTimeout(TicketCubit cubit) async {
    if (!mounted || _refreshDialogOpen) return;

    // Sahifa hozir eng ustki (ko'rinadigan) ekran emasmi — masalan foydalanuvchi
    // bilet tafsilotlari yoki boshqa ekranga o'tgan bo'lsa — dialogni hozir
    // CHIQARMAYMIZ. Biroz kutib qayta tekshiramiz; sahifaga qaytib kelgach,
    // `isCurrent` true bo'ladi va dialog o'shanda chiqadi.
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) {
      _priceRefreshTimer?.cancel();
      _priceRefreshTimer =
          Timer(_visibilityRecheck, () => _onPriceRefreshTimeout(cubit));
      return;
    }

    _refreshDialogOpen = true;
    final searchAgain = await ProjectDialogs.showPricesOutdatedDialog(context);
    _refreshDialogOpen = false;
    if (!mounted || cubit.isClosed) return;
    if (searchAgain) {
      // Joriy (filtrlangan yoki boshlang'ich) parametrlar bilan qayta qidiramiz;
      // natija kelganda taymer yana qaytadan boshlanadi.
      cubit.add(GetRecommendationsEvent(cubit.filterReqBody));
    }
  }

  @override
  void dispose() {
    _priceRefreshTimer?.cancel();
    super.dispose();
  }

  /// Indikator tugallanish animatsiyasini yakunlagach uni olib tashlaymiz.
  void _onLoadingBarCompleted() {
    if (mounted && _finishing) {
      setState(() => _finishing = false);
    }
  }

  /// Har bir manba kelib ro'yxat qayta saralanganda chaqiriladi. Foydalanuvchi
  /// pastga scroll qilgan bo'lsa — eng arzon reys tepaga chiqqanini ko'rishi
  /// uchun ro'yxatni silliq tepaga suradi. Allaqachon tepada bo'lsa hech narsa
  /// qilmaymiz (FLIP animatsiyasi qayta tartiblanishni o'zi ko'rsatadi).
  void _maybeScrollCheapestToTop() {
    final controller = _innerScroll;
    if (controller == null || !controller.hasClients) return;
    // Ozgina qoldiqni "tepada" deb hisoblaymiz (aniq 0 bo'lishi shart emas).
    if (controller.offset <= 8) return;

    // Scroll bilan bir vaqtda kartalar FLIP qilib to'qnashmasin — shu
    // yangilanishda qayta tartiblash animatsiyasini o'tkazib yuboramiz.
    _reorderSuppressed = true;
    controller.animateTo(
      0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reorderSuppressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (context) =>
            TicketCubit(widget.requestBody, false),
        child: BlocConsumer<TicketCubit, TicketsState>(
          listener: (context, state) {
            // Yangi qidiruv boshlanganda taymerni to'xtatamiz; natija to'liq
            // kelganda (yoki bo'sh/xato bo'lganda) 5 daqiqalik taymerni
            // qaytadan boshlaymiz — shu paytdan idle hisoblanadi.
            if (state is TicketLoadingState) {
              _priceRefreshTimer?.cancel();
            } else if (state is TicketSuccessState) {
              if (!state.isLoadingMore) {
                _restartPriceRefreshTimer(
                    BlocProvider.of<TicketCubit>(context));
              }
              // Har bir manba kelib ro'yxat qayta saralanganda (2-, 3-...),
              // user pastda bo'lsa eng arzonni ko'rsatish uchun tepaga suramiz —
              // oxirgi manbani kutib turmaymiz (u kech kelishi mumkin).
              _maybeScrollCheapestToTop();
            } else if (state is TicketEmptyState || state is TicketErrorState) {
              _restartPriceRefreshTimer(BlocProvider.of<TicketCubit>(context));
            }
          },
          builder: (context, state) {
            final ticketCubit = BlocProvider.of<TicketCubit>(context);

            // Indikator holati: yuklash boshlanganda tugallanish bayrog'ini
            // o'chiramiz; loading→natija qirrasida esa indikator tezda to'lib
            // o'chish animatsiyasini o'ynashi uchun uni yoqamiz.
            final bool isLoading = state is TicketLoadingState;
            if (isLoading) {
              _finishing = false;
            } else if (_prevLoading) {
              _finishing = true;
            }
            _prevLoading = isLoading;
            final bool showLoadingBar = isLoading || _finishing;

            return Scaffold(
                body: SafeArea(
                    top: false,
                    bottom: Platform.isAndroid,
                    child: NestedScrollView(
                        headerSliverBuilder: (context, innerBoxIsScrolled) {
                      final bool isDark = context.themeProvider.isDark;
                      final showFilters =
                          state is TicketSuccessState || ticketCubit.isFiltered;
                      // Web-uslub chiplar: har biri o'z filtrining joriy
                      // qiymatini ko'rsatadi, bosilganda tanlov sheet ochiladi.
                      final _RecViewFilterBar? filterBar = showFilters
                          ? _RecViewFilterBar(
                              values: _viewFilters,
                              onOpen: (section) =>
                                  _openViewFilters(ticketCubit, section),
                            )
                          : null;
                      return [
                        SliverAppBar(
                          pinned: true,
                          floating: false,
                          automaticallyImplyLeading: false,
                          backgroundColor: context.color.primaryContainer,
                          surfaceTintColor: Colors.transparent,
                          elevation: 0,
                          scrolledUnderElevation: 0,
                          systemOverlayStyle: isDark
                              ? const SystemUiOverlayStyle(
                                  statusBarColor: Colors.transparent,
                                  statusBarIconBrightness: Brightness.light,
                                  statusBarBrightness: Brightness.dark)
                              : const SystemUiOverlayStyle(
                                  statusBarColor: Colors.transparent,
                                  statusBarIconBrightness: Brightness.dark,
                                  statusBarBrightness: Brightness.light),
                          toolbarHeight: 64,
                          centerTitle: true,
                          leadingWidth: 46,
                          leading: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: _RecHeroIconButton(
                              icon: Icons.arrow_back_ios_new_rounded,
                              onTap: () => Navigator.of(context).maybePop(),
                            ),
                          ),
                          title: _RecHeroTitle(
                            origin: widget.requestBody.firstSegmentTitle,
                            destination: widget.requestBody.lastSegmentTitle,
                            params: widget.requestBody.params,
                          ),
                          actions: [
                            _RecHeroIconButton(
                              asset: Assets.ticketsUsdIcon,
                              onTap: () =>
                                  ProjectDialogs.showCurrencyMenu(context),
                            ),
                            // Valyuta yonidagi filter tugmasi ham xuddi
                            // chiplar kabi web-uslub to'liq "Filtr" sheet'ini
                            // ochadi (hech bir bo'lim ochilmagan holda).
                            _RecHeroIconButton(
                              asset: Assets.ticketsFilterIcon,
                              onTap: () =>
                                  _openViewFilters(ticketCubit, null),
                            ),
                            const SizedBox(width: 4),
                          ],
                          bottom: (filterBar != null ||
                                  showLoadingBar ||
                                  _showDateStrip)
                              ? _RecHeroAppBarBottom(
                                  showLoadingBar: showLoadingBar,
                                  isLoading: isLoading,
                                  onLoadingCompleted: _onLoadingBarCompleted,
                                  filterBar: filterBar,
                                  // Sana-narx lentasi appbar tarkibida —
                                  // appbar pinned bo'lgani uchun scroll'da
                                  // KAFOLATLI qadalib turadi.
                            dateStrip: _showDateStrip
                                      ? _DatePriceStrip(
                                          selected: _selectedStripDate()!,
                                          monthPrices: _monthPrices,
                                          onDateTap: (date) => _onStripDateTap(
                                              ticketCubit, date),
                                        )
                                      : null,
                                )
                              : null,
                        )
                      ];
                    }, body: Builder(builder: (context) {
                      _innerScroll = PrimaryScrollController.maybeOf(context);
                      // Chiplardagi ko'rinish filtrlari yuklangan ro'yxatga
                      // shu yerda qo'llanadi (web'dagi kabi — darhol).
                      final List<FlightElement> viewFlights =
                          state is TicketSuccessState
                              ? _applyViewFilters(state
                                  .recommendationRes.recommedations!.flights)
                              : const [];
                      return CustomScrollView(
                        slivers: [
                          // "Aviakompaniyalar bo'yicha" jamlama kartasi.
                          if (state is TicketSuccessState)
                            SliverToBoxAdapter(
                              child: _AirlinesSummaryCard(
                                flights: viewFlights,
                              ),
                            ),
                          switch (state) {
                            // Filtrlar hech narsa qoldirmadi — xabar +
                            // filtrlarni tozalash tugmasi.
                            TicketSuccessState() when viewFlights.isEmpty =>
                              SliverPadding(
                                padding: context.k16horizontalPadding,
                                sliver: SliverToBoxAdapter(
                                  child: _FilteredEmptyView(
                                    onClear: _clearViewFilters,
                                  ),
                                ),
                              ),
                            TicketSuccessState() => _AnimatedFlightList(
                                flights: viewFlights,
                                sortMode: _viewSort,
                                isLoadingMore: state.isLoadingMore,
                                flightType: widget.requestBody.flight_Type ?? 0,
                                animateReorder: !_reorderSuppressed,
                              ),
                            _ => SliverPadding(
                                padding: context.k16horizontalPadding,
                                sliver: SliverToBoxAdapter(
                                  child: switch (state) {
                                    TicketLoadingState() =>
                                      MySafarTicketShimmer(
                                        isReturn:
                                            widget.requestBody.flight_Type == 1,
                                      ),
                                    TicketEmptyState() => Column(
                                        children: [
                                          context.szBoxHeight16,
                                          SizedBox(
                                              height: 48,
                                              width: 48,
                                              child: Image.asset(Assets
                                                  .ticketsSearchEmptyIcon)),
                                          Text(
                                            "not_found_tickets".tr(),
                                            style: context.textTheme.bodyMedium
                                                ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14),
                                          ),
                                          context.szBoxHeight12,
                                          Text(
                                            "found_other_tickets".tr(),
                                            textAlign: TextAlign.center,
                                            style: context.textTheme.bodyMedium,
                                          )
                                        ],
                                      ),
                                    TicketErrorState() => Center(
                                        child: Text(state.errorMsg),
                                      ),
                                    _ => const SizedBox(),
                                  },
                                ),
                              ),
                          },
                        ],
                      );
                    }))));
          },
        ));
  }
}

// ════════════════════════════════════════════════════════════════════
//  LIGHT APP BAR (Figma): orqaga + yo'nalish pill'i + valyuta/filter;
//  ostida qora sana-narx lentasi va filter chip'lari.
// ════════════════════════════════════════════════════════════════════

/// App bar tugmasi — och fonda to'q rangli oddiy ikonka (doirasiz).
class _RecHeroIconButton extends StatelessWidget {
  final IconData? icon;
  final String? asset;
  final VoidCallback onTap;

  const _RecHeroIconButton({this.icon, this.asset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color color = context.themeProvider.isDark
        ? Colors.white
        : const Color(0xFF16244A);
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Center(
            child: asset != null
                ? SvgPicture.asset(
                    asset!,
                    width: 21,
                    height: 21,
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  )
                : Icon(icon, color: color, size: 19),
          ),
        ),
      ),
    );
  }
}

/// Markazdagi yo'nalish pill'i (Figma): "Toshkent → Dubai" va pastida
/// "27 iyun · 1 yo'lovchi · Ekonom" parametrlari.
class _RecHeroTitle extends StatelessWidget {
  final String origin;
  final String destination;
  final String params;

  const _RecHeroTitle({
    required this.origin,
    required this.destination,
    required this.params,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.themeProvider.isDark;
    final Color textColor = isDark ? Colors.white : const Color(0xFF16244A);
    final Color subColor =
        isDark ? Colors.white70 : ProjectTheme.secondaryTextLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(20) : const Color(0xFFEFF2F8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  origin,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 16, color: textColor),
              ),
              Flexible(
                child: Text(
                  destination,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (params.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              params,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: subColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Appbar ostidagi web-uslub filter chiplari qatori (mysafar.uz mobil):
/// [⇅ Saralash] [✈ Almashishlar] [🧳 Bagaj] [🛡 Tarif] [🕐 Vaqt] [✈ Avia].
/// Har bir chip o'z filtrining JORIY qiymatini ko'rsatadi; bosilganda
/// web'dagi kabi to'liq "Filtr" sheet'i o'sha bo'lim ochiq holda ochiladi.
/// Qiymat standartdan farq qilsa chip ko'k tusda.
class _RecViewFilterBar extends StatelessWidget implements PreferredSizeWidget {
  final _ViewFilterValues values;
  final void Function(_ViewFilterSection section) onOpen;

  const _RecViewFilterBar({
    required this.values,
    required this.onOpen,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final v = values;
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        children: [
          _RecFilterChip(
            icon: Icons.swap_vert_rounded,
            label: v.sortLabel(),
            active: v.sort != 0,
            onTap: () => onOpen(_ViewFilterSection.sort),
          ),
          const SizedBox(width: 8),
          _RecFilterChip(
            icon: Icons.flight_takeoff_rounded,
            label: v.transferLabel(),
            active: v.directOnly,
            onTap: () => onOpen(_ViewFilterSection.transfer),
          ),
          const SizedBox(width: 8),
          _RecFilterChip(
            icon: Icons.luggage_rounded,
            label: v.baggageLabel(),
            active: v.baggageOnly,
            onTap: () => onOpen(_ViewFilterSection.baggage),
          ),
          const SizedBox(width: 8),
          // Web'dagi kabi: tarif/vaqt/aviakompaniya chiplari qiymat emas,
          // BO'LIM NOMINI ko'rsatadi (qiymat ro'yxat emas, murakkab).
          _RecFilterChip(
            icon: Icons.verified_user_outlined,
            label: "filter_tariff_title".tr(),
            active: v.refundable || v.exchangeable,
            onTap: () => onOpen(_ViewFilterSection.tariff),
          ),
          const SizedBox(width: 8),
          _RecFilterChip(
            icon: Icons.schedule_rounded,
            label: "filter_time_title".tr(),
            active: v.hasTimeFilter,
            onTap: () => onOpen(_ViewFilterSection.time),
          ),
          const SizedBox(width: 8),
          _RecFilterChip(
            icon: Icons.airplane_ticket_outlined,
            label: "airlines_tab".tr(),
            active: v.excludedAirlines.isNotEmpty,
            onTap: () => onOpen(_ViewFilterSection.airlines),
          ),
        ],
      ),
    );
  }
}

/// Bitta filter chipi: ikonka + joriy qiymat + pastga strelka (web'dagi kabi).
class _RecFilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _RecFilterChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.themeProvider.isDark;
    final Color bg = active
        ? ProjectTheme.brandColor.withAlpha(isDark ? 60 : 26)
        : (isDark ? Colors.white.withAlpha(20) : const Color(0xFFF1F4F9));
    final Color fg = active
        ? (isDark ? Colors.white : ProjectTheme.brandColor)
        : (isDark ? Colors.white : const Color(0xFF16244A));

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: fg,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 3),
              Icon(Icons.keyboard_arrow_down_rounded, size: 17, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}

/// Appbar pastki qismi: sana-narx lentasi + chip'lar + yuklash indikatori.
class _RecHeroAppBarBottom extends StatelessWidget
    implements PreferredSizeWidget {
  /// Indikator umuman ko'rinadimi (yuklash + tugallanish animatsiyasi davomida).
  final bool showLoadingBar;

  /// `true` — natija kutilmoqda (sekin to'ladi); `false` — natija keldi
  /// (tezda to'lib o'chadi).
  final bool isLoading;

  /// Indikator tugallanish animatsiyasini yakunlaganda chaqiriladi.
  final VoidCallback onLoadingCompleted;

  final _RecViewFilterBar? filterBar;

  /// Sana-narx lentasi — appbar tarkibida bo'lgani uchun scroll'da
  /// qadalib turadi (web'dagi kabi chiplar ostida).
  final Widget? dateStrip;

  const _RecHeroAppBarBottom({
    required this.showLoadingBar,
    required this.isLoading,
    required this.onLoadingCompleted,
    this.filterBar,
    this.dateStrip,
  });

  /// Yuklash indikatori egallaydigan balandlik (chiziq + foiz qatori +
  /// pastki bo'shliq).
  static const double _loadingHeight = 22;

  @override
  Size get preferredSize => Size.fromHeight(
        (filterBar?.preferredSize.height ?? 0) +
            (dateStrip != null ? _DatePriceStrip.height : 0) +
            (showLoadingBar ? _loadingHeight : 0),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (filterBar != null) filterBar!,
        if (dateStrip != null) dateStrip!,
        if (showLoadingBar)
          _RecHeroLoadingBar(
            key: const ValueKey('rec-hero-loading-bar'),
            isLoading: isLoading,
            onCompleted: onLoadingCompleted,
          ),
      ],
    );
  }
}

/// Gradient hero ostidagi yupqa progress indikatori.
///
/// Natija kutilayotganda sekinlik bilan ~90% gacha to'ladi (tobora sekinlashib);
/// natija kelganda ([isLoading] `false` bo'lganda) tezda 100% ga to'lib, so'ng
/// o'chadi va [onCompleted] chaqiriladi. Chiziq yonida joriy to'lish foizi
/// ham ko'rsatiladi.
class _RecHeroLoadingBar extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onCompleted;

  const _RecHeroLoadingBar({
    super.key,
    required this.isLoading,
    required this.onCompleted,
  });

  @override
  State<_RecHeroLoadingBar> createState() => _RecHeroLoadingBarState();
}

class _RecHeroLoadingBarState extends State<_RecHeroLoadingBar>
    with TickerProviderStateMixin {
  // To'lish ulushi (0→1).
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 9000),
  );

  // Ko'rinish (1→0) — tugaganda o'chish (fade out) uchun.
  late final AnimationController _opacity = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    value: 1.0,
  );

  @override
  void initState() {
    super.initState();
    if (widget.isLoading) _startTrickle();
  }

  @override
  void didUpdateWidget(covariant _RecHeroLoadingBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading != widget.isLoading) {
      if (widget.isLoading) {
        _startTrickle();
      } else {
        _finish();
      }
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _opacity.dispose();
    super.dispose();
  }

  /// Natija kelishigacha sekinlik bilan ~90% gacha to'ladi (tobora sekinlashib).
  void _startTrickle() {
    _opacity.value = 1.0;
    _progress.value = 0.0;
    _progress.animateTo(
      0.9,
      duration: const Duration(milliseconds: 9000),
      curve: Curves.easeOut,
    );
  }

  /// Natija keldi — tezda 100% ga to'lib, so'ng o'chadi.
  Future<void> _finish() async {
    try {
      await _progress.animateTo(
        1.0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
      if (!mounted || widget.isLoading) return;
      await _opacity.animateTo(
        0.0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    } catch (_) {
      // TickerCanceled — yangi yuklash boshlandi yoki widget yo'q qilindi.
      return;
    }
    if (!mounted || widget.isLoading) return;
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    // Foiz matni qorong'u temada oq (brand ko'k fon bilan qo'shilib
    // ketmasligi uchun), yorug'ida brand ko'k.
    final Color percentColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : ProjectTheme.brandColor;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SizedBox(
        height: 14,
        width: double.infinity,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([_progress, _opacity]),
            builder: (_, __) {
              final int percent =
                  (_progress.value * 100).clamp(0, 100).round();
              return Opacity(
                opacity: _opacity.value,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 3,
                        child: CustomPaint(
                          painter: _LoadingBarPainter(
                            fillFraction: _progress.value,
                            track: ProjectTheme.brandColor.withAlpha(40),
                            fill: ProjectTheme.brandColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Kenglik qat'iy — foiz o'sganda qator "sakramaydi".
                    SizedBox(
                      width: 36,
                      child: Text(
                        "$percent%",
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 11,
                          height: 1.0,
                          fontWeight: FontWeight.w800,
                          color: percentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Yumaloq uchli yo'l (track) ustida chapdan o'ngga to'ladigan yorqin chiziq.
class _LoadingBarPainter extends CustomPainter {
  /// 0→1 oralig'ida to'ldirilgan ulush (curve qo'llanilgan).
  final double fillFraction;
  final Color track;
  final Color fill;

  _LoadingBarPainter({
    required this.fillFraction,
    required this.track,
    required this.fill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.height / 2);
    final full = RRect.fromRectAndRadius(Offset.zero & size, radius);

    // Yarim-shaffof yo'l (track).
    canvas.drawRRect(full, Paint()..color = track);

    final fillWidth = (size.width * fillFraction).clamp(0.0, size.width);
    if (fillWidth <= 0) return;

    final fillRect = Rect.fromLTWH(0, 0, fillWidth, size.height);
    // Boshlanishi yumshoqroq, uchi yorqinroq — "to'lib borish" hissi.
    final shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [fill.withAlpha(110), fill],
    ).createShader(fillRect);

    canvas.save();
    canvas.clipRRect(full);
    canvas.drawRRect(
      RRect.fromRectAndRadius(fillRect, radius),
      Paint()..shader = shader,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LoadingBarPainter old) =>
      old.fillFraction != fillFraction ||
      old.track != track ||
      old.fill != fill;
}

/// Natijalar ro'yxati ostida ko'rsatiladigan "yana qidirilmoqda" indikatori —
/// bir manba natijasi chiqqach, qolgan manbalar kutilayotganda ko'rinadi.
class _MoreResultsLoading extends StatelessWidget {
  const _MoreResultsLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor:
                  AlwaysStoppedAnimation<Color>(ProjectTheme.brandColor),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "searching".tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  NARX BO'YICHA SARALANADIGAN, SILLIQ SILJISH ANIMATSIYALI RO'YXAT
// ════════════════════════════════════════════════════════════════════

/// Narx satridan sonni ajratadi. `amount` formatlangan bo'lishi mumkin
/// ("1 500 000", "1,500,000" kabi) — shuning uchun raqam va nuqtadan boshqa
/// barcha belgilarni (bo'shliq, vergul, valyuta) olib tashlab parse qilamiz.
double _parseAmount(String? s) {
  if (s == null) return double.infinity;
  final cleaned = s.replaceAll(',', '').replaceAll(RegExp(r'[^0-9.]'), '');
  final v = double.tryParse(cleaned);
  return (v == null || v <= 0) ? double.infinity : v;
}

/// FlightElement narxini (son) qaytaradi — saralash uchun. Avval UZS, bo'lmasa
/// USD, so'ng RUB. Valyutalar chiziqli konvertatsiya bo'lgani uchun tartib
/// istalgan valyutada bir xil. Noaniq/yo'q narx ro'yxat oxiriga tushadi.
double _flightPriceUzs(FlightElement f) {
  final uzs = _parseAmount(f.price?.uzs?.amount);
  if (uzs != double.infinity) return uzs;
  final usd = _parseAmount(f.price?.usd?.amount);
  if (usd != double.infinity) return usd;
  return _parseAmount(f.price?.rub?.amount);
}

/// Sana ("24.07.2026" / "24-07-2026" / "2026-07-24") va vaqt ("19:10")
/// satrlaridan monotonik saralash kaliti yasaydi. Ba'zi manbalarda `ts`
/// (epoch) kelmagani uchun kartada ko'rinadigan sana/vaqtdan hisoblaymiz.
double _dateTimeKey(String? date, String? time) {
  final raw = (date ?? '').trim();
  if (raw.isEmpty) return double.infinity;
  final parts = raw.contains('-') ? raw.split('-') : raw.split('.');
  if (parts.length != 3) return double.infinity;
  final bool yearFirst = parts[0].length == 4;
  final day = int.tryParse(yearFirst ? parts[2] : parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(yearFirst ? parts[0] : parts[2]);
  if (day == null || month == null || year == null) return double.infinity;

  int minutes = 0;
  final t = (time ?? '').split(':');
  if (t.length >= 2) {
    minutes = (int.tryParse(t[0]) ?? 0) * 60 + (int.tryParse(t[1]) ?? 0);
  }
  // Kun kaliti * 1440 + kun ichidagi daqiqa.
  final dayKey = year * 10000 + month * 100 + day;
  return dayKey * 1440.0 + minutes;
}

/// Birinchi yo'nalishning jo'nash sana-vaqti — "uchish vaqti bo'yicha"
/// saralash uchun.
double _flightDepTs(FlightElement f) {
  final segs = f.getSegmentsByDirection(0);
  if (segs.isEmpty) return double.infinity;
  return _dateTimeKey(segs.first.dep.date, segs.first.dep.time);
}

/// Birinchi yo'nalishning yetib borish sana-vaqti.
double _flightArrTs(FlightElement f) {
  final segs = f.getSegmentsByDirection(0);
  if (segs.isEmpty) return double.infinity;
  return _dateTimeKey(segs.last.arr.date, segs.last.arr.time);
}

/// Umumiy parvoz davomiyligi (daqiqa) — barcha yo'nalishlar yig'indisi.
double _flightDurationMin(FlightElement f) {
  final total = f.duration ?? 0;
  if (total > 0) return total.toDouble();
  double sum = 0;
  final dirs = f.segmentsDirection?.length ?? 1;
  for (int i = 0; i < dirs; i++) {
    sum += f.getDirDuration(i);
  }
  return sum > 0 ? sum : double.infinity;
}

/// Reys natijalari ro'yxati.
///
/// • Manbalar hali kelayotganda ([isLoadingMore] `true`) — kelish (merge)
///   tartibida ko'rsatadi.
/// • Barcha manbalar tugagach ([isLoadingMore] `false`) — narx bo'yicha o'sish
///   tartibida saralaydi (eng arzon tepada). Saralashda tartib o'zgargan
///   kartalar yangi o'rniga FLIP texnikasi bilan SILLIQ suriladi (qo'pol
///   sakrash yo'q).
class _AnimatedFlightList extends StatefulWidget {
  final List<FlightElement> flights;
  final bool isLoadingMore;
  final int flightType;

  /// Chiplardagi saralash rejimi: 0-narx, 1-uchish, 2-qo'nish, 3-davomiylik.
  /// O'zgarganda kartalar FLIP animatsiyasi bilan yangi tartibga suriladi.
  final int sortMode;

  /// `false` bo'lsa, bu yangilanishda kartalarni qayta tartiblovchi FLIP
  /// animatsiyasi o'tkazib yuboriladi (ro'yxat tepaga scroll qilinayotganda,
  /// ikki animatsiya to'qnashmasligi uchun).
  final bool animateReorder;

  const _AnimatedFlightList({
    required this.flights,
    required this.isLoadingMore,
    required this.flightType,
    this.sortMode = 0,
    this.animateReorder = true,
  });

  @override
  State<_AnimatedFlightList> createState() => _AnimatedFlightListState();
}

class _AnimatedFlightListState extends State<_AnimatedFlightList> {
  /// Ekranda qurilgan (mounted) kartalar: id → ularning holati. FLIP uchun
  /// pozitsiyalarni o'lchash va animatsiyani ishga tushirishda ishlatamiz.
  final Map<String, _FlipItemState> _active = {};

  /// Hozir ko'rsatilayotgan tartib (yuklanayotganda — kelish tartibi; tugagach
  /// — narx bo'yicha saralangan).
  late List<FlightElement> _display;

  @override
  void initState() {
    super.initState();
    _display = _computeDisplay();
  }

  void _register(String id, _FlipItemState s) => _active[id] = s;
  void _unregister(String id, _FlipItemState s) {
    if (_active[id] == s) _active.remove(id);
  }

  /// Saralash kaliti — chiplarda tanlangan rejimga qarab.
  double _sortKey(FlightElement f) => switch (widget.sortMode) {
        1 => _flightDepTs(f),
        2 => _flightArrTs(f),
        3 => _flightDurationMin(f),
        _ => _flightPriceUzs(f),
      };

  /// Ko'rsatiladigan tartibni hisoblaydi: tanlangan rejim bo'yicha barqaror
  /// (teng qiymatlarda kelish tartibini saqlovchi) saralash. Manbalar
  /// bosqichma-bosqich kelsa ham (2-, 3-...) eng yaxshisi darhol tepaga
  /// chiqadi, oxirgi manbani kutmasdan.
  List<FlightElement> _computeDisplay() {
    final indexed = <MapEntry<int, FlightElement>>[
      for (int i = 0; i < widget.flights.length; i++)
        MapEntry(i, widget.flights[i]),
    ];
    indexed.sort((a, b) {
      final c = _sortKey(a.value).compareTo(_sortKey(b.value));
      return c != 0 ? c : a.key.compareTo(b.key);
    });
    return [for (final e in indexed) e.value];
  }

  @override
  void didUpdateWidget(covariant _AnimatedFlightList oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldDisplay = _display;
    final newDisplay = _computeDisplay();
    _display = newDisplay;

    // Ota-widget shu yangilanishda ro'yxatni tepaga scroll qilayotgan bo'lsa,
    // FLIP'ni o'tkazib yuboramiz — ro'yxat to'g'ridan-to'g'ri saralangan holda
    // ko'rsatiladi (scroll animatsiyasi bilan to'qnashmasin).
    if (!widget.animateReorder) return;

    final oldIds = [for (final f in oldDisplay) f.id];
    final newIds = [for (final f in newDisplay) f.id];
    if (!_orderChanged(oldIds, newIds)) return;

    // Eski (joriy layout) pozitsiyalarni — yangi tartib qurilishidan OLDIN —
    // o'lchab olamiz. Faqat ekrandagi kartalar o'lchanadi.
    final Map<String, Offset> oldOffsets = {};
    _active.forEach((id, s) {
      final off = s.slotOffset();
      if (off != null) oldOffsets[id] = off;
    });
    final oldIndex = {for (int i = 0; i < oldIds.length; i++) oldIds[i]: i};

    // Yangi layout chizilgach, yangi pozitsiyalarni o'lchab, farq (delta)
    // bo'yicha har bir kartani eski o'rnidan yangisiga silliq suramiz.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _runFlip(oldOffsets, oldIndex, newIds),
    );
  }

  bool _orderChanged(List<String> a, List<String> b) {
    if (a.length != b.length) return true;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return true;
    }
    return false;
  }

  void _runFlip(
    Map<String, Offset> oldOffsets,
    Map<String, int> oldIndex,
    List<String> newIds,
  ) {
    if (!mounted) return;

    // Yangi pozitsiyalar + o'rtacha karta balandligi (ekrandan tashqaridan
    // kiruvchilar uchun taxminiy siljishni hisoblashda kerak).
    final newOffsets = <String, Offset>{};
    double avgHeight = 0;
    int measured = 0;
    _active.forEach((id, s) {
      final off = s.slotOffset();
      if (off != null) {
        newOffsets[id] = off;
        final h = s.slotHeight();
        if (h != null && h > 0) {
          avgHeight += h;
          measured++;
        }
      }
    });
    if (measured > 0) avgHeight /= measured;
    if (avgHeight <= 0) avgHeight = 160;

    final screenH = MediaQuery.of(context).size.height;
    final newIndex = {for (int i = 0; i < newIds.length; i++) newIds[i]: i};

    newOffsets.forEach((id, newOff) {
      final s = _active[id];
      if (s == null) return;

      Offset delta;
      final old = oldOffsets[id];
      if (old != null) {
        // Aniq FLIP: eski → yangi pozitsiya farqi.
        delta = old - newOff;
      } else {
        // Ekrandan tashqaridan kirdi — indeks yo'nalishi bo'yicha taxminiy
        // siljish (pastdan ko'tarilsa pastdan, tepadan tushsa tepadan).
        final oi = oldIndex[id];
        if (oi == null) return; // butunlay yangi element — animatsiyasiz
        final ni = newIndex[id] ?? 0;
        double dy = ((oi - ni) * avgHeight).clamp(-screenH, screenH);
        delta = Offset(0, dy);
      }

      if (delta.dy.abs() < 0.5 && delta.dx.abs() < 0.5) return;
      s.playFrom(delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final flights = _display;
    final count = flights.length;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      sliver: SliverList.separated(
        itemCount: count + (widget.isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          // Oxirgi element — qolgan manbalar kutilayotgani uchun loading.
          if (index >= count) {
            return const _MoreResultsLoading();
          }
          final flight = flights[index];
          // Belgilar faqat narx bo'yicha saralashda ma'noli: "Eng arzon" —
          // 1-kartada (logo yonida), "Ekonom" — 1- va 2-kartalarda (tepada).
          final bool isCheapest = index == 0 && widget.sortMode == 0;
          final bool economBadge = index < 2 && widget.sortMode == 0;
          return _FlipItem(
            key: ValueKey(flight.id),
            id: flight.id,
            controller: this,
            child: RepaintBoundary(
              child: switch (widget.flightType) {
                1 => _ReturnDateFlightContainer(
                    flightElement: flight,
                    isCheapest: isCheapest,
                    showEconomBadge: economBadge),
                2 => _MultipleDateFlightContainer(
                    flightElement: flight,
                    isCheapest: isCheapest,
                    showEconomBadge: economBadge),
                _ => _SingleDateFlightContainer(
                    flightElement: flight,
                    isCheapest: isCheapest,
                    showEconomBadge: economBadge),
              },
            ),
          );
        },
      ),
    );
  }
}

/// Bitta karta o'rami: tartib o'zgarganda [playFrom] orqali berilgan boshlang'ich
/// siljishdan nolga qarab silliq suriladi. Tashqi `SizedBox` — o'lchov uchun
/// (layout o'rni); siljish ichki `Transform` bilan beriladi, shuning uchun
/// o'lchov animatsiyadan ta'sirlanmaydi.
class _FlipItem extends StatefulWidget {
  final String id;
  final _AnimatedFlightListState controller;
  final Widget child;

  const _FlipItem({
    required Key key,
    required this.id,
    required this.controller,
    required this.child,
  }) : super(key: key);

  @override
  State<_FlipItem> createState() => _FlipItemState();
}

class _FlipItemState extends State<_FlipItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );
  Offset _from = Offset.zero;

  @override
  void initState() {
    super.initState();
    widget.controller._register(widget.id, this);
  }

  @override
  void didUpdateWidget(covariant _FlipItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      widget.controller._unregister(oldWidget.id, this);
      widget.controller._register(widget.id, this);
    }
  }

  @override
  void dispose() {
    widget.controller._unregister(widget.id, this);
    _ctrl.dispose();
    super.dispose();
  }

  /// Karta layout o'rnining global pozitsiyasi (tashqi `SizedBox` — Transform
  /// ichkarida bo'lgani uchun animatsiya bu o'lchovga ta'sir qilmaydi).
  Offset? slotOffset() {
    final obj = context.findRenderObject();
    if (obj is RenderBox && obj.attached && obj.hasSize) {
      return obj.localToGlobal(Offset.zero);
    }
    return null;
  }

  double? slotHeight() {
    final obj = context.findRenderObject();
    if (obj is RenderBox && obj.attached && obj.hasSize) {
      return obj.size.height;
    }
    return null;
  }

  /// Kartani [delta] siljishdan boshlab nolga qarab animatsiya bilan suradi.
  void playFrom(Offset delta) {
    if (!mounted) return;
    setState(() => _from = delta);
    _ctrl.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _from = Offset.zero);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          if (_from == Offset.zero) return child!;
          final t = Curves.easeOutCubic.transform(_ctrl.value);
          final off = Offset.lerp(_from, Offset.zero, t)!;
          return Transform.translate(offset: off, child: child);
        },
        child: widget.child,
      ),
    );
  }
}
