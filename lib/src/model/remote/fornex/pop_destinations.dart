class PopDestinationsModel {
  final int id;
  final int destinationId;
  final PopDestinationsText name;
  final String slug;
  final PopDestinationsText description;
  final PopDestinationsLinks links;
  final String longitude;
  final String latitude;
  final String createdAt;
  final String updatedAt;
  final PopularDestination destination;
  final List<ImageModel> images;

  PopDestinationsModel({
    required this.id,
    required this.destinationId,
    required this.name,
    required this.slug,
    required this.description,
    required this.links,
    required this.longitude,
    required this.latitude,
    required this.createdAt,
    required this.updatedAt,
    required this.destination,
    required this.images,
  });

  factory PopDestinationsModel.fromJson(Map<String, dynamic> json) {
    return PopDestinationsModel(
      id: json['id'],
      destinationId: json['destination_id'],
      name: PopDestinationsText.fromJson(json['name']),
      slug: json['slug'],
      description: PopDestinationsText.fromJson(json['description']),
      links: PopDestinationsLinks.fromJson(json['links']),
      longitude: json['longitude'],
      latitude: json['latitude'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      destination: PopularDestination.fromJson(json['destination']),
      images:
          (json['images'] as List).map((e) => ImageModel.fromJson(e)).toList(),
    );
  }
}

class PopDestinationsText {
  final String en;
  final String ru;
  final String uz;

  PopDestinationsText({required this.en, required this.ru, required this.uz});

  factory PopDestinationsText.fromJson(Map<String, dynamic> json) {
    return PopDestinationsText(
      en: json['en'] ?? '',
      ru: json['ru'] ?? '',
      uz: json['uz'] ?? '',
    );
  }
}

class PopDestinationsLinks {
  final String? website;
  final String? telegram;
  final String? instagram;

  PopDestinationsLinks({this.website, this.telegram, this.instagram});

  factory PopDestinationsLinks.fromJson(Map<String, dynamic> json) {
    return PopDestinationsLinks(
      website: json['website'],
      telegram: json['telegram'],
      instagram: json['instagram'],
    );
  }
}

class PopularDestination {
  final int id;
  final PopDestinationsText name;
  final String slug;
  final String aviationCode;

  PopularDestination({
    required this.id,
    required this.name,
    required this.slug,
    required this.aviationCode,
  });

  factory PopularDestination.fromJson(Map<String, dynamic> json) {
    return PopularDestination(
      id: json['id'],
      name: PopDestinationsText.fromJson(json['name']),
      slug: json['slug'],
      aviationCode: json['aviation_code'],
    );
  }
}

class ImageModel {
  final int placeId;
  final String image;

  ImageModel({required this.placeId, required this.image});

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      placeId: json['place_id'],
      image: json['image'],
    );
  }
}
