import 'package:mysafar_sdk/src/model/remote/avia/airports_model.dart';

/// Asosiy forma "Qayerdan" maydonining default qiymati — Toshkent (TAS).
class DefaultAirports {
  DefaultAirports._();

  static const String tashkentIata = 'TAS';

  /// Tilga mos Toshkent modeli.
  static AirPortsModel tashkent({String lang = 'uz'}) {
    final code = lang.toLowerCase();
    late final String city;
    late final String country;
    late final String airport;
    if (code.startsWith('ru')) {
      city = 'Ташкент';
      country = 'Узбекистан';
      airport = 'Международный аэропорт Ташкент';
    } else if (code.startsWith('en')) {
      city = 'Tashkent';
      country = 'Uzbekistan';
      airport = 'Tashkent International Airport';
    } else {
      city = 'Toshkent';
      country = 'Oʻzbekiston';
      airport = 'Toshkent xalqaro aeroporti';
    }

    return AirPortsModel(
      countryIataCode: 'UZ',
      countryName: country,
      cityName: city,
      cityIataCode: tashkentIata,
      airports: [
        Airports(airportName: airport, airportIataCode: tashkentIata),
      ],
    );
  }

  static bool isTashkent(AirPortsModel? a) =>
      a?.cityIataCode?.toUpperCase() == tashkentIata;
}
