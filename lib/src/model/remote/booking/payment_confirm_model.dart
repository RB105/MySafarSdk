class PaymentConfirmModel {
  bool? success;
  Data? data;

  PaymentConfirmModel({this.success, this.data});

  PaymentConfirmModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  Book? book;

  Data({this.book});

  Data.fromJson(Map<String, dynamic> json) {
    book = json['book'] != null ? Book.fromJson(json['book']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (book != null) {
      data['book'] = book!.toJson();
    }
    return data;
  }
}

class Book {
  List<Tickets>? tickets;
  List<PassengersPriceDetails>? passengersPriceDetails;
  Order? order;

  Book({this.tickets, this.passengersPriceDetails, this.order});

  Book.fromJson(Map<String, dynamic> json) {
    if (json['tickets'] != null) {
      tickets = <Tickets>[];
      json['tickets'].forEach((v) {
        tickets!.add(Tickets.fromJson(v));
      });
    }
    if (json['passengers_price_details'] != null) {
      passengersPriceDetails = <PassengersPriceDetails>[];
      json['passengers_price_details'].forEach((v) {
        passengersPriceDetails!.add(PassengersPriceDetails.fromJson(v));
      });
    }
    order = json['order'] != null ? Order.fromJson(json['order']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (tickets != null) {
      data['tickets'] = tickets!.map((v) => v.toJson()).toList();
    }
    if (passengersPriceDetails != null) {
      data['passengers_price_details'] =
          passengersPriceDetails!.map((v) => v.toJson()).toList();
    }
    if (order != null) {
      data['order'] = order!.toJson();
    }
    return data;
  }
}

class Tickets {
  bool? actual;
  Documents? documents;
  String? bookingProvider;
  Provider? provider;
  Carrier? carrier;
  bool? isCertificateIssued;
  List<Passengers>? passengers;

  Tickets(
      {this.actual,
        this.documents,
        this.bookingProvider,
        this.provider,
        this.carrier,
        this.isCertificateIssued,
        this.passengers});

  Tickets.fromJson(Map<String, dynamic> json) {
    actual = json['actual'];
    documents = json['documents'] != null
        ? Documents.fromJson(json['documents'])
        : null;
    bookingProvider = json['booking_provider'];
    provider = json['provider'] != null
        ? Provider.fromJson(json['provider'])
        : null;
    carrier =
    json['carrier'] != null ? Carrier.fromJson(json['carrier']) : null;
    isCertificateIssued = json['is_certificate_issued'];
    if (json['passengers'] != null) {
      passengers = <Passengers>[];
      json['passengers'].forEach((v) {
        passengers!.add(Passengers.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['actual'] = actual;
    if (documents != null) {
      data['documents'] = documents!.toJson();
    }
    data['booking_provider'] = bookingProvider;
    if (provider != null) {
      data['provider'] = provider!.toJson();
    }
    if (carrier != null) {
      data['carrier'] = carrier!.toJson();
    }
    data['is_certificate_issued'] = isCertificateIssued;
    if (passengers != null) {
      data['passengers'] = passengers!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Documents {
  String? ticketReceipt;

  Documents({this.ticketReceipt});

  Documents.fromJson(Map<String, dynamic> json) {
    ticketReceipt = json['ticket_receipt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['ticket_receipt'] = ticketReceipt;
    return data;
  }
}

class Provider {
  String? name;
  String? currency;

  Provider({this.name, this.currency});

  Provider.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    currency = json['currency'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['currency'] = currency;
    return data;
  }
}

class Carrier {
  int? id;
  String? code;
  String? title;

  Carrier({this.id, this.code, this.title});

  Carrier.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    code = json['code'];
    title = json['title'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['code'] = code;
    data['title'] = title;
    return data;
  }
}

class Passengers {
  int? id;
  Name? name;
  String? email;
  String? phone;
  String? gender;
  String? birthdate;
  String? citizenship;
  String? age;
  Document? document;
  String? key;
  String? uuid;
  TicketData? ticketData;

  Passengers(
      {this.id,
        this.name,
        this.email,
        this.phone,
        this.gender,
        this.birthdate,
        this.citizenship,
        this.age,
        this.document,
        this.key,
        this.uuid,
        this.ticketData});

  Passengers.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'] != null ? Name.fromJson(json['name']) : null;
    email = json['email'];
    phone = json['phone'];
    gender = json['gender'];
    birthdate = json['birthdate'];
    citizenship = json['citizenship'];
    age = json['age'];
    document = json['document'] != null
        ? Document.fromJson(json['document'])
        : null;
    key = json['key'];
    uuid = json['uuid'];
    ticketData = json['ticketData'] != null
        ? TicketData.fromJson(json['ticketData'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    if (name != null) {
      data['name'] = name!.toJson();
    }
    data['email'] = email;
    data['phone'] = phone;
    data['gender'] = gender;
    data['birthdate'] = birthdate;
    data['citizenship'] = citizenship;
    data['age'] = age;
    if (document != null) {
      data['document'] = document!.toJson();
    }
    data['key'] = key;
    data['uuid'] = uuid;
    if (ticketData != null) {
      data['ticketData'] = ticketData!.toJson();
    }
    return data;
  }
}

class Name {
  String? first;
  String? middle;
  String? last;

  Name({this.first, this.middle, this.last});

  Name.fromJson(Map<String, dynamic> json) {
    first = json['first'];
    middle = json['middle'];
    last = json['last'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['first'] = first;
    data['middle'] = middle;
    data['last'] = last;
    return data;
  }
}

class Document {
  String? type;
  String? num;
  String? expire;
  String? originalNumber;

  Document({this.type, this.num, this.expire, this.originalNumber});

  Document.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    num = json['num'];
    expire = json['expire'];
    originalNumber = json['original_number'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['num'] = num;
    data['expire'] = expire;
    data['original_number'] = originalNumber;
    return data;
  }
}

class TicketData {
  String? number;
  String? text;
  bool? refunded;

  TicketData({this.number, this.text, this.refunded});

  TicketData.fromJson(Map<String, dynamic> json) {
    number = json['number'];
    text = json['text'];
    refunded = json['refunded'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['number'] = number;
    data['text'] = text;
    data['refunded'] = refunded;
    return data;
  }
}

class PassengersPriceDetails {
  String? key;
  String? uuid;
  int? ticketPrice;

  PassengersPriceDetails({this.key, this.uuid, this.ticketPrice});

  PassengersPriceDetails.fromJson(Map<String, dynamic> json) {
    key = json['key'];
    uuid = json['uuid'];
    ticketPrice = json['ticket_price'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['key'] = key;
    data['uuid'] = uuid;
    data['ticket_price'] = ticketPrice;
    return data;
  }
}

class Order {
  int? orderId;
  int? billingNumber;
  Channel? channel;
  String? sig;
  String? expire;
  int? expireRemain;
  String? created;
  Status? status;
  List<PassengersPriceDetails>? passengersPriceDetails;

  Order(
      {this.orderId,
        this.billingNumber,
        this.channel,
        this.sig,
        this.expire,
        this.expireRemain,
        this.created,
        this.status,
        this.passengersPriceDetails});

  Order.fromJson(Map<String, dynamic> json) {
    orderId = json['order_id'];
    billingNumber = json['billing_number'];
    channel =
    json['channel'] != null ? Channel.fromJson(json['channel']) : null;
    sig = json['sig'];
    expire = json['expire'];
    expireRemain = json['expire_remain'];
    created = json['created'];
    status =
    json['status'] != null ? Status.fromJson(json['status']) : null;
    if (json['passengers_price_details'] != null) {
      passengersPriceDetails = <PassengersPriceDetails>[];
      json['passengers_price_details'].forEach((v) {
        passengersPriceDetails!.add(PassengersPriceDetails.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['order_id'] = orderId;
    data['billing_number'] = billingNumber;
    if (channel != null) {
      data['channel'] = channel!.toJson();
    }
    data['sig'] = sig;
    data['expire'] = expire;
    data['expire_remain'] = expireRemain;
    data['created'] = created;
    if (status != null) {
      data['status'] = status!.toJson();
    }
    if (passengersPriceDetails != null) {
      data['passengers_price_details'] =
          passengersPriceDetails!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Channel {
  String? code;
  Source? source;

  Channel({this.code, this.source});

  Channel.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    source =
    json['source'] != null ? Source.fromJson(json['source']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['code'] = code;
    if (source != null) {
      data['source'] = source!.toJson();
    }
    return data;
  }
}

class Source {
  String? code;

  Source({this.code});

  Source.fromJson(Map<String, dynamic> json) {
    code = json['code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['code'] = code;
    return data;
  }
}

class Status {
  String? sign;
  String? title;

  Status({this.sign, this.title});

  Status.fromJson(Map<String, dynamic> json) {
    sign = json['sign'];
    title = json['title'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['sign'] = sign;
    data['title'] = title;
    return data;
  }
}
