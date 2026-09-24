import 'package:mysafar_sdk/src/core/extension/date_time_ext.dart';
import 'package:mysafar_sdk/src/model/remote/avia/airports_model.dart';
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart'
    show FilterAirLineItemsModel;
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

/// for get-recommendations api request body
class RecommendationRequestBody {
  /// adult
  late final int adt;

  /// children
  late final int chd;

  /// baby
  late final int inf;

  late final int? ins;
  late final int? src;
  late final int? yth;
  late final String? lang;
  late String? token;

  ///  e - эконом класс, b - бизнес класс, f - первый класс, w - комфорт, a - все классы
  late String? klass;
  late List<RecommendationReqBodySegment>? segments;
  late bool? isBaggage;
  late final bool? isCharter;

  // price
  int? priceOrder;
  int? arrOrder;
  int? depOrder;
  int? durationOrder;
  late final List<String>? gdsBlackList;
  late final List<String>? gdsWhiteList;
  late int? isDirectOnly;
  List<RequestBodyAirlineModel>? filterAirlines;

  /// defines whether single date or return or multi way
  ///
  /// 0 -> one way, 1 -> round trip, 2 -> multi
  late final int? flight_Type;
  RecommendationRequestBody({
    this.token,
    required this.adt,
    required this.chd,
    required this.inf,
    this.ins,
    this.src,
    this.yth,
    this.lang,
    this.klass,
    this.segments,
    this.isBaggage,
    this.isCharter,
    this.priceOrder,
    this.arrOrder,
    this.depOrder,
    this.durationOrder,
    this.gdsBlackList,
    this.gdsWhiteList,
    this.isDirectOnly,
    this.filterAirlines,
    this.flight_Type,
  });

  RecommendationRequestBody.fromJson(Map<String, dynamic> json) {
    // AI/ovozli qidiruv va tarix javoblari: son o'rniga satr yoki null kelishi
    // mumkin — ilgari `late final int` ga null/String TypeError tashlardi.
    adt = _intOr(json['adt'], 1);
    chd = _intOr(json['chd'], 0);
    inf = _intOr(json['inf'], 0);
    ins = _intOrNull(json['ins']);
    src = _intOrNull(json['src']);
    yth = _intOrNull(json['yth']);
    lang = json['lang']?.toString();
    token = json['token']?.toString();
    klass = json['class_']?.toString();
    segments = json['segments'] is List
        ? [
            for (final e in json['segments'] as List)
              if (e is Map)
                RecommendationReqBodySegment.fromJson(
                    Map<String, dynamic>.from(e))
          ]
        : [];

    isBaggage = _flag(json['is_baggage']);
    isCharter = _flag(json['is_charter']);
    priceOrder = _intOr(json['price_order'], 0);
    gdsBlackList = json['gds_black_list'] != null
        ? (json['gds_black_list'] as List)
            .map(
              (e) => '$e',
            )
            .toList()
        : [];
    gdsWhiteList = json['gds_white_list'] != null
        ? (json['gds_white_list'] as List)
            .map(
              (e) => '$e',
            )
            .toList()
        : [];
    isDirectOnly = _flag(json['is_direct_only']) ? 1 : 0;
    filterAirlines = json['filter_airlines'] != null
        ? (json['filter_airlines'] as List)
            .map(
              (e) => RequestBodyAirlineModel.fromJson('$e'),
            )
            .toList()
        : <RequestBodyAirlineModel>[];

    flight_Type = flightTypeOf(segments);
  }

  /// Segmentlardan qidiruv turi: 1 ta — bir tomonga (0); 2 ta va ikkinchisi
  /// birinchisining teskarisi — borib-kelish (1); qolgan hollar — murakkab
  /// yo'nalish (2). Ilgari 2+ segmentli AI qidiruv doim "borib-kelish" deb
  /// ko'rsatilardi (№78).
  static int flightTypeOf(List<RecommendationReqBodySegment>? segments) {
    final segs = segments ?? const <RecommendationReqBodySegment>[];
    if (segs.length <= 1) return 0;
    if (segs.length == 2) {
      String code(AirPortsModel? a) =>
          (a?.cityIataCode ?? '').trim().toUpperCase();
      final a = segs[0], b = segs[1];
      if (code(a.from).isNotEmpty &&
          code(a.from) == code(b.to) &&
          code(a.to) == code(b.from)) {
        return 1;
      }
    }
    return 2;
  }

  /// Barcha segmentlarda o'qiladigan sana bormi. AI/ovozli qidiruv sanasiz
  /// javob qaytarsa `false` — natijalar sahifasi ochilmasligi kerak.
  bool get hasValidDates {
    final segs = segments;
    if (segs == null || segs.isEmpty) return false;
    return segs.every((s) => parseSegmentDate(s.date) != null);
  }

  /// Segment sanasini o'qiydi: `dd.MM.yyyy`, `dd-MM-yyyy` yoki ISO
  /// `yyyy-MM-dd` (vaqt qismi bilan ham). Bo'sh/yaroqsiz — `null` (istisno
  /// tashlanmaydi). Ilgari "2026-09-30" DateTime(30, 9, 2026) bo'lardi.
  static DateTime? parseSegmentDate(String? raw) {
    var text = (raw ?? '').trim();
    if (text.isEmpty) return null;
    final tIndex = text.indexOf(RegExp(r'[T ]'));
    if (tIndex > 0) text = text.substring(0, tIndex);
    final parts = text.contains('-') ? text.split('-') : text.split('.');
    if (parts.length != 3) return null;
    final yearFirst = parts[0].trim().length == 4;
    final day = int.tryParse((yearFirst ? parts[2] : parts[0]).trim());
    final month = int.tryParse(parts[1].trim());
    final year = int.tryParse((yearFirst ? parts[0] : parts[2]).trim());
    if (day == null || month == null || year == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31 || year < 1900) {
      return null;
    }
    final date = DateTime(year, month, day);
    // 31.02 kabi "toshib o'tgan" sanalarni rad etamiz.
    if (date.month != month || date.day != day) return null;
    return date;
  }

  /// Sanani so'rov formatiga (`dd.MM.yyyy`) keltiradi; o'qib bo'lmasa — "".
  static String normalizeSegmentDate(String? raw) {
    final d = parseSegmentDate(raw);
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}.'
        '${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  static int? _intOrNull(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  static int _intOr(dynamic v, int fallback) => _intOrNull(v) ?? fallback;

  /// true / 1 / "1" / "true" → true; qolgani false.
  static bool _flag(dynamic v) =>
      v == true || v == 1 || v == '1' || v == 'true';
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['adt'] = adt;
    data['chd'] = chd ;
    data['inf'] = inf;
    data['ins'] = ins ?? 0;
    data['src'] = src ?? 0;
    data['yth'] = yth ?? 0;
    // Til berilmasa — SDK faol tili (uz/ru/en ga moslangan, №81). Ilgari
    // doim "en" ketib, natijalarda shahar nomlari inglizcha chiqardi.
    data['lang'] = lang ?? dataLang();
    if (token?.isNotEmpty ?? false) {
      data['token'] = token ?? "";
    }
    data['class_'] = klass ?? "a";
    if (segments != null) {
      data['segments'] = segments?.map((v) => v.toJson()).toList();
    }
    if (isBaggage ?? false) {
      data['is_baggage'] = true;
    }
    data['is_charter'] = isCharter ?? false;
    if (priceOrder != null && priceOrder != 0) {
      data['price_order'] = 1;
    }
    if (depOrder != null && depOrder != 0) {
      data['dep_order'] = 1;
    }
    if (arrOrder != null && arrOrder != 0) {
      data['arr_order'] = 1;
    }
    if (durationOrder != null && durationOrder != 0) {
      data['duration_order'] = 1;
    }
    data['gds_black_list'] = gdsBlackList ?? [];
    data['gds_white_list'] = gdsWhiteList ?? [];
    data['is_direct_only'] = isDirectOnly ?? 0;
    // Faqat foydalanuvchi filtrda AYNAN tanlagan aviakompaniyalar yuboriladi.
    // Tanlov bo'lmasa bo'sh ro'yxat — server barcha aviakompaniyalarni
    // qidiradi (oldingi natijadagi kompaniyalar bilan cheklanmaydi).
    data['filter_airlines'] = chosenAirlineCodes;
    data['count'] = 30;
    return data;
  }

  String get firstSegmentTitle =>
      segments?.first.from?.cityName ??
      segments?.first.from?.cityIataCode ??
      "";

  String get lastSegmentTitle {
    if (flight_Type == 2) {
      return segments?.last.to?.cityName ?? "";
    }
    return segments?[0].to?.cityName ?? segments?[0].to?.cityIataCode ?? "";
  }

  String get params {
    // Sana bo'sh yoki yaroqsiz bo'lsa — build ichida istisno tashlamaymiz
    // (ilgari FormatException natijalar sahifasini qulatardi, №78).
    final segs = segments ?? const <RecommendationReqBodySegment>[];
    final first = segs.isEmpty ? null : parseSegmentDate(segs.first.date);
    final DateTime? second = flight_Type == 0 || segs.length < 2
        ? null
        : parseSegmentDate(flight_Type == 1 ? segs[1].date : segs.last.date);
    String date = [
      if (first != null) first.dateWithMonthLowerCase,
      if (second != null) second.dateWithMonthLowerCase,
    ].join(" - ");

    String getPassCount() {
      final count = adt + chd + inf;
      return "passenger_params_count_title".tr(namedArgs: {"count": "$count"});
    }

    String getKlassName() {
      switch (klass) {
        case "a":
          return "klass_a".tr();
        case "b":
          return "klass_b".tr();
        case "e":
          return "klass_e".tr();
        default:
          return "klass_a".tr();
      }
    }

    final prefix = date.isEmpty ? "" : "$date, ";
    return "$prefix${getPassCount()}., ${getKlassName()}";
  }

  /// Foydalanuvchi filtrda aniq tanlagan aviakompaniya kodlari. Bo'sh
  /// bo'lsa — aviakompaniya filtri yo'q (barcha kompaniyalar so'raladi).
  List<String> get chosenAirlineCodes => [
        for (final a in filterAirlines ?? const <RequestBodyAirlineModel>[])
          if ((a.isChosed ?? false) && (a.code ?? '').isNotEmpty) a.code!,
      ];

  /// So'rov aviakompaniya bo'yicha cheklanganmi (foydalanuvchi tanlovi).
  bool get hasAirlineFilter => chosenAirlineCodes.isNotEmpty;

  /// Natijadagi aviakompaniyalardan filter ro'yxatini tuzadi (sheet'da
  /// ko'rsatish uchun). Foydalanuvchi oldin tanlaganlari saqlanadi, qolganlari
  /// TANLANMAGAN bo'ladi — aks holda keyingi qidiruvlar (sana lentasi, qayta
  /// qidirish) faqat oldingi natijadagi kompaniyalarni so'rab, sekin yoki
  /// xato bergan manbadagi reyslar qaytib kelmay qolardi.
  void setFilterAirlinesFromItems(List<FilterAirLineItemsModel> items) {
    final chosen = chosenAirlineCodes.toSet();
    filterAirlines = items.map((item) {
      return RequestBodyAirlineModel(
        code: item.code,
        name: item.title,
        isChosed: chosen.contains(item.code),
      );
    }).toList();
  }

  /// order doc
  ///
  ///  0 - Price
  ///  1 - Dep
  ///  2 - Arr
  ///  3 - Duration
  int getOrder() {
    if (priceOrder != null && priceOrder == 1) {
      return 0;
    }
    if (depOrder != null && depOrder == 1) {
      return 1;
    }
    if (arrOrder != null && arrOrder == 1) {
      return 2;
    }
    if (durationOrder != null && durationOrder == 1) {
      return 3;
    }

    return 0;
  }

  void setOrder(int order) {
    priceOrder = null;
    depOrder = null;
    arrOrder = null;
    durationOrder = null;
    switch (order) {
      case 0:
        priceOrder = 1;
        return;
      case 1:
        depOrder = 1;
        return;
      case 2:
        arrOrder = 1;
        return;
      case 3:
        durationOrder = 1;
        return;
    }
  }

  bool getBaggage() {
    if (isBaggage ?? false) {
      return true;
    }

    return false;
  }

  bool isDirect() {
    if (isDirectOnly == 1) {
      return true;
    }
    return false;
  }

  void setDefaultFilterParams() {
    priceOrder = 1;
    depOrder = null;
    arrOrder = null;
    durationOrder = null;
    isBaggage = null;
    // Standart holat — aviakompaniya filtri yo'q (hech biri tanlanmagan).
    for (final e in filterAirlines ?? const <RequestBodyAirlineModel>[]) {
      e.isChosed = false;
    }
    isDirectOnly = 0;
    klass = "a";
  }

  @override
  String toString() {
    return "Body(segments $segments price: $priceOrder, arr: $arrOrder, dep: $depOrder, dur: $durationOrder)";
  }

  RecommendationRequestBody copyWith({
    int? adt,
    int? chd,
    int? inf,
    int? ins,
    int? src,
    int? yth,
    String? lang,
    String? token,
    String? klass,
    List<RecommendationReqBodySegment>? segments,
    bool? isBaggage,
    bool? isCharter,
    int? priceOrder,
    int? arrOrder,
    int? depOrder,
    int? durationOrder,
    List<String>? gdsBlackList,
    List<String>? gdsWhiteList,
    int? isDirectOnly,
    List<RequestBodyAirlineModel>? filterAirlines,
    int? flight_Type,
  }) {
    return RecommendationRequestBody(
      adt: adt ?? this.adt,
      chd: chd ?? this.chd,
      inf: inf ?? this.inf,
      ins: ins ?? this.ins,
      src: src ?? this.src,
      yth: yth ?? this.yth,
      lang: lang ?? this.lang,
      token: token ?? this.token,
      klass: klass ?? this.klass,
      segments: segments ?? this.segments,
      isBaggage: isBaggage ?? this.isBaggage,
      isCharter: isCharter ?? this.isCharter,
      priceOrder: priceOrder ?? this.priceOrder,
      arrOrder: arrOrder ?? this.arrOrder,
      depOrder: depOrder ?? this.depOrder,
      durationOrder: durationOrder ?? this.durationOrder,
      gdsBlackList: gdsBlackList ?? this.gdsBlackList,
      gdsWhiteList: gdsWhiteList ?? this.gdsWhiteList,
      isDirectOnly: isDirectOnly ?? this.isDirectOnly,
      filterAirlines: filterAirlines ?? this.filterAirlines,
      flight_Type: flight_Type ?? this.flight_Type,
    );
  }

}

/// this segment is schema used in [RecommendationRequestBody](/Users/rb105/Projects/avia_mobile/lib/model/local/get_recom_req_model.dart#L4)
class RecommendationReqBodySegment {
  AirPortsModel? to;
  AirPortsModel? from;
  String? date;

  RecommendationReqBodySegment({this.to, this.date, this.from});

  RecommendationReqBodySegment.fromJson(Map<String, dynamic> json) {
    to = AirPortsModel(cityIataCode: "${json['to'] ?? ""}");
    from = AirPortsModel(cityIataCode: "${json['from'] ?? ""}");
    // ISO (yyyy-MM-dd) sana ham `dd.MM.yyyy` ga keltiriladi; yaroqsiz — "".
    date = RecommendationRequestBody.normalizeSegmentDate(json['date']?.toString());
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['to'] = to?.cityIataCode;
    data['date'] = date;
    data['from'] = from?.cityIataCode;
    return data;
  }

  RecommendationReqBodySegment copyWith({
    AirPortsModel? to,
    AirPortsModel? from,
    String? date,
  }) {
    return RecommendationReqBodySegment(
      to: to ?? this.to,
      from: from ?? this.from,
      date: date ?? this.date,
    );
  }

  /// Yaroqsiz/bo'sh sana — `null` (istisno yo'q).
  DateTime? get getDateTime =>
      RecommendationRequestBody.parseSegmentDate(date);

  @override
  String toString() {
    return "Segment: from: ${from?.cityIataCode}, to: ${to?.cityIataCode}  , date: $date \n";
  }
}

class RequestBodyAirlineModel {
  bool? isChosed;
  String? name;
  String? code;
  RequestBodyAirlineModel({this.isChosed, this.name, this.code});

  RequestBodyAirlineModel.fromJson(String? e) {
    code = e ?? "";
  }

  String toJson() {
    if (isChosed ?? false) {
      return code ?? "";
    }
    return "";
  }
}
