part of 'route_search_cubit.dart';

/// [RouteSearchCubit] holati — yo'nalish qidiruv oynasidagi butun forma va
/// yuklangan ma'lumot. Equatable orqali qiymat bo'yicha solishtiriladi, shu
/// sababli bir xil holat qayta emit qilinsa UI qayta chizilmaydi.
class RouteSearchState extends Equatable {
  /// Qayerdan / qayerga.
  final AirPortsModel from;
  final AirPortsModel to;

  /// Jo'nash sanasi va (borish-qaytish bo'lsa) qaytish sanasi.
  final DateTime? date;
  final DateTime? endDate;

  /// Yo'lovchilar va klass.
  final int adt;
  final int chd;
  final int inf;
  final String klass;

  /// Filtrlar.
  final bool direct;
  final bool baggage;

  /// "Eng arzon kunlar" bloki uchun oylik narxlar (yuklanish holati bilan).
  final TicketDatePriceModel? monthPrices;
  final bool monthLoading;

  /// "Yo'nalish haqida" kartasi — "qayerga" shahri v1 bazasida bo'lsa.
  final DestinationDetailModel? destInfo;

  const RouteSearchState({
    required this.from,
    required this.to,
    this.date,
    this.endDate,
    this.adt = 1,
    this.chd = 0,
    this.inf = 0,
    this.klass = 'e',
    this.direct = false,
    this.baggage = false,
    this.monthPrices,
    this.monthLoading = true,
    this.destInfo,
  });

  /// Jo'nash sanasi tanlanganmi (qidirish tugmasi shunda ko'rinadi).
  bool get hasDate => date != null;

  /// Qayerdan va qayerga bir xil shahar (qidirishga yo'l qo'yilmaydi).
  bool get isSameAirport => from.cityIataCode == to.cityIataCode;

  int get passengerCount => adt + chd + inf;

  /// [clear*] bayroqlari null'ga o'rnatish uchun — copyWith odatda null'ni
  /// "o'zgartirma"dan ajrata olmaydi.
  RouteSearchState copyWith({
    AirPortsModel? from,
    AirPortsModel? to,
    DateTime? date,
    bool clearDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    int? adt,
    int? chd,
    int? inf,
    String? klass,
    bool? direct,
    bool? baggage,
    TicketDatePriceModel? monthPrices,
    bool clearMonthPrices = false,
    bool? monthLoading,
    DestinationDetailModel? destInfo,
    bool clearDestInfo = false,
  }) {
    return RouteSearchState(
      from: from ?? this.from,
      to: to ?? this.to,
      date: clearDate ? null : (date ?? this.date),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      adt: adt ?? this.adt,
      chd: chd ?? this.chd,
      inf: inf ?? this.inf,
      klass: klass ?? this.klass,
      direct: direct ?? this.direct,
      baggage: baggage ?? this.baggage,
      monthPrices: clearMonthPrices ? null : (monthPrices ?? this.monthPrices),
      monthLoading: monthLoading ?? this.monthLoading,
      destInfo: clearDestInfo ? null : (destInfo ?? this.destInfo),
    );
  }

  @override
  List<Object?> get props => [
        from,
        to,
        date,
        endDate,
        adt,
        chd,
        inf,
        klass,
        direct,
        baggage,
        monthPrices,
        monthLoading,
        destInfo,
      ];
}
