part of 'route_search_cubit.dart';

/// [RouteSearchCubit] holati — yo'nalish qidiruv oynasidagi butun forma va
/// yuklangan ma'lumot. Equatable orqali qiymat bo'yicha solishtiriladi, shu
/// sababli bir xil holat qayta emit qilinsa UI qayta chizilmaydi.
/// Murakkab marshrut ("slojniy marshrut") ning bitta yo'nalishi: qayerdan,
/// qayerga va jo'nash sanasi. Foydalanuvchi ularni bosqichma-bosqich
/// to'ldirgani uchun barcha maydonlar `null` bo'lishi mumkin.
class RouteLeg extends Equatable {
  final AirPortsModel? from;
  final AirPortsModel? to;
  final DateTime? date;

  const RouteLeg({this.from, this.to, this.date});

  /// Qidiruvga tayyor (uchala maydon ham to'ldirilgan).
  bool get isComplete => from != null && to != null && date != null;

  /// Qayerdan va qayerga bir xil shahar.
  bool get isSameCity =>
      from?.cityIataCode != null && from?.cityIataCode == to?.cityIataCode;

  RouteLeg copyWith({
    AirPortsModel? from,
    AirPortsModel? to,
    DateTime? date,
  }) {
    return RouteLeg(
      from: from ?? this.from,
      to: to ?? this.to,
      date: date ?? this.date,
    );
  }

  @override
  List<Object?> get props => [from, to, date];
}

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

  /// Narxlar jadvali va eng arzon kunni aniqlash uchun oylik narxlar
  /// (yuklanish holati bilan).
  final TicketDatePriceModel? monthPrices;
  final bool monthLoading;

  /// "Yo'nalish haqida" kartasi — "qayerga" shahri v1 bazasida bo'lsa.
  final DestinationDetailModel? destInfo;

  /// "Eng yaxshi takliflar" bloki — eng arzon kun uchun topilgan aniq
  /// reyslar (webdagi kabi: oylik kalendardan eng arzon sana olinadi va
  /// o'sha sanaga qidiruv yuboriladi).
  final List<FlightElement> offers;
  final bool offersLoading;

  /// Takliflar qaysi sana uchun yuklangani (kartalarda ko'rsatiladi).
  final DateTime? offersDate;

  /// Faol tab: `false` — oddiy (borish / borish-qaytish), `true` — murakkab
  /// marshrut (bir nechta yo'nalish ketma-ket).
  final bool multiMode;

  /// Murakkab marshrut yo'nalishlari. Tab birinchi marta ochilganda joriy
  /// forma qiymatlaridan to'ldiriladi.
  final List<RouteLeg> legs;

  /// Yo'nalishlar soni chegaralari.
  static const int minLegs = 2;
  static const int maxLegs = 5;

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
    this.offers = const [],
    this.offersLoading = true,
    this.offersDate,
    this.multiMode = false,
    this.legs = const [],
  });

  /// Jo'nash sanasi tanlanganmi (qidirish tugmasi shunda ko'rinadi).
  bool get hasDate => date != null;

  /// Qayerdan va qayerga bir xil shahar (qidirishga yo'l qo'yilmaydi).
  bool get isSameAirport => from.cityIataCode == to.cityIataCode;

  int get passengerCount => adt + chd + inf;

  /// Yana yo'nalish qo'shish mumkinmi (maksimum [maxLegs] ta).
  bool get canAddLeg => legs.length < maxLegs;

  /// Yo'nalishni o'chirish mumkinmi (kamida [minLegs] ta qolishi kerak).
  bool get canRemoveLeg => legs.length > minLegs;

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
    List<FlightElement>? offers,
    bool? offersLoading,
    DateTime? offersDate,
    bool clearOffersDate = false,
    bool? multiMode,
    List<RouteLeg>? legs,
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
      offers: offers ?? this.offers,
      offersLoading: offersLoading ?? this.offersLoading,
      offersDate: clearOffersDate ? null : (offersDate ?? this.offersDate),
      multiMode: multiMode ?? this.multiMode,
      legs: legs ?? this.legs,
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
        offers,
        offersLoading,
        offersDate,
        multiMode,
        legs,
      ];
}
