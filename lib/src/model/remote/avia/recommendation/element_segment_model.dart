part of 'get_recom_res_model.dart';

class FlightSegment {
  Arr arr;
  Arr dep;
  int seats;
  String flightNumber;
  int direction;
  FlightDuration duration;
  int routeDuration;
  bool isBaggage;
  Baggage baggage;
  String comment;
  String commentHash;
  Cbaggage cbaggage;
  bool isRefund;
  bool isChange;
  bool refund;
  bool change;
  Class segmentClass;
  bool first;
  bool last;
  String fareCode;
  Supplier carrier;
  Aircraft aircraft;
  List<dynamic> stops;
  String miles;
  String changeMiles;
  bool isMiniRulesExists;
  bool isOnlineCheckinRequired;
  List<dynamic> brands;
  Provider provider;
  String type;
  RefundBlock? refundBlock;
  ExchangeBlock? exchangeBlock;

  FlightSegment(
      {required this.arr,
      required this.dep,
      required this.seats,
      required this.flightNumber,
      required this.direction,
      required this.duration,
      required this.routeDuration,
      required this.isBaggage,
      required this.baggage,
      required this.comment,
      required this.commentHash,
      required this.cbaggage,
      required this.isRefund,
      required this.isChange,
      required this.refund,
      required this.change,
      required this.segmentClass,
      required this.first,
      required this.last,
      required this.fareCode,
      required this.carrier,
      required this.aircraft,
      required this.stops,
      required this.miles,
      required this.changeMiles,
      required this.isMiniRulesExists,
      required this.isOnlineCheckinRequired,
      required this.brands,
      required this.provider,
      required this.type,
      this.refundBlock,
      this.exchangeBlock});

  factory FlightSegment.fromJson(Map<String, dynamic> json) => FlightSegment(
      arr: json["arr"] is Map<String, dynamic>
          ? Arr.fromJson(json["arr"])
          : Arr(
              date: "",
              time: "",
              datetime: "",
              ts: "",
              terminal: "",
              airport: Supplier(id: 0, code: "", title: ""),
              city: Supplier(id: 0, code: "", title: ""),
              region: Supplier(id: 0, code: "", title: ""),
              country: Supplier(id: 0, code: "", title: "")),
      dep: json["dep"] is Map<String, dynamic>
          ? Arr.fromJson(json["dep"])
          : Arr(
              date: "",
              time: "",
              datetime: "",
              ts: "",
              terminal: "",
              airport: Supplier(id: 0, code: "", title: ""),
              city: Supplier(id: 0, code: "", title: ""),
              region: Supplier(id: 0, code: "", title: ""),
              country: Supplier(id: 0, code: "", title: "")),
      seats: _getInt(json["seats"]),
      flightNumber: json["flight_number"] ?? "",
      direction: json["direction"] ?? "",
      duration: json["duration"] is Map<String, dynamic>
          ? FlightDuration.fromJson(json["duration"])
          : FlightDuration(
              flight: TransferClass(common: 0, hour: 0, minute: 0),
              transfer: TransferClass(common: 0, hour: 0, minute: 0)),
      routeDuration: json["route_duration"] ?? "",
      isBaggage: json["is_baggage"] ?? false,
      baggage: Baggage.fromJson(json["baggage"]),
      comment: json["comment"] ?? "",
      commentHash: json["comment_hash"] ?? "",
      cbaggage: Cbaggage.fromJson(json["cbaggage"]),
      isRefund: json["is_refund"] ?? false,
      isChange: json["is_change"] ?? false,
      refund: json["refund"] ?? false,
      change: json["change"] ?? false,
      segmentClass: json["class"] is Map<String, dynamic>
          ? Class.fromJson(json["class"])
          : Class(typeId: "", name: "", service: ""),
      first: json["first"] ?? false,
      last: json["last"] ?? false,
      fareCode: json["fare_code"] ?? "",
      carrier: json["carrier"] is Map<String, dynamic>
          ? Supplier.fromJson(json["carrier"])
          : Supplier(id: 0, code: "", title: ""),
      aircraft: json["aircraft"] is Map<String, dynamic>
          ? Aircraft.fromJson(json["aircraft"])
          : Aircraft(code: "", title: ""),
      stops: json["stops"] != null
          ? List<dynamic>.from(json["stops"].map((x) => x))
          : [],
      miles: json["miles"] ?? "",
      changeMiles: json["change_miles"] ?? "",
      isMiniRulesExists: json["is_mini_rules_exists"] ?? false,
      isOnlineCheckinRequired: json["is_online_checkin_required"] ?? false,
      brands: json["brands"] != null
          ? List<dynamic>.from(json["brands"].map((x) => x))
          : [],
      provider: Provider.fromJson(json["provider"]),
      type: json["type"] ?? "",
      refundBlock: RefundBlock.fromJson(json['refundBlock']),
      exchangeBlock: ExchangeBlock.fromJson(json['exchangeBlock']));

  Map<String, dynamic> toJson() => {
        "arr": arr.toJson(),
        "dep": dep.toJson(),
        "seats": seats,
        "flight_number": flightNumber,
        "direction": direction,
        "duration": duration.toJson(),
        "route_duration": routeDuration,
        "is_baggage": isBaggage,
        "baggage": baggage.toJson(),
        "comment": comment,
        "comment_hash": commentHash,
        "cbaggage": cbaggage.toJson(),
        "is_refund": isRefund,
        "is_change": isChange,
        "refund": refund,
        "change": change,
        "class": segmentClass.toJson(),
        "first": first,
        "last": last,
        "fare_code": fareCode,
        "carrier": carrier.toJson(),
        "aircraft": aircraft.toJson(),
        "stops": List<dynamic>.from(stops.map((x) => x)),
        "miles": miles,
        "change_miles": changeMiles,
        "is_mini_rules_exists": isMiniRulesExists,
        "is_online_checkin_required": isOnlineCheckinRequired,
        "brands": List<dynamic>.from(brands.map((x) => x)),
        "provider": provider.toJson(),
        "type": type,
      };

  String getAircraftDetails() {
    final title = aircraft.title.isNotEmpty ? "${aircraft.title}, " : "";
    final code = aircraft.code.isNotEmpty ? "${aircraft.code}-" : "";
    final number = flightNumber;
    return "$title  ${"race_number".tr(namedArgs: {"num": code})} $number";
  }
}

class ExchangeBlock {
  BeforeDeparture? beforeDeparture;

  ExchangeBlock({this.beforeDeparture});

  factory ExchangeBlock.fromJson(Map<String, dynamic> json) {
    return ExchangeBlock(
      beforeDeparture: json['beforeDeparture'] != null
          ? BeforeDeparture.fromJson(json['beforeDeparture'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (beforeDeparture != null) 'beforeDeparture': beforeDeparture!.toJson(),
    };
  }
}

class RefundBlock {
  BeforeDeparture? beforeDeparture;

  RefundBlock({this.beforeDeparture});

  factory RefundBlock.fromJson(Map<String, dynamic> json) {
    return RefundBlock(
      beforeDeparture: json['beforeDeparture'] != null
          ? BeforeDeparture.fromJson(json['beforeDeparture'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (beforeDeparture != null) 'beforeDeparture': beforeDeparture!.toJson(),
    };
  }
}

class BeforeDeparture {
  bool? isAvailable;
  bool? isFree;
  String? comment;

  BeforeDeparture({this.isAvailable, this.isFree, this.comment});

  factory BeforeDeparture.fromJson(Map<String, dynamic> json) {
    return BeforeDeparture(
      isAvailable: json['isAvailable'],
      isFree: json['isFree'],
      comment: json['comment'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isAvailable': isAvailable,
      'isFree': isFree,
      'comment': comment,
    };
  }
}

class Aircraft {
  String code;
  String title;

  Aircraft({
    required this.code,
    required this.title,
  });

  factory Aircraft.fromJson(Map<String, dynamic> json) => Aircraft(
        code: json["code"] ?? "",
        title: json["title"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "code": code,
        "title": title,
      };
}

class Arr {
  String? date;
  String? time;
  String? datetime;
  dynamic ts;
  String? terminal;
  Supplier? airport;
  Supplier? city;
  Supplier? region;
  Supplier? country;

  Arr({
    this.date,
    this.time,
    this.datetime,
    this.ts,
    this.terminal,
    this.airport,
    this.city,
    this.region,
    this.country,
  });

  factory Arr.fromJson(Map<String, dynamic> json) => Arr(
        date: json["date"] ?? "",
        time: json["time"] ?? "",
        datetime: json["datetime"] ?? "",
        ts: json["ts"] ?? "",
        terminal: json["terminal"] ?? "",
        airport: json["airport"] is Map<String, dynamic>
            ? Supplier.fromJson(json["airport"])
            : Supplier(id: 0, code: "", title: ""),
        city: json["city"] is Map<String, dynamic>
            ? Supplier.fromJson(json["city"])
            : Supplier(id: 0, code: "", title: ""),
        region: json["region"] is Map<String, dynamic>
            ? Supplier.fromJson(json["region"])
            : Supplier(id: 0, code: "", title: ""),
        country: json["country"] is Map<String, dynamic>
            ? Supplier.fromJson(json["country"])
            : Supplier(id: 0, code: "", title: ""),
      );

  Map<String, dynamic> toJson() => {
        "date": date,
        "time": time,
        "datetime": datetime,
        "ts": ts,
        "terminal": terminal,
        "airport": airport?.toJson(),
        "city": city?.toJson(),
        "region": region?.toJson(),
        "country": country?.toJson(),
      };
}

class Baggage {
  int piece;
  int weight;
  Dimensions? dimensions;
  String? weightUnit;

  Baggage(
      {required this.piece,
      required this.weight,
      this.weightUnit,
      this.dimensions});

  factory Baggage.fromJson(Map<String, dynamic> json) => Baggage(
      piece: json["piece"] ?? 0,
      weight: json["weight"] ?? 0,
      dimensions: json["dimensions"] != null
          ? Dimensions.fromJson(json["dimensions"])
          : Dimensions(),
      weightUnit: json["weight_unit"]);

  Map<String, dynamic> toJson() => {
        "piece": piece,
        "weight": weight,
      };
}

class Cbaggage {
  int piece;
  int weight;
  Dimensions? dimensions;
  String? weightUnit;

  Cbaggage({
    required this.piece,
    required this.weight,
    this.dimensions,
    this.weightUnit,
  });

  factory Cbaggage.fromJson(Map<String, dynamic> json) => Cbaggage(
        piece: json["piece"] ?? 0,
        weight: json["weight"] ?? 0,
        dimensions: json["dimensions"] is Map<String, dynamic>
            ? Dimensions.fromJson(json["dimensions"])
            : Dimensions(width: 0, length: 0, height: 0),
        weightUnit: json["weight_unit"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "piece": piece,
        "weight": weight,
        "dimensions": dimensions?.toJson(),
        "weight_unit": weightUnit,
      };
}

class Dimensions {
  int? width;
  int? length;
  int? height;

  Dimensions({
    this.width,
    this.length,
    this.height,
  });

  factory Dimensions.fromJson(Map<String, dynamic> json) => Dimensions(
        width: json["width"],
        length: json["length"],
        height: json["height"],
      );

  Map<String, dynamic> toJson() => {
        "width": width,
        "length": length,
        "height": height,
      };
}

class FlightDuration {
  TransferClass flight;
  TransferClass? transfer;

  FlightDuration({
    required this.flight,
    this.transfer,
  });

  factory FlightDuration.fromJson(Map<String, dynamic> json) => FlightDuration(
        flight: json["flight"] is Map<String, dynamic>
            ? TransferClass.fromJson(json["flight"])
            : TransferClass(common: 0, hour: 0, minute: 0),
        transfer: json["transfer"] is Map<String, dynamic>
            ? TransferClass.fromJson(json["transfer"])
            : TransferClass(common: 0, hour: 0, minute: 0),
      );

  Map<String, dynamic> toJson() => {
        "flight": flight.toJson(),
        "transfer": transfer?.toJson(),
      };
}

class TransferClass {
  int common;
  int hour;
  int minute;

  TransferClass({
    required this.common,
    required this.hour,
    required this.minute,
  });

  factory TransferClass.fromJson(Map<String, dynamic> json) => TransferClass(
        common: json["common"] ?? 0,
        hour: json["hour"] ?? 0,
        minute: json["minute"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "common": common,
        "hour": hour,
        "minute": minute,
      };
}

class Class {
  dynamic typeId;
  String name;
  String service;

  Class({
    required this.typeId,
    required this.name,
    required this.service,
  });

  factory Class.fromJson(Map<String, dynamic> json) => Class(
        typeId: json["type_id"] ?? "",
        name: json["name"] ?? "",
        service: json["service"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "type_id": typeId,
        "name": name,
        "service": service,
      };
}
