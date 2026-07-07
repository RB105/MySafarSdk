part of 'get_recom_res_model.dart';

class FlightElement {
  String id;
  bool? isTourOperator;
  String? tariff;
  String? tariffClass;
  String? fareFamilyType;
  bool? fareFamilyFlag;
  String? fareFamilyMarketingName;
  int? duration;
  int? segmentsCount;
  String? type;
  bool? isInnerFlight;
  bool? isBaggage;
  bool? isCharter;
  bool? isRefund;
  bool? isHideTariff;
  bool? isSubsidized;
  String? bookUrl;
  dynamic citizenships;
  bool? isVtrip;
  Provider? provider;
  String? officeId;
  FlightPrice? price;
  List<dynamic>? priceDetails;
  ExtraBaggage? extraBaggage;
  List<FlightSegment>? segments;
  List<List<int>>? segmentsDirection;
  List<Upgrade>? upgrades;
  List<dynamic>? pricerInfo;
  Map<String, Document>? documents;
  dynamic ticketingTimeLimit;
  bool? bookingWithPartialDataAllowed;
  dynamic specialTariffType;
  AgeThresholds? ageThresholds;
  bool? isHealthDeclarationChecked;

  FlightElement({
    required this.id,
    this.isTourOperator,
    this.tariff,
    this.tariffClass,
    this.fareFamilyType,
    this.fareFamilyFlag,
    this.fareFamilyMarketingName,
    this.duration,
    this.segmentsCount,
    this.type,
    this.isInnerFlight,
    this.isBaggage,
    this.isCharter,
    this.isRefund,
    this.isHideTariff,
    this.isSubsidized,
    this.bookUrl,
    this.citizenships,
    this.isVtrip,
    this.provider,
    this.officeId,
    this.price,
    this.priceDetails,
    this.extraBaggage,
    this.segments,
    this.segmentsDirection,
    this.upgrades,
    this.pricerInfo,
    this.documents,
    this.ticketingTimeLimit,
    this.bookingWithPartialDataAllowed,
    this.specialTariffType,
    this.ageThresholds,
    this.isHealthDeclarationChecked,
  });

  factory FlightElement.fromJson(Map<String, dynamic> json) => FlightElement(
        id: json["id"] ?? "",
        isTourOperator: json["is_tour_operator"] ?? false,
        tariff: json["tariff"] ?? "",
        tariffClass: json["tariff_class"] ?? "",
        fareFamilyType: json["fare_family_type"] ?? "",
        fareFamilyFlag: json["fare_family_flag"] ?? false,
        fareFamilyMarketingName: json["fare_family_marketing_name"],
        duration: json["duration"] ?? "",
        segmentsCount: json["segments_count"] ?? "",
        type: json["type"] ?? "",
        isInnerFlight: json["is_inner_flight"] ?? false,
        isBaggage: json["is_baggage"] ?? false,
        isCharter: json["is_charter"] ?? false,
        isRefund: json["is_refund"] ?? false,
        isHideTariff: json["is_hide_tariff"] ?? false,
        isSubsidized: json["is_subsidized"] ?? false,
        bookUrl: json["book_url"] ?? "",
        citizenships: json["citizenships"] ?? "",
        isVtrip: json["is_vtrip"] ?? false,
        provider: json["provider"] is Map<String, dynamic>
            ? Provider.fromJson(json["provider"])
            : Provider(
                gds: 0,
                name: "",
                supplier: Supplier(id: 0, code: "", title: "")),
        officeId: json["office_id"] ?? "",
        price: json["price"] is Map<String, dynamic>
            ? FlightPrice.fromJson(json["price"])
            : FlightPrice(
                usd: FluffyRub(amount: '0'),
                rub: FluffyRub(
                  amount: "0",
                ),
                uzs: json['UZS'] is Map<String, dynamic>
                    ? FluffyUzs.fromJson(json['UZS'])
                    : FluffyUzs(amount: "0")),
        priceDetails: json["price_details"] != null
            ? List<dynamic>.from(json["price_details"].map((x) => x))
            : [],
        extraBaggage: json['extra_baggage'] is Map<String, dynamic>
            ? ExtraBaggage.fromJson(json["extra_baggage"])
            : ExtraBaggage(
                list: [],
                limit: Limit(
                    holdWeight: 0,
                    handWeight: 0,
                    handHeight: 0,
                    handWidth: 0,
                    handLength: 0)),
        segments: json["segments"] != null
            ? List<FlightSegment>.from(
                json["segments"].map((x) => FlightSegment.fromJson(x)))
            : [],
        segmentsDirection: json["segments_direction"] != null
            ? (json["segments_direction"] as List)
                .map((innerList) => (innerList as List).cast<int>())
                .toList()
            : [],
        upgrades: json["upgrades"] != null
            ? List<Upgrade>.from(
                json["upgrades"].map((x) => Upgrade.fromJson(x)))
            : [],
        pricerInfo: json["pricer_info"] != null
            ? List<dynamic>.from(json["pricer_info"].map((x) => x))
            : [],
        documents: json["documents"] != null
            ? Map.from(json["documents"]).map(
                (k, v) => MapEntry<String, Document>(k, Document.fromJson(v)))
            : {},
        ticketingTimeLimit: json["ticketing_time_limit"] ?? "",
        bookingWithPartialDataAllowed:
            json["booking_with_partial_data_allowed"] ?? false,
        specialTariffType: json["special_tariff_type"] ?? "",
        ageThresholds: json["age_thresholds"] is Map<String, dynamic>
            ? AgeThresholds.fromJson(json["age_thresholds"])
            : AgeThresholds(
                infant: Adult(min: 0, max: 0),
                child: Adult(min: 0, max: 0),
                adult: Adult(min: 0, max: 0)),
        isHealthDeclarationChecked:
            json["is_health_declaration_checked"] ?? false,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "is_tour_operator": isTourOperator,
        "tariff": tariff,
        "tariff_class": tariffClass,
        "fare_family_type": fareFamilyType,
        "fare_family_flag": fareFamilyFlag,
        "fare_family_marketing_name": fareFamilyMarketingName,
        "duration": duration,
        "segments_count": segmentsCount,
        "type": type,
        "is_inner_flight": isInnerFlight,
        "is_baggage": isBaggage,
        "is_charter": isCharter,
        "is_refund": isRefund,
        "is_hide_tariff": isHideTariff,
        "is_subsidized": isSubsidized,
        "book_url": bookUrl,
        "citizenships": citizenships,
        "is_vtrip": isVtrip,
        "provider": provider?.toJson(),
        "office_id": officeId,
        "price_details": List<dynamic>.from(priceDetails?.map((x) => x) ?? []),
        "extra_baggage": extraBaggage?.toJson(),
        "segments": List<dynamic>.from(segments?.map((x) => x.toJson()) ?? []),
        "segments_direction": List<dynamic>.from(segmentsDirection
                ?.map((x) => List<dynamic>.from(x.map((x) => x))) ??
            []),
        "upgrades": List<dynamic>.from(upgrades?.map((x) => x.toJson()) ?? []),
        "pricer_info": List<dynamic>.from(pricerInfo?.map((x) => x) ?? []),
        "documents": (documents ?? {})
            .map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
        "ticketing_time_limit": ticketingTimeLimit,
        "booking_with_partial_data_allowed": bookingWithPartialDataAllowed,
        "special_tariff_type": specialTariffType,
        "age_thresholds": ageThresholds?.toJson(),
        "is_health_declaration_checked": isHealthDeclarationChecked,
      };

  bool hasAirportChange(List<FlightSegment> segments, int index) {
    if (index < 0 || index + 1 >= segments.length) return false;

    final currentArrCode = segments[index].arr.airport?.code;
    final nextDepCode = segments[index + 1].dep.airport?.code;

    return currentArrCode != nextDepCode;
  }

  String getAirportChangeText(List<FlightSegment> segments, int index) {
    if (index < 0 || index + 1 >= segments.length) return "";

    final currentArrCode = segments[index].arr.airport?.code;
    final nextDepCode = segments[index + 1].dep.airport?.code;

    if (currentArrCode != nextDepCode) {
      return "airport_change_text".tr(
        namedArgs: {
          'from': segments[index].arr.airport?.title ?? "",
          'to': segments[index + 1].dep.airport?.title ?? "",
        },
      );
    }

    return "";
  }

  /// index is Direction order in list of segment direction
  List<FlightSegment> getSegmentsByDirection(int index) {
    var result = <FlightSegment>[];
    for (final segment in segments ?? []) {
      if (segment.direction == index) {
        result.add(segment);
      }
    }
    return result;
  }

  List<List<FlightSegment>> getSegmentList() {
    List<List<FlightSegment>> list = [];
    for (int i = 0; i < segmentsDirection!.length; i++) {
      list.add(getSegmentsByDirection(i));
    }
    return list;
  }

  /// returns 'peresadka' count
  int getTransferCount(int index) {
    var result = <FlightSegment>[];
    for (final segment in segments ?? []) {
      if (segment.direction == index) {
        result.add(segment);
      }
    }
    if (result.length > 1) {
      return result.length - 1;
    }
    return 0;
  }

  /// sample: Tashkent - Parij
  String getSegmentTitleByTitle(int index) {
    var result = <FlightSegment>[];
    for (final segment in segments ?? []) {
      if (segment.direction == index) {
        result.add(segment);
      }
    }
    return "${result.first.dep.city?.title} - ${result.last.arr.city?.title}";
  }

  int getDirDuration(int segmentList) {
    int result = 0;
    final directionSegments = getSegmentsByDirection(segmentList);

    for (var i = 0; i < directionSegments.length; i++) {
      result += directionSegments[i].duration.flight.common;

      // Transfer (layover) vaqtini ham qo'shamiz. Ba'zi providerlar
      // `duration.transfer` ni bermaydi — bunda `ts` (epoch) farqidan
      // hisoblanadi. Aks holda umumiy vaqt peresadkasiz chiqib qoladi.
      if (i < directionSegments.length - 1) {
        result += getLayoverMinutes(directionSegments, i);
      }
    }
    return result;
  }

  /// 29 Noy. 14:50
  String getDirectionTime(int index) {
    var result = <FlightSegment>[];
    for (final segment in segments ?? []) {
      if (segment.direction == index) {
        result.add(segment);
      }
    }
    final date = _parseDate(result.first.dep.date ?? "");
    return "${date.dateWithMonth}. ${result.first.dep.time}";
  }

  DateTime _parseDate(String dateStr) {
    List<String> parts = [];
    if (dateStr.contains("-")) {
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

  bool isExchangeable() {
    for (final segment in segments ?? <FlightSegment>[]) {
      if (segment.isChange == false) {
        return false;
      }
    }
    return true;
  }

  // Cached seat count — `segments` is immutable after parse, so the minimum
  // seat value can be computed once and reused across rebuilds/list scrolls.
  int? _seatCountCache;

  int getSeatCount() {
    final cached = _seatCountCache;
    if (cached != null) return cached;

    final segs = segments;
    if (segs == null || segs.isEmpty) {
      _seatCountCache = 0;
      return 0;
    }

    final min = segs.reduce(
        (value, element) => value.seats < element.seats ? value : element);

    return _seatCountCache = min.seats;
  }

  bool withBaggage() {
    for (var segment in segments ?? []) {
      if (segment.isBaggage == false) {
        return false;
      }
    }
    return true;
  }

  String getBaggage() {
    String unit = "kg";

    if (isBaggage == false) {
      return "no_baggage".tr();
    }

    for (final segment in segments ?? <FlightSegment>[]) {
      if (segment.baggage.weight == 0) {
        return "with_baggage".tr();
      }
    }

    final minWeight = segments?.reduce(
      (value, element) =>
          value.baggage.weight < element.baggage.weight ? value : element,
    );

    final piece = segments?.reduce(
      (value, element) =>
          value.baggage.piece < element.baggage.piece ? value : element,
    );

    return "${piece?.baggage.piece}x${minWeight?.baggage.weight} $unit";
  }

  bool withCBaggage() {
    final segs = segments ?? <FlightSegment>[];
    if (segs.isEmpty) return false;
    // Qo'l yuki mavjudligi BO'LAK (piece) soni bilan aniqlanadi.
    // Og'irlik ba'zi tashuvchilarda ko'rsatilmaydi (o'lcham bo'yicha) —
    // shuning uchun weight==0/null qo'l yuki yo'q degani emas.
    for (var segment in segs) {
      if (segment.cbaggage.piece == 0) {
        return false;
      }
    }
    return true;
  }

  String getCBaggage() {
    final segs = segments ?? <FlightSegment>[];
    if (segs.isEmpty) return "no_luggage".tr();

    // Biror segmentda bo'lak bo'lmasa — qo'l yuki yo'q.
    if (segs.any((s) => s.cbaggage.piece == 0)) {
      return "no_luggage".tr();
    }

    final minPiece =
        segs.map((s) => s.cbaggage.piece).reduce((a, b) => a < b ? a : b);

    // Og'irligi ko'rsatilgan (musbat) segmentlardan eng kichigini olamiz.
    // Ba'zi reyslarda og'irlik berilmaydi (null/0) — bunda faqat bo'lak
    // soni ko'rsatiladi, "1x0kg" kabi chalg'ituvchi yozuv chiqmaydi.
    final positiveWeights =
        segs.map((s) => s.cbaggage.weight).where((w) => w > 0).toList();

    if (positiveWeights.isEmpty) {
      return "luggage_size".tr(namedArgs: {"count": "$minPiece"});
    }

    final minWeight = positiveWeights.reduce((a, b) => a < b ? a : b);
    return "${minPiece}x$minWeight kg";
  }

  /// segments[index] dan keyingi transfer (layover) vaqti, daqiqalarda.
  /// Avval API'ning `duration.transfer` qiymati ishlatiladi; u bo'lmasa
  /// (ba'zi providerlarda kelmaydi) `ts` (epoch) farqidan hisoblanadi.
  int getLayoverMinutes(List<FlightSegment> segs, int index) {
    if (index < 0 || index + 1 >= segs.length) return 0;

    final apiTransfer = segs[index].duration.transfer?.common ?? 0;
    if (apiTransfer > 0) return apiTransfer;

    final arrTs = _tsToInt(segs[index].arr.ts);
    final depTs = _tsToInt(segs[index + 1].dep.ts);
    if (arrTs <= 0 || depTs <= 0 || depTs <= arrTs) return 0;

    return ((depTs - arrTs) / 60).round();
  }

  int _tsToInt(dynamic ts) {
    if (ts is int) return ts;
    if (ts is num) return ts.toInt();
    if (ts is String) return int.tryParse(ts) ?? 0;
    return 0;
  }
}

class AgeThresholds {
  Adult infant;
  Adult child;
  Adult adult;

  AgeThresholds({
    required this.infant,
    required this.child,
    required this.adult,
  });

  factory AgeThresholds.fromJson(Map<String, dynamic> json) => AgeThresholds(
        infant: json["infant"] is Map<String, dynamic>
            ? Adult.fromJson(json["infant"])
            : Adult(min: 0, max: 0),
        child: json["child"] is Map<String, dynamic>
            ? Adult.fromJson(json["child"])
            : Adult(min: 0, max: 0),
        adult: json["adult"] is Map<String, dynamic>
            ? Adult.fromJson(json["adult"])
            : Adult(min: 0, max: 0),
      );

  Map<String, dynamic> toJson() => {
        "infant": infant.toJson(),
        "child": child.toJson(),
        "adult": adult.toJson(),
      };
}

class Adult {
  int min;
  int max;

  Adult({
    required this.min,
    required this.max,
  });

  factory Adult.fromJson(Map<String, dynamic> json) => Adult(
        min: _getInt(json["min"]),
        max: _getInt(json["max"]),
      );

  Map<String, dynamic> toJson() => {
        "min": min,
        "max": max,
      };
}

class Document {
  List<String> ru;
  List<String> other;

  Document({
    required this.ru,
    required this.other,
  });

  factory Document.fromJson(Map<String, dynamic> json) => Document(
        ru: json["ru"] != null
            ? List<String>.from(json["ru"].map((x) => x))
            : [],
        other: json["other"] != null
            ? List<String>.from(json["other"].map((x) => x))
            : [],
      );

  Map<String, dynamic> toJson() => {
        "ru": List<dynamic>.from(ru.map((x) => x)),
        "other": List<dynamic>.from(other.map((x) => x)),
      };
}

class ExtraBaggage {
  List<ListElement> list;
  Limit limit;

  ExtraBaggage({
    required this.list,
    required this.limit,
  });

  factory ExtraBaggage.fromJson(Map<String, dynamic> json) => ExtraBaggage(
        list: json["list"] != null
            ? List<ListElement>.from(
                json["list"].map((x) => ListElement.fromJson(x)))
            : [],
        limit: json["limit"] is Map<String, dynamic>
            ? Limit.fromJson(json["limit"])
            : Limit(
                holdWeight: 0,
                handWeight: 0,
                handHeight: 0,
                handWidth: 0,
                handLength: 0),
      );

  Map<String, dynamic> toJson() => {
        "list": List<dynamic>.from(list.map((x) => x.toJson())),
        "limit": limit.toJson(),
      };
}

class Limit {
  int holdWeight;
  int handWeight;
  int handHeight;
  int handWidth;
  int handLength;

  Limit({
    required this.holdWeight,
    required this.handWeight,
    required this.handHeight,
    required this.handWidth,
    required this.handLength,
  });

  factory Limit.fromJson(Map<String, dynamic> json) => Limit(
        handWeight: json["hand_weight"] ?? 0,
        holdWeight: json["hold_weight"] ?? 0,
        handHeight: json["hand_height"] ?? 0,
        handWidth: json["hand_width"] ?? 0,
        handLength: json["hand_length"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "hold_weight": holdWeight,
        "hand_weight": handWeight,
        "hand_height": handHeight,
        "hand_width": handWidth,
        "hand_length": handLength,
      };
}

class ListElement {
  int count;
  ListPrice price;

  ListElement({
    required this.count,
    required this.price,
  });

  factory ListElement.fromJson(Map<String, dynamic> json) => ListElement(
        count: _getInt(json["count"]),
        price: json["price"] is Map<String, dynamic>
            ? ListPrice.fromJson(json["price"])
            : ListPrice(rub: PurpleRub(amount: 0)),
      );

  Map<String, dynamic> toJson() => {
        "count": count,
        "price": price.toJson(),
      };
}

class ListPrice {
  PurpleRub rub;

  ListPrice({
    required this.rub,
  });

  factory ListPrice.fromJson(Map<String, dynamic> json) => ListPrice(
        rub: json["RUB"] is Map<String, dynamic>
            ? PurpleRub.fromJson(json["RUB"])
            : PurpleRub(amount: 0),
      );

  Map<String, dynamic> toJson() => {
        "RUB": rub.toJson(),
      };
}

class PurpleRub {
  dynamic amount;

  PurpleRub({
    required this.amount,
  });

  factory PurpleRub.fromJson(Map<String, dynamic> json) => PurpleRub(
        amount: json["amount"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "amount": amount,
      };
}

class Provider {
  int gds;
  String name;
  Supplier supplier;

  Provider({
    required this.gds,
    required this.name,
    required this.supplier,
  });

  factory Provider.fromJson(Map<String, dynamic> json) => Provider(
        gds: json["gds"] ?? 0,
        name: json["name"] ?? "",
        supplier: json["supplier"] is Map<String, dynamic>
            ? Supplier.fromJson(json["supplier"])
            : Supplier(id: 0, code: "", title: ""),
      );

  Map<String, dynamic> toJson() => {
        "gds": gds,
        "name": name,
        "supplier": supplier.toJson(),
      };
}

class Supplier {
  int id;
  String code;
  String title;
  String? shortTitle;

  Supplier({
    required this.id,
    required this.code,
    required this.title,
    this.shortTitle,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
        id: json["id"] ?? 0,
        code: json["code"] ?? "",
        title: json["title"] ?? "",
        shortTitle: json["short_title"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "code": code,
        "title": title,
        "short_title": shortTitle,
      };
}

class Upgrade {
  String? id;
  bool? isBaggage;
  bool? isRefund;
  int? weight;
  int? piece;
  IncreasePrice? increasePrice;
  IncreasePrice? fullPrice;

  Upgrade(
      {this.id,
      this.isBaggage,
      this.isRefund,
      this.weight,
      this.piece,
      this.increasePrice,
      this.fullPrice});

  factory Upgrade.fromJson(Map<String, dynamic> json) => Upgrade(
        id: json["id"] ?? "",
        isBaggage: json["is_baggage"] ?? false,
        isRefund: json["is_refund"] ?? false,
        increasePrice: json["increase_price"] is Map<String, dynamic>
            ? IncreasePrice.fromJson(json["increase_price"])
            : null,
        fullPrice: json["full_price"] is Map<String, dynamic>
            ? IncreasePrice.fromJson(json["full_price"])
            : null,
        weight: json['weight'] ?? 0,
        piece: json['piece'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "is_baggage": isBaggage,
        "is_refund": isRefund,
        "increase_price": increasePrice?.toJson(),
      };
}

class IncreasePrice {
  String? rub;
  String? uzs;
  String? usd;

  IncreasePrice({this.rub, this.uzs, this.usd});

  factory IncreasePrice.fromJson(Map<String, dynamic> json) =>
      IncreasePrice(rub: json["RUB"] ?? "", usd: json['USD'], uzs: json['UZS']);

  Map<String, dynamic> toJson() => {};
}
