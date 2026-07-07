class ConfirmedTicketsModel {
  int? id;
  List<Transactions>? transactions;
  String? createdAt;
  String? updatedAt;
  bool? isDeleted;
  String? deletedAt;
  String? billingId;
  int? expireRemain;
  int? user;
  String? callbackStatus;
  ConfirmTicketResponse? response;
  Transaction?transaction;

  ConfirmedTicketsModel(
      {this.id,
      this.transactions,
      this.createdAt,
      this.updatedAt,
      this.isDeleted,
      this.deletedAt,
      this.billingId,
      this.expireRemain,
      this.user,
      this.callbackStatus,
      this.transaction,
      this.response});

  ConfirmedTicketsModel.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? 0;

    transactions = json['transactions'] != null
        ? (json['transactions'] as List)
            .map(
              (e) => Transactions.fromJson(e),
            )
            .toList()
        : <Transactions>[];

    createdAt = json['created_at'] ?? "";
    updatedAt = json['updated_at'] ?? "";
    isDeleted = json['is_deleted'] ?? false;
    deletedAt = json['deleted_at'] ?? "";
    billingId = json['billing_id'] ?? "";
    transaction= json['transaction'] != null
        ? Transaction.fromJson(json['transaction'])
        : null;
    expireRemain = _getInt(json['expire_remain']);
    user = _getInt(json['user']);
    callbackStatus=json["callback_status"]??"";
    response = json['response'] != null
        ? ConfirmTicketResponse.fromJson(json['response'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    if (transactions != null) {
      data['transactions'] = transactions!.map((v) => v.toJson()).toList();
    }
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['is_deleted'] = isDeleted;
    data['deleted_at'] = deletedAt;
    data['billing_id'] = billingId;
    data['expire_remain'] = expireRemain;
    data['user'] = user;
    return data;
  }
}

class Transactions {
  int? id;
  String? createdAt;
  String? updatedAt;
  bool? isDeleted;
  String? deletedAt;
  int? amount;
  int? currency;
  String? trId;
  int? type;
  bool? status;
  int? statusType;
  int? user;
  int? ticket;

  Transactions(
      {this.id,
      this.createdAt,
      this.updatedAt,
      this.isDeleted,
      this.deletedAt,
      this.amount,
      this.currency,
      this.trId,
      this.type,
      this.status,
      this.statusType,
      this.user,
      this.ticket});

  Transactions.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? 0;
    createdAt = json['created_at'] ?? "";
    updatedAt = json['updated_at'] ?? "";
    isDeleted = json['is_deleted'] ?? false;
    deletedAt = json['deleted_at'] ?? "";
    amount = _getInt(json['amount']);
    currency = _getInt(json['currency']);
    trId = json['tr_id'] ?? "";
    type = _getInt(json['type']);
    status = json['status'] ?? false;
    statusType = _getInt(json['status_type']);
    user = _getInt(json['user']);
    ticket = _getInt(json['ticket']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['is_deleted'] = isDeleted;
    data['deleted_at'] = deletedAt;
    data['amount'] = amount;
    data['currency'] = currency;
    data['tr_id'] = trId;
    data['type'] = type;
    data['status'] = status;
    data['status_type'] = statusType;
    data['user'] = user;
    data['ticket'] = ticket;
    return data;
  }
}

class ConfirmTicketResponse {
  final String? pid;
  final int? code;
  final ConfirmTicketResponseData? data;
  final ConfirmTicketResponseTime? time;
  final bool? success;

  ConfirmTicketResponse({
    this.pid,
    this.code,
    this.data,
    this.time,
    this.success,
  });

  factory ConfirmTicketResponse.fromJson(Map<String, dynamic> json) =>
      ConfirmTicketResponse(
        pid: json["pid"],
        code: _getInt(json["code"]),
        data: json["data"] == null
            ? null
            : ConfirmTicketResponseData.fromJson(json["data"]),
        time: json["time"] == null
            ? null
            : ConfirmTicketResponseTime.fromJson(json["time"]),
        success: json["success"],
      );

  Map<String, dynamic> toJson() => {
        "pid": pid,
        "code": code,
        "data": data?.toJson(),
        "time": time?.toJson(),
        "success": success,
      };
}

class ConfirmTicketResponseData {
  final Book? book;

  ConfirmTicketResponseData({
    this.book,
  });

  factory ConfirmTicketResponseData.fromJson(Map<String, dynamic> json) =>
      ConfirmTicketResponseData(
        book: json["book"] == null ? null : Book.fromJson(json["book"]),
      );

  Map<String, dynamic> toJson() => {
        "book": book?.toJson(),
      };
}

class Book {
  final Order? order;
  final BookFlight? flight;
  final List<ConfirmedTicket>? tickets;
  final bool? isVtrip;
  final Map<String, DocumentValue>? documents;
  final List<dynamic>? insurances;
  final List<Passenger>? passengers;
  final String? payedData;
  final bool? isPriceChanged;
  final BookAgentModePrices? agentModePrices;
  final bool? isPaymentDisabled;
  final OrderPriceDetails? orderPriceDetails;
  final RefundAvailability? refundAvailability;
  final bool? isEticketAvailable;
  final String? disablingReasonTicket;
  final bool? isSearchPriceChanged;
  final List<PassengersPriceDetail>? passengersPriceDetails;
  final String? paymentDisablingReason;
  final bool? refundRequestAlreadySent;

  Book({
    this.order,
    this.flight,
    this.tickets,
    this.isVtrip,
    this.documents,
    this.insurances,
    this.passengers,
    this.payedData,
    this.isPriceChanged,
    this.agentModePrices,
    this.isPaymentDisabled,
    this.orderPriceDetails,
    this.refundAvailability,
    this.isEticketAvailable,
    this.disablingReasonTicket,
    this.isSearchPriceChanged,
    this.passengersPriceDetails,
    this.paymentDisablingReason,
    this.refundRequestAlreadySent,
  });

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        order: json["order"] == null ? null : Order.fromJson(json["order"]),
        flight:
            json["flight"] == null ? null : BookFlight.fromJson(json["flight"]),
        tickets: json["tickets"] == null
            ? []
            : List<ConfirmedTicket>.from(
                json["tickets"]!.map((x) => ConfirmedTicket.fromJson(x))),
        isVtrip: json["is_vtrip"],
      documents: json["documents"] == null
          ? null
          : Map<String, DocumentValue>.from(
        json["documents"].map(
              (k, v) => MapEntry(k, DocumentValue.fromJson(v)),
        ),
      ),
        insurances: json["insurances"] == null
            ? []
            : List<dynamic>.from(json["insurances"]!.map((x) => x)),
        passengers: json["passengers"] == null
            ? []
            : List<Passenger>.from(
                json["passengers"]!.map((x) => Passenger.fromJson(x))),
        payedData: json["payed_data"],
        isPriceChanged: json["is_price_changed"],
        agentModePrices: json["agent_mode_prices"] == null
            ? null
            : BookAgentModePrices.fromJson(json["agent_mode_prices"]),
        isPaymentDisabled: json["is_payment_disabled"],
        orderPriceDetails: json["order_price_details"] == null
            ? null
            : OrderPriceDetails.fromJson(json["order_price_details"]),
        refundAvailability: json["refund_availability"] == null
            ? null
            : RefundAvailability.fromJson(json["refund_availability"]),
        isEticketAvailable: json["is_eticket_available"],
        disablingReasonTicket: json["disabling_reason_ticket"],
        isSearchPriceChanged: json["is_search_price_changed"],
        passengersPriceDetails: json["passengers_price_details"] == null
            ? []
            : List<PassengersPriceDetail>.from(json["passengers_price_details"]!
                .map((x) => PassengersPriceDetail.fromJson(x))),
        paymentDisablingReason: json["payment_disabling_reason"],
        refundRequestAlreadySent: json["refund_request_already_sent"],
      );

  Map<String, dynamic> toJson() => {
        "order": order?.toJson(),
        "flight": flight?.toJson(),
        "tickets": tickets == null
            ? []
            : List<dynamic>.from(tickets!.map((x) => x.toJson())),
        "is_vtrip": isVtrip,
        "documents": Map.from(documents!)
            .map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
        "insurances": insurances == null
            ? []
            : List<dynamic>.from(insurances!.map((x) => x)),
        "passengers": passengers == null
            ? []
            : List<dynamic>.from(passengers!.map((x) => x.toJson())),
        "payed_data": payedData,
        "is_price_changed": isPriceChanged,
        "agent_mode_prices": agentModePrices?.toJson(),
        "is_payment_disabled": isPaymentDisabled,
        "order_price_details": orderPriceDetails?.toJson(),
        "refund_availability": refundAvailability?.toJson(),
        "is_eticket_available": isEticketAvailable,
        "disabling_reason_ticket": disablingReasonTicket,
        "is_search_price_changed": isSearchPriceChanged,
        "passengers_price_details": passengersPriceDetails == null
            ? []
            : List<dynamic>.from(
                passengersPriceDetails!.map((x) => x.toJson())),
        "payment_disabling_reason": paymentDisablingReason,
        "refund_request_already_sent": refundRequestAlreadySent,
      };
}

class BookAgentModePrices {
  final int? debitFromBalance;
  final List<ConfirmedTicketPassengersAmountsDetail>? passengersAmountsDetails;
  final int? totalAmountForActiveAgentMode;

  BookAgentModePrices({
    this.debitFromBalance,
    this.passengersAmountsDetails,
    this.totalAmountForActiveAgentMode,
  });

  factory BookAgentModePrices.fromJson(Map<String, dynamic> json) =>
      BookAgentModePrices(
        debitFromBalance: _getInt(json["debit_from_balance"]),
        passengersAmountsDetails: json["passengers_amounts_details"] == null
            ? []
            : List<ConfirmedTicketPassengersAmountsDetail>.from(
                json["passengers_amounts_details"]?.map(
                    (x) => ConfirmedTicketPassengersAmountsDetail.fromJson(x))),
        totalAmountForActiveAgentMode:
            _getInt(json["total_amount_for_active_agent_mode"]),
      );

  Map<String, dynamic> toJson() => {
        "debit_from_balance": debitFromBalance,
        "passengers_amounts_details": passengersAmountsDetails == null
            ? []
            : List<dynamic>.from(
                passengersAmountsDetails!.map((x) => x.toJson())),
        "total_amount_for_active_agent_mode": totalAmountForActiveAgentMode,
      };
}

class ConfirmedTicketPassengersAmountsDetail {
  final String? key;
  final int? serviceAmountForActiveAgentMode;
  final int? serviceAmountForNonActiveAgentMode;

  ConfirmedTicketPassengersAmountsDetail({
    this.key,
    this.serviceAmountForActiveAgentMode,
    this.serviceAmountForNonActiveAgentMode,
  });

  factory ConfirmedTicketPassengersAmountsDetail.fromJson(
          Map<String, dynamic> json) =>
      ConfirmedTicketPassengersAmountsDetail(
        key: json["key"],
        serviceAmountForActiveAgentMode:
            _getInt(json["service_amount_for_active_agent_mode"]),
        serviceAmountForNonActiveAgentMode:
            _getInt(json["service_amount_for_non_active_agent_mode"]),
      );

  Map<String, dynamic> toJson() => {
        "key": key,
        "service_amount_for_active_agent_mode": serviceAmountForActiveAgentMode,
        "service_amount_for_non_active_agent_mode":
            serviceAmountForNonActiveAgentMode,
      };
}

class DocumentValue {
  final List<String>? ru;
  final List<String>? other;

  DocumentValue({
    this.ru,
    this.other,
  });

  factory DocumentValue.fromJson(Map<String, dynamic> json) => DocumentValue(
        ru: json["ru"] == null
            ? []
            : List<String>.from(json["ru"]!.map((x) => x)),
        other: json["other"] == null
            ? []
            : List<String>.from(json["other"]!.map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "ru": ru == null ? [] : List<dynamic>.from(ru!.map((x) => x)),
        "other": other == null ? [] : List<dynamic>.from(other!.map((x) => x)),
      };
}

class BookFlight {
  final String? type;
  final int? duration;
  final bool? isVtrip;
  final FlightProvider? provider;
  final List<ConfirmedTicketSegment>? segments;
  final String? fareFamilyType;
  final bool? isTourOperator;

  BookFlight({
    this.type,
    this.duration,
    this.isVtrip,
    this.provider,
    this.segments,
    this.fareFamilyType,
    this.isTourOperator,
  });

  factory BookFlight.fromJson(Map<String, dynamic> json) => BookFlight(
        type: json["type"],
        duration: _getInt(json["duration"]),
        isVtrip: json["is_vtrip"],
        provider: json["provider"] == null
            ? null
            : FlightProvider.fromJson(json["provider"]),
        segments: json["segments"] == null
            ? []
            : List<ConfirmedTicketSegment>.from(json["segments"]!
                .map((x) => ConfirmedTicketSegment.fromJson(x))),
        fareFamilyType: json["fare_family_type"],
        isTourOperator: json["is_tour_operator"],
      );

  Map<String, dynamic> toJson() => {
        "type": type,
        "duration": duration,
        "is_vtrip": isVtrip,
        "provider": provider?.toJson(),
        "segments": segments == null
            ? []
            : List<dynamic>.from(segments!.map((x) => x.toJson())),
        "fare_family_type": fareFamilyType,
        "is_tour_operator": isTourOperator,
      };
}

class FlightProvider {
  final int? gds;
  final String? name;
  final ConfirmedTicketCarrier? supplier;

  FlightProvider({
    this.gds,
    this.name,
    this.supplier,
  });

  factory FlightProvider.fromJson(Map<String, dynamic> json) => FlightProvider(
        gds: _getInt(json["gds"]),
        name: json["name"],
        supplier: json["supplier"] == null
            ? null
            : ConfirmedTicketCarrier.fromJson(json["supplier"]),
      );

  Map<String, dynamic> toJson() => {
        "gds": gds,
        "name": name,
        "supplier": supplier?.toJson(),
      };
}

class ConfirmedTicketCarrier {
  final int? id;
  final String? code;
  final String? title;
  final String? providerCode;

  ConfirmedTicketCarrier({
    this.id,
    this.code,
    this.title,
    this.providerCode,
  });

  factory ConfirmedTicketCarrier.fromJson(Map<String, dynamic> json) =>
      ConfirmedTicketCarrier(
        id: _getInt(json["id"]),
        code: json["code"],
        title: json["title"],
        providerCode: json["provider_code"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "code": code,
        "title": title,
        "provider_code": providerCode,
      };
}

class ConfirmedTicketSegment {
  final ConfirmedTicketArr? arr;
  final ConfirmedTicketArr? dep;
  final String? type;
  final Class? segmentClass;
  final List<dynamic>? stops;
  final SegmentStatus? status;
  final CbaggageClass? baggage;
  final ConfirmedTicketCarrier? carrier;
  final String? comment;
  final String? aircraft;
  final CbaggageClass? cbaggage;
  final ConfirmedTicketDuration? duration;
  final FlightProvider? provider;
  final int? direction;
  final String? fareCode;
  final bool? isChange;
  final bool? isRefund;
  final String? flightNumber;
  final List<dynamic>? flightChanges;
  final bool? baggageRecheck;
  final String? refundedStatus;
  final int? ticketDuration;
  final AircraftDetails? aircraftDetails;
  final bool? isMiniRulesExists;
  final bool? isOnlineCheckinRequired;
  final List<ParametersForEachPassenger>? parametersForEachPassenger;

  ConfirmedTicketSegment({
    this.arr,
    this.dep,
    this.type,
    this.segmentClass,
    this.stops,
    this.status,
    this.baggage,
    this.carrier,
    this.comment,
    this.aircraft,
    this.cbaggage,
    this.duration,
    this.provider,
    this.direction,
    this.fareCode,
    this.isChange,
    this.isRefund,
    this.flightNumber,
    this.flightChanges,
    this.baggageRecheck,
    this.refundedStatus,
    this.ticketDuration,
    this.aircraftDetails,
    this.isMiniRulesExists,
    this.isOnlineCheckinRequired,
    this.parametersForEachPassenger,
  });

  factory ConfirmedTicketSegment.fromJson(Map<String, dynamic> json) =>
      ConfirmedTicketSegment(
        arr: json["arr"] == null
            ? null
            : ConfirmedTicketArr.fromJson(json["arr"]),
        dep: json["dep"] == null
            ? null
            : ConfirmedTicketArr.fromJson(json["dep"]),
        type: json["type"],
        segmentClass:
            json["class"] == null ? null : Class.fromJson(json["class"]),
        stops: json["stops"] == null
            ? []
            : List<dynamic>.from(json["stops"]!.map((x) => x)),
        status: json["status"] == null
            ? null
            : SegmentStatus.fromJson(json["status"]),
        baggage: json["baggage"] == null
            ? null
            : CbaggageClass.fromJson(json["baggage"]),
        carrier: json["carrier"] == null
            ? null
            : ConfirmedTicketCarrier.fromJson(json["carrier"]),
        comment: json["comment"],
        aircraft: json["aircraft"],
        cbaggage: json["cbaggage"] == null
            ? null
            : CbaggageClass.fromJson(json["cbaggage"]),
        duration: json["duration"] == null
            ? null
            : ConfirmedTicketDuration.fromJson(json["duration"]),
        provider: json["provider"] == null
            ? null
            : FlightProvider.fromJson(json["provider"]),
        direction: _getInt(json["direction"]),
        fareCode: json["fare_code"],
        isChange: json["is_change"],
        isRefund: json["is_refund"],
        flightNumber: json["flight_number"],
        flightChanges: json["flight_changes"] == null
            ? []
            : List<dynamic>.from(json["flight_changes"]!.map((x) => x)),
        baggageRecheck: json["baggage_recheck"],
        refundedStatus: json["refunded_status"],
        ticketDuration: _getInt(json["ticket_duration"]),
        aircraftDetails: json["aircraft_details"] == null
            ? null
            : AircraftDetails.fromJson(json["aircraft_details"]),
        isMiniRulesExists: json["is_mini_rules_exists"],
        isOnlineCheckinRequired: json["is_online_checkin_required"],
        parametersForEachPassenger:
            json["parameters_for_each_passenger"] == null
                ? []
                : List<ParametersForEachPassenger>.from(
                    json["parameters_for_each_passenger"]!
                        .map((x) => ParametersForEachPassenger.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "arr": arr?.toJson(),
        "dep": dep?.toJson(),
        "type": type,
        "class": segmentClass?.toJson(),
        "stops": stops == null ? [] : List<dynamic>.from(stops!.map((x) => x)),
        "status": status?.toJson(),
        "baggage": baggage?.toJson(),
        "carrier": carrier?.toJson(),
        "comment": comment,
        "aircraft": aircraft,
        "cbaggage": cbaggage?.toJson(),
        "duration": duration?.toJson(),
        "provider": provider?.toJson(),
        "direction": direction,
        "fare_code": fareCode,
        "is_change": isChange,
        "is_refund": isRefund,
        "flight_number": flightNumber,
        "flight_changes": flightChanges == null
            ? []
            : List<dynamic>.from(flightChanges!.map((x) => x)),
        "baggage_recheck": baggageRecheck,
        "refunded_status": refundedStatus,
        "ticket_duration": ticketDuration,
        "aircraft_details": aircraftDetails?.toJson(),
        "is_mini_rules_exists": isMiniRulesExists,
        "is_online_checkin_required": isOnlineCheckinRequired,
        "parameters_for_each_passenger": parametersForEachPassenger == null
            ? []
            : List<dynamic>.from(
                parametersForEachPassenger!.map((x) => x.toJson())),
      };
}

class AircraftDetails {
  final String? code;
  final String? title;

  AircraftDetails({
    this.code,
    this.title,
  });

  factory AircraftDetails.fromJson(Map<String, dynamic> json) =>
      AircraftDetails(
        code: json["code"],
        title: json["title"],
      );

  Map<String, dynamic> toJson() => {
        "code": code,
        "title": title,
      };
}

class ConfirmedTicketArr {
  final ConfirmedTicketCarrier? city;
  final String? date;
  final String? time;
  final ConfirmedTicketRegion? region;
  final ConfirmedTicketCarrier? airport;
  final ConfirmedTicketCarrier? country;
  final String? datetime;
  final String? terminal;

  ConfirmedTicketArr({
    this.city,
    this.date,
    this.time,
    this.region,
    this.airport,
    this.country,
    this.datetime,
    this.terminal,
  });

  factory ConfirmedTicketArr.fromJson(Map<String, dynamic> json) =>
      ConfirmedTicketArr(
        city: json["city"] == null
            ? null
            : ConfirmedTicketCarrier.fromJson(json["city"]),
        date: json["date"],
        time: json["time"],
        region: json["region"] == null
            ? null
            : ConfirmedTicketRegion.fromJson(json["region"]),
        airport: json["airport"] == null
            ? null
            : ConfirmedTicketCarrier.fromJson(json["airport"]),
        country: json["country"] == null
            ? null
            : ConfirmedTicketCarrier.fromJson(json["country"]),
        datetime: json["datetime"],
        terminal: json["terminal"],
      );

  Map<String, dynamic> toJson() => {
        "city": city?.toJson(),
        "date": date,
        "time": time,
        "region": region?.toJson(),
        "airport": airport?.toJson(),
        "country": country?.toJson(),
        "datetime": datetime,
        "terminal": terminal,
      };
}

class ConfirmedTicketRegion {
  final int? id;
  final String? code;
  final String? title;

  ConfirmedTicketRegion({
    this.id,
    this.code,
    this.title,
  });

  factory ConfirmedTicketRegion.fromJson(Map<String, dynamic> json) =>
      ConfirmedTicketRegion(
        id: json["id"],
        code: json["code"],
        title: json["title"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "code": code,
        "title": title,
      };
}

class CbaggageClass {
  final int? piece;
  final int? weight;

  CbaggageClass({
    this.piece,
    this.weight,
  });

  factory CbaggageClass.fromJson(Map<String, dynamic> json) => CbaggageClass(
        piece: _getInt(json["piece"]),
        weight: _getInt(json["weight"]),
      );

  Map<String, dynamic> toJson() => {
        "piece": piece,
        "weight": weight,
      };
}

class ConfirmedTicketDuration {
  final DurationFlight? flight;

  ConfirmedTicketDuration({
    this.flight,
  });

  factory ConfirmedTicketDuration.fromJson(Map<String, dynamic> json) =>
      ConfirmedTicketDuration(
        flight: json["flight"] == null
            ? null
            : DurationFlight.fromJson(json["flight"]),
      );

  Map<String, dynamic> toJson() => {
        "flight": flight?.toJson(),
      };
}

class DurationFlight {
  final int? hour;
  final int? common;
  final int? minute;

  DurationFlight({
    this.hour,
    this.common,
    this.minute,
  });

  factory DurationFlight.fromJson(Map<String, dynamic> json) => DurationFlight(
        hour: _getInt(json["hour"]),
        common: _getInt(json["common"]),
        minute: _getInt(json["minute"]),
      );

  Map<String, dynamic> toJson() => {
        "hour": hour,
        "common": common,
        "minute": minute,
      };
}

class ParametersForEachPassenger {
  final String? brand;
  final CarryOnBaggageClass? baggage;
  final ConfirmedTicketCarrier? flightClass;
  final String? passengerId;
  final bool? isRefundable;
  final String? ticketNumber;
  final String? flightComment;
  final bool? isExchangeable;
  final CarryOnBaggageClass? carryOnBaggage;

  ParametersForEachPassenger({
    this.brand,
    this.baggage,
    this.flightClass,
    this.passengerId,
    this.isRefundable,
    this.ticketNumber,
    this.flightComment,
    this.isExchangeable,
    this.carryOnBaggage,
  });

  factory ParametersForEachPassenger.fromJson(Map<String, dynamic> json) =>
      ParametersForEachPassenger(
        brand: json["brand"],
        baggage: json["baggage"] == null
            ? null
            : CarryOnBaggageClass.fromJson(json["baggage"]),
        flightClass: json["flight_class"] == null
            ? null
            : ConfirmedTicketCarrier.fromJson(json["flight_class"]),
        passengerId: json["passenger_id"],
        isRefundable: json["is_refundable"],
        ticketNumber: json["ticket_number"],
        flightComment: json["flight_comment"],
        isExchangeable: json["is_exchangeable"],
        carryOnBaggage: json["carry_on_baggage"] == null
            ? null
            : CarryOnBaggageClass.fromJson(json["carry_on_baggage"]),
      );

  Map<String, dynamic> toJson() => {
        "brand": brand,
        "baggage": baggage?.toJson(),
        "flight_class": flightClass?.toJson(),
        "passenger_id": passengerId,
        "is_refundable": isRefundable,
        "ticket_number": ticketNumber,
        "flight_comment": flightComment,
        "is_exchangeable": isExchangeable,
        "carry_on_baggage": carryOnBaggage?.toJson(),
      };
}

class CarryOnBaggageClass {
  final int? weight;
  final int? bagsCount;
  final ConfirmedTicketDimensions? dimensions;
  final String? weightUnit;

  CarryOnBaggageClass({
    this.weight,
    this.bagsCount,
    this.dimensions,
    this.weightUnit,
  });

  factory CarryOnBaggageClass.fromJson(Map<String, dynamic> json) =>
      CarryOnBaggageClass(
        weight: _getInt(json["weight"]),
        bagsCount: _getInt(json["bags_count"]),
        dimensions: json["dimensions"] != null
            ? ConfirmedTicketDimensions.fromJson(json["dimensions"])
            : null,
        weightUnit: json["weight_unit"],
      );

  Map<String, dynamic> toJson() => {
        "weight": weight,
        "bags_count": bagsCount,
        "dimensions": dimensions?.toJson(),
        "weight_unit": weightUnit,
      };
}

class ConfirmedTicketDimensions {
  int? width;
  int? height;
  int? length;

  ConfirmedTicketDimensions({this.width, this.height, this.length});

  ConfirmedTicketDimensions.fromJson(Map<String, dynamic> json) {
    width = _getInt(json['width']);
    height = _getInt(json['height']);
    length = _getInt(json['length']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['width'] = width;
    data['height'] = height;
    data['length'] = length;
    return data;
  }
}

class Class {
  final String? name;
  final String? title;
  final int? typeId;

  Class({
    this.name,
    this.title,
    this.typeId,
  });

  factory Class.fromJson(Map<String, dynamic> json) => Class(
        name: json["name"],
        title: json["title"],
        typeId: _getInt(json["type_id"]),
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "title": title,
        "type_id": typeId,
      };
}

class SegmentStatus {
  final String? code;
  final String? description;

  SegmentStatus({
    this.code,
    this.description,
  });

  factory SegmentStatus.fromJson(Map<String, dynamic> json) => SegmentStatus(
        code: json["code"],
        description: json["description"],
      );

  Map<String, dynamic> toJson() => {
        "code": code,
        "description": description,
      };
}

class Order {
  final String? sig;
  final Price? price;
  final String? expire;
  final OrderStatus? status;
  final Channel? channel;
  final String? created;
  final bool? isReal;
  final String? payment;
  final int? userId;
  final int? orderId;
  final List<Payment>? payments;
  final int? expireRemain;
  final int? billingNumber;
  final String? alfaPodeliPayment;

  Order({
    this.sig,
    this.price,
    this.expire,
    this.status,
    this.channel,
    this.created,
    this.isReal,
    this.payment,
    this.userId,
    this.orderId,
    this.payments,
    this.expireRemain,
    this.billingNumber,
    this.alfaPodeliPayment,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        sig: json["sig"],
        price: json["price"] == null ? null : Price.fromJson(json["price"]),
        expire: json["expire"],
        status: json["status"] == null
            ? null
            : OrderStatus.fromJson(json["status"]),
        channel:
            json["channel"] == null ? null : Channel.fromJson(json["channel"]),
        created: json["created"],
        isReal: json["is_real"],
        payment: json["payment"],
        userId: _getInt(json["user_id"]),
        orderId: _getInt(json["order_id"]),
        payments: json["payments"] == null
            ? []
            : List<Payment>.from(
                json["payments"]!.map((x) => Payment.fromJson(x))),
        expireRemain: _getInt(json["expire_remain"]),
        billingNumber: _getInt(json["billing_number"]),
        alfaPodeliPayment: json["alfa_podeli_payment"],
      );

  Map<String, dynamic> toJson() => {
        "sig": sig,
        "price": price?.toJson(),
        "expire": expire,
        "status": status?.toJson(),
        "channel": channel?.toJson(),
        "created": created,
        "is_real": isReal,
        "payment": payment,
        "user_id": userId,
        "order_id": orderId,
        "payments": payments == null
            ? []
            : List<dynamic>.from(payments!.map((x) => x.toJson())),
        "expire_remain": expireRemain,
        "billing_number": billingNumber,
        "alfa_podeli_payment": alfaPodeliPayment,
      };
}

class Channel {
  final String? code;
  final Source? source;

  Channel({
    this.code,
    this.source,
  });

  factory Channel.fromJson(Map<String, dynamic> json) => Channel(
        code: json["code"],
        source: json["source"] == null ? null : Source.fromJson(json["source"]),
      );

  Map<String, dynamic> toJson() => {
        "code": code,
        "source": source?.toJson(),
      };
}

class Source {
  final String? code;

  Source({
    this.code,
  });

  factory Source.fromJson(Map<String, dynamic> json) => Source(
        code: json["code"],
      );

  Map<String, dynamic> toJson() => {
        "code": code,
      };
}

class Payment {
  final int? orderAmount;
  final String? merchantName;
  final bool? isAffiliateFee;
  final PaymentAgentModePrices? agentModePrices;
  final int? agentAffiliateFee;
  final int? partnerAffiliateFee;

  Payment({
    this.orderAmount,
    this.merchantName,
    this.isAffiliateFee,
    this.agentModePrices,
    this.agentAffiliateFee,
    this.partnerAffiliateFee,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        orderAmount: _getInt(json["order_amount"]),
        merchantName: json["merchant_name"],
        isAffiliateFee: json["is_affiliate_fee"],
        agentModePrices: json["agent_mode_prices"] == null
            ? null
            : PaymentAgentModePrices.fromJson(json["agent_mode_prices"]),
        agentAffiliateFee: _getInt(json["agent_affiliate_fee"]),
        partnerAffiliateFee: _getInt(json["partner_affiliate_fee"]),
      );

  Map<String, dynamic> toJson() => {
        "order_amount": orderAmount,
        "merchant_name": merchantName,
        "is_affiliate_fee": isAffiliateFee,
        "agent_mode_prices": agentModePrices?.toJson(),
        "agent_affiliate_fee": agentAffiliateFee,
        "partner_affiliate_fee": partnerAffiliateFee,
      };
}

class PaymentAgentModePrices {
  final int? amountToPay;

  PaymentAgentModePrices({
    this.amountToPay,
  });

  factory PaymentAgentModePrices.fromJson(Map<String, dynamic> json) =>
      PaymentAgentModePrices(
        amountToPay: _getInt(json["amount_to_pay"]),
      );

  Map<String, dynamic> toJson() => {
        "amount_to_pay": amountToPay,
      };
}

class Price {
  final Uzs? uzs;

  Price({
    this.uzs,
  });

  factory Price.fromJson(Map<String, dynamic> json) => Price(
        uzs: json["UZS"] == null ? null : Uzs.fromJson(json["UZS"]),
      );

  Map<String, dynamic> toJson() => {
        "UZS": uzs?.toJson(),
      };
}

class Uzs {
  final int? fee;
  final int? fare;
  final int? taxes;
  final double? amount;
  final int? discount;
  final int? insurance;
  final int? amountBase;
  final int? extraBaggage;
  final int? amountWithoutPaymentExpense;

  Uzs({
    this.fee,
    this.fare,
    this.taxes,
    this.amount,
    this.discount,
    this.insurance,
    this.amountBase,
    this.extraBaggage,
    this.amountWithoutPaymentExpense,
  });

  factory Uzs.fromJson(Map<String, dynamic> json) => Uzs(
        fee: _getInt(json["fee"]),
        fare: _getInt(json["fare"]),
        taxes: _getInt(json["taxes"]),
    amount: _getDouble(json["amount"]),
    discount: _getInt(json["discount"]),
        insurance: _getInt(json["insurance"]),
        amountBase: _getInt(json["amount_base"]),
        extraBaggage: _getInt(json["extra_baggage"]),
        amountWithoutPaymentExpense:
            _getInt(json["amount_without_payment_expense"]),
      );

  Map<String, dynamic> toJson() => {
        "fee": fee,
        "fare": fare,
        "taxes": taxes,
        "amount": amount,
        "discount": discount,
        "insurance": insurance,
        "amount_base": amountBase,
        "extra_baggage": extraBaggage,
        "amount_without_payment_expense": amountWithoutPaymentExpense,
      };
}

class OrderStatus {
  final String? sign;
  final String? title;

  OrderStatus({
    this.sign,
    this.title,
  });

  factory OrderStatus.fromJson(Map<String, dynamic> json) => OrderStatus(
        sign: json["sign"],
        title: json["title"],
      );

  Map<String, dynamic> toJson() => {
        "sign": sign,
        "title": title,
      };
}

class OrderPriceDetails {
  final int? comsa;
  final int? acquiring;
  final int? totalPrice;
  final int? myAgentFee;
  final int? affiliateFee;
  final int? ticketsPrice;
  final int? insurancePrice;
  final int? totalAgentProfit;
  final int? agentAffiliateFee;
  final int? partnerAffiliateFee;

  OrderPriceDetails({
    this.comsa,
    this.acquiring,
    this.totalPrice,
    this.myAgentFee,
    this.affiliateFee,
    this.ticketsPrice,
    this.insurancePrice,
    this.totalAgentProfit,
    this.agentAffiliateFee,
    this.partnerAffiliateFee,
  });

  factory OrderPriceDetails.fromJson(Map<String, dynamic> json) =>
      OrderPriceDetails(
        comsa: _getInt(json["comsa"]),
        acquiring: _getInt(json["acquiring"]),
        totalPrice: _getInt(json["total_price"]),
        myAgentFee: _getInt(json["my_agent_fee"]),
        affiliateFee: _getInt(json["affiliate_fee"]),
        ticketsPrice: _getInt(json["tickets_price"]),
        insurancePrice: _getInt(json["insurance_price"]),
        totalAgentProfit: _getInt(json["total_agent_profit"]),
        agentAffiliateFee: _getInt(json["agent_affiliate_fee"]),
        partnerAffiliateFee: _getInt(json["partner_affiliate_fee"]),
      );

  Map<String, dynamic> toJson() => {
        "comsa": comsa,
        "acquiring": acquiring,
        "total_price": totalPrice,
        "my_agent_fee": myAgentFee,
        "affiliate_fee": affiliateFee,
        "tickets_price": ticketsPrice,
        "insurance_price": insurancePrice,
        "total_agent_profit": totalAgentProfit,
        "agent_affiliate_fee": agentAffiliateFee,
        "partner_affiliate_fee": partnerAffiliateFee,
      };
}

class Passenger {
  final int? id;
  final String? age;
  final String? key;
  final Name? name;
  final String? uuid;
  final String? email;
  final String? phone;
  final String? gender;
  final PassengerDocument? document;
  final String? birthdate;
  final String? bonusCard;
  final List<dynamic>? insurances;
  final TicketData? ticketData;
  final String? citizenship;
  final List<dynamic>? accompanyingAdults;

  Passenger({
    this.id,
    this.age,
    this.key,
    this.name,
    this.uuid,
    this.email,
    this.phone,
    this.gender,
    this.document,
    this.birthdate,
    this.bonusCard,
    this.insurances,
    this.ticketData,
    this.citizenship,
    this.accompanyingAdults,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) => Passenger(
        id: _getInt(json["id"]),
        age: json["age"],
        key: json["key"],
        name: json["name"] == null ? null : Name.fromJson(json["name"]),
        uuid: json["uuid"],
        email: json["email"],
        phone: json["phone"],
        gender: json["gender"],
        document: json["document"] == null
            ? null
            : PassengerDocument.fromJson(json["document"]),
        birthdate: json["birthdate"],
        bonusCard: json["bonus_card"],
        insurances: json["insurances"] == null
            ? []
            : List<dynamic>.from(json["insurances"]!.map((x) => x)),
        ticketData: json["ticketData"] == null
            ? null
            : TicketData.fromJson(json["ticketData"]),
        citizenship: json["citizenship"],
        accompanyingAdults: json["accompanying_adults"] == null
            ? []
            : List<dynamic>.from(json["accompanying_adults"]!.map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "age": age,
        "key": key,
        "name": name?.toJson(),
        "uuid": uuid,
        "email": email,
        "phone": phone,
        "gender": gender,
        "document": document?.toJson(),
        "birthdate": birthdate,
        "bonus_card": bonusCard,
        "insurances": insurances == null
            ? []
            : List<dynamic>.from(insurances!.map((x) => x)),
        "ticketData": ticketData?.toJson(),
        "citizenship": citizenship,
        "accompanying_adults": accompanyingAdults == null
            ? []
            : List<dynamic>.from(accompanyingAdults!.map((x) => x)),
      };
}

class PassengerDocument {
  final String? num;
  final String? type;
  final DateTime? expire;
  final String? originalNumber;

  PassengerDocument({
    this.num,
    this.type,
    this.expire,
    this.originalNumber,
  });

  factory PassengerDocument.fromJson(Map<String, dynamic> json) =>
      PassengerDocument(
        num: json["num"],
        type: json["type"],
        expire: json["expire"] == null
            ? null
            : DateTime.tryParse(json["expire"]),
        originalNumber: json["original_number"],
      );

  Map<String, dynamic> toJson() => {
        "num": num,
        "type": type,
        "expire": expire?.toIso8601String(),
        "original_number": originalNumber,
      };
}

class Name {
  final String? last;
  final String? first;
  final String? middle;

  Name({
    this.last,
    this.first,
    this.middle,
  });

  factory Name.fromJson(Map<String, dynamic> json) => Name(
        last: json["last"],
        first: json["first"],
        middle: json["middle"],
      );

  Map<String, dynamic> toJson() => {
        "last": last,
        "first": first,
        "middle": middle,
      };
}
class Transaction {
  String? trId;
  int? amount;
  int? currency;
  bool? status;

  Transaction({this.trId, this.amount, this.currency, this.status});

  Transaction.fromJson(Map<String, dynamic> json) {
    trId = json['tr_id'];
    amount = json['amount'];
    currency = json['currency'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['tr_id'] = trId;
    data['amount'] = amount;
    data['currency'] = currency;
    data['status'] = status;
    return data;
  }
}

class TicketData {
  final String? text;
  final String? number;
  final bool? refunded;

  TicketData({
    this.text,
    this.number,
    this.refunded,
  });

  factory TicketData.fromJson(Map<String, dynamic> json) => TicketData(
        text: json["text"],
        number: json["number"],
        refunded: json["refunded"],
      );

  Map<String, dynamic> toJson() => {
        "text": text,
        "number": number,
        "refunded": refunded,
      };
}

class PassengersPriceDetail {
  final int? fee;
  final String? key;
  final int? vat;
  final String? uuid;
  final int? comsa;
  final List<ConfirmedTicketTax>? taxes;
  final int? tariff;
  final int? acquiring;
  final Commissions? commissions;
  final int? taxesAmount;
  final int? ticketPrice;
  final int? affiliateFee;
  final String? refundAmounts;
  final int? insurancePrice;
  final int? agentAffiliateFee;
  final int? partnerAffiliateFee;

  PassengersPriceDetail({
    this.fee,
    this.key,
    this.vat,
    this.uuid,
    this.comsa,
    this.taxes,
    this.tariff,
    this.acquiring,
    this.commissions,
    this.taxesAmount,
    this.ticketPrice,
    this.affiliateFee,
    this.refundAmounts,
    this.insurancePrice,
    this.agentAffiliateFee,
    this.partnerAffiliateFee,
  });

  factory PassengersPriceDetail.fromJson(Map<String, dynamic> json) =>
      PassengersPriceDetail(
        fee: _getInt(json["fee"]),
        key: json["key"],
        vat: _getInt(json["vat"]),
        uuid: json["uuid"],
        comsa: _getInt(json["comsa"]),
        taxes: json["taxes"] == null
            ? []
            : List<ConfirmedTicketTax>.from(
                json["taxes"]!.map((x) => ConfirmedTicketTax.fromJson(x))),
        tariff: _getInt(json["tariff"]),
        acquiring: _getInt(json["acquiring"]),
        commissions: json["commissions"] == null
            ? null
            : Commissions.fromJson(json["commissions"]),
        taxesAmount: _getInt(json["taxes_amount"]),
        ticketPrice: _getInt(json["ticket_price"]),
        affiliateFee: _getInt(json["affiliate_fee"]),
        refundAmounts: json["refund_amounts"],
        insurancePrice: _getInt(json["insurance_price"]),
        agentAffiliateFee: _getInt(json["agent_affiliate_fee"]),
        partnerAffiliateFee: _getInt(json["partner_affiliate_fee"]),
      );

  Map<String, dynamic> toJson() => {
        "fee": fee,
        "key": key,
        "vat": vat,
        "uuid": uuid,
        "comsa": comsa,
        "taxes": taxes == null
            ? []
            : List<dynamic>.from(taxes!.map((x) => x.toJson())),
        "tariff": tariff,
        "acquiring": acquiring,
        "commissions": commissions?.toJson(),
        "taxes_amount": taxesAmount,
        "ticket_price": ticketPrice,
        "affiliate_fee": affiliateFee,
        "refund_amounts": refundAmounts,
        "insurance_price": insurancePrice,
        "agent_affiliate_fee": agentAffiliateFee,
        "partner_affiliate_fee": partnerAffiliateFee,
      };
}

class Commissions {
  final int? otherCommission;

  Commissions({
    this.otherCommission,
  });

  factory Commissions.fromJson(Map<String, dynamic> json) => Commissions(
        otherCommission: _getInt(json["other_commission"]),
      );

  Map<String, dynamic> toJson() => {
        "other_commission": otherCommission,
      };
}

class ConfirmedTicketTax {
  final String? code;
  final int? amount;
  final String? currency;

  ConfirmedTicketTax({
    this.code,
    this.amount,
    this.currency,
  });

  factory ConfirmedTicketTax.fromJson(Map<String, dynamic> json) =>
      ConfirmedTicketTax(
        code: json["code"],
        amount: _getInt(json["amount"]),
        currency: json["currency"],
      );

  Map<String, dynamic> toJson() => {
        "code": code,
        "amount": amount,
        "currency": currency,
      };
}

class RefundAvailability {
  final List<dynamic>? tickets;
  final bool? isAutoRefundRequestAvailable;

  RefundAvailability({
    this.tickets,
    this.isAutoRefundRequestAvailable,
  });

  factory RefundAvailability.fromJson(Map<String, dynamic> json) =>
      RefundAvailability(
        tickets: json["tickets"] == null
            ? []
            : List<dynamic>.from(json["tickets"]!.map((x) => x)),
        isAutoRefundRequestAvailable: json["is_auto_refund_request_available"],
      );

  Map<String, dynamic> toJson() => {
        "tickets":
            tickets == null ? [] : List<dynamic>.from(tickets!.map((x) => x)),
        "is_auto_refund_request_available": isAutoRefundRequestAvailable,
      };
}

class ConfirmedTicket {
  final bool? actual;
  final ConfirmedTicketCarrier? carrier;
  final String? locator;
  final ConfirmedTicketDuration? duration;
  final ConfirmedTicketProvider? provider;
  final ConfirmedTicketDocuments? documents;
  final List<Passenger>? passengers;
  final String? receiptText;
  final List<dynamic>? vndLocators;
  final String? bookingProvider;
  final String? bookingOfficeId;
  final String? specialTariffType;
  final String? fareFamilyMarketingName;

  ConfirmedTicket({
    this.actual,
    this.carrier,
    this.locator,
    this.duration,
    this.provider,
    this.documents,
    this.passengers,
    this.receiptText,
    this.vndLocators,
    this.bookingProvider,
    this.bookingOfficeId,
    this.specialTariffType,
    this.fareFamilyMarketingName,
  });

  factory ConfirmedTicket.fromJson(Map<String, dynamic> json) =>
      ConfirmedTicket(
        actual: json["actual"],
        carrier: json["carrier"] == null
            ? null
            : ConfirmedTicketCarrier.fromJson(json["carrier"]),
        locator: json["locator"],
        duration: json["duration"] == null
            ? null
            : ConfirmedTicketDuration.fromJson(json["duration"]),
        provider: json["provider"] == null
            ? null
            : ConfirmedTicketProvider.fromJson(json["provider"]),
        documents: json["documents"] == null
            ? null
            : ConfirmedTicketDocuments.fromJson(json["documents"]),
        passengers: json["passengers"] == null
            ? []
            : List<Passenger>.from(
                json["passengers"]!.map((x) => Passenger.fromJson(x))),
        receiptText: json["receipt_text"],
        vndLocators: json["vnd_locators"] == null
            ? []
            : List<dynamic>.from(json["vnd_locators"]!.map((x) => x)),
        bookingProvider: json["booking_provider"],
        bookingOfficeId: json["booking_office_id"],
        specialTariffType: json["special_tariff_type"],
        fareFamilyMarketingName: json["fare_family_marketing_name"],
      );

  Map<String, dynamic> toJson() => {
        "actual": actual,
        "carrier": carrier?.toJson(),
        "locator": locator,
        "duration": duration?.toJson(),
        "provider": provider?.toJson(),
        "documents": documents?.toJson(),
        "passengers": passengers == null
            ? []
            : List<dynamic>.from(passengers!.map((x) => x.toJson())),
        "receipt_text": receiptText,
        "vnd_locators": vndLocators == null
            ? []
            : List<dynamic>.from(vndLocators!.map((x) => x)),
        "booking_provider": bookingProvider,
        "booking_office_id": bookingOfficeId,
        "special_tariff_type": specialTariffType,
        "fare_family_marketing_name": fareFamilyMarketingName,
      };
}

class ConfirmedTicketDocuments {
  final String? ticketReceipt;

  ConfirmedTicketDocuments({
    this.ticketReceipt,
  });

  factory ConfirmedTicketDocuments.fromJson(Map<String, dynamic> json) =>
      ConfirmedTicketDocuments(
        ticketReceipt: json["ticket_receipt"],
      );

  Map<String, dynamic> toJson() => {
        "ticket_receipt": ticketReceipt,
      };
}

class ConfirmedTicketProvider {
  final String? name;
  final String? currency;

  ConfirmedTicketProvider({
    this.name,
    this.currency,
  });

  factory ConfirmedTicketProvider.fromJson(Map<String, dynamic> json) =>
      ConfirmedTicketProvider(
        name: json["name"],
        currency: json["currency"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "currency": currency,
      };
}

class ConfirmTicketResponseTime {
  final double? execution;

  ConfirmTicketResponseTime({
    this.execution,
  });

  factory ConfirmTicketResponseTime.fromJson(Map<String, dynamic> json) =>
      ConfirmTicketResponseTime(
        execution: json["execution"]?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "execution": execution,
      };
}

// ignore: unused_element
double? _getDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}



int _getInt(dynamic param) {
  try {
    return int.parse("$param");
  } catch (e) {
    return 0;
  }
}
