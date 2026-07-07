
class CentrumBookingCreateModel {
  OTAAirBookRS? oTAAirBookRS;

  CentrumBookingCreateModel({this.oTAAirBookRS});

  CentrumBookingCreateModel.fromJson(Map<String, dynamic> json) {
    oTAAirBookRS = json['OTA_AirBookRS'] != null
        ? OTAAirBookRS.fromJson(json['OTA_AirBookRS'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (oTAAirBookRS != null) {
      data['OTA_AirBookRS'] = oTAAirBookRS!.toJson();
    }
    return data;
  }
}

class OTAAirBookRS {
  String? xmlns;
  String? echoToken;
  String? timeStamp;
  String? target;
  String? version;
  String? sequenceNmbr;
  String? primaryLangID;
  dynamic success; // null bo'lishi mumkin
  AirReservation? airReservation;

  OTAAirBookRS({
    this.xmlns,
    this.echoToken,
    this.timeStamp,
    this.target,
    this.version,
    this.sequenceNmbr,
    this.primaryLangID,
    this.success,
    this.airReservation,
  });

  OTAAirBookRS.fromJson(Map<String, dynamic> json) {
    xmlns = json['@xmlns'];
    echoToken = json['@EchoToken'];
    timeStamp = json['@TimeStamp'];
    target = json['@Target'];
    version = json['@Version'];
    sequenceNmbr = json['@SequenceNmbr'];
    primaryLangID = json['@PrimaryLangID'];
    success = json['Success'];
    airReservation = json['AirReservation'] != null
        ? AirReservation.fromJson(json['AirReservation'])
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
    if (airReservation != null) {
      data['AirReservation'] = airReservation!.toJson();
    }
    return data;
  }
}

class AirReservation {
  String? createdDateTme;
  AirItinerary? airItinerary;
  ArrangerInfo? arrangerInfo;
  PriceInfo? priceInfo;
  TravelerInfo? travelerInfo;
  ContactPerson? contactPerson;
  Fulfillment? fulfillment;
  Ticketing? ticketing;
  TotalFare? balanceInfo;
  TotalFare? balanceInfoInAgentCurrency;
  BookingReferenceID? bookingReferenceID;
  dynamic offer;

  AirReservation({
    this.createdDateTme,
    this.airItinerary,
    this.arrangerInfo,
    this.priceInfo,
    this.travelerInfo,
    this.contactPerson,
    this.fulfillment,
    this.ticketing,
    this.balanceInfo,
    this.balanceInfoInAgentCurrency,
    this.bookingReferenceID,
    this.offer,
  });

  AirReservation.fromJson(Map<String, dynamic> json) {
    createdDateTme = json['@CreatedDateTme'];
    airItinerary = json['AirItinerary'] != null
        ? AirItinerary.fromJson(json['AirItinerary'])
        : null;
    arrangerInfo = json['ArrangerInfo'] != null
        ? ArrangerInfo.fromJson(json['ArrangerInfo'])
        : null;
    priceInfo = json['PriceInfo'] != null
        ? PriceInfo.fromJson(json['PriceInfo'])
        : null;
    travelerInfo = json['TravelerInfo'] != null
        ? TravelerInfo.fromJson(json['TravelerInfo'])
        : null;
    contactPerson = json['ContactPerson'] != null
        ? ContactPerson.fromJson(json['ContactPerson'])
        : null;
    fulfillment = json['Fulfillment'] != null
        ? Fulfillment.fromJson(json['Fulfillment'])
        : null;
    ticketing = json['Ticketing'] != null
        ? Ticketing.fromJson(json['Ticketing'])
        : null;
    balanceInfo = json['BalanceInfo'] != null
        ? TotalFare.fromJson(json['BalanceInfo'])
        : null;
    balanceInfoInAgentCurrency = json['BalanceInfoInAgentCurrency'] != null
        ? TotalFare.fromJson(json['BalanceInfoInAgentCurrency'])
        : null;
    bookingReferenceID = json['BookingReferenceID'] != null
        ? BookingReferenceID.fromJson(json['BookingReferenceID'])
        : null;
    offer = json['Offer'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['@CreatedDateTme'] = createdDateTme;
    if (airItinerary != null) data['AirItinerary'] = airItinerary!.toJson();
    if (arrangerInfo != null) data['ArrangerInfo'] = arrangerInfo!.toJson();
    if (priceInfo != null) data['PriceInfo'] = priceInfo!.toJson();
    if (travelerInfo != null) data['TravelerInfo'] = travelerInfo!.toJson();
    if (contactPerson != null) data['ContactPerson'] = contactPerson!.toJson();
    if (fulfillment != null) data['Fulfillment'] = fulfillment!.toJson();
    if (ticketing != null) data['Ticketing'] = ticketing!.toJson();
    if (balanceInfo != null) data['BalanceInfo'] = balanceInfo!.toJson();
    if (balanceInfoInAgentCurrency != null) {
      data['BalanceInfoInAgentCurrency'] = balanceInfoInAgentCurrency!.toJson();
    }
    if (bookingReferenceID != null) {
      data['BookingReferenceID'] = bookingReferenceID!.toJson();
    }
    data['Offer'] = offer;
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
        ? OriginDestinationOptions.fromJson(json['OriginDestinationOptions'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['@DirectionInd'] = directionInd;
    if (originDestinationOptions != null) {
      data['OriginDestinationOptions'] = originDestinationOptions!.toJson();
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
    final data = <String, dynamic>{};
    if (originDestinationOption != null) {
      data['OriginDestinationOption'] = originDestinationOption!.toJson();
    }
    return data;
  }
}

class OriginDestinationOption {
  FlightSegment? flightSegment;

  OriginDestinationOption({this.flightSegment});

  OriginDestinationOption.fromJson(Map<String, dynamic> json) {
    flightSegment = json['FlightSegment'] != null
        ? FlightSegment.fromJson(json['FlightSegment'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (flightSegment != null) data['FlightSegment'] = flightSegment!.toJson();
    return data;
  }
}

class FlightSegment {
  String? status;
  String? flightNumber;
  String? fareBasisCode;
  String? resBookDesigCode;
  String? fareFamilyCode;
  String? departureDateTime;
  String? arrivalDateTime;
  String? stopQuantity;
  String? rPH;
  DepartureAirport? departureAirport;
  DepartureAirport? arrivalAirport;
  OperatingAirline? operatingAirline;
  Equipment? equipment;
  MarketingCabins? marketingCabins;

  FlightSegment({
    this.status,
    this.flightNumber,
    this.fareBasisCode,
    this.resBookDesigCode,
    this.fareFamilyCode,
    this.departureDateTime,
    this.arrivalDateTime,
    this.stopQuantity,
    this.rPH,
    this.departureAirport,
    this.arrivalAirport,
    this.operatingAirline,
    this.equipment,
    this.marketingCabins,
  });

  FlightSegment.fromJson(Map<String, dynamic> json) {
    status = json['@Status'];
    flightNumber = json['@FlightNumber'];
    fareBasisCode = json['@FareBasisCode'];
    resBookDesigCode = json['@ResBookDesigCode'];
    fareFamilyCode = json['@FareFamilyCode'];
    departureDateTime = json['@DepartureDateTime'];
    arrivalDateTime = json['@ArrivalDateTime'];
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
    final data = <String, dynamic>{};
    data['@Status'] = status;
    data['@FlightNumber'] = flightNumber;
    data['@FareBasisCode'] = fareBasisCode;
    data['@ResBookDesigCode'] = resBookDesigCode;
    data['@FareFamilyCode'] = fareFamilyCode;
    data['@DepartureDateTime'] = departureDateTime;
    data['@ArrivalDateTime'] = arrivalDateTime;
    data['@StopQuantity'] = stopQuantity;
    data['@RPH'] = rPH;
    if (departureAirport != null) data['DepartureAirport'] = departureAirport!.toJson();
    if (arrivalAirport != null) data['ArrivalAirport'] = arrivalAirport!.toJson();
    if (operatingAirline != null) data['OperatingAirline'] = operatingAirline!.toJson();
    if (equipment != null) data['Equipment'] = equipment!.toJson();
    if (marketingCabins != null) data['MarketingCabins'] = marketingCabins!.toJson();
    return data;
  }
}

class DepartureAirport {
  String? locationCode;
  String? locationName;

  DepartureAirport({this.locationCode, this.locationName});

  DepartureAirport.fromJson(Map<String, dynamic> json) {
    locationCode = json['@LocationCode'];
    locationName = json['@LocationName'];
  }

  Map<String, dynamic> toJson() {
    return {
      '@LocationCode': locationCode,
      '@LocationName': locationName,
    };
  }
}

class OperatingAirline {
  String? code;

  OperatingAirline({this.code});

  OperatingAirline.fromJson(Map<String, dynamic> json) {
    code = json['@Code'];
  }

  Map<String, dynamic> toJson() {
    return {'@Code': code};
  }
}

class Equipment {
  String? airEquipType;

  Equipment({this.airEquipType});

  Equipment.fromJson(Map<String, dynamic> json) {
    airEquipType = json['@AirEquipType'];
  }

  Map<String, dynamic> toJson() {
    return {'@AirEquipType': airEquipType};
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
    final data = <String, dynamic>{};
    if (marketingCabin != null) data['MarketingCabin'] = marketingCabin!.toJson();
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
    return {
      '@Name': name,
      '@RPH': rPH,
    };
  }
}

class ArrangerInfo {
  CompanyInfo? companyInfo;

  ArrangerInfo({this.companyInfo});

  ArrangerInfo.fromJson(Map<String, dynamic> json) {
    companyInfo = json['CompanyInfo'] != null
        ? CompanyInfo.fromJson(json['CompanyInfo'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (companyInfo != null) data['CompanyInfo'] = companyInfo!.toJson();
    return data;
  }
}

class CompanyInfo {
  String? companyShortName;
  String? code;

  CompanyInfo({this.companyShortName, this.code});

  CompanyInfo.fromJson(Map<String, dynamic> json) {
    companyShortName = json['@CompanyShortName'];
    code = json['@Code'];
  }

  Map<String, dynamic> toJson() {
    return {
      '@CompanyShortName': companyShortName,
      '@Code': code,
    };
  }
}

class PriceInfo {
  ItinTotalFare? itinTotalFare;
  PTCFareBreakdowns? pTCFareBreakdowns;

  PriceInfo({this.itinTotalFare, this.pTCFareBreakdowns});

  PriceInfo.fromJson(Map<String, dynamic> json) {
    itinTotalFare = json['ItinTotalFare'] != null
        ? ItinTotalFare.fromJson(json['ItinTotalFare'])
        : null;
    pTCFareBreakdowns = json['PTC_FareBreakdowns'] != null
        ? PTCFareBreakdowns.fromJson(json['PTC_FareBreakdowns'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (itinTotalFare != null) data['ItinTotalFare'] = itinTotalFare!.toJson();
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
    final data = <String, dynamic>{};
    if (totalFare != null) data['TotalFare'] = totalFare!.toJson();
    return data;
  }
}

class TotalFare {
  String? currencyCode;
  String? decimalPlaces;
  String? amount;

  TotalFare({this.currencyCode, this.decimalPlaces, this.amount});

  TotalFare.fromJson(Map<String, dynamic> json) {
    currencyCode = json['@CurrencyCode'];
    decimalPlaces = json['@DecimalPlaces'];
    amount = json['@Amount'];
  }

  Map<String, dynamic> toJson() {
    return {
      '@CurrencyCode': currencyCode,
      '@DecimalPlaces': decimalPlaces,
      '@Amount': amount,
    };
  }
}

class PTCFareBreakdowns {
  PTCFareBreakdown? pTCFareBreakdown;

  PTCFareBreakdowns({this.pTCFareBreakdown});

  PTCFareBreakdowns.fromJson(Map<String, dynamic> json) {
    pTCFareBreakdown = json['PTC_FareBreakdown'] != null
        ? PTCFareBreakdown.fromJson(json['PTC_FareBreakdown'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (pTCFareBreakdown != null) {
      data['PTC_FareBreakdown'] = pTCFareBreakdown!.toJson();
    }
    return data;
  }
}

class PTCFareBreakdown {
  PassengerTypeQuantity? passengerTypeQuantity;
  FareBasisCodes? fareBasisCodes;
  PassengerFare? passengerFare;
  FareInfoWrapper? fareInfo; // Nested FareInfo

  PTCFareBreakdown({
    this.passengerTypeQuantity,
    this.fareBasisCodes,
    this.passengerFare,
    this.fareInfo,
  });

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
    fareInfo = json['FareInfo'] != null
        ? FareInfoWrapper.fromJson(json['FareInfo'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (passengerTypeQuantity != null) {
      data['PassengerTypeQuantity'] = passengerTypeQuantity!.toJson();
    }
    if (fareBasisCodes != null) data['FareBasisCodes'] = fareBasisCodes!.toJson();
    if (passengerFare != null) data['PassengerFare'] = passengerFare!.toJson();
    if (fareInfo != null) data['FareInfo'] = fareInfo!.toJson();
    return data;
  }
}

// Nested FareInfo (ichidagi FareInfo)
class FareInfoWrapper {
  String? fareBasisCode;
  Fare? fare;

  FareInfoWrapper({this.fareBasisCode, this.fare});

  FareInfoWrapper.fromJson(Map<String, dynamic> json) {
    fareBasisCode = json['@FareBasisCode'];
    fare = json['Fare'] != null ? Fare.fromJson(json['Fare']) : null;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['@FareBasisCode'] = fareBasisCode;
    if (fare != null) data['Fare'] = fare!.toJson();
    return data;
  }
}

class Fare {
  String? baseAmount;

  Fare({this.baseAmount});

  Fare.fromJson(Map<String, dynamic> json) {
    baseAmount = json['@BaseAmount'];
  }

  Map<String, dynamic> toJson() {
    return {'@BaseAmount': baseAmount};
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
    return {
      '@Code': code,
      '@Quantity': quantity,
    };
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
    final data = <String, dynamic>{};
    if (fareBasisCode != null) data['FareBasisCode'] = fareBasisCode!.toJson();
    return data;
  }
}

class FareBasisCode {
  String? cabinClassRPH;
  String? text;

  FareBasisCode({this.cabinClassRPH, this.text});

  FareBasisCode.fromJson(Map<String, dynamic> json) {
    cabinClassRPH = json['@CabinClassRPH'];
    text = json['#text'];
  }

  Map<String, dynamic> toJson() {
    return {
      '@CabinClassRPH': cabinClassRPH,
      '#text': text,
    };
  }
}

class PassengerFare {
  TotalFare? baseFare;
  Taxes? taxes;
  TotalFare? totalFare;
  FareBaggageAllowance? fareBaggageAllowance;

  PassengerFare({
    this.baseFare,
    this.taxes,
    this.totalFare,
    this.fareBaggageAllowance,
  });

  PassengerFare.fromJson(Map<String, dynamic> json) {
    baseFare = json['BaseFare'] != null ? TotalFare.fromJson(json['BaseFare']) : null;
    taxes = json['Taxes'] != null ? Taxes.fromJson(json['Taxes']) : null;
    totalFare = json['TotalFare'] != null ? TotalFare.fromJson(json['TotalFare']) : null;
    fareBaggageAllowance = json['FareBaggageAllowance'] != null
        ? FareBaggageAllowance.fromJson(json['FareBaggageAllowance'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (baseFare != null) data['BaseFare'] = baseFare!.toJson();
    if (taxes != null) data['Taxes'] = taxes!.toJson();
    if (totalFare != null) data['TotalFare'] = totalFare!.toJson();
    if (fareBaggageAllowance != null) {
      data['FareBaggageAllowance'] = fareBaggageAllowance!.toJson();
    }
    return data;
  }
}

class Taxes {
  List<Tax>? tax;

  Taxes({this.tax});

  Taxes.fromJson(Map<String, dynamic> json) {
    if (json['Tax'] != null) {
      tax = (json['Tax'] as List).map((v) => Tax.fromJson(v)).toList();
    }
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
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
  String? amount;

  Tax({
    this.taxCode,
    this.taxName,
    this.currencyCode,
    this.decimalPlaces,
    this.amount,
  });

  Tax.fromJson(Map<String, dynamic> json) {
    taxCode = json['@TaxCode'];
    taxName = json['@TaxName'];
    currencyCode = json['@CurrencyCode'];
    decimalPlaces = json['@DecimalPlaces'];
    amount = json['@Amount'];
  }

  Map<String, dynamic> toJson() {
    return {
      '@TaxCode': taxCode,
      '@TaxName': taxName,
      '@CurrencyCode': currencyCode,
      '@DecimalPlaces': decimalPlaces,
      '@Amount': amount,
    };
  }
}

class FareBaggageAllowance {
  String? flightSegmentRPH;
  String? unitOfMeasureQuantity;
  String? unitOfMeasure;
  String? unitOfMeasureCode;

  FareBaggageAllowance({
    this.flightSegmentRPH,
    this.unitOfMeasureQuantity,
    this.unitOfMeasure,
    this.unitOfMeasureCode,
  });

  FareBaggageAllowance.fromJson(Map<String, dynamic> json) {
    flightSegmentRPH = json['@FlightSegmentRPH'];
    unitOfMeasureQuantity = json['@UnitOfMeasureQuantity'];
    unitOfMeasure = json['@UnitOfMeasure'];
    unitOfMeasureCode = json['@UnitOfMeasureCode'];
  }

  Map<String, dynamic> toJson() {
    return {
      '@FlightSegmentRPH': flightSegmentRPH,
      '@UnitOfMeasureQuantity': unitOfMeasureQuantity,
      '@UnitOfMeasure': unitOfMeasure,
      '@UnitOfMeasureCode': unitOfMeasureCode,
    };
  }
}

class TravelerInfo {
  AirTraveler? airTraveler;

  TravelerInfo({this.airTraveler});

  TravelerInfo.fromJson(Map<String, dynamic> json) {
    airTraveler = json['AirTraveler'] != null
        ? AirTraveler.fromJson(json['AirTraveler'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (airTraveler != null) data['AirTraveler'] = airTraveler!.toJson();
    return data;
  }
}

class AirTraveler {
  String? birthDate;
  String? passengerTypeCode;
  String? accompaniedByInfantInd;
  String? travelerNationality;
  String? gender;
  PersonName? personName;
  Document? document;
  TravelerRefNumber? travelerRefNumber;

  AirTraveler({
    this.birthDate,
    this.passengerTypeCode,
    this.accompaniedByInfantInd,
    this.travelerNationality,
    this.gender,
    this.personName,
    this.document,
    this.travelerRefNumber,
  });

  AirTraveler.fromJson(Map<String, dynamic> json) {
    birthDate = json['@BirthDate'];
    passengerTypeCode = json['@PassengerTypeCode'];
    accompaniedByInfantInd = json['@AccompaniedByInfantInd'];
    travelerNationality = json['@TravelerNationality'];
    gender = json['@Gender'];
    personName = json['PersonName'] != null
        ? PersonName.fromJson(json['PersonName'])
        : null;
    document = json['Document'] != null ? Document.fromJson(json['Document']) : null;
    travelerRefNumber = json['TravelerRefNumber'] != null
        ? TravelerRefNumber.fromJson(json['TravelerRefNumber'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['@BirthDate'] = birthDate;
    data['@PassengerTypeCode'] = passengerTypeCode;
    data['@AccompaniedByInfantInd'] = accompaniedByInfantInd;
    data['@TravelerNationality'] = travelerNationality;
    data['@Gender'] = gender;
    if (personName != null) data['PersonName'] = personName!.toJson();
    if (document != null) data['Document'] = document!.toJson();
    if (travelerRefNumber != null) {
      data['TravelerRefNumber'] = travelerRefNumber!.toJson();
    }
    return data;
  }
}

class PersonName {
  String? namePrefix;
  String? givenName;
  String? surname;

  PersonName({this.namePrefix, this.givenName, this.surname});

  PersonName.fromJson(Map<String, dynamic> json) {
    namePrefix = json['NamePrefix'];
    givenName = json['GivenName'];
    surname = json['Surname'];
  }

  Map<String, dynamic> toJson() {
    return {
      'NamePrefix': namePrefix,
      'GivenName': givenName,
      'Surname': surname,
    };
  }
}

class Document {
  String? docID;
  String? docType;
  String? docIssueCountry;
  String? docHolderNationality;
  String? effectiveDate;
  String? expireDate;

  Document({
    this.docID,
    this.docType,
    this.docIssueCountry,
    this.docHolderNationality,
    this.effectiveDate,
    this.expireDate,
  });

  Document.fromJson(Map<String, dynamic> json) {
    docID = json['@DocID'];
    docType = json['@DocType'];
    docIssueCountry = json['@DocIssueCountry'];
    docHolderNationality = json['@DocHolderNationality'];
    effectiveDate = json['@EffectiveDate'];
    expireDate = json['@ExpireDate'];
  }

  Map<String, dynamic> toJson() {
    return {
      '@DocID': docID,
      '@DocType': docType,
      '@DocIssueCountry': docIssueCountry,
      '@DocHolderNationality': docHolderNationality,
      '@EffectiveDate': effectiveDate,
      '@ExpireDate': expireDate,
    };
  }
}

class TravelerRefNumber {
  String? rPH;

  TravelerRefNumber({this.rPH});

  TravelerRefNumber.fromJson(Map<String, dynamic> json) {
    rPH = json['@RPH'];
  }

  Map<String, dynamic> toJson() {
    return {'@RPH': rPH};
  }
}

class ContactPerson {
  ContactPersonName? personName;
  Telephone? telephone;
  Telephone? homeTelephone;
  String? email;

  ContactPerson({this.personName, this.telephone, this.homeTelephone, this.email});

  ContactPerson.fromJson(Map<String, dynamic> json) {
    personName = json['PersonName'] != null
        ? ContactPersonName.fromJson(json['PersonName'])
        : null;
    telephone = json['Telephone'] != null
        ? Telephone.fromJson(json['Telephone'])
        : null;
    homeTelephone = json['HomeTelephone'] != null
        ? Telephone.fromJson(json['HomeTelephone'])
        : null;
    email = json['Email'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (personName != null) data['PersonName'] = personName!.toJson();
    if (telephone != null) data['Telephone'] = telephone!.toJson();
    if (homeTelephone != null) data['HomeTelephone'] = homeTelephone!.toJson();
    data['Email'] = email;
    return data;
  }
}

// ContactPerson uchun alohida PersonName (NamePrefix yo'q)
class ContactPersonName {
  String? givenName;
  String? surname;

  ContactPersonName({this.givenName, this.surname});

  ContactPersonName.fromJson(Map<String, dynamic> json) {
    givenName = json['GivenName'];
    surname = json['Surname'];
  }

  Map<String, dynamic> toJson() {
    return {
      'GivenName': givenName,
      'Surname': surname,
    };
  }
}

class Telephone {
  String? phoneNumber;

  Telephone({this.phoneNumber});

  Telephone.fromJson(Map<String, dynamic> json) {
    phoneNumber = json['@PhoneNumber'];
  }

  Map<String, dynamic> toJson() {
    return {'@PhoneNumber': phoneNumber};
  }
}

class Fulfillment {
  dynamic paymentDetails;

  Fulfillment({this.paymentDetails});

  Fulfillment.fromJson(Map<String, dynamic> json) {
    paymentDetails = json['PaymentDetails'];
  }

  Map<String, dynamic> toJson() {
    return {'PaymentDetails': paymentDetails};
  }
}

class Ticketing {
  String? ticketTimeLimit;
  String? ticketingStatus;

  Ticketing({this.ticketTimeLimit, this.ticketingStatus});

  Ticketing.fromJson(Map<String, dynamic> json) {
    ticketTimeLimit = json['@TicketTimeLimit'];
    ticketingStatus = json['@TicketingStatus'];
  }

  Map<String, dynamic> toJson() {
    return {
      '@TicketTimeLimit': ticketTimeLimit,
      '@TicketingStatus': ticketingStatus,
    };
  }
}

class BookingReferenceID {
  String? status;
  String? instance;
  String? iD;
  String? iDContext;

  BookingReferenceID({this.status, this.instance, this.iD, this.iDContext});

  BookingReferenceID.fromJson(Map<String, dynamic> json) {
    status = json['@Status'];
    instance = json['@Instance'];
    iD = json['@ID'];
    iDContext = json['@ID_Context'];
  }

  Map<String, dynamic> toJson() {
    return {
      '@Status': status,
      '@Instance': instance,
      '@ID': iD,
      '@ID_Context': iDContext,
    };
  }
}