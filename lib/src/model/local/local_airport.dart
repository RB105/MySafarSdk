/// Asset JSON (`assets/data/airports_iata.json`) dagi bitta aeroport yoki
/// metropolitan shahar kodi (masalan MOW).
class LocalAirport {
  final String icao;
  final String iata;
  final String name;
  final String city;
  final String state;
  final String country;
  final int elevation;
  final double lat;
  final double lon;
  final String tz;
  final Map<String, String> countryNames;
  final Map<String, LocalAirportNames> names;
  final List<String> aliases;

  /// Metropolitan shahar kodi (masalan SVO/DME → MOW).
  final String cityCode;

  /// `true` bo‘lsa bu yozuv alohida aeroport emas, shahar kodi (MOW).
  final bool isCityCode;

  /// Shahar kodiga bog‘langan aeroport IATA lari.
  final List<String> metroAirports;

  /// Qidiruv uchun oldindan normalizatsiya qilingan tokenlar (pastki registr).
  final Set<String> searchTokens;

  const LocalAirport({
    required this.icao,
    required this.iata,
    required this.name,
    required this.city,
    required this.state,
    required this.country,
    required this.elevation,
    required this.lat,
    required this.lon,
    required this.tz,
    required this.countryNames,
    required this.names,
    required this.aliases,
    required this.cityCode,
    required this.isCityCode,
    required this.metroAirports,
    required this.searchTokens,
  });

  factory LocalAirport.fromJson(Map<String, dynamic> json) {
    final countryNamesRaw =
        (json['country_names'] as Map?)?.cast<String, dynamic>() ?? const {};
    final countryNames = countryNamesRaw.map(
      (k, v) => MapEntry(k, v?.toString() ?? ''),
    );

    final namesRaw = (json['names'] as Map?)?.cast<String, dynamic>() ?? {};
    final names = <String, LocalAirportNames>{};
    for (final entry in namesRaw.entries) {
      final m = (entry.value as Map?)?.cast<String, dynamic>() ?? {};
      names[entry.key] = LocalAirportNames.fromJson(m);
    }

    final aliases = (json['aliases'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];

    final metroAirports = (json['metro_airports'] as List?)
            ?.map((e) => e.toString().toUpperCase())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];

    final cityCode = (json['city_code']?.toString() ?? '').toUpperCase();
    final iata = json['iata']?.toString() ?? '';

    final tokens = <String>{...aliases};
    for (final a in aliases) {
      for (final part in a.split(RegExp(r'\s+'))) {
        if (part.length >= 2) tokens.add(part);
      }
    }
    if (cityCode.isNotEmpty) {
      tokens.add(cityCode.toLowerCase());
    }

    return LocalAirport(
      icao: json['icao']?.toString() ?? '',
      iata: iata,
      name: json['name']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      elevation: (json['elevation'] as num?)?.toInt() ?? 0,
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0,
      tz: json['tz']?.toString() ?? '',
      countryNames: countryNames,
      names: names,
      aliases: aliases,
      cityCode: cityCode,
      isCityCode: json['is_city_code'] == true,
      metroAirports: metroAirports,
      searchTokens: tokens,
    );
  }

  LocalAirportNames localizedNames(String lang) {
    final code = _lang(lang);
    return names[code] ??
        names['en'] ??
        LocalAirportNames(city: city, state: state, airport: name);
  }

  String localizedCity(String lang) => localizedNames(lang).city;

  String localizedAirport(String lang) {
    final n = localizedNames(lang).airport;
    return n.isNotEmpty ? n : name;
  }

  String localizedCountry(String lang) {
    final code = _lang(lang);
    return countryNames[code] ?? countryNames['en'] ?? country;
  }

  String localizedState(String lang) => localizedNames(lang).state;

  /// Guruhlash / tanlash uchun shahar IATA: metropolitan kod yoki o‘zi.
  String get effectiveCityIata {
    if (cityCode.isNotEmpty) return cityCode;
    if (isCityCode && iata.isNotEmpty) return iata.toUpperCase();
    return iata.toUpperCase();
  }

  static String _lang(String lang) {
    final l = lang.toLowerCase();
    if (l.startsWith('uz')) return 'uz';
    if (l.startsWith('ru')) return 'ru';
    return 'en';
  }
}

class LocalAirportNames {
  final String city;
  final String state;
  final String airport;

  const LocalAirportNames({
    required this.city,
    required this.state,
    required this.airport,
  });

  factory LocalAirportNames.fromJson(Map<String, dynamic> json) {
    return LocalAirportNames(
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      airport: json['airport']?.toString() ?? '',
    );
  }
}
