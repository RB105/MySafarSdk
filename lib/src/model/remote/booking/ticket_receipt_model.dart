
class TicketReceiptModel {
  String locator;
  List<String> vndLocators;
  String bookingOfficeId;
  String receiptText;
  bool actual;
  Documents documents;
  String bookingProvider;
  Provider provider;
  Carrier carrier;
  Duration duration;
  List<Passenger> passengers;
  dynamic specialTariffType;
  String fareFamilyMarketingName;

  TicketReceiptModel({
    required this.locator,
    required this.vndLocators,
    required this.bookingOfficeId,
    required this.receiptText,
    required this.actual,
    required this.documents,
    required this.bookingProvider,
    required this.provider,
    required this.carrier,
    required this.duration,
    required this.passengers,
    required this.specialTariffType,
    required this.fareFamilyMarketingName,
  });

  factory TicketReceiptModel.fromJson(Map<String, dynamic> json) =>
      TicketReceiptModel(
        locator: json["locator"],
        vndLocators: json["vnd_locators"] != null
            ? List<String>.from(json["vnd_locators"].map((x) => x))
            : [],
        bookingOfficeId: json["booking_office_id"],
        receiptText: json["receipt_text"],
        actual: json["actual"],
        documents: Documents.fromJson(json["documents"]),
        bookingProvider: json["booking_provider"],
        provider: Provider.fromJson(json["provider"]),
        carrier: Carrier.fromJson(json["carrier"]),
        duration: Duration.fromJson(json["duration"]),
        passengers: json["passengers"] != null
            ? List<Passenger>.from(
                json["passengers"].map((x) => Passenger.fromJson(x)))
            : [],
        specialTariffType: json["special_tariff_type"]??"",
        fareFamilyMarketingName: json["fare_family_marketing_name"]??"",
      );

  Map<String, dynamic> toJson() => {
        "locator": locator,
        "vnd_locators": List<dynamic>.from(vndLocators.map((x) => x)),
        "booking_office_id": bookingOfficeId,
        "receipt_text": receiptText,
        "actual": actual,
        "documents": documents.toJson(),
        "booking_provider": bookingProvider,
        "provider": provider.toJson(),
        "carrier": carrier.toJson(),
        "duration": duration.toJson(),
        "passengers": List<dynamic>.from(passengers.map((x) => x.toJson())),
        "special_tariff_type": specialTariffType,
        "fare_family_marketing_name": fareFamilyMarketingName,
      };
}

class Carrier {
  int id;
  String code;
  String title;

  Carrier({
    required this.id,
    required this.code,
    required this.title,
  });

  factory Carrier.fromJson(Map<String, dynamic> json) => Carrier(
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

class Documents {
  String ticketReceipt;

  Documents({
    required this.ticketReceipt,
  });

  factory Documents.fromJson(Map<String, dynamic> json) => Documents(
        ticketReceipt: json["ticket_receipt"],
      );

  Map<String, dynamic> toJson() => {
        "ticket_receipt": ticketReceipt,
      };
}

class Duration {
  Flight flight;

  Duration({
    required this.flight,
  });

  factory Duration.fromJson(Map<String, dynamic> json) => Duration(
        flight: Flight.fromJson(json["flight"]),
      );

  Map<String, dynamic> toJson() => {
        "flight": flight.toJson(),
      };
}

class Flight {
  int common;
  int hour;
  int minute;

  Flight({
    required this.common,
    required this.hour,
    required this.minute,
  });

  factory Flight.fromJson(Map<String, dynamic> json) => Flight(
        common: json["common"],
        hour: json["hour"],
        minute: json["minute"],
      );

  Map<String, dynamic> toJson() => {
        "common": common,
        "hour": hour,
        "minute": minute,
      };
}

class Passenger {
  int id;
  Name name;
  String email;
  String phone;
  String gender;
  String birthdate;
  String citizenship;
  String age;
  Document document;
  TicketData ticketData;
  dynamic bonusCard;
  String key;
  String uuid;
  List<dynamic> insurances;
  List<dynamic> accompanyingAdults;

  Passenger({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.gender,
    required this.birthdate,
    required this.citizenship,
    required this.age,
    required this.document,
    required this.ticketData,
    required this.bonusCard,
    required this.key,
    required this.uuid,
    required this.insurances,
    required this.accompanyingAdults,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) => Passenger(
        id: json["id"],
        name: Name.fromJson(json["name"]),
        email: json["email"],
        phone: json["phone"],
        gender: json["gender"],
        birthdate: json["birthdate"],
        citizenship: json["citizenship"],
        age: json["age"],
        document: Document.fromJson(json["document"]),
        ticketData: TicketData.fromJson(json["ticketData"]),
        bonusCard: json["bonus_card"]??"",
        key: json["key"],
        uuid: json["uuid"],
        insurances: List<dynamic>.from(json["insurances"].map((x) => x)),
        accompanyingAdults:
            List<dynamic>.from(json["accompanying_adults"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name.toJson(),
        "email": email,
        "phone": phone,
        "gender": gender,
        "birthdate": birthdate,
        "citizenship": citizenship,
        "age": age,
        "document": document.toJson(),
        "ticketData": ticketData.toJson(),
        "bonus_card": bonusCard,
        "key": key,
        "uuid": uuid,
        "insurances": List<dynamic>.from(insurances.map((x) => x)),
        "accompanying_adults":
            List<dynamic>.from(accompanyingAdults.map((x) => x)),
      };
}

class Document {
  String type;
  String num;
  String originalNumber;
  DateTime expire;

  Document({
    required this.type,
    required this.num,
    required this.originalNumber,
    required this.expire,
  });

  factory Document.fromJson(Map<String, dynamic> json) => Document(
        type: json["type"],
        num: json["num"],
        originalNumber: json["original_number"],
        expire: json["expire"] != null
            ? (DateTime.tryParse(json["expire"]) ??
                DateTime.fromMillisecondsSinceEpoch(0))
            : DateTime.fromMillisecondsSinceEpoch(0),
      );

  Map<String, dynamic> toJson() => {
        "type": type,
        "num": num,
        "original_number": originalNumber,
        "expire": expire.toIso8601String(),
      };
}

class Name {
  String first;
  String middle;
  String last;

  Name({
    required this.first,
    required this.middle,
    required this.last,
  });

  factory Name.fromJson(Map<String, dynamic> json) => Name(
        first: json["first"],
        middle: json["middle"],
        last: json["last"],
      );

  Map<String, dynamic> toJson() => {
        "first": first,
        "middle": middle,
        "last": last,
      };
}

class TicketData {
  String number;
  String text;
  bool refunded;

  TicketData({
    required this.number,
    required this.text,
    required this.refunded,
  });

  factory TicketData.fromJson(Map<String, dynamic> json) => TicketData(
        number: json["number"],
        text: json["text"]??"",
        refunded: json["refunded"],
      );

  Map<String, dynamic> toJson() => {
        "number": number,
        "text": text,
        "refunded": refunded,
      };
}

class Provider {
  String name;
  String currency;

  Provider({
    required this.name,
    required this.currency,
  });

  factory Provider.fromJson(Map<String, dynamic> json) => Provider(
        name: json["name"],
        currency: json["currency"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "currency": currency,
      };
}
