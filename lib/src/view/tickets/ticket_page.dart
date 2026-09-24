import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter/services.dart'
    show HapticFeedback, SystemUiOverlayStyle;
import 'package:mysafar_sdk/src/core/config/response_config.dart'
    show NetworkSuccessResponse;
import 'package:mysafar_sdk/src/core/enum/currency.dart' show AppCurrency;
import 'package:mysafar_sdk/src/core/extension/context_ext.dart'
    show SizeContext;
import 'package:mysafar_sdk/src/core/styles/theme.dart' show ProjectTheme;
import 'package:mysafar_sdk/src/core/tools/currency_provider.dart'
    show CurrencyProvider;
import 'package:mysafar_sdk/src/model/remote/avia/ticket_date_price_model.dart'
    show TicketDatePriceModel, DatePrice;
import 'package:mysafar_sdk/src/service/avia_service.dart' show AviaService;
import 'package:mysafar_sdk/src/core/tools/app_cache_manager.dart'
    show AppCacheManager;
import 'package:mysafar_sdk/src/core/tools/formatters.dart';
import 'package:mysafar_sdk/src/core/tools/project_assets.dart'
    show ProjectAssets;
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart';
import 'package:mysafar_sdk/src/generated/assets.dart' show Assets;
import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart'
    show ErrorDialogAction, ErrorDialogKind, ProjectDialogs;
import 'package:mysafar_sdk/src/core/tools/sdk_sheets.dart';
import 'package:mysafar_sdk/src/core/widgets/sdk_dialog.dart'
    show SdkDialogButton, SdkDialogButtonVariant;
import 'package:mysafar_sdk/src/core/widgets/toast_widget.dart'
    show AppMessageType;
import 'package:mysafar_sdk/src/cubit/tickets/tickets_cubit.dart';
import 'package:mysafar_sdk/src/cubit/tickets/flight_results_utils.dart'
    show FlightResultsUtils, ListResultMemo;
import 'package:mysafar_sdk/src/model/local/recom_req_model.dart'
    show RecommendationRequestBody;
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightElement, FlightSegment, GetRecommendationResModel;
import 'package:flutter_bloc/flutter_bloc.dart' show BlocConsumer, BlocProvider;
import 'package:flutter_svg/flutter_svg.dart' show SvgPicture;
import 'package:mysafar_sdk/src/view/tickets/ticket_info_page.dart';
import 'package:provider/provider.dart' show Provider;
import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';

part '_tickets_container_widgets.dart';

part '_ticket_loading_widget.dart';

part '_ticket_summary_widgets.dart';

part '_ticket_filters_sheet.dart';

class RecommendationsTicketPage extends StatefulWidget {
  final RecommendationRequestBody requestBody;

  const RecommendationsTicketPage({super.key, required this.requestBody});

  static const routeName = '/tickets';

  /// Navigator stack'dagi eng yuqori chiptalar sahifasiga qaytadi (ustidagi
  /// barcha ekranlar yopiladi) va xuddi shu parametrlar bilan qayta qidiradi.
  /// Masalan to'lov vaqti tugaganda. Stack'da chiptalar sahifasi bo'lmasa
  /// hech narsa qilmaydi va `false` qaytaradi.
  static bool returnAndSearchAgain(BuildContext context, {String? message}) {
    // Eng oxirgi ochilgani — stack'da eng yuqorida turgani.
    final target = _RecommendationsTicketPageState._live.reversed
        .where((state) => state.mounted && (state._route?.isActive ?? false))
        .firstOrNull;
    final route = target?._route;
    if (target == null || route == null) return false;

    Navigator.of(context).popUntil((r) => r == route || r.isFirst);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (target.mounted) target._searchAgain(message: message);
    });
    return true;
  }

  @override
  State<RecommendationsTicketPage> createState() =>
      _RecommendationsTicketPageState();
}


/// Chiptalar sahifasi status bar — iOS'da SliverAppBar o'zi yetarli emas;
/// Scaffold atrofida AnnotatedRegion bilan birga ishlatiladi.
SystemUiOverlayStyle _ticketPageOverlayStyle(bool isDark) => isDark
    ? const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      )
    : const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      );

class _RecommendationsTicketPageState extends State<RecommendationsTicketPage> {
  /// Hozir mount bo'lgan (stack'dagi) sahifalar — ochilish tartibida.
  static final List<_RecommendationsTicketPageState> _live = [];

  ModalRoute<dynamic>? _route;
  TicketCubit? _ticketCubit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
  }

  /// [RecommendationsTicketPage.returnAndSearchAgain] dan chaqiriladi:
  /// ro'yxat tepaga qaytadi va joriy parametrlar bilan yangi so'rov ketadi.
  void _searchAgain({String? message}) {
    final cubit = _ticketCubit;
    if (cubit == null || cubit.isClosed) return;
    final controller = _innerScroll;
    if (controller != null && controller.hasClients) controller.jumpTo(0);
    cubit.add(GetRecommendationsEvent(cubit.filterReqBody));
    if (message != null && message.isNotEmpty) {
      ProjectDialogs.showCustomToast(context, message,
          type: AppMessageType.warning);
    }
  }
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

  // Foydalanuvchi eskirish dialogini yopib, natijalarni ko'rishda davom etdi —
  // ro'yxat ustida bloklamaydigan ogohlantirish banneri ("Qayta qidirish"
  // bilan) ko'rsatiladi. Yangi qidiruv boshlanganda o'chadi. Bron oldidan
  // reys baribir serverda qayta tekshiriladi (TicketInfoPage).
  bool _pricesStale = false;

  // ── API xatosi dialogi ────────────────────────────────────────────────
  // Qidiruvda barcha manbalar xato bergan bo'lsa (tarmoq uzilishi va h.k.),
  // ro'yxat o'rniga dialog chiqaramiz: "Qayta urinish" — xuddi shu parametrlar
  // bilan yangi so'rov; "Yopish" — bitta oldingi ekranga qaytish.
  // Bayroq bir vaqtda ikkita dialog ochilib ketmasligi uchun.
  bool _errorDialogOpen = false;

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
    _live.add(this);
    _loadedStripFilters = _stripFilters();
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
      // Qidiruvdagi yo'lovchilar/klass bilan — qidiruv sahifasi bilan bir xil
      // kesh kaliti (takroriy so'rov yo'q) va narxlar shu qidiruvga mos.
      final body = widget.requestBody;
      // №80: lenta narxlari qidiruvning "To'g'ri reys" / "Bagaj" filtrlari
      // bilan (ilgari ulanishli/bagajsiz reys narxi ko'rinardi).
      final (direct, baggage) = _stripFilters();
      final int req = ++_monthPricesReq;
      final response = await AviaService().getPriceByMonth(
        from,
        to,
        adt: body.adt,
        chd: body.chd,
        inf: body.inf,
        klass: body.klass ?? 'a',
        direct: direct,
        baggage: baggage,
      );
      if (!mounted || req != _monthPricesReq) return;
      if (response is NetworkSuccessResponse) {
        setState(() => _monthPrices = response.data as TicketDatePriceModel);
      }
    } catch (_) {
      // Narxlarsiz ham lenta ishlayveradi.
    }
  }

  int _monthPricesReq = 0;
  (bool, bool)? _loadedStripFilters;

  /// Sana lentasi narxlari uchun filtrlar: qidiruv (server) filtri yoki
  /// ekrandagi ko'rinish filtri yoqilgan bo'lsa.
  (bool, bool) _stripFilters() {
    final body = _ticketCubit?.filterReqBody ?? widget.requestBody;
    return (
      body.isDirect() || _viewFilters.directOnly,
      body.getBaggage() || _viewFilters.baggageOnly,
    );
  }

  /// Filtrlar o'zgargan bo'lsa lenta narxlarini qayta so'raydi.
  void _reloadMonthPricesIfFiltersChanged() {
    if (!_showDateStrip) return;
    final current = _stripFilters();
    if (current == _loadedStripFilters) return;
    _loadedStripFilters = current;
    _loadMonthPrices();
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

  // Ko'rinish filtrlari versiyasi — filtrlangan ro'yxat keshi ([_viewFlightsMemo])
  // faqat filtr yoki natija ro'yxati o'zgarganda qayta hisoblanishi uchun.
  int _viewFiltersVersion = 0;
  final ListResultMemo<List<FlightElement>> _viewFlightsMemo =
      ListResultMemo<List<FlightElement>>();

  void _clearViewFilters({String source = 'empty_view'}) {
    setState(() {
      _viewFilters.reset();
      _viewFiltersVersion++;
      _orderFrozen = false;
      _hasHiddenUpdates = false;
    });
    _reloadMonthPricesIfFiltersChanged();
    AnalyticsService()
        .trackButtonTap('filter_reset', extra: {'source': source});
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

  /// Ko'rinish filtrlarini yuklangan ro'yxatga qo'llaydi (saralash emas —
  /// u [_AnimatedFlightList] ichida, FLIP animatsiyasi bilan bajariladi).
  /// [values] berilmasa sahifaning joriy filtrlari ishlatiladi (sheet esa
  /// qoralama qiymatlar bo'yicha natija sonini shu orqali hisoblaydi).
  List<FlightElement> _applyViewFilters(List<FlightElement> src,
      [_ViewFilterValues? values]) {
    final v = values ?? _viewFilters;
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
    return _ViewFilterValues.matchesPeriods(
            v.depPeriods, _minutesOfDay(segs.first.dep.time)) &&
        _ViewFilterValues.matchesPeriods(
            v.arrPeriods, _minutesOfDay(segs.last.arr.time));
  }

  /// Chip yoki appbar'dagi filter tugmasi bosilganda TO'LIQ "Filtr" sheet'i
  /// ochiladi — chip bosilganda o'sha bo'limga surilgan holda, filter
  /// tugmasida esa boshidan ([section] `null`).
  /// Qo'llash bosilgandagina qiymatlar ro'yxatga qo'llanadi.
  Future<void> _openViewFilters(
      TicketCubit cubit, _ViewFilterSection? section) async {
    HapticFeedback.lightImpact();
    AnalyticsService().trackButtonTap('ticket_view_filters');
    final flights = cubit.overAllData?.recommedations?.flights ?? const [];
    final result = await _showViewFiltersSheet(
      context,
      initial: _viewFilters,
      initialSection: section,
      airlines: _groupFlightsByAirline(flights),
      countResults: (values) => _applyViewFilters(flights, values).length,
    );
    if (result != null && mounted) {
      setState(() {
        _viewFilters.copyFrom(result);
        _viewFiltersVersion++;
        // Foydalanuvchi o'zi qayta saraladi — muzlatilgan tartib bekor.
        _orderFrozen = false;
        _hasHiddenUpdates = false;
      });
      _reloadMonthPricesIfFiltersChanged();
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

  // ── Yangi manba kelganda scroll joyini saqlash ────────────────────────
  // Natijalar 3 ta manbadan bosqichma-bosqich keladi va ro'yxat narx bo'yicha
  // saralanadi. Ilgari foydalanuvchi pastda bo'lsa ro'yxat majburan tepaga
  // surilardi — o'qiyotgan kartasi yo'qolardi. Endi user pastda bo'lsa,
  // ko'rsatilayotgan tartib MUZLATILADI (`_orderFrozen`): mavjud kartalar
  // joyida qoladi, yangi reyslar oxiriga qo'shiladi va pastda "Yangi reyslar"
  // tugmasi chiqadi. Uni bossa (yoki o'zi tepaga qaytsa) ro'yxat to'liq
  // saralanadi.
  //
  // Tugma bosilganda kartalarni qayta tartiblovchi FLIP animatsiyasi scroll
  // bilan to'qnashmasligi uchun shu yangilanishda FLIP o'tkazib yuboriladi
  // (`_reorderSuppressed`).
  bool _reorderSuppressed = false;
  bool _orderFrozen = false;
  bool _hasHiddenUpdates = false;
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
      AnalyticsService().trackButtonTap('tickets_search_again',
          extra: {'source': 'prices_outdated'});
      cubit.add(GetRecommendationsEvent(cubit.filterReqBody));
    } else {
      // Yopildi — bloklamaymiz, faqat ro'yxat ustida banner qoladi.
      setState(() => _pricesStale = true);
    }
  }

  /// "Bilet topilmadi" / xato holatidan qidiruv formasiga (oldingi ekranga)
  /// qaytish — sana, yo'nalish yoki yo'lovchilarni o'zgartirish uchun.
  void _changeSearch(String source) {
    AnalyticsService()
        .trackButtonTap('tickets_change_search', extra: {'source': source});
    Navigator.of(context).maybePop();
  }

  /// "Bilet topilmadi" / xato holatidan xuddi shu parametrlar bilan qayta
  /// qidirish.
  void _retrySearch(String source) {
    AnalyticsService()
        .trackButtonTap('tickets_search_again', extra: {'source': source});
    _searchAgain();
  }

  /// API'dan HAR QANDAY xato kelganda (tarmoq, timeout, 4xx, 5xx, noma'lum)
  /// shu dialog ko'rsatiladi — sarlavha xato turiga qarab o'zgaradi.
  /// "Qayta urinish" bosilsa — joriy parametrlar bilan yangi so'rov,
  /// "Yopish" bosilsa — bitta oldingi ekranga (qidiruv formasiga) qaytamiz.
  Future<void> _showErrorDialog(
      TicketCubit cubit, TicketErrorState state) async {
    if (!mounted || _errorDialogOpen || _refreshDialogOpen) return;

    // Sahifa ekranda ko'rinmasa (masalan, user boshqa ekranga o'tib ketgan
    // bo'lsa) dialogni chiqarmaymiz — narx yangilash dialogidagi qoidaning
    // aynan o'zi.
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return;

    _errorDialogOpen = true;
    final action = await ProjectDialogs.showApiErrorDialog(
      context,
      message: state.errorMsg,
      errorType: state.errorType,
    );
    _errorDialogOpen = false;
    if (!mounted) return;

    if (action == ErrorDialogAction.retry) {
      if (cubit.isClosed) return;
      cubit.add(GetRecommendationsEvent(cubit.filterReqBody));
    } else {
      // Yopish — bitta oldingi ekranga (qidiruv formasiga) qaytamiz.
      Navigator.of(context).maybePop();
    }
  }

  /// Xato holati izohi — dialogdagi qoida bilan bir xil: server matni bo'sh
  /// yoki sarlavhaning o'zi bo'lsa, xato turiga mos tayyor matn.
  static String _errorSubtitle(TicketErrorState state) {
    final kind = ErrorDialogKind.fromErrorType(state.errorType);
    final message = state.errorMsg.trim();
    return (message.isEmpty || message == kind.title)
        ? kind.fallbackMessage
        : message;
  }

  @override
  void dispose() {
    _live.remove(this);
    _priceRefreshTimer?.cancel();
    super.dispose();
  }

  /// Indikator tugallanish animatsiyasini yakunlagach uni olib tashlaymiz.
  void _onLoadingBarCompleted() {
    if (mounted && _finishing) {
      setState(() => _finishing = false);
    }
  }

  /// Har bir manba natijasi kelganda chaqiriladi. Foydalanuvchi pastga scroll
  /// qilgan bo'lsa — joyidan SURILMAYDI: tartib muzlatiladi va "Yangi reyslar"
  /// tugmasi ko'rsatiladi. Tepada bo'lsa hech narsa qilmaymiz (FLIP animatsiyasi
  /// qayta tartiblanishni o'zi ko'rsatadi).
  /// [_onResultsArrived] oxirgi marta qaysi natija obyekti uchun chaqirilgan.
  GetRecommendationResModel? _lastArrivedRes;

  /// Oxirgi ko'rilgan natijaning reyslari — yangi reys qo'shildimi
  /// solishtirish uchun (№86).
  List<FlightElement>? _lastArrivedFlights;

  void _onResultsArrived() {
    final controller = _innerScroll;
    if (controller == null || !controller.hasClients) return;
    // Ozgina qoldiqni "tepada" deb hisoblaymiz (aniq 0 bo'lishi shart emas).
    if (controller.offset <= 8) return;
    setState(() {
      _orderFrozen = true;
      _hasHiddenUpdates = true;
    });
  }

  /// "Yangi reyslar" tugmasi: ro'yxat to'liq saralanadi va tepaga suriladi.
  void _showUpdatedResults() {
    HapticFeedback.lightImpact();
    AnalyticsService().trackButtonTap('tickets_new_results');
    final controller = _innerScroll;
    // Scroll bilan bir vaqtda kartalar FLIP qilib to'qnashmasin — shu
    // yangilanishda qayta tartiblash animatsiyasini o'tkazib yuboramiz.
    setState(() {
      _reorderSuppressed = true;
      _orderFrozen = false;
      _hasHiddenUpdates = false;
    });
    if (controller != null && controller.hasClients) {
      controller.animateTo(
        0,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reorderSuppressed = false;
    });
  }

  /// User o'zi ro'yxat tepasiga qaytdi — muzlatilgan tartibni bekor qilamiz.
  bool _onBodyScroll(ScrollUpdateNotification n) {
    if (_orderFrozen && n.depth == 0 && n.metrics.pixels <= 8) {
      setState(() {
        _orderFrozen = false;
        _hasHiddenUpdates = false;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (context) => TicketCubit(widget.requestBody, false),
        child: BlocConsumer<TicketCubit, TicketsState>(
          listener: (context, state) {
            // Yangi qidiruv boshlanganda taymerni to'xtatamiz; natija to'liq
            // kelganda (yoki bo'sh/xato bo'lganda) 5 daqiqalik taymerni
            // qaytadan boshlaymiz — shu paytdan idle hisoblanadi.
            if (state is TicketLoadingState) {
              _priceRefreshTimer?.cancel();
              // Server filtri (appbar) o'zgargan bo'lsa — lenta narxlari ham.
              _reloadMonthPricesIfFiltersChanged();
              _lastArrivedFlights = null;
              // Yangi qidiruv — eskirish banneri va muzlatilgan tartib bekor.
              if (_pricesStale || _orderFrozen || _hasHiddenUpdates) {
                setState(() {
                  _pricesStale = false;
                  _orderFrozen = false;
                  _hasHiddenUpdates = false;
                });
              }
            } else if (state is TicketSuccessState) {
              if (!state.isLoadingMore) {
                _restartPriceRefreshTimer(
                    BlocProvider.of<TicketCubit>(context));
              }
              // Har bir manba kelganda (2-, 3-...) user pastda bo'lsa —
              // joyidan surmaymiz, "Yangi reyslar" tugmasini ko'rsatamiz.
              // Xato / bo'sh manba ham shu holatni (o'sha ro'yxat bilan)
              // qayta chiqaradi — ro'yxat o'zgarmagan bo'lsa tugma chiqmasin.
              if (!identical(state.recommendationRes, _lastArrivedRes)) {
                _lastArrivedRes = state.recommendationRes;
                // Merge har doim YANGI obyekt qaytaradi — dedupe'dan keyin
                // yangi reys qo'shilmagan bo'lsa (faqat takror yoki arzonroq
                // dublikat) tugma chiqmaydi (№86).
                final previous = _lastArrivedFlights;
                final current =
                    state.recommendationRes.recommedations?.flights ??
                        const <FlightElement>[];
                _lastArrivedFlights = current;
                if (previous == null ||
                    FlightResultsUtils.hasNewFlights(previous, current)) {
                  _onResultsArrived();
                }
              }
            } else if (state is TicketEmptyState || state is TicketErrorState) {
              _restartPriceRefreshTimer(BlocProvider.of<TicketCubit>(context));
              // API xato qaytardi (tur muhim emas) — ro'yxat o'rniga xato
              // dialogini ko'rsatamiz (qayta urinish / orqaga qaytish).
              if (state is TicketErrorState) {
                _showErrorDialog(BlocProvider.of<TicketCubit>(context), state);
              }
            }
          },
          builder: (context, state) {
            final ticketCubit = BlocProvider.of<TicketCubit>(context);
            _ticketCubit = ticketCubit;

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

            final bool isDark = context.isDarkMode;

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: _ticketPageOverlayStyle(isDark),
              child: Scaffold(
                body: SafeArea(
                    top: false,
                    bottom: Platform.isAndroid,
                    child: NestedScrollView(
                        headerSliverBuilder: (context, innerBoxIsScrolled) {
                      final showFilters =
                          state is TicketSuccessState || ticketCubit.isFiltered;
                      // Web-uslub chiplar: har biri o'z filtrining joriy
                      // qiymatini ko'rsatadi, bosilganda tanlov sheet ochiladi.
                      final _RecViewFilterBar? filterBar = showFilters
                          ? _RecViewFilterBar(
                              values: _viewFilters,
                              onOpen: (section) =>
                                  _openViewFilters(ticketCubit, section),
                              onClear: () => _clearViewFilters(source: 'chips'),
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
                          systemOverlayStyle: _ticketPageOverlayStyle(isDark),
                          toolbarHeight: 64,
                          centerTitle: true,
                          leadingWidth: 52,
                          leading: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: _RecHeroIconButton(
                              asset: Assets.iconsScanBackIcon,
                              semanticLabel: "back".tr(),
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
                              asset: Assets.iconsTicketsCurrencyIcon,
                              semanticLabel: "rate".tr(),
                              onTap: () =>
                                  ProjectDialogs.showCurrencyMenu(context),
                            ),
                            // Valyuta yonidagi filter tugmasi ham xuddi
                            // chiplar kabi to'liq "Filtr" sheet'ini ochadi;
                            // belgida faol filtrlar soni.
                            _RecHeroIconButton(
                              asset: Assets.iconsTicketsFiltersIcon,
                              semanticLabel: "filter_title".tr(),
                              badge: _viewFilters.activeCount,
                              onTap: () => _openViewFilters(ticketCubit, null),
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
                      // Natija ro'yxati yoki filtrlar o'zgarmasa — keshdan
                      // (har rebuild'da qayta filtrlanmaydi).
                      final List<FlightElement> viewFlights =
                          state is TicketSuccessState
                              ? _viewFlightsMemo.get(
                                  state.recommendationRes.recommedations!
                                      .flights,
                                  _viewFiltersVersion,
                                  () => _applyViewFilters(state
                                      .recommendationRes
                                      .recommedations!
                                      .flights))
                              : const [];
                      final list = CustomScrollView(
                        slivers: [
                          // Narxlar eskirgan (dialog yopilgan) — bloklamaydigan
                          // ogohlantirish + "Qayta qidirish".
                          if (state is TicketSuccessState && _pricesStale)
                            SliverToBoxAdapter(
                              child: _PricesOutdatedBanner(
                                onRefresh: () =>
                                    _retrySearch('prices_outdated_banner'),
                              ),
                            ),
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
                                freezeOrder: _orderFrozen,
                              ),
                            _ => SliverPadding(
                                padding: context.k16horizontalPadding,
                                sliver: SliverToBoxAdapter(
                                  child: switch (state) {
                                    TicketLoadingState() => Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: _TicketCardSkeleton(
                                          isReturn:
                                              widget.requestBody.flight_Type ==
                                                  1,
                                        ),
                                      ),
                                    // Boshi berk ko'cha emas: qidiruvni
                                    // o'zgartirish yoki qayta qidirish.
                                    TicketEmptyState() => _NoResultsView(
                                        title: "not_found_tickets".tr(),
                                        // "Boshqa sanalarda topdik" izohi faqat
                                        // sana-narx lentasi ko'rinsa ma'noli.
                                        subtitle: _showDateStrip
                                            ? "found_other_tickets".tr()
                                            : null,
                                        primaryLabel: "change_search".tr(),
                                        onPrimary: () =>
                                            _changeSearch('empty'),
                                        secondaryLabel: "search_again".tr(),
                                        onSecondary: () =>
                                            _retrySearch('empty'),
                                      ),
                                    // Xato asosan dialog orqali ko'rsatiladi;
                                    // dialog chiqmagan hollarda (sahifa o'sha
                                    // payt ko'rinmagan) sahifa bo'sh qolmasin —
                                    // xuddi shu matn va "Qayta urinish".
                                    TicketErrorState() => _NoResultsView(
                                        title: ErrorDialogKind.fromErrorType(
                                                state.errorType)
                                            .title,
                                        subtitle: _errorSubtitle(state),
                                        primaryLabel: "retry_search".tr(),
                                        onPrimary: () =>
                                            _retrySearch('error'),
                                        secondaryLabel: "change_search".tr(),
                                        onSecondary: () =>
                                            _changeSearch('error'),
                                      ),
                                    _ => const SizedBox(),
                                  },
                                ),
                              ),
                          },
                        ],
                      );
                      return NotificationListener<ScrollUpdateNotification>(
                        onNotification: _onBodyScroll,
                        child: Stack(
                          children: [
                            list,
                            // Pastda turgan userga: yangi manba natijalari
                            // qo'shildi — bosilsa saralanib tepaga suriladi.
                            if (_hasHiddenUpdates &&
                                state is TicketSuccessState)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 20,
                                child: Center(
                                  child: _NewResultsPill(
                                    onTap: _showUpdatedResults,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }))),
              ),
            );
          },
        ));
  }
}

// ════════════════════════════════════════════════════════════════════
//  LIGHT APP BAR (Figma): orqaga + yo'nalish pill'i + valyuta/filter;
//  ostida qora sana-narx lentasi va filter chip'lari.
// ════════════════════════════════════════════════════════════════════

/// App bar tugmasi — och fonda to'q rangli oddiy ikonka (doirasiz).
/// Bosish maydoni 48dp; ekran o'quvchi uchun [semanticLabel] bilan.
class _RecHeroIconButton extends StatelessWidget {
  final String asset;
  final VoidCallback onTap;

  /// Ekran o'quvchi (TalkBack/VoiceOver) o'qiydigan tugma nomi.
  final String semanticLabel;

  /// 0 dan katta bo'lsa o'ng yuqori burchakda son belgisi ko'rsatiladi.
  final int badge;

  const _RecHeroIconButton({
    required this.asset,
    required this.onTap,
    required this.semanticLabel,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final Color color =
        context.isDarkMode ? Colors.white : const Color(0xFF16244A);
    final button = Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: SvgPicture.asset(
              asset,
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
    final String label =
        badge > 0 ? "$semanticLabel ($badge)" : semanticLabel;
    final labelled = Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: button,
    );
    if (badge <= 0) return labelled;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        labelled,
        Positioned(
          top: 7,
          right: 6,
          child: IgnorePointer(
            child: Container(
              constraints: const BoxConstraints(minWidth: 17),
              height: 17,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ProjectTheme.brandColor,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: context.color.primaryContainer,
                  width: 1.5,
                ),
              ),
              child: Text(
                "$badge",
                style: _TixTheme.style(11, FontWeight.w800, Colors.white),
                textScaler: TextScaler.noScaling,
              ),
            ),
          ),
        ),
      ],
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
    final bool isDark = context.isDarkMode;
    final Color textColor = isDark ? Colors.white : const Color(0xFF16244A);
    final Color subColor =
        isDark ? Colors.white70 : ProjectTheme.secondaryTextLight;

    // Appbar balandligi qat'iy (64px) — katta tizim shriftida ikki qator
    // sig'may qolmasligi uchun matn kattalashishi cheklanadi.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: _buildPill(textColor, subColor, isDark),
    );
  }

  Widget _buildPill(Color textColor, Color subColor, bool isDark) {
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
              final int percent = (_progress.value * 100).clamp(0, 100).round();
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
                        // Qat'iy 36x14 joy — tizim shrifti kattalashtirmasin.
                        textScaler: TextScaler.noScaling,
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

/// Narxlar eskirgan bo'lishi mumkinligi haqida ro'yxat ustidagi bloklamaydigan
/// banner (eskirish dialogi yopilgandan keyin) — "Qayta qidirish" bilan.
class _PricesOutdatedBanner extends StatelessWidget {
  final VoidCallback onRefresh;

  const _PricesOutdatedBanner({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    const Color amber = Color(0xFFB45309);
    final Color accent = t.dark ? const Color(0xFFFBBF24) : amber;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: accent.withAlpha(t.dark ? 36 : 24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withAlpha(t.dark ? 90 : 70)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, size: 20, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "prices_outdated_banner".tr(),
              style: _TixTheme.style(13, FontWeight.w600, t.hi, height: 1.3),
            ),
          ),
          const SizedBox(width: 6),
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              onRefresh();
            },
            style: TextButton.styleFrom(
              foregroundColor: ProjectTheme.brandColor,
              minimumSize: const Size(48, 44),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: Text(
              "search_again".tr(),
              style: _TixTheme.style(
                  13.5,
                  FontWeight.w700,
                  t.dark ? Colors.white : ProjectTheme.brandColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// User pastda turganda yangi manba natijalari qo'shilganini bildiruvchi
/// suzuvchi tugma — bosilsa ro'yxat saralanib tepaga suriladi.
class _NewResultsPill extends StatelessWidget {
  final VoidCallback onTap;

  const _NewResultsPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      liveRegion: true,
      child: Material(
        color: ProjectTheme.brandColor,
        elevation: 4,
        shadowColor: Colors.black38,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_upward_rounded,
                      size: 18, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    "new_flights_found".tr(),
                    style: _TixTheme.style(14, FontWeight.w700, Colors.white),
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

// ════════════════════════════════════════════════════════════════════
//  NARX BO'YICHA SARALANADIGAN, SILLIQ SILJISH ANIMATSIYALI RO'YXAT
// ════════════════════════════════════════════════════════════════════

/// FlightElement narxini (son) qaytaradi — saralash uchun. Narx matni bir
/// marta (odatda fon isolate'da) o'qilib keshlanadi: [FlightElement.sortPrice].
double _flightPriceUzs(FlightElement f) => f.sortPrice;

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

  /// `true` — ko'rsatilayotgan tartib saqlanadi (user pastda turganda yangi
  /// manba keldi): mavjud kartalar joyida qoladi, yangilari oxiriga qo'shiladi.
  final bool freezeOrder;

  const _AnimatedFlightList({
    required this.flights,
    required this.isLoadingMore,
    required this.flightType,
    this.sortMode = 0,
    this.animateReorder = true,
    this.freezeOrder = false,
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

  /// Joriy ro'yxatdagi eng arzon reys id'si ("Eng arzon" belgisi uchun —
  /// tartib muzlatilganda ham to'g'ri kartaga qo'yilsin).
  String? _cheapestId;

  /// Barqaror karta kaliti: arzonroq dublikat eski kartani almashtirganda
  /// (boshqa id) yangi reys ESKI kartaning kalitini oladi — karta qayta
  /// yaratilmaydi va muzlatilgan tartibda o'z o'rnida qoladi (№86).
  /// `reys id → kalit`; yo'q bo'lsa kalit = id.
  final Map<String, String> _stableKey = {};

  String _keyOf(FlightElement f) => _stableKey[f.id] ?? f.id;

  /// Almashtirilgan reyslar uchun kalitlarni ko'chiradi va eskilarini tozalaydi.
  void _updateStableKeys(Map<String, String> replaced) {
    final currentIds = <String>{for (final f in widget.flights) f.id};
    replaced.forEach((newId, oldId) {
      final key = _stableKey[oldId] ?? oldId;
      // Kalit boshqa (mavjud) reys id'si bilan to'qnashmasin.
      if (currentIds.contains(key) && key != newId) return;
      _stableKey[newId] = key;
    });
    _stableKey.removeWhere((id, _) => !currentIds.contains(id));
  }

  @override
  void initState() {
    super.initState();
    _display = _computeDisplay();
    _cheapestId = _findCheapestId();
  }

  String? _findCheapestId() {
    FlightElement? best;
    for (final f in widget.flights) {
      // Faqat UZS narxli reys "Eng arzon" bo'la oladi (№82).
      if (!f.hasUzsSortPrice) continue;
      if (best == null || f.sortPrice < best.sortPrice) best = f;
    }
    return best?.id;
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
  List<FlightElement> _computeDisplay() =>
      FlightResultsUtils.stableSort(widget.flights, _sortKey);

  /// Muzlatilgan tartib: hozir ko'rinayotgan kartalar o'z o'rnida (ro'yxatda
  /// hali bo'lsa), yangi kelganlar — o'zaro saralangan holda — oxirida.
  List<FlightElement> _computeFrozenDisplay(
      [Map<String, String> replaced = const {}]) {
    final byId = <String, FlightElement>{
      for (final f in widget.flights) f.id: f,
    };
    // eski id → uni almashtirgan (arzonroq dublikat) reys id'si.
    final replacedBy = <String, String>{
      for (final e in replaced.entries) e.value: e.key,
    };
    final kept = <FlightElement>[];
    for (final f in _display) {
      final newId = replacedBy[f.id];
      final current =
          byId.remove(f.id) ?? (newId == null ? null : byId.remove(newId));
      if (current != null) kept.add(current);
    }
    final added = [
      for (final f in widget.flights)
        if (byId.containsKey(f.id)) f,
    ];
    return [...kept, ...FlightResultsUtils.stableSort(added, _sortKey)];
  }

  @override
  void didUpdateWidget(covariant _AnimatedFlightList oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Ro'yxat, saralash rejimi va muzlatish o'zgarmagan bo'lsa (masalan
    // indikator yoki taymer tufayli rebuild) — qayta saralamaymiz.
    if (identical(oldWidget.flights, widget.flights) &&
        oldWidget.sortMode == widget.sortMode &&
        oldWidget.freezeOrder == widget.freezeOrder) {
      return;
    }

    final oldDisplay = _display;
    // Eski tartib kalitlari — kalitlar yangilanishidan OLDIN.
    final oldIds = [for (final f in oldDisplay) _keyOf(f)];
    Map<String, String> replaced = const {};
    if (!identical(oldWidget.flights, widget.flights)) {
      replaced =
          FlightResultsUtils.replacedIds(oldWidget.flights, widget.flights);
      _updateStableKeys(replaced);
    }
    final newDisplay = widget.freezeOrder
        ? _computeFrozenDisplay(replaced)
        : _computeDisplay();
    _display = newDisplay;
    if (!identical(oldWidget.flights, widget.flights)) {
      _cheapestId = _findCheapestId();
    }

    // Ota-widget shu yangilanishda ro'yxatni tepaga scroll qilayotgan bo'lsa,
    // FLIP'ni o'tkazib yuboramiz — ro'yxat to'g'ridan-to'g'ri saralangan holda
    // ko'rsatiladi (scroll animatsiyasi bilan to'qnashmasin).
    if (!widget.animateReorder) return;

    final newIds = [for (final f in newDisplay) _keyOf(f)];
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      sliver: SliverList.separated(
        itemCount: count + (widget.isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          // Oxirgi element — qolgan manbalar kutilayotgani uchun loading.
          if (index >= count) {
            return const _MoreResultsLoading();
          }
          final flight = flights[index];
          // Belgilar faqat narx bo'yicha saralashda ma'noli: "Eng arzon" —
          // 1-kartada (logo yonida), "Ekonom" — 1- va 2-kartalarda (tepada).
          final bool isCheapest =
              widget.sortMode == 0 && flight.id == _cheapestId;
          final bool economBadge = index < 2 && widget.sortMode == 0;
          final String stableKey = _keyOf(flight);
          return _FlipItem(
            key: ValueKey(stableKey),
            id: stableKey,
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
