import 'package:mysafar_sdk/src/model/local/recom_req_model.dart'
    show RecommendationReqBodySegment, RecommendationRequestBody;
import 'package:mysafar_sdk/src/model/remote/avia/airports_model.dart'
    show AirPortsModel;
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightElement, GetRecommendationResModel;
import 'package:mysafar_sdk/src/model/remote/avia/ticket_date_price_model.dart'
    show DatePrice, TicketDatePriceModel;
import 'package:mysafar_sdk/src/service/config/remote_config_service.dart'
    show RemoteConfigService;
import 'package:mysafar_sdk/src/model/remote/destination/destination_detail_model.dart'
    show DestinationDetailModel;
import 'package:mysafar_sdk/src/service/avia_service.dart' show AviaService;
import 'package:mysafar_sdk/src/service/fornex/fornex_repository.dart'
    show FornexRepository;
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'dart:async' show Timer;

import 'package:dio/dio.dart' show CancelToken;
import 'package:mysafar_sdk/src/core/config/network_request_scope.dart'
    show NetworkCancel, NetworkRequestScope;
import 'package:mysafar_sdk/src/cubit/main/datePicker/date_picker_cubit.dart'
    show MonthPriceParams;

part 'route_search_state.dart';

/// Yo'nalish qidiruv oynasining biznes-mantig'i (RouteSearchPage). Barcha
/// forma holati va yuklanadigan ma'lumot shu yerda — sahifaning o'zi faqat
/// holatni chizadi va foydalanuvchi tanlovlarini shu cubit'ga uzatadi.
class RouteSearchCubit extends Cubit<RouteSearchState> with NetworkCancel {
  RouteSearchCubit({
    required AirPortsModel from,
    required AirPortsModel to,
    required AviaService aviaService,
    required FornexRepository fornexRepository,
    RecommendationRequestBody? lastSearch,
  })  : _avia = aviaService,
        _fornex = fornexRepository,
        super(initialState(from: from, to: to, lastSearch: lastSearch)) {
    _loadMonthPrices();
    _loadDestInfo();
  }

  final AviaService _avia;
  final FornexRepository _fornex;

  /// Boshlang'ich holat: yo'lovchilar soni va klass oxirgi qidiruvdan olinadi
  /// (№31) — takroriy qidiruvda har safar qaytadan tanlash shart emas.
  /// Noto'g'ri qiymatlar (chaqaloq > katta, jami > 9) standartga qaytadi.
  static RouteSearchState initialState({
    required AirPortsModel from,
    required AirPortsModel to,
    RecommendationRequestBody? lastSearch,
  }) {
    final base = RouteSearchState(from: from, to: to);
    if (lastSearch == null) return base;
    final int adt = lastSearch.adt;
    final int chd = lastSearch.chd;
    final int inf = lastSearch.inf;
    final bool valid =
        adt >= 1 && chd >= 0 && inf >= 0 && inf <= adt && adt + chd + inf <= 9;
    final String klass = (lastSearch.klass ?? '').trim().toLowerCase();
    return base.copyWith(
      adt: valid ? adt : null,
      chd: valid ? chd : null,
      inf: valid ? inf : null,
      klass: const {'a', 'e', 'b', 'f', 'w'}.contains(klass) ? klass : null,
    );
  }

  /// Joriy so'rov kaliti — async yuklash tugaganda natija hali dolzarbmi
  /// (foydalanuvchi shahar, yo'lovchilar, klass yoki filtrlarni
  /// almashtirmadimi) tekshirish uchun. Oylik narxlar ham, takliflar ham shu
  /// parametrlar bilan so'raladi.
  String get _routeKey => '${state.from.cityIataCode}-${state.to.cityIataCode}'
      '|${state.adt}-${state.chd}-${state.inf}-${state.klass}'
      '|${state.direct}-${state.baggage}';

  /// Oylik narxlar so'rovi parametrlari — kalendar va narxlar jadvali ham
  /// aynan shularni yuboradi, shuning uchun narxlar bir marta so'raladi.
  MonthPriceParams get priceParams => MonthPriceParams(
        adt: state.adt,
        chd: state.chd,
        inf: state.inf,
        klass: MonthPriceParams.normalizeKlass(state.klass),
        direct: state.direct,
        baggage: state.baggage,
      );

  // ── Forma tanlovlari ──────────────────────────────────────────────────

  void setFrom(AirPortsModel value) {
    emit(state.copyWith(from: value));
    _loadMonthPrices();
  }

  void setTo(AirPortsModel value) {
    emit(state.copyWith(to: value));
    _loadMonthPrices();
    _loadDestInfo();
  }

  void swap() {
    emit(state.copyWith(from: state.to, to: state.from));
    _loadMonthPrices();
    _loadDestInfo();
  }

  void setDates(DateTime date, DateTime? endDate) {
    emit(endDate == null
        ? state.copyWith(date: date, clearEndDate: true)
        : state.copyWith(date: date, endDate: endDate));
  }

  void pickDay(DateTime day) {
    emit(state.copyWith(
      date: DateTime(day.year, day.month, day.day),
      clearEndDate: true,
    ));
  }

  void setPassengers({
    required int adt,
    required int chd,
    required int inf,
    required String klass,
  }) {
    if (state.adt == adt &&
        state.chd == chd &&
        state.inf == inf &&
        state.klass == klass) {
      return;
    }
    emit(state.copyWith(adt: adt, chd: chd, inf: inf, klass: klass));
    // Narxlar va "Eng yaxshi takliflar" yo'lovchilar soni va klassga bog'liq —
    // eski (boshqa tarkib uchun topilgan) takliflar bron qilinmasin.
    _loadMonthPrices();
  }

  /// Filtr kalitlari — narxlar kalendari ham shu filtrlar bilan qayta so'raladi
  /// (o'chiq filtr so'rovga umuman qo'shilmaydi).
  void setFilters({required bool direct, required bool baggage}) {
    if (state.direct == direct && state.baggage == baggage) return;
    emit(state.copyWith(direct: direct, baggage: baggage));
    _loadMonthPrices();
  }

  // ── Murakkab marshrut (tab 2) ─────────────────────────────────────────

  void setMultiMode(bool value) {
    if (state.multiMode == value) return;
    if (value && state.legs.isEmpty) {
      emit(state.copyWith(
        multiMode: true,
        legs: [
          RouteLeg(from: state.from, to: state.to, date: state.date),
          RouteLeg(from: state.to),
        ],
      ));
      return;
    }
    emit(state.copyWith(multiMode: value));
  }

  void addLeg() {
    if (!state.canAddLeg) return;
    final last = state.legs.isEmpty ? null : state.legs.last;
    emit(state.copyWith(legs: [...state.legs, RouteLeg(from: last?.to)]));
  }

  void removeLeg(int index) {
    if (!state.canRemoveLeg || index < 0 || index >= state.legs.length) return;
    final legs = [...state.legs]..removeAt(index);
    emit(state.copyWith(legs: legs));
  }

  void setLegFrom(int index, AirPortsModel value) =>
      _updateLeg(index, (leg) => leg.copyWith(from: value));

  void setLegTo(int index, AirPortsModel value) =>
      _updateLeg(index, (leg) => leg.copyWith(to: value));

  void setLegDate(int index, DateTime value) => _updateLeg(
        index,
        (leg) =>
            leg.copyWith(date: DateTime(value.year, value.month, value.day)),
      );

  void _updateLeg(int index, RouteLeg Function(RouteLeg leg) update) {
    if (index < 0 || index >= state.legs.length) return;
    final legs = [...state.legs];
    legs[index] = update(legs[index]);
    emit(state.copyWith(legs: legs));
  }

  String? validateLegs() {
    final legs = state.legs;
    if (legs.length < RouteSearchState.minLegs) return "home_fill_search";
    DateTime? previous;
    for (final leg in legs) {
      if (!leg.isComplete) return "home_fill_search";
      if (leg.isSameCity) return "same_airport_warning";
      if (previous != null && leg.date!.isBefore(previous)) {
        return "routes_date_order_warning";
      }
      previous = leg.date;
    }
    return null;
  }

  // ── Ma'lumot yuklash ──────────────────────────────────────────────────

  /// Oylik narxlar so'rovining boshlanish sanasi: tanlangan sana bugundan
  /// boshlanadigan 30 kunlik oynaga tushsa — `null` (bugundan, umumiy kesh).
  static DateTime? _monthAnchor(DateTime? date) {
    if (date == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    return day.difference(today).inDays < 30 ? null : day;
  }

  Future<void> _loadMonthPrices() async {
    refreshNetworkCancel();
    // Eski parametrlar bilan ketayotgan / kutilayotgan takliflar qidiruvi
    // darhol bekor qilinadi (№79).
    _cancelBestOffers();
    // Parametrlar qayta yuklanmoqda — oldingi takliflar endi yaroqsiz.
    _offersLoadedKey = null;
    final key = _routeKey;
    // Eski takliflar ham darhol olib tashlanadi: ular boshqa yo'nalish /
    // yo'lovchilar uchun topilgan, bosilsa noto'g'ri parametrlar bilan
    // bronga ketardi.
    emit(state.copyWith(
      monthLoading: true,
      clearMonthPrices: true,
      offersLoading: true,
      offers: const [],
      clearOffersDate: true,
    ));
    try {
      final response = await withNetworkCancel(
        () => _avia.getPriceByMonth(
          state.from.cityIataCode ?? '',
          state.to.cityIataCode ?? '',
          // Sana 30 kunlik oynaga tushsa yuborilmaydi (bugundan) — narxlar
          // jadvali, kalendar va karta bir xil so'rov/kesh kalitidan
          // foydalanadi (№39). Uzoqroq sana tanlangan bo'lsa, narxlar o'sha
          // davr uchun olinadi.
          date: _monthAnchor(state.date),
          adt: priceParams.adt,
          chd: priceParams.chd,
          inf: priceParams.inf,
          klass: priceParams.klass,
          direct: priceParams.direct,
          baggage: priceParams.baggage,
        ),
      );
      if (isClosed || key != _routeKey) return;
      emit(state.copyWith(
        monthLoading: false,
        monthPrices: response is NetworkSuccessResponse
            ? response.data as TicketDatePriceModel
            : null,
        clearMonthPrices: response is! NetworkSuccessResponse,
      ));
      _scheduleBestOffers();
    } catch (_) {
      if (!isClosed && key == _routeKey) {
        emit(state.copyWith(monthLoading: false, offersLoading: false));
      }
    }
  }

  static const int _maxOffers = 6;

  // ── "Eng yaxshi takliflar" fon qidiruvi (№79) ─────────────────────────
  // Ilgari sahifa ochilganda va har yo'lovchi/filtr o'zgarishida HAMMA
  // manbaga parallel to'liq qidiruv ketardi va asosiy qidiruv boshlanganda
  // ham bekor qilinmasdi (90 s gacha) — birinchi natijalar sekinlashardi.
  // Endi: debounce, o'z CancelToken'i (yangi so'rov / natijalarga o'tishda
  // bekor), manbalar KETMA-KET (birinchi reys bergan manbada to'xtaydi).
  static const Duration offersDebounce = Duration(milliseconds: 700);
  Timer? _offersDebounce;
  CancelToken? _offersCancel;
  int _offersSeq = 0;

  /// Qaysi parametrlar ([_routeKey]) uchun takliflar oxirigacha yuklangan.
  String? _offersLoadedKey;

  /// Natijalar sahifasi ochiq — fon takliflar qidiruvi boshlanmaydi
  /// (oylik narxlar shu paytda kelsa ham); qaytilganda davom etadi.
  bool _backgroundPaused = false;

  void _scheduleBestOffers() {
    _offersDebounce?.cancel();
    if (_backgroundPaused) return;
    _offersDebounce = Timer(offersDebounce, () {
      _offersDebounce = null;
      if (!isClosed) _loadBestOffers();
    });
  }

  void _cancelBestOffers() {
    _offersDebounce?.cancel();
    _offersDebounce = null;
    final token = _offersCancel;
    if (token != null && !token.isCancelled) token.cancel('superseded');
    _offersCancel = null;
    _offersSeq++;
  }

  /// Asosiy qidiruv (natijalar sahifasi) boshlanganda: fon takliflar
  /// qidiruvi to'xtatiladi — server va tarmoq asosiy qidiruvga qoladi.
  void pauseBackgroundSearches() {
    _backgroundPaused = true;
    _cancelBestOffers();
    if (!isClosed && state.offersLoading && !state.monthLoading) {
      emit(state.copyWith(offersLoading: false));
    }
  }

  /// Natijalar sahifasidan qaytilganda: takliflar joriy parametrlar uchun
  /// yuklanmagan bo'lsa (to'xtatilgan edi) — qayta rejalashtiriladi.
  void resumeBackgroundSearches() {
    _backgroundPaused = false;
    if (isClosed) return;
    if (state.monthPrices == null) {
      // Pauza paytida oylik narxlar xato bilan tugagan — takliflar
      // yuklanmaydi, shimmer abadiy qolmasin.
      if (!state.monthLoading && state.offersLoading) {
        emit(state.copyWith(offersLoading: false));
      }
      return;
    }
    if (_offersLoadedKey == _routeKey) return;
    emit(state.copyWith(offersLoading: true));
    _scheduleBestOffers();
  }

  @override
  Future<void> close() {
    _cancelBestOffers();
    return super.close();
  }

  Future<void> _loadBestOffers() async {
    final date = _cheapestDate();
    if (date == null) {
      _offersLoadedKey = _routeKey;
      if (!isClosed) {
        emit(state.copyWith(
          offersLoading: false,
          offers: const [],
          clearOffersDate: true,
        ));
      }
      return;
    }
    final key = _routeKey;
    final int seq = ++_offersSeq;
    final token = CancelToken();
    _offersCancel = token;
    bool isStale() => isClosed || key != _routeKey || seq != _offersSeq;
    emit(state.copyWith(offersLoading: true, offers: const []));
    try {
      // Takliflar foydalanuvchining AYNAN o'z yo'lovchilari, klassi va
      // filtrlari bilan qidiriladi: taklif bosilganda shu reys (id/narx)
      // `buildRequest()` parametrlari bilan bronga ketadi — 1 kattalik
      // narx/id N yo'lovchiga bron qilinmasligi kerak.
      final body = RecommendationRequestBody(
        adt: state.adt,
        chd: state.chd,
        inf: state.inf,
        segments: [
          RecommendationReqBodySegment(
            from: state.from,
            to: state.to,
            date: "${date.day}.${date.month}.${date.year}",
          ),
        ],
        flight_Type: 0,
        klass: state.klass,
        isDirectOnly: state.direct ? 1 : 0,
        isBaggage: state.baggage,
      );
      final params = body.toJson();
      final List<String> endpoints =
          RemoteConfigService.instance.recommendationEndpoints;
      // Manbalar KETMA-KET: odatda birinchisi yetarli — 3 ta og'ir parallel
      // qidiruv o'rniga bitta. Reys bermasa keyingisiga o'tiladi.
      final List<FlightElement> flights = [];
      final Set<Object?> seenIds = {};
      for (final ep in endpoints) {
        final NetworkResponse response = await NetworkRequestScope.run(
          token,
          () => _avia.getRecommendations(params: params, endPoint: ep),
        );
        if (isStale()) return;
        if (response is! NetworkSuccessResponse) continue;
        final model = response.data as GetRecommendationResModel;
        for (final f
            in model.recommedations?.flights ?? const <FlightElement>[]) {
          if (seenIds.add(f.id)) flights.add(f);
        }
        if (flights.isNotEmpty) break;
      }
      if (isStale()) return;
      flights.sort((a, b) => _price(a).compareTo(_price(b)));
      final top = flights.length > _maxOffers
          ? flights.sublist(0, _maxOffers)
          : flights;

      _offersLoadedKey = key;
      emit(state.copyWith(
        offersLoading: false,
        offers: top,
        offersDate: date,
      ));
    } catch (_) {
      if (!isStale()) {
        emit(state.copyWith(offersLoading: false, offers: const []));
      }
    } finally {
      if (identical(_offersCancel, token)) _offersCancel = null;
    }
  }

  DateTime? _cheapestDate() {
    final m = state.monthPrices;
    if (m == null) return null;
    final List<DatePrice> list =
        m.uzsPrices ?? m.rubPrices ?? m.usdPrices ?? const [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime? bestDate;
    double? bestValue;
    for (final p in list) {
      final d = p.date;
      final s = (p.sum ?? '').trim();
      if (d == null || s.isEmpty || s == '0') continue;
      if (d.isBefore(today)) continue;
      final v = _parseSum(s);
      if (v == null) continue;
      if (bestValue == null || v < bestValue) {
        bestValue = v;
        bestDate = d;
      }
    }
    return bestDate;
  }

  static double? _parseSum(String s) {
    String t = s.replaceAll(' ', '').replaceAll('\u00a0', '').toUpperCase();
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

  /// Natijalar sahifasi bilan bir xil saralash narxi: faqat USD/RUB narxli
  /// reys UZS narxlilardan keyin (№82).
  static double _price(FlightElement e) => e.sortPrice;

  Future<void> _loadDestInfo() async {
    final cityName = state.to.cityName ?? '';
    emit(state.copyWith(clearDestInfo: true));
    if (cityName.isEmpty) return;
    try {
      final response = await _fornex.getDestinationDetailByCity(cityName);
      if (isClosed || cityName != (state.to.cityName ?? '')) return;
      if (response is NetworkSuccessResponse) {
        emit(state.copyWith(destInfo: response.data as DestinationDetailModel));
      }
    } catch (_) {}
  }

  // ── Qidiruv so'rovi ───────────────────────────────────────────────────

  /// [day] berilsa — forma holatini O'ZGARTIRMASDAN shu kunga bir tomonlama
  /// so'rov (masalan "Eng yaxshi takliflar" kartasi uchun, №85).
  RecommendationRequestBody buildRequest({DateTime? day}) {
    final date = day ?? state.date!;
    final endDate = day != null ? null : state.endDate;
    return RecommendationRequestBody(
      adt: state.adt,
      chd: state.chd,
      inf: state.inf,
      segments: [
        RecommendationReqBodySegment(
          from: state.from,
          to: state.to,
          date: "${date.day}.${date.month}.${date.year}",
        ),
        if (endDate != null)
          RecommendationReqBodySegment(
            from: state.to,
            to: state.from,
            date: "${endDate.day}.${endDate.month}.${endDate.year}",
          ),
      ],
      flight_Type: endDate != null ? 1 : 0,
      klass: state.klass,
      isDirectOnly: state.direct ? 1 : 0,
      isBaggage: state.baggage,
    );
  }

  RecommendationRequestBody buildMultiRequest() {
    return RecommendationRequestBody(
      adt: state.adt,
      chd: state.chd,
      inf: state.inf,
      segments: [
        for (final leg in state.legs)
          RecommendationReqBodySegment(
            from: leg.from,
            to: leg.to,
            date: _formatDate(leg.date!),
          ),
      ],
      flight_Type: 2,
      klass: state.klass,
      isDirectOnly: state.direct ? 1 : 0,
      isBaggage: state.baggage,
    );
  }

  static String _formatDate(DateTime d) => "${d.day}.${d.month}.${d.year}";
}
