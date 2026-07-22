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

part 'route_search_state.dart';

/// Yo'nalish qidiruv oynasining biznes-mantig'i (RouteSearchPage). Barcha
/// forma holati va yuklanadigan ma'lumot shu yerda — sahifaning o'zi faqat
/// holatni chizadi va foydalanuvchi tanlovlarini shu cubit'ga uzatadi.
///
/// Bog'liqliklar (servislar) konstruktordan beriladi — get_it orqali ulanadi,
/// testda esa mock berish mumkin (testlanuvchanlik).
class RouteSearchCubit extends Cubit<RouteSearchState> {
  RouteSearchCubit({
    required AirPortsModel from,
    required AirPortsModel to,
    required AviaService aviaService,
    required FornexRepository fornexRepository,
  })  : _avia = aviaService,
        _fornex = fornexRepository,
        super(RouteSearchState(from: from, to: to)) {
    _loadMonthPrices();
    _loadDestInfo();
  }

  final AviaService _avia;
  final FornexRepository _fornex;

  /// Joriy yo'nalish kaliti — async yuklash tugaganda natija hali dolzarbmi
  /// (foydalanuvchi shahar almashtirmadimi) tekshirish uchun.
  String get _routeKey =>
      '${state.from.cityIataCode}-${state.to.cityIataCode}';

  // ── Forma tanlovlari ──────────────────────────────────────────────────

  /// "Qayerdan" o'zgardi — narxlar qayta yuklanadi.
  void setFrom(AirPortsModel value) {
    emit(state.copyWith(from: value));
    _loadMonthPrices();
  }

  /// "Qayerga" o'zgardi — narxlar va shahar ma'lumoti qayta yuklanadi.
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

  /// Kalendardan sana(lar) tanlandi — [endDate] null bo'lsa bir tomonlama.
  void setDates(DateTime date, DateTime? endDate) {
    emit(endDate == null
        ? state.copyWith(date: date, clearEndDate: true)
        : state.copyWith(date: date, endDate: endDate));
  }

  /// Tezkor chip yoki "Eng arzon kunlar" qatoridan bir tomonlama sana.
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
    emit(state.copyWith(adt: adt, chd: chd, inf: inf, klass: klass));
  }

  void setFilters({required bool direct, required bool baggage}) {
    emit(state.copyWith(direct: direct, baggage: baggage));
  }

  // ── Ma'lumot yuklash ──────────────────────────────────────────────────

  /// Oylik narxlar — sessiya keshidan o'qiladi (takror so'rov ketmaydi).
  /// Yuklash tugaganda yo'nalish o'zgargan bo'lsa natija tashlanadi.
  Future<void> _loadMonthPrices() async {
    final key = _routeKey;
    emit(state.copyWith(
      monthLoading: true,
      clearMonthPrices: true,
      offersLoading: true,
      offers: const [],
    ));
    try {
      final response = await _avia.getPriceByMonth(
        state.from.cityIataCode ?? '',
        state.to.cityIataCode ?? '',
      );
      if (isClosed || key != _routeKey) return;
      emit(state.copyWith(
        monthLoading: false,
        monthPrices: response is NetworkSuccessResponse
            ? response.data as TicketDatePriceModel
            : null,
        clearMonthPrices: response is! NetworkSuccessResponse,
      ));
      // Narxlar kelgach eng arzon kun ma'lum bo'ladi — o'sha sanaga aniq
      // reyslar qidiriladi (webdagi "Eng yaxshi takliflar" bo'limi).
      _loadBestOffers();
    } catch (_) {
      if (!isClosed && key == _routeKey) {
        emit(state.copyWith(monthLoading: false, offersLoading: false));
      }
    }
  }

  /// "Eng yaxshi takliflar" — eng arzon kunga qidiruv.
  /// Parallel so'rovlar, natijalar birlashtiriladi, eng arzon [_maxOffers]
  /// reys saqlanadi.
  static const int _maxOffers = 6;

  Future<void> _loadBestOffers() async {
    final date = _cheapestDate();
    if (date == null) {
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
    emit(state.copyWith(offersLoading: true, offers: const []));
    try {
      final body = RecommendationRequestBody(
        adt: 1,
        chd: 0,
        inf: 0,
        segments: [
          RecommendationReqBodySegment(
            from: state.from,
            to: state.to,
            date: "${date.day}.${date.month}.${date.year}",
          ),
        ],
        flight_Type: 0,
        klass: 'a',
      );
      final params = body.toJson();
      final List<String> endpoints =
          RemoteConfigService.instance.recommendationEndpoints;
      final List<NetworkResponse> responses = await Future.wait(
        endpoints.map(
          (ep) => _avia.getRecommendations(params: params, endPoint: ep),
        ),
      );
      if (isClosed || key != _routeKey) return;

      final List<FlightElement> flights = [];
      final Set<Object?> seenIds = {};
      for (final response in responses) {
        if (response is! NetworkSuccessResponse) continue;
        final model = response.data as GetRecommendationResModel;
        for (final f
            in model.recommedations?.flights ?? const <FlightElement>[]) {
          if (seenIds.add(f.id)) flights.add(f);
        }
      }
      flights.sort((a, b) => _price(a).compareTo(_price(b)));
      final top = flights.length > _maxOffers
          ? flights.sublist(0, _maxOffers)
          : flights;

      emit(state.copyWith(
        offersLoading: false,
        offers: top,
        offersDate: date,
      ));
    } catch (_) {
      if (!isClosed && key == _routeKey) {
        emit(state.copyWith(offersLoading: false, offers: const []));
      }
    }
  }

  /// Oylik narxlardagi eng arzon kun (bugundan boshlab).
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

  static double _price(FlightElement e) =>
      double.tryParse(e.price?.uzs?.amount ?? '') ?? double.maxFinite;

  /// "Qayerga" shahri v1 bazasida bo'lsa yo'nalish ma'lumotini yuklaydi;
  /// bo'lmasa (yoki xato) blok ko'rsatilmaydi. Moslashtirish SHAHAR NOMI
  /// bo'yicha bajariladi (aeroport kodi emas — u ro'yxatdagi kod bilan
  /// farq qilishi mumkin).
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

  /// Joriy holatdan chipta qidiruvi so'rovini quradi (sana tanlangan deb
  /// hisoblanadi — chaqirishdan oldin [RouteSearchState.hasDate] tekshiriladi).
  RecommendationRequestBody buildRequest() {
    final date = state.date!;
    final endDate = state.endDate;
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
}
