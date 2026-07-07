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
      search: Search.fromJson(json["search"]),
      flights: json["flights"] != null
          ? List<FlightElement>.from(
              json["flights"].map((x) => FlightElement.fromJson(x)))
          : [],
      segmentsComments: comments,
      healthDeclarationText: json["health_declaration_text"] ?? "",
      predefinedAirlines: json["segments_comments"] != null
          ? List<dynamic>.from(json["predefined_airlines"].map((x) => x))
          : [],
      excludedAirlines: json["excluded_airlines"] != null
          ? List<dynamic>.from(json["excluded_airlines"].map((x) => x))
          : [],
    );
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
        inclusionCarriers:
            List<dynamic>.from(json["inclusion_carriers"].map((x) => x) ?? []),
        exclusionCarriers:
            List<dynamic>.from(json["exclusion_carriers"].map((x) => x) ?? []),
        adt: _getInt(json["adt"]),
        channel: json["channel"] ?? "",
        chd: json["chd"] ?? 0,
        searchClass: json["class"] ?? "",
        inf: json["inf"] ?? 0,
        partner: json["partner"] ?? "",
        segments: json["segments"] != null
            ? List<SearchSegment>.from(
                json["segments"].map((x) => SearchSegment.fromJson(x)))
            : [],
        src: json["src"] ?? 0,
        token: json["token"] ?? "",
        type: json["type"] ?? "",
        yth: json["yth"] ?? 0,
        ins: json["ins"] ?? 0,
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

int _getInt(dynamic param) {
  try {
    return int.parse("$param");
  } catch (e) {
    return 0;
  }
}
