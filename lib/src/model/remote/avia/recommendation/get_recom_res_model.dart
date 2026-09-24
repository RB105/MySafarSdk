import 'package:mysafar_sdk/src/core/extension/date_time_ext.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

part 'element_price_model.dart';
part 'element_segment_model.dart';
part 'flight_element_model.dart';

class GetRecommendationResModel {
  OverAllData? recommedations;
  List<FilterAirLineItemsModel>? filterAirLineItems;

  GetRecommendationResModel({this.recommedations, this.filterAirLineItems});

  GetRecommendationResModel.fromJson(Map<String, dynamic> json) {
    //
    recommedations = OverAllData.fromJson(json['data']);
    filterAirLineItems = json['filter_airlines_items'] != null
        ? (json['filter_airlines_items'] as List)
            .map((e) => FilterAirLineItemsModel.fromJson(e))
            .toList()
        : [];
  }
}

class FilterAirLineItemsModel {
  int? id;
  String? code;
  String? title;

  FilterAirLineItemsModel({this.id, this.code, this.title});

  FilterAirLineItemsModel.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? 0;
    code = json['code'] ?? "";
    title = json['title'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['code'] = code;
    data['title'] = title;
    return data;
  }
}

class OverAllData {
  Search search;
  List<FlightElement> flights;
  List<SegmentsComments> segmentsComments;
  String healthDeclarationText;
  List<dynamic> predefinedAirlines;
  List<dynamic> excludedAirlines;

  OverAllData({
    required this.search,
    required this.flights,
    required this.segmentsComments,
    required this.healthDeclarationText,
    required this.predefinedAirlines,
    required this.excludedAirlines,
  });

  factory OverAllData.fromJson(Map<String, dynamic> json) {
    List<SegmentsComments> comments = [];
    if (json["segments_comments"] is Map<String, dynamic>) {
      (json["segments_comments"] as Map).forEach(
        (key, value) =>
            comments.add(SegmentsComments(key: key, comment: value)),
      );
    }
    return OverAllData(
      search: Search.fromJson(_asMap(json["search"]) ?? const {}),
      flights: parseFlightsSafely(json["flights"]),
      segmentsComments: comments,
      healthDeclarationText: json["health_declaration_text"] ?? "",
      // Ilgari `segments_comments` tekshirilib `predefined_airlines` o'qilardi
      // — u null bo'lsa butun javob qulardi.
      predefinedAirlines: _asList(json["predefined_airlines"]),
      excludedAirlines: _asList(json["excluded_airlines"]),
    );
  }

  /// Reyslarni BITTALAB o'qiydi: bitta reysda buzuq maydon bo'lsa faqat
  /// o'sha reys tashlab yuboriladi (debug log bilan). Ilgari bitta xato butun
  /// manba javobini `error_other` ga aylantirib, hamma reyslar yo'qolardi.
  static List<FlightElement> parseFlightsSafely(dynamic raw) {
    if (raw is! List) return <FlightElement>[];
    final result = <FlightElement>[];
    for (final item in raw) {
      final map = _asMap(item);
      if (map == null) continue;
      try {
        result.add(FlightElement.fromJson(map));
      } catch (e) {
        debugPrint('recommendation: buzuq reys o\'tkazib yuborildi '
            '(id=${map["id"]}): $e');
      }
    }
    return result;
  }
}

/// used in [OverAllData](/Users/rb105/Test/avia_mobile/lib/model/remote/avia/recommendation/get_recom_res_model.dart#L45)
class Search {
  List<dynamic> inclusionCarriers;
  List<dynamic> exclusionCarriers;
  int adt;
  String channel;
  int chd;
  String searchClass;
  int inf;
  String partner;
  List<SearchSegment> segments;
  int src;
  String token;
  String type;
  int yth;
  int ins;

  Search({
    required this.inclusionCarriers,
    required this.exclusionCarriers,
    required this.adt,
    required this.channel,
    required this.chd,
    required this.searchClass,
    required this.inf,
    required this.partner,
    required this.segments,
    required this.src,
    required this.token,
    required this.type,
    required this.yth,
    required this.ins,
  });

  factory Search.fromJson(Map<String, dynamic> json) => Search(
        // null kelsa ilgari `.map` NoSuchMethodError tashlardi.
        inclusionCarriers: _asList(json["inclusion_carriers"]),
        exclusionCarriers: _asList(json["exclusion_carriers"]),
        adt: _getInt(json["adt"]),
        channel: "${json["channel"] ?? ""}",
        chd: _getInt(json["chd"]),
        searchClass: "${json["class"] ?? ""}",
        inf: _getInt(json["inf"]),
        partner: "${json["partner"] ?? ""}",
        segments: json["segments"] is List
            ? [
                for (final x in json["segments"] as List)
                  if (_asMap(x) != null) SearchSegment.fromJson(_asMap(x)!)
              ]
            : [],
        src: _getInt(json["src"]),
        token: "${json["token"] ?? ""}",
        type: "${json["type"] ?? ""}",
        yth: _getInt(json["yth"]),
        ins: _getInt(json["ins"]),
      );

  Map<String, dynamic> toJson() => {
        "inclusion_carriers":
            List<dynamic>.from(inclusionCarriers.map((x) => x)),
        "exclusion_carriers":
            List<dynamic>.from(exclusionCarriers.map((x) => x)),
        "adt": adt,
        "channel": channel,
        "chd": chd,
        "class": searchClass,
        "inf": inf,
        "partner": partner,
        "segments": List<dynamic>.from(segments.map((x) => x.toJson())),
        "src": src,
        "token": token,
        "type": type,
        "yth": yth,
        "ins": ins,
      };
}

class SearchSegment {
  SegmentDirection from;
  SegmentDirection to;
  String date;

  SearchSegment({
    required this.from,
    required this.to,
    required this.date,
  });

  factory SearchSegment.fromJson(Map<String, dynamic> json) => SearchSegment(
        from: json["from"] is Map<String, dynamic>
            ? SegmentDirection.fromJson(json["from"])
            : SegmentDirection(
                name: "",
                iata: "",
                country: Country(name: "", iata: ""),
                region: ""),
        to: json["to"] is Map<String, dynamic>
            ? SegmentDirection.fromJson(json["to"])
            : SegmentDirection(
                name: "",
                iata: "",
                country: Country(name: "", iata: ""),
                region: ""),
        date: json["date"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "from": from.toJson(),
        "to": to.toJson(),
        "date": date,
      };
}

class SegmentDirection {
  String name;
  String iata;
  Country country;
  String region;

  SegmentDirection({
    required this.name,
    required this.iata,
    required this.country,
    required this.region,
  });

  factory SegmentDirection.fromJson(Map<String, dynamic> json) =>
      SegmentDirection(
        name: json["name"] ?? "",
        iata: json["iata"] ?? "",
        country: json["country"] is Map<String, dynamic>
            ? Country.fromJson(json["country"])
            : Country(name: "", iata: ""),
        region: json["region"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "iata": iata,
        "country": country.toJson(),
        "region": region,
      };
}

class Country {
  String name;
  String iata;

  Country({
    required this.name,
    required this.iata,
  });

  factory Country.fromJson(Map<String, dynamic> json) => Country(
        name: json["name"] ?? "",
        iata: json["iata"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "iata": iata,
      };
}

class SegmentsComments {
  String key;
  String comment;

  SegmentsComments({
    required this.key,
    required this.comment,
  });
}

double _getDouble(dynamic param) {
  try {
    return double.parse("$param");
  } catch (e) {
    return 0.0;
  }
}

int _getInt(dynamic param) => _intOrNull(param) ?? 0;

/// Bardoshli butun son: int, num (12.0), "12", "12.0" → 12; "" / null /
/// boshqa tur → null. Backend ba'zan int o'rniga "" yoki satr yuboradi —
/// ilgari `json["duration"] ?? ""` kabi yozuvlar TypeError tashlardi.
int? _intOrNull(dynamic param) {
  if (param is int) return param;
  if (param is num) return param.isFinite ? param.toInt() : null;
  if (param is String) {
    final t = param.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t) ?? double.tryParse(t)?.toInt();
  }
  return null;
}

/// `Map` (har qanday kalit turi bilan) → `Map<String, dynamic>`, aks holda null.
Map<String, dynamic>? _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return v.map((k, val) => MapEntry("$k", val));
  return null;
}

/// Ro'yxat bo'lsa nusxasi, aks holda (null / boshqa tur) — bo'sh ro'yxat.
List<dynamic> _asList(dynamic v) =>
    v is List ? List<dynamic>.from(v) : <dynamic>[];
