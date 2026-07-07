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
    adt = json['adt'];
    chd = json['chd'];
    inf = json['inf'];
    ins = json['ins'];
    src = json['src'];
    yth = json['yth'];
    lang = json['lang'];
    token = json['token'];
    klass = json['class_'];
    segments = json['segments'] != null
        ? (json['segments'] as List)
            .map(
              (e) => RecommendationReqBodySegment.fromJson(e),
            )
            .toList()
        : [];

    isBaggage = json['is_baggage'] ?? false;
    isCharter = json['is_charter'] ?? false;
    priceOrder = json['price_order'] ?? 0;
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
    isDirectOnly = json['is_direct_only'] ?? 0;
    filterAirlines = json['filter_airlines'] != null
        ? (json['filter_airlines'] as List)
            .map(
              (e) => RequestBodyAirlineModel.fromJson('$e'),
            )
            .toList()
        : <RequestBodyAirlineModel>[];

    flight_Type = segments != null && segments!.length > 1 ? 1 : 0;
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['adt'] = adt;
    data['chd'] = chd ;
    data['inf'] = inf;
    data['ins'] = ins ?? 0;
    data['src'] = src ?? 0;
    data['yth'] = yth ?? 0;
    data['lang'] = lang ?? "en";
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
    final temp_arr = filterAirlines
        ?.where(
          (element) => element.isChosed ?? false,
        )
        .toList();

    // Filter out empty strings
    final airlinesList = temp_arr
            ?.map((e) => e.toJson())
            .where((e) => e.toString().isNotEmpty)
            .toList() ??
        <String>[];
    data['filter_airlines'] = airlinesList;
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
    late String date = "";
    if (flight_Type == 0) {
      final tmp = _parseDate(segments?[0].date ?? "");
      date = tmp.dateWithMonthLowerCase;
    } else if (flight_Type == 1) {
      final tmp1 = _parseDate(segments?[0].date ?? "");
      date = tmp1.dateWithMonthLowerCase;
      final tmp2 = _parseDate(segments?[1].date ?? "");
      date += " - ${tmp2.dateWithMonthLowerCase}";
    } else {
      final tmp1 = _parseDate(segments?[0].date ?? "");
      date = tmp1.dateWithMonthLowerCase;
      final tmp2 = _parseDate(segments?.last.date ?? "");
      date += " - ${tmp2.dateWithMonthLowerCase}";
    }

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

    return "$date, ${getPassCount()}., ${getKlassName()}";
  }

  void setFilterAirlinesFromItems(List<FilterAirLineItemsModel> items) {
    filterAirlines = items.map((item) {
      return RequestBodyAirlineModel(
        code: item.code,
        name: item.title,
        isChosed: true, // or false, depending on logic
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
    filterAirlines
        ?.map(
          (e) => e.isChosed = true,
        )
        .toList();
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

  DateTime _parseDate(String dateStr) {
    List<String> parts = [];
    if (dateStr.contains('-')) {
      parts = dateStr.split('-');
    } else {
      parts = dateStr.split('.');
    }
    if (parts.length != 3) {
      throw FormatException("Invalid date format. Expected dd.MM.yyyy");
    }

    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);

    return DateTime(year, month, day);
  }
}

/// this segment is schema used in [RecommendationRequestBody](/Users/rb105/Projects/avia_mobile/lib/model/local/get_recom_req_model.dart#L4)
class RecommendationReqBodySegment {
  AirPortsModel? to;
  AirPortsModel? from;
  String? date;

  RecommendationReqBodySegment({this.to, this.date, this.from});

  RecommendationReqBodySegment.fromJson(Map<String, dynamic> json) {
    to = AirPortsModel(cityIataCode: json['to'] ?? "");
    from = AirPortsModel(cityIataCode: json['from'] ?? "");
    date = json['date'] ?? "";
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

  DateTime? get getDateTime {
    if (date == null) {
      return null;
    }
    final parts = date!.split('.');

    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);

    return DateTime(year, month, day);
  }

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
