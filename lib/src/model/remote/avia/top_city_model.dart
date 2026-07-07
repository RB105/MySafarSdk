import 'package:mysafar_sdk/src/model/remote/avia/airports_model.dart'
    show AirPortsModel;

class TopCityModel {
  int? id;
  String? countryFromUz;
  String? countryFromRu;
  String? countryFromEn;
  String? countryToUz;
  String? countryToRu;
  String? countryToEn;
  String? fromCityUz;
  String? fromCityRu;
  String? fromCityEn;
  String? fromIata;
  String? toIata;
  String? toUz;
  String? toRu;
  String? toEn;
  int? priceUzs;
  int? priceRub;
  int? priceUsd;
  bool? isActive;
  String? img;
  int? order;

  TopCityModel({
    this.id,
    this.countryFromUz,
    this.countryFromRu,
    this.countryFromEn,
    this.countryToUz,
    this.countryToRu,
    this.countryToEn,
    this.fromCityUz,
    this.fromCityRu,
    this.fromCityEn,
    this.fromIata,
    this.toIata,
    this.toUz,
    this.toRu,
    this.toEn,
    this.priceUzs,
    this.priceRub,
    this.priceUsd,
    this.isActive,
    this.img,
    this.order,
  });

  TopCityModel.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? 0;
    countryFromUz = json['country_from_uz'] ?? "";
    countryFromRu = json['country_from_ru'] ?? "";
    countryFromEn = json['country_from_en'] ?? "";
    countryToUz = json['country_to_uz'] ?? "";
    countryToRu = json['country_to_ru'] ?? "";
    countryToEn = json['country_to_en'] ?? "";
    fromCityUz = json['from_city_uz'] ?? "";
    fromCityRu = json['from_city_ru'] ?? "";
    fromCityEn = json['from_city_en'] ?? "";
    fromIata = json['from_iata'] ?? "";
    toIata = json['to_iata'] ?? "";
    toUz = json['to_uz'] ?? "";
    toRu = json['to_ru'] ?? "";
    toEn = json['to_en'] ?? "";
    priceUzs = json['price_uzs'] ?? 0;
    priceRub = json['price_rub'] ?? 0;
    priceUsd = json['price_usd'] ?? 0;
    isActive = json['is_active'] ?? false;
    img = json['img'] ?? "";
    order = json['order'] ?? 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['country_from_uz'] = countryFromUz;
    data['country_from_ru'] = countryFromRu;
    data['country_from_en'] = countryFromEn;
    data['country_to_uz'] = countryToUz;
    data['country_to_ru'] = countryToRu;
    data['country_to_en'] = countryToEn;
    data['from_city_uz'] = fromCityUz;
    data['from_city_ru'] = fromCityRu;
    data['from_city_en'] = fromCityEn;
    data['from_iata'] = fromIata;
    data['to_iata'] = toIata;
    data['to_uz'] = toUz;
    data['to_ru'] = toRu;
    data['to_en'] = toEn;
    data['price_uzs'] = priceUzs;
    data['price_rub'] = priceRub;
    data['price_usd'] = priceUsd;
    data['is_active'] = isActive;
    data['img'] = img;
    data['order'] = order;
    return data;
  }

  // Optional: formatted price getter
  String formatPrice(int? price) {
    if (price == null) return "0";
    final str = price.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i != 0 && (str.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  String get formattedPriceUzs => formatPrice(priceUzs);
  String get formattedPriceRub => formatPrice(priceRub);
  String get formattedPriceUsd => formatPrice(priceUsd);
}

extension TopCityToAirports on TopCityModel {
  AirPortsModel getFromByLang(String lang) {
    late String cityName;
    late String cityIataCode;
    late String countryName;
    switch (lang) {
      case 'ru':
        cityName = fromCityRu ?? "";
        cityIataCode = fromIata ?? "";
        countryName = countryFromRu ?? "";
        break;
      case 'en':
        cityName = fromCityEn ?? "";
        cityIataCode = fromIata ?? "";
        countryName = countryToEn ?? "";
        break;
      default:
        cityName = fromCityUz ?? "";
        cityIataCode = fromIata ?? "";
        countryName = countryFromUz ?? "";
    }

    return AirPortsModel(
      cityName: cityName,
      cityIataCode: cityIataCode,
      countryName: countryName,
    );
  }

  AirPortsModel getToByLang(String lang) {
    late String cityName;
    late String cityIataCode;
    late String countryName;
    switch (lang) {
      case 'ru':
        cityName = toRu ?? "";
        cityIataCode = toIata ?? "";
        countryName = countryFromRu ?? "";
        break;
      case 'en':
        cityName = toEn ?? "";
        cityIataCode = toIata ?? "";
        countryName = countryToEn ?? "";
        break;
      default:
        cityName = toUz ?? "";
        cityIataCode = toIata ?? "";
        countryName = countryFromUz ?? "";
    }

    return AirPortsModel(
      cityName: cityName,
      cityIataCode: cityIataCode,
      countryName: countryName,
    );
  }

  AirPortsModel get fromAirportModel {
    return AirPortsModel(
      cityName: fromCityUz,
      cityIataCode: fromIata,
      countryName: countryFromUz,
    );
  }

  AirPortsModel get toAirportModel {
    return AirPortsModel(
      cityName: toUz,
      cityIataCode: toIata,
      countryName: countryToUz,
    );
  }
}
