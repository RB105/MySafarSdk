class GetCentrumRecommendation {
  OTAPSSAirFareFamilySearchRS? oTAPSSAirFareFamilySearchRS;

  GetCentrumRecommendation({this.oTAPSSAirFareFamilySearchRS});

  GetCentrumRecommendation.fromJson(Map<String, dynamic> json) {
    oTAPSSAirFareFamilySearchRS = json['OTAPSS_AirFareFamilySearchRS'] != null
        ? OTAPSSAirFareFamilySearchRS.fromJson(
        json['OTAPSS_AirFareFamilySearchRS'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (oTAPSSAirFareFamilySearchRS != null) {
      data['OTAPSS_AirFareFamilySearchRS'] =
          oTAPSSAirFareFamilySearchRS!.toJson();
    }
    return data;
  }
}

class OTAPSSAirFareFamilySearchRS {
  String? xmlns;
  String? echoToken;
  String? timeStamp;
  String? target;
  String? version;
  String? sequenceNmbr;
  String? primaryLangID;
  dynamic success;
  FareFamilyPricedItineraries? fareFamilyPricedItineraries;

  OTAPSSAirFareFamilySearchRS(
      {this.xmlns,
        this.echoToken,
        this.timeStamp,
        this.target,
        this.version,
        this.sequenceNmbr,
        this.primaryLangID,
        this.success,
        this.fareFamilyPricedItineraries});

  OTAPSSAirFareFamilySearchRS.fromJson(Map<String, dynamic> json) {
    xmlns = json['@xmlns'];
    echoToken = json['@EchoToken'];
    timeStamp = json['@TimeStamp'];
    target = json['@Target'];
    version = json['@Version'];
    sequenceNmbr = json['@SequenceNmbr'];
    primaryLangID = json['@PrimaryLangID'];
    success = json['Success'];
    fareFamilyPricedItineraries = json['FareFamilyPricedItineraries'] != null
        ? FareFamilyPricedItineraries.fromJson(
        json['FareFamilyPricedItineraries'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['@xmlns'] = xmlns;
    data['@EchoToken'] = echoToken;
    data['@TimeStamp'] = timeStamp;
    data['@Target'] = target;
    data['@Version'] = version;
    data['@SequenceNmbr'] = sequenceNmbr;
    data['@PrimaryLangID'] = primaryLangID;
    data['Success'] = success;
    if (fareFamilyPricedItineraries != null) {
      data['FareFamilyPricedItineraries'] =
          fareFamilyPricedItineraries!.toJson();
    }
    return data;
  }
}

class FareFamilyPricedItineraries {
  List<FareFamilyPricedItinerary>? fareFamilyPricedItinerary;

  FareFamilyPricedItineraries({this.fareFamilyPricedItinerary});

  FareFamilyPricedItineraries.fromJson(Map<String, dynamic> json) {
    if (json['FareFamilyPricedItinerary'] != null) {
      fareFamilyPricedItinerary = <FareFamilyPricedItinerary>[];
      if (json['FareFamilyPricedItinerary'] is List) {
        // Handle case when FareFamilyPricedItinerary is a list
        json['FareFamilyPricedItinerary'].forEach((v) {
          fareFamilyPricedItinerary!.add(FareFamilyPricedItinerary.fromJson(v));
        });
      } else if (json['FareFamilyPricedItinerary'] is Map<String, dynamic>) {
        // Handle case when FareFamilyPricedItinerary is a single object
        fareFamilyPricedItinerary!.add(
            FareFamilyPricedItinerary.fromJson(json['FareFamilyPricedItinerary']));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (fareFamilyPricedItinerary != null) {
      data['FareFamilyPricedItinerary'] =
          fareFamilyPricedItinerary!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class FareFamilyPricedItinerary {
  String? rPH;
  String? direction;
  DepartureAirport? departureAirport;
  DepartureAirport? arrivalAirport;
  AirItinerary? airItinerary;
  FareFamilyInformation? fareFamilyInformation;

  FareFamilyPricedItinerary(
      {this.rPH,
        this.direction,
        this.departureAirport,
        this.arrivalAirport,
        this.airItinerary,
        this.fareFamilyInformation});

  FareFamilyPricedItinerary.fromJson(Map<String, dynamic> json) {
    rPH = json['@RPH'];
    direction = json['@Direction'];
    departureAirport = json['DepartureAirport'] != null
        ? DepartureAirport.fromJson(json['DepartureAirport'])
        : null;
    arrivalAirport = json['ArrivalAirport'] != null
        ? DepartureAirport.fromJson(json['ArrivalAirport'])
        : null;
    airItinerary = json['AirItinerary'] != null
        ? AirItinerary.fromJson(json['AirItinerary'])
        : null;
    fareFamilyInformation = json['FareFamilyInformation'] != null
        ? FareFamilyInformation.fromJson(json['FareFamilyInformation'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['@RPH'] = rPH;
    data['@Direction'] = direction;
    if (departureAirport != null) {
      data['DepartureAirport'] = departureAirport!.toJson();
    }
    if (arrivalAirport != null) {
      data['ArrivalAirport'] = arrivalAirport!.toJson();
    }
    if (airItinerary != null) {
      data['AirItinerary'] = airItinerary!.toJson();
    }
    if (fareFamilyInformation != null) {
      data['FareFamilyInformation'] = fareFamilyInformation!.toJson();
    }
    return data;
  }
}

class DepartureAirport {
  String? locationCode;
  String? terminal;

  DepartureAirport({this.locationCode,this.terminal});

  DepartureAirport.fromJson(Map<String, dynamic> json) {
    locationCode = json['@LocationCode'];
    terminal=json['@Terminal'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['@LocationCode'] = locationCode;
    data['@Terminal']=terminal;
    return data;
  }
}

class AirItinerary {
  String? directionInd;
  OriginDestinationOptions? originDestinationOptions;

  AirItinerary({this.directionInd, this.originDestinationOptions});

  AirItinerary.fromJson(Map<String, dynamic> json) {
    directionInd = json['@DirectionInd'];
    originDestinationOptions = json['OriginDestinationOptions'] != null
        ? OriginDestinationOptions.fromJson(
        json['OriginDestinationOptions'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['@DirectionInd'] = directionInd;
    if (originDestinationOptions != null) {
      data['OriginDestinationOptions'] =
          originDestinationOptions!.toJson();
    }
    return data;
  }
}

class OriginDestinationOptions {
  OriginDestinationOption? originDestinationOption;

  OriginDestinationOptions({this.originDestinationOption});

  OriginDestinationOptions.fromJson(Map<String, dynamic> json) {
    originDestinationOption = json['OriginDestinationOption'] != null
        ? OriginDestinationOption.fromJson(json['OriginDestinationOption'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (originDestinationOption != null) {
      data['OriginDestinationOption'] = originDestinationOption!.toJson();
    }
    return data;
  }
}

class OriginDestinationOption {
  String? refNumber;
  FlightSegment? flightSegment;

  OriginDestinationOption({this.refNumber, this.flightSegment});

  OriginDestinationOption.fromJson(Map<String, dynamic> json) {
    refNumber = json['@RefNumber'];
    flightSegment = json['FlightSegment'] != null
        ? FlightSegment.fromJson(json['FlightSegment'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['@RefNumber'] = refNumber;
    if (flightSegment != null) {
      data['FlightSegment'] = flightSegment!.toJson();
    }
    return data;
  }
}

class FlightSegment {
  String? flightNumber;
  String? departureDateTime;
  String? arrivalDateTime;
  String? duration;
  String? stopQuantity;
  String? rPH;
  DepartureAirport? departureAirport;
  DepartureAirport? arrivalAirport;
  OperatingAirline? operatingAirline;
  Equipment? equipment;
  MarketingCabins? marketingCabins;

  FlightSegment(
      {this.flightNumber,
        this.departureDateTime,
        this.arrivalDateTime,
        this.duration,
        this.stopQuantity,
        this.rPH,
        this.departureAirport,
        this.arrivalAirport,
        this.operatingAirline,
        this.equipment,
        this.marketingCabins});

  FlightSegment.fromJson(Map<String, dynamic> json) {
    flightNumber = json['@FlightNumber'];
    departureDateTime = json['@DepartureDateTime'];
    arrivalDateTime = json['@ArrivalDateTime'];
    duration = json['@Duration'];
    stopQuantity = json['@StopQuantity'];
    rPH = json['@RPH'];
    departureAirport = json['DepartureAirport'] != null
        ? DepartureAirport.fromJson(json['DepartureAirport'])
        : null;
    arrivalAirport = json['ArrivalAirport'] != null
        ? DepartureAirport.fromJson(json['ArrivalAirport'])
        : null;
    operatingAirline = json['OperatingAirline'] != null
        ? OperatingAirline.fromJson(json['OperatingAirline'])
        : null;
    equipment = json['Equipment'] != null
        ? Equipment.fromJson(json['Equipment'])
        : null;
    marketingCabins = json['MarketingCabins'] != null
        ? MarketingCabins.fromJson(json['MarketingCabins'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['@FlightNumber'] = flightNumber;
    data['@DepartureDateTime'] = departureDateTime;
    data['@ArrivalDateTime'] = arrivalDateTime;
    data['@Duration'] = duration;
    data['@StopQuantity'] = stopQuantity;
    data['@RPH'] = rPH;
    if (departureAirport != null) {
      data['DepartureAirport'] = departureAirport!.toJson();
    }
    if (arrivalAirport != null) {
      data['ArrivalAirport'] = arrivalAirport!.toJson();
    }
    if (operatingAirline != null) {
      data['OperatingAirline'] = operatingAirline!.toJson();
    }
    if (equipment != null) {
      data['Equipment'] = equipment!.toJson();
    }
    if (marketingCabins != null) {
      data['MarketingCabins'] = marketingCabins!.toJson();
    }
    return data;
  }
}

class OperatingAirline {
  String? code;

  OperatingAirline({this.code});

  OperatingAirline.fromJson(Map<String, dynamic> json) {
    code = json['@Code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['@Code'] = code;
    return data;
  }
}

class Equipment {
  String? airEquipType;

  Equipment({this.airEquipType});

  Equipment.fromJson(Map<String, dynamic> json) {
    airEquipType = json['@AirEquipType'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['@AirEquipType'] = airEquipType;
    return data;
  }
}

class MarketingCabins {
  MarketingCabin? marketingCabin;

  MarketingCabins({this.marketingCabin});

  MarketingCabins.fromJson(Map<String, dynamic> json) {
    marketingCabin = json['MarketingCabin'] != null
        ? MarketingCabin.fromJson(json['MarketingCabin'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (marketingCabin != null) {
      data['MarketingCabin'] = marketingCabin!.toJson();
    }
    return data;
  }
}

class MarketingCabin {
  String? name;
  String? rPH;

  MarketingCabin({this.name, this.rPH});

  MarketingCabin.fromJson(Map<String, dynamic> json) {
    name = json['@Name'];
    rPH = json['@RPH'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['@Name'] = name;
    data['@RPH'] = rPH;
    return data;
  }
}

class FareFamilyInformation {
  List<FareFamilyInfo>? fareFamilyInfo;

  FareFamilyInformation({this.fareFamilyInfo});

  FareFamilyInformation.fromJson(Map<String, dynamic> json) {
    if (json['FareFamilyInfo'] != null) {
      fareFamilyInfo = <FareFamilyInfo>[];
      json['FareFamilyInfo'].forEach((v) {
        fareFamilyInfo!.add(FareFamilyInfo.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (fareFamilyInfo != null) {
      data['FareFamilyInfo'] =
          fareFamilyInfo!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class FareFamilyInfo {
  String? rPH;
  String? fareFamilyCode;
  String? fareFamilyName;
  String? onDRefNumberRPHList;
  AirItineraryPricingInfo? airItineraryPricingInfo;

  FareFamilyInfo(
      {this.rPH,
        this.fareFamilyCode,
        this.fareFamilyName,
        this.onDRefNumberRPHList,
        this.airItineraryPricingInfo});

  FareFamilyInfo.fromJson(Map<String, dynamic> json) {
    rPH = json['@RPH'];
    fareFamilyCode = json['@fareFamilyCode'];
    fareFamilyName = json['@fareFamilyName'];
    onDRefNumberRPHList = json['@OnDRefNumberRPHList'];
    airItineraryPricingInfo = json['AirItineraryPricingInfo'] != null
        ? AirItineraryPricingInfo.fromJson(json['AirItineraryPricingInfo'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['@RPH'] = rPH;
    data['@fareFamilyCode'] = fareFamilyCode;
    data['@fareFamilyName'] = fareFamilyName;
    data['@OnDRefNumberRPHList'] = onDRefNumberRPHList;
    if (airItineraryPricingInfo != null) {
      data['AirItineraryPricingInfo'] = airItineraryPricingInfo!.toJson();
    }
    return data;
  }
}

class AirItineraryPricingInfo {
  ItinTotalFare? itinTotalFare;
  PTCFareBreakdowns? pTCFareBreakdowns;

  AirItineraryPricingInfo({this.itinTotalFare, this.pTCFareBreakdowns});

  AirItineraryPricingInfo.fromJson(Map<String, dynamic> json) {
    itinTotalFare = json['ItinTotalFare'] != null
        ? ItinTotalFare.fromJson(json['ItinTotalFare'])
        : null;
    pTCFareBreakdowns = json['PTC_FareBreakdowns'] != null
        ? PTCFareBreakdowns.fromJson(json['PTC_FareBreakdowns'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (itinTotalFare != null) {
      data['ItinTotalFare'] = itinTotalFare!.toJson();
    }
    if (pTCFareBreakdowns != null) {
      data['PTC_FareBreakdowns'] = pTCFareBreakdowns!.toJson();
    }
    return data;
  }
}

class ItinTotalFare {
  TotalFare? totalFare;

  ItinTotalFare({this.totalFare});

  ItinTotalFare.fromJson(Map<String, dynamic> json) {
    totalFare = json['TotalFare'] != null
        ? TotalFare.fromJson(json['TotalFare'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (totalFare != null) {
      data['TotalFare'] = totalFare!.toJson();
    }
    return data;
  }
}

class TotalFare {
  String? currencyCode;
  String? amount;

  TotalFare({this.currencyCode, this.amount});

  TotalFare.fromJson(Map<String, dynamic> json) {
    currencyCode = json['@CurrencyCode'];
    amount = json['@Amount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['@CurrencyCode'] = currencyCode;
    data['@Amount'] = amount;
    return data;
  }
}

class PTCFareBreakdowns {
  List<PTCFareBreakdown>? pTCFareBreakdown;

  PTCFareBreakdowns({this.pTCFareBreakdown});

  PTCFareBreakdowns.fromJson(Map<String, dynamic> json) {
    if (json['PTC_FareBreakdown'] != null) {
      pTCFareBreakdown = <PTCFareBreakdown>[];

      if (json['PTC_FareBreakdown'] is List) {
        json['PTC_FareBreakdown'].forEach((v) {
          pTCFareBreakdown!.add(PTCFareBreakdown.fromJson(v));
        });
      } else {

        pTCFareBreakdown!.add(PTCFareBreakdown.fromJson(json['PTC_FareBreakdown']));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (pTCFareBreakdown != null) {
      data['PTC_FareBreakdown'] =
          pTCFareBreakdown!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class PTCFareBreakdown {
  PassengerTypeQuantity? passengerTypeQuantity;
  FareBasisCodes? fareBasisCodes;
  PassengerFare? passengerFare;

  PTCFareBreakdown(
      {this.passengerTypeQuantity, this.fareBasisCodes, this.passengerFare});

  PTCFareBreakdown.fromJson(Map<String, dynamic> json) {
    passengerTypeQuantity = json['PassengerTypeQuantity'] != null
        ? PassengerTypeQuantity.fromJson(json['PassengerTypeQuantity'])
        : null;
    fareBasisCodes = json['FareBasisCodes'] != null
        ? FareBasisCodes.fromJson(json['FareBasisCodes'])
        : null;
    passengerFare = json['PassengerFare'] != null
        ? PassengerFare.fromJson(json['PassengerFare'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (passengerTypeQuantity != null) {
      data['PassengerTypeQuantity'] = passengerTypeQuantity!.toJson();
    }
    if (fareBasisCodes != null) {
      data['FareBasisCodes'] = fareBasisCodes!.toJson();
    }
    if (passengerFare != null) {
      data['PassengerFare'] = passengerFare!.toJson();
    }
    return data;
  }
}

class PassengerTypeQuantity {
  String? code;
  String? quantity;

  PassengerTypeQuantity({this.code, this.quantity});

  PassengerTypeQuantity.fromJson(Map<String, dynamic> json) {
    code = json['@Code'];
    quantity = json['@Quantity'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['@Code'] = code;
    data['@Quantity'] = quantity;
    return data;
  }
}

class FareBasisCodes {
  FareBasisCode? fareBasisCode;

  FareBasisCodes({this.fareBasisCode});

  FareBasisCodes.fromJson(Map<String, dynamic> json) {
    fareBasisCode = json['FareBasisCode'] != null
        ? FareBasisCode.fromJson(json['FareBasisCode'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (fareBasisCode != null) {
      data['FareBasisCode'] = fareBasisCode!.toJson();
    }
    return data;
  }
}

class FareBasisCode {
  String? flightSegmentRPH;
  String? resBookDesigCode;
  String? resBookDesigQuantity;
  String? cabinClassRPH;
  String? text;

  FareBasisCode(
      {this.flightSegmentRPH,
        this.resBookDesigCode,
        this.resBookDesigQuantity,
        this.cabinClassRPH,
        this.text});

  FareBasisCode.fromJson(Map<String, dynamic> json) {
    flightSegmentRPH = json['@FlightSegmentRPH'];
    resBookDesigCode = json['@ResBookDesigCode'];
    resBookDesigQuantity = json['@ResBookDesigQuantity'];
    cabinClassRPH = json['@CabinClassRPH'];
    text = json['#text'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['@FlightSegmentRPH'] = flightSegmentRPH;
    data['@ResBookDesigCode'] = resBookDesigCode;
    data['@ResBookDesigQuantity'] = resBookDesigQuantity;
    data['@CabinClassRPH'] = cabinClassRPH;
    data['#text'] = text;
    return data;
  }
}

class PassengerFare {
  BaseFare? baseFare;
  Taxes? taxes;
  FareBaggageAllowance? fareBaggageAllowance;

  PassengerFare({this.baseFare, this.taxes, this.fareBaggageAllowance});

  PassengerFare.fromJson(Map<String, dynamic> json) {
    baseFare = json['BaseFare'] != null
        ? BaseFare.fromJson(json['BaseFare'])
        : null;
    taxes = json['Taxes'] != null ? Taxes.fromJson(json['Taxes']) : null;
    fareBaggageAllowance = json['FareBaggageAllowance'] != null
        ? FareBaggageAllowance.fromJson(json['FareBaggageAllowance'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (baseFare != null) {
      data['BaseFare'] = baseFare!.toJson();
    }
    if (taxes != null) {
      data['Taxes'] = taxes!.toJson();
    }
    if (fareBaggageAllowance != null) {
      data['FareBaggageAllowance'] = fareBaggageAllowance!.toJson();
    }
    return data;
  }
}

class BaseFare {
  String? currencyCode;
  String? decimalPlaces;
  String? amount;
  String? originalAmount;

  BaseFare(
      {this.currencyCode,
        this.decimalPlaces,
        this.amount,
        this.originalAmount});

  BaseFare.fromJson(Map<String, dynamic> json) {
    currencyCode = json['@CurrencyCode'];
    decimalPlaces = json['@DecimalPlaces'];
    amount = json['@Amount'];
    originalAmount = json['@OriginalAmount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['@CurrencyCode'] = currencyCode;
    data['@DecimalPlaces'] = decimalPlaces;
    data['@Amount'] = amount;
    data['@OriginalAmount'] = originalAmount;
    return data;
  }
}

class Taxes {
  List<Tax>? tax;

  Taxes({this.tax});

  Taxes.fromJson(Map<String, dynamic> json) {
    if (json['Tax'] != null) {
      tax = <Tax>[];
      json['Tax'].forEach((v) {
        tax!.add(Tax.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (tax != null) {
      data['Tax'] = tax!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Tax {
  String? taxCode;
  String? taxName;
  String? currencyCode;
  String? decimalPlaces;
  String? text;

  Tax(
      {this.taxCode,
        this.taxName,
        this.currencyCode,
        this.decimalPlaces,
        this.text});

  Tax.fromJson(Map<String, dynamic> json) {
    taxCode = json['@TaxCode'];
    taxName = json['@TaxName'];
    currencyCode = json['@CurrencyCode'];
    decimalPlaces = json['@DecimalPlaces'];
    text = json['#text'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['@TaxCode'] = taxCode;
    data['@TaxName'] = taxName;
    data['@CurrencyCode'] = currencyCode;
    data['@DecimalPlaces'] = decimalPlaces;
    data['#text'] = text;
    return data;
  }
}

class FareBaggageAllowance {
  String? flightSegmentRPH;
  String? unitOfMeasureQuantity;
  String? unitOfMeasure;
  String? unitOfMeasureCode;

  FareBaggageAllowance(
      {this.flightSegmentRPH,
        this.unitOfMeasureQuantity,
        this.unitOfMeasure,
        this.unitOfMeasureCode});

  FareBaggageAllowance.fromJson(Map<String, dynamic> json) {
    flightSegmentRPH = json['@FlightSegmentRPH'];
    unitOfMeasureQuantity = json['@UnitOfMeasureQuantity'];
    unitOfMeasure = json['@UnitOfMeasure'];
    unitOfMeasureCode = json['@UnitOfMeasureCode'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['@FlightSegmentRPH'] = flightSegmentRPH;
    data['@UnitOfMeasureQuantity'] = unitOfMeasureQuantity;
    data['@UnitOfMeasure'] = unitOfMeasure;
    data['@UnitOfMeasureCode'] = unitOfMeasureCode;
    return data;
  }
}
