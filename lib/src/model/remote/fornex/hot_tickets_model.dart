import 'package:easy_localization/easy_localization.dart';
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart';

class HotTicket {
  final HotTicketRoute route;
  final HotTicketDetails ticket;

  HotTicket({
    required this.route,
    required this.ticket,
  });

  factory HotTicket.fromJson(Map<String, dynamic> json) {
    return HotTicket(
      route: HotTicketRoute.fromJson(json['route']),
      ticket: HotTicketDetails.fromJson(json['ticket']),
    );
  }
}

class HotTicketRoute {
  final String fromCity;
  final String fromDate;
  final String toCity;
  final String toDate;

  HotTicketRoute({
    required this.fromCity,
    required this.fromDate,
    required this.toCity,
    required this.toDate,
  });

  factory HotTicketRoute.fromJson(Map<String, dynamic> json) {
    return HotTicketRoute(
      fromCity: json['from_city'],
      fromDate: json['from_date'],
      toCity: json['to_city'],
      toDate: json['to_date'],
    );
  }
}

class HotTicketDetails {
  final String id;
  final HotTicketPrice price;
  final int duration;
  final HotTicketProvider provider;
  final int segmentsCount;
  final List<HotTicketSegment> segments;

  HotTicketDetails({
    required this.id,
    required this.price,
    required this.duration,
    required this.provider,
    required this.segmentsCount,
    required this.segments,
  });

  factory HotTicketDetails.fromJson(Map<String, dynamic> json) {
    return HotTicketDetails(
      id: json['id'],
      price: HotTicketPrice.fromJson(json['price']),
      duration: json['duration'],
      provider: HotTicketProvider.fromJson(json['provider']),
      segmentsCount: json['segments_count'],
      segments: (json['segments'] as List)
          .map((e) => HotTicketSegment.fromJson(e))
          .toList(),
    );
  }

  String getTransferInfo() {
    if (segments.length > 1) {
      return "race_number".tr(namedArgs: {"num": "$segmentsCount"});
    }
    return "only_direct".tr();
  }

  FlightElement getFlightElement() {
    return FlightElement(
      id: id,
      price: FlightPrice(
          rub: FluffyRub(amount: price.rub?.amount),
          uzs: FluffyUzs(amount: price.uzs.amount),
          usd: FluffyRub(amount: price.usd?.amount)),
    );
  }

  String getCityTitle() {
    return "${segments.first.dep?.city?.title} - ${segments.last.arr?.city?.title}";
  }
}

class HotTicketPrice {
  final CurrencyPrice uzs;
  final CurrencyPrice? rub;
  final CurrencyPrice? usd;

  HotTicketPrice({
    required this.uzs,
    this.rub,
    this.usd,
  });

  factory HotTicketPrice.fromJson(Map<String, dynamic> json) {
    return HotTicketPrice(
      uzs: CurrencyPrice.fromJson(json['UZS']),
      rub: json['RUB'] != null ? CurrencyPrice.fromJson(json['RUB']) : null,
      usd: json['USD'] != null ? CurrencyPrice.fromJson(json['USD']) : null,
    );
  }
}

class CurrencyPrice {
  final String amount;
  final int? filterIndex;

  CurrencyPrice({
    required this.amount,
    this.filterIndex,
  });

  factory CurrencyPrice.fromJson(Map<String, dynamic> json) {
    return CurrencyPrice(
      amount: json['amount'],
      filterIndex: json['filter_index'],
    );
  }
}

class HotTicketProvider {
  final int? gds;
  final String? name;
  final HotTicketSupplier supplier;

  HotTicketProvider({
    required this.gds,
    required this.name,
    required this.supplier,
  });

  factory HotTicketProvider.fromJson(Map<String, dynamic> json) {
    return HotTicketProvider(
      gds: json['gds'] ?? 0,
      name: json['name'],
      supplier: HotTicketSupplier.fromJson(json['supplier']),
    );
  }
}

class HotTicketSupplier {
  final int? id;
  final String? code;
  final String? title;

  HotTicketSupplier({
    required this.id,
    required this.code,
    required this.title,
  });

  factory HotTicketSupplier.fromJson(Map<String, dynamic> json) {
    return HotTicketSupplier(
      id: json['id'],
      code: json['code'],
      title: json['title'],
    );
  }
}

class HotTicketSegment {
  final SegmentTimeInfo? dep;
  final SegmentTimeInfo? arr;
  final int? seats;
  final String? flightNumber;
  final SegmentDuration? duration;
  final bool? isBaggage;
  final SegmentClass? segmentClass;
  final SegmentCarrier? carrier;
  final HotTicketProvider? provider;

  HotTicketSegment({
    required this.dep,
    required this.arr,
    required this.seats,
    required this.flightNumber,
    required this.duration,
    required this.isBaggage,
    required this.segmentClass,
    required this.carrier,
    required this.provider,
  });

  factory HotTicketSegment.fromJson(Map<String, dynamic> json) {
    return HotTicketSegment(
      dep: SegmentTimeInfo.fromJson(json['dep']),
      arr: SegmentTimeInfo.fromJson(json['arr']),
      seats: json['seats'],
      flightNumber: json['flight_number'],
      duration: SegmentDuration.fromJson(json['duration']['flight']),
      isBaggage: json['is_baggage'],
      segmentClass: SegmentClass.fromJson(json['class']),
      carrier: SegmentCarrier.fromJson(json['carrier']),
      provider: HotTicketProvider.fromJson(json['provider']),
    );
  }
}

class SegmentTimeInfo {
  final String? date;
  final String? time;
  final String? datetime;
  final int? ts;
  final String? terminal;
  final SegmentAirport? airport;
  final SegmentCity? city;
  final SegmentRegion? region;
  final SegmentCountry? country;

  SegmentTimeInfo({
    required this.date,
    required this.time,
    required this.datetime,
    required this.ts,
    required this.terminal,
    required this.airport,
    required this.city,
    this.region,
    required this.country,
  });

  String getFlightDay() {
    try {
      return date?.split('.')[0] ?? ""; // e.g. "15"
    } catch (_) {
      return '';
    }
  }

  factory SegmentTimeInfo.fromJson(Map<String, dynamic> json) {
    return SegmentTimeInfo(
      date: json['date'],
      time: json['time'],
      datetime: json['datetime'],
      ts: json['ts'],
      terminal: json['terminal'] ?? '',
      airport: SegmentAirport.fromJson(json['airport']),
      city: SegmentCity.fromJson(json['city']),
      region: json['region'] != null
          ? SegmentRegion.fromJson(json['region'])
          : null,
      country: SegmentCountry.fromJson(json['country']),
    );
  }
}

class SegmentAirport {
  final int? id;
  final String? title;
  final String? shortTitle;
  final String? code;

  SegmentAirport({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.code,
  });

  factory SegmentAirport.fromJson(Map<String, dynamic> json) {
    return SegmentAirport(
      id: json['id'],
      title: json['title'],
      shortTitle: json['short_title'],
      code: json['code'],
    );
  }
}

class SegmentCity {
  final int? id;
  final String? code;
  final String? title;

  SegmentCity({
    required this.id,
    required this.code,
    required this.title,
  });

  factory SegmentCity.fromJson(Map<String, dynamic> json) {
    return SegmentCity(
      id: json['id'],
      code: json['code'],
      title: json['title'],
    );
  }
}

class SegmentRegion {
  final int? id;
  final String? code;
  final String? title;

  SegmentRegion({
    this.id,
    this.code,
    this.title,
  });

  factory SegmentRegion.fromJson(Map<String, dynamic> json) {
    return SegmentRegion(
      id: json['id'],
      code: json['code'],
      title: json['title'],
    );
  }
}

class SegmentCountry {
  final int? id;
  final String? code;
  final String? title;

  SegmentCountry({
    required this.id,
    required this.code,
    required this.title,
  });

  factory SegmentCountry.fromJson(Map<String, dynamic> json) {
    return SegmentCountry(
      id: json['id'],
      code: json['code'],
      title: json['title'],
    );
  }
}

class SegmentDuration {
  final int? common;
  final int? hour;
  final int? minute;

  SegmentDuration({
    required this.common,
    required this.hour,
    required this.minute,
  });

  factory SegmentDuration.fromJson(Map<String, dynamic> json) {
    return SegmentDuration(
      common: json['common'],
      hour: json['hour'],
      minute: json['minute'],
    );
  }
}

class SegmentClass {
  final int? typeId;
  final String? name;
  final String? service;

  SegmentClass({
    required this.typeId,
    required this.name,
    required this.service,
  });

  factory SegmentClass.fromJson(Map<String, dynamic> json) {
    return SegmentClass(
      typeId: json['type_id'],
      name: json['name'],
      service: json['service'],
    );
  }
}

class SegmentCarrier {
  final int? id;
  final String? code;
  final String? title;

  SegmentCarrier({
    required this.id,
    required this.code,
    required this.title,
  });

  factory SegmentCarrier.fromJson(Map<String, dynamic> json) {
    return SegmentCarrier(
      id: json['id'],
      code: json['code'],
      title: json['title'],
    );
  }
}
