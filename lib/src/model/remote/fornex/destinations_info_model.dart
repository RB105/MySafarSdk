class DestinationsInfoModel {
  Result? result;
  String? error;

  DestinationsInfoModel({this.result, this.error});

  DestinationsInfoModel.fromJson(Map<String, dynamic> json) {
    result =
    json['result'] != null ? Result.fromJson(json['result']) : null;
    error = json['error'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (result != null) {
      data['result'] = result!.toJson();
    }
    data['error'] = error;
    return data;
  }
}

class Result {
  int? id;
  Name? name;
  String? slug;
  String? aviationCode;
  String? createdAt;
  String? updatedAt;
  dynamic ticketInfo;
  dynamic ticketInfoUpdatedAt;
  List<Places>? places;

  Result(
      {this.id,
        this.name,
        this.slug,
        this.aviationCode,
        this.createdAt,
        this.updatedAt,
        this.ticketInfo,
        this.ticketInfoUpdatedAt,
        this.places});

  Result.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'] != null ? Name.fromJson(json['name']) : null;
    slug = json['slug'];
    aviationCode = json['aviation_code'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    ticketInfo = json['ticket_info'];
    ticketInfoUpdatedAt = json['ticket_info_updated_at'];
    if (json['places'] != null) {
      places = <Places>[];
      json['places'].forEach((v) {
        places!.add(Places.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    if (name != null) {
      data['name'] = name!.toJson();
    }
    data['slug'] = slug;
    data['aviation_code'] = aviationCode;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['ticket_info'] = ticketInfo;
    data['ticket_info_updated_at'] = ticketInfoUpdatedAt;
    if (places != null) {
      data['places'] = places!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Name {
  String? en;
  String? ru;
  String? uz;

  Name({this.en, this.ru, this.uz});

  Name.fromJson(Map<String, dynamic> json) {
    en = json['en'];
    ru = json['ru'];
    uz = json['uz'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['en'] = en;
    data['ru'] = ru;
    data['uz'] = uz;
    return data;
  }
}

class Places {
  int? id;
  int? destinationId;
  Name? name;
  String? slug;
  Name? description;
  Links? links;
  String? longitude;
  String? latitude;
  String? createdAt;
  String? updatedAt;
  List<Images>? images;

  Places(
      {this.id,
        this.destinationId,
        this.name,
        this.slug,
        this.description,
        this.links,
        this.longitude,
        this.latitude,
        this.createdAt,
        this.updatedAt,
        this.images});

  Places.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    destinationId = json['destination_id'];
    name = json['name'] != null ? Name.fromJson(json['name']) : null;
    slug = json['slug'];
    description = json['description'] != null
        ? Name.fromJson(json['description'])
        : null;
    links = json['links'] != null ? Links.fromJson(json['links']) : null;
    longitude = json['longitude'];
    latitude = json['latitude'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    if (json['images'] != null) {
      images = <Images>[];
      json['images'].forEach((v) {
        images!.add(Images.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['destination_id'] = destinationId;
    if (name != null) {
      data['name'] = name!.toJson();
    }
    data['slug'] = slug;
    if (description != null) {
      data['description'] = description!.toJson();
    }
    if (links != null) {
      data['links'] = links!.toJson();
    }
    data['longitude'] = longitude;
    data['latitude'] = latitude;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (images != null) {
      data['images'] = images!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Links {
  String? website;
  String? telegram;
  String? instagram;

  Links({this.website, this.telegram, this.instagram});

  Links.fromJson(Map<String, dynamic> json) {
    website = json['website']??"";
    telegram = json['telegram']??"";
    instagram = json['instagram']??"";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['website'] = website;
    data['telegram'] = telegram;
    data['instagram'] = instagram;
    return data;
  }
}

class Images {
  int? placeId;
  String? image;

  Images({this.placeId, this.image});

  Images.fromJson(Map<String, dynamic> json) {
    placeId = json['place_id'];
    image = json['image'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['place_id'] = placeId;
    data['image'] = image;
    return data;
  }
}
