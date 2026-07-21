import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/services.dart' show rootBundle;
import 'package:mysafar_sdk/src/model/local/local_airport.dart';
import 'package:mysafar_sdk/src/model/remote/avia/airports_model.dart';

/// Offline multi-language airport search (en / ru / uz).
///
/// Qidiradi: IATA/ICAO, shahar, aeroport nomi, viloyat, davlat nomi va
/// JSON dagi `aliases` (masalan: "qoraqalpogiston" → Nukus, "MOW" → Moskva).
class AirportLocalSearchService {
  AirportLocalSearchService._();
  static final AirportLocalSearchService instance =
      AirportLocalSearchService._();
  factory AirportLocalSearchService() => instance;

  static const _assetPath = 'packages/mysafar_sdk/assets/data/airports_iata.json';

  /// O'zbekistondan eng ko'p uchiladigan yo'nalishlar (yuqoridagi — ustunroq).
  /// "M" → Moskva, "I" → Istanbul birinchi chiqishi uchun.
  static const List<String> _popularFromUz = [
    'MOW', // Moskva (barcha)
    'IST', // Istanbul
    'SAW', // Istanbul Sabiha
    'DXB', // Dubai
    'AYT', // Antalya
    'ALA', // Almaty
    'NQZ', // Astana
    'LED', // Sankt-Peterburg
    'SVO',
    'DME',
    'VKO',
    'FRU', // Bishkek
    'DYU', // Dushanbe
    'ASB', // Ashgabat
    'GYD', // Baku
    'ESB', // Ankara
    'ADB', // Izmir
    'AUH',
    'SHJ',
    'DOH',
    'JED',
    'MED',
    'RUH',
    'DEL',
    'BOM',
    'BKK',
    'ICN',
    'NRT',
    'HND',
    'KUL',
    'SIN',
    'PEK',
    'PVG',
    'FRA',
    'CDG',
    'LHR',
    'TAS', // Toshkent (qidiruvda ham yuqori)
    'SKD',
    'BHK',
    'UGC',
    'FEG',
    'NMA',
    'AZN',
    'NVI',
    'KSQ',
    'TMJ',
    'NCU',
  ];

  /// Shahar guruhlash: bir nechta aeroport bitta shahar kodiga.
  static const Map<String, String> _cityMergeTo = {
    'arnavutkoy': 'IST',
    'istanbul': 'IST',
    'moscow': 'MOW',
    'moskva': 'MOW',
    'dubai': 'DXB',
    'dubay': 'DXB',
    'almaty': 'ALA',
    'olmaota': 'ALA',
    'astana': 'NQZ',
    'ostona': 'NQZ',
    'tashkent': 'TAS',
    'toshkent': 'TAS',
  };

  List<LocalAirport>? _airports;
  Map<String, LocalAirport>? _byIata;
  bool _loading = false;
  Future<void>? _loadFuture;

  bool get isReady => _airports != null;

  /// Assetni bir marta yuklaydi (idempotent).
  Future<void> ensureLoaded() {
    if (_airports != null) return Future.value();
    if (_loadFuture != null) return _loadFuture!;
    _loadFuture = _load();
    return _loadFuture!;
  }

  Future<void> _load() async {
    if (_loading || _airports != null) return;
    _loading = true;
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw StateError('airports_iata.json must be a JSON object');
      }
      final list = <LocalAirport>[];
      final byIata = <String, LocalAirport>{};
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is! Map) continue;
        final airport =
            LocalAirport.fromJson(Map<String, dynamic>.from(value));
        if (airport.iata.trim().isEmpty) continue;
        list.add(airport);
        byIata[airport.iata.toUpperCase()] = airport;
      }
      _airports = list;
      _byIata = byIata;
      if (kDebugMode) {
        debugPrint(
          'AirportLocalSearchService: loaded ${list.length} airports',
        );
      }
    } catch (e, st) {
      debugPrint('AirportLocalSearchService load error: $e\n$st');
      _airports = const [];
      _byIata = const {};
    } finally {
      _loading = false;
    }
  }

  /// Elastic-like qidiruv. Natijalar shahar / metro kod bo‘yicha guruhlanadi.
  Future<List<AirPortsModel>> search({
    required String query,
    String lang = 'en',
    int limit = 40,
  }) async {
    await ensureLoaded();
    final airports = _airports;
    final byIata = _byIata;
    if (airports == null || airports.isEmpty || byIata == null) {
      return const [];
    }

    final q = normalize(query);
    if (q.isEmpty) return const [];

    final scored = <_ScoredAirport>[];
    for (final a in airports) {
      final score = _score(a, q, lang);
      if (score > 0) {
        scored.add(_ScoredAirport(a, score));
      }
    }

    if (scored.isEmpty) return const [];

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      // Mashhur yo'nalish oldin
      final pop = _popularRank(b.airport).compareTo(_popularRank(a.airport));
      if (pop != 0) return pop;
      // Shahar kodlari (MOW) oddiy aeroportdan oldin
      if (a.airport.isCityCode != b.airport.isCityCode) {
        return a.airport.isCityCode ? -1 : 1;
      }
      return a.airport.localizedCity(lang).compareTo(
            b.airport.localizedCity(lang),
          );
    });

    // Shahar + davlat (yoki city_code) bo‘yicha guruhlash
    final groups = <String, _CityGroup>{};
    final maxScan = scored.length < 400 ? scored.length : 400;

    for (var i = 0; i < maxScan; i++) {
      final item = scored[i];
      final a = item.airport;

      final groupKey = _groupKey(a);
      final preferredCityIata = _preferredCityIata(a);

      final group = groups.putIfAbsent(
        groupKey,
        () => _CityGroup(
          country: a.country,
          countryName: a.localizedCountry(lang),
          cityName: a.localizedCity(lang),
          cityIata: preferredCityIata,
          bestScore: item.score,
          airports: [],
        ),
      );

      if (item.score > group.bestScore) {
        group.bestScore = item.score;
        // Yaxshiroq shahar nomi (Arnavutkoy o'rniga Istanbul)
        final nice = a.localizedCity(lang);
        if (nice.isNotEmpty &&
            (group.cityName.isEmpty ||
                a.isCityCode ||
                _popularRank(a) < 50)) {
          group.cityName = nice;
        }
      }
      // Metropolitan / preferred kod ustun
      if (a.isCityCode ||
          preferredCityIata.length == 3 &&
              _popularRankCode(preferredCityIata) <
                  _popularRankCode(group.cityIata)) {
        group.cityIata = preferredCityIata;
      }

      if (a.isCityCode) {
        // MOW kabi: barcha metro aeroportlarni ichiga qo‘shamiz
        for (final code in a.metroAirports) {
          final child = byIata[code];
          if (child == null || child.isCityCode) continue;
          group.airports.add(
            Airports(
              airportName: child.localizedAirport(lang),
              airportIataCode: child.iata,
            ),
          );
        }
        // Agar metro ro‘yxat bo‘sh bo‘lsa, o‘zini qo‘shamiz
        if (a.metroAirports.isEmpty) {
          group.airports.add(
            Airports(
              airportName: a.localizedAirport(lang),
              airportIataCode: a.iata,
            ),
          );
        }
      } else {
        group.airports.add(
          Airports(
            airportName: a.localizedAirport(lang),
            airportIataCode: a.iata,
          ),
        );
        // Agar bu aeroport metro guruhga tegishli bo‘lsa — qolganlarini ham
        // to‘ldirish (birinchi marta topilganda).
        if (a.cityCode.isNotEmpty && group.airports.length == 1) {
          final metro = byIata[a.cityCode];
          if (metro != null && metro.isCityCode) {
            group.cityIata = metro.iata.toUpperCase();
            group.cityName = metro.localizedCity(lang);
            for (final code in metro.metroAirports) {
              final child = byIata[code];
              if (child == null) continue;
              group.airports.add(
                Airports(
                  airportName: child.localizedAirport(lang),
                  airportIataCode: child.iata,
                ),
              );
            }
          }
        }
      }

      if (groups.length >= limit && i > 50) break;
    }

    final ordered = groups.values.toList()
      ..sort((a, b) {
        final byScore = b.bestScore.compareTo(a.bestScore);
        if (byScore != 0) return byScore;
        return _popularRankCode(a.cityIata)
            .compareTo(_popularRankCode(b.cityIata));
      });

    return ordered.take(limit).map((g) {
      final unique = <String, Airports>{};
      for (final ap in g.airports) {
        final code = (ap.airportIataCode ?? '').toUpperCase();
        if (code.isEmpty) continue;
        // Shahar kodi o‘zini nested listga qayta qo‘ymaymiz
        if (code == g.cityIata.toUpperCase() && unique.isNotEmpty) continue;
        unique.putIfAbsent(code, () => ap);
      }
      // city code yozuvi nestedda qolmasin (MOW o‘zi aeroport emas)
      unique.remove(g.cityIata.toUpperCase());

      return AirPortsModel(
        countryIataCode: g.country,
        countryName: g.countryName,
        cityName: g.cityName,
        cityIataCode: g.cityIata,
        airports: unique.values.toList(),
      );
    }).toList();
  }

  String _groupKey(LocalAirport a) {
    if (a.cityCode.isNotEmpty) {
      return '${a.country}|city:${a.cityCode}';
    }
    if (a.isCityCode) {
      return '${a.country}|city:${a.iata.toUpperCase()}';
    }
    final enCity = normalize(
      (a.names['en']?.city.isNotEmpty == true)
          ? a.names['en']!.city
          : a.city,
    );
    final merge = _cityMergeTo[enCity];
    if (merge != null) {
      return '${a.country}|city:$merge';
    }
    // localized names ham merge (uz: Dubay, Moskva)
    final uzCity = normalize(a.names['uz']?.city ?? '');
    final ruCity = normalize(a.names['ru']?.city ?? '');
    for (final c in [uzCity, ruCity, normalize(a.city)]) {
      final m = _cityMergeTo[c];
      if (m != null) return '${a.country}|city:$m';
    }
    return '${a.country}|$enCity';
  }

  String _preferredCityIata(LocalAirport a) {
    if (a.isCityCode && a.iata.isNotEmpty) return a.iata.toUpperCase();
    if (a.cityCode.isNotEmpty) return a.cityCode;
    final enCity = normalize(
      (a.names['en']?.city.isNotEmpty == true)
          ? a.names['en']!.city
          : a.city,
    );
    return _cityMergeTo[enCity] ??
        _cityMergeTo[normalize(a.names['uz']?.city ?? '')] ??
        a.iata.toUpperCase();
  }

  /// 0 = eng mashhur, katta son = oddiy.
  int _popularRank(LocalAirport a) {
    final codes = <String>{
      a.iata.toUpperCase(),
      if (a.cityCode.isNotEmpty) a.cityCode,
      _preferredCityIata(a),
    };
    var best = 9999;
    for (final c in codes) {
      final r = _popularRankCode(c);
      if (r < best) best = r;
    }
    return best;
  }

  int _popularRankCode(String code) {
    final i = _popularFromUz.indexOf(code.toUpperCase());
    return i < 0 ? 9999 : i;
  }

  /// Mashhur yo'nalish bonus (index 0 → eng katta).
  int _popularBoost(LocalAirport a) {
    final rank = _popularRank(a);
    if (rank >= 9999) return 0;
    return 5000 - rank * 40;
  }

  int _score(LocalAirport a, String q, String lang) {
    final iata = a.iata.toLowerCase();
    final icao = a.icao.toLowerCase();
    final cityCode = a.cityCode.toLowerCase();
    final boost = _popularBoost(a);

    // Exact IATA / ICAO / city code (MOW)
    if (iata == q) return (a.isCityCode ? 11000 : 10000) + boost;
    if (cityCode.isNotEmpty && cityCode == q) return 10500 + boost;
    if (icao.isNotEmpty && icao == q) return 9500 + boost;
    // 1+ harf: IATA prefiks
    if (q.isNotEmpty && iata.startsWith(q)) {
      return (a.isCityCode ? 9200 : 9000) + q.length * 10 + boost;
    }
    if (q.isNotEmpty && cityCode.isNotEmpty && cityCode.startsWith(q)) {
      return 9100 + q.length * 10 + boost;
    }
    if (q.isNotEmpty && icao.isNotEmpty && icao.startsWith(q)) {
      return 8800 + q.length * 10 + boost;
    }

    final city = normalize(a.localizedCity(lang));
    final cityEn = normalize(
      (a.names['en']?.city.isNotEmpty == true)
          ? a.names['en']!.city
          : a.city,
    );
    final cityRaw = normalize(a.city);
    final airport = normalize(a.localizedAirport(lang));
    final airportEn = normalize(a.name);
    final state = normalize(a.localizedState(lang));
    final stateEn = normalize(a.state);
    final country = normalize(a.localizedCountry(lang));
    final countryEn = normalize(a.countryNames['en'] ?? '');
    final countryRu = normalize(a.countryNames['ru'] ?? '');
    final countryUz = normalize(a.countryNames['uz'] ?? '');

    int best = 0;

    void consider(String field, int base) {
      if (field.isEmpty) return;
      if (field == q) {
        best = best < base + 500 ? base + 500 : best;
      } else if (field.startsWith(q)) {
        best = best < base + 300 ? base + 300 : best;
      } else if (field.contains(q)) {
        best = best < base + 100 ? base + 100 : best;
      }
    }

    consider(city, 7000);
    consider(cityEn, 6950);
    consider(cityRaw, 6900);
    consider(airport, 6000);
    consider(airportEn, 5900);
    consider(state, 5000);
    consider(stateEn, 4900);
    consider(country, 4000);
    consider(countryEn, 4000);
    consider(countryRu, 4000);
    consider(countryUz, 4000);
    consider(normalize(a.country), 3500);

    if (a.searchTokens.contains(q)) {
      best = best < 7500 ? 7500 : best;
    } else {
      for (final t in a.searchTokens) {
        if (q.isNotEmpty && t.startsWith(q)) {
          // 1 harf: mashhur aliaslar (moscow, istanbul) ham ishlasin
          if (q.length >= 2 || t.length >= 3 || boost > 0) {
            best = best < 7200 ? 7200 : best;
            break;
          }
        }
        if (q.length >= 3 && t.contains(q)) {
          best = best < 5500 ? 5500 : best;
          break;
        }
      }
    }

    final parts = q.split(RegExp(r'\s+')).where((p) => p.length >= 2).toList();
    if (parts.length > 1) {
      final hay = StringBuffer()
        ..write(city)
        ..write(' ')
        ..write(cityEn)
        ..write(' ')
        ..write(airport)
        ..write(' ')
        ..write(state)
        ..write(' ')
        ..write(country)
        ..write(' ')
        ..write(countryEn)
        ..write(' ')
        ..write(countryRu)
        ..write(' ')
        ..write(countryUz)
        ..write(' ')
        ..write(a.searchTokens.join(' '));
      final hayStr = hay.toString();
      if (parts.every((p) => hayStr.contains(p))) {
        best = best < 6800 ? 6800 : best;
      }
    }

    if (best <= 0) return 0;
    return best + boost;
  }

  /// Qidiruv normalizatsiyasi: lower, diacritic, apostrof olib tashlash.
  static String normalize(String input) {
    if (input.isEmpty) return '';
    var s = input.trim().toLowerCase();
    const apostrophes = ['ʻ', 'ʼ', "'", '`', '’', '‘', 'ʹ', '´'];
    for (final ch in apostrophes) {
      s = s.replaceAll(ch, '');
    }
    s = s.replaceAllMapped(
      RegExp(r'[\u0300-\u036f]'),
      (_) => '',
    );
    const map = {
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'ã': 'a',
      'å': 'a',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',
      'ñ': 'n',
      'ç': 'c',
      'ş': 's',
      'ğ': 'g',
      'ı': 'i',
      'ə': 'e',
    };
    final buf = StringBuffer();
    for (final r in s.runes) {
      final ch = String.fromCharCode(r);
      buf.write(map[ch] ?? ch);
    }
    s = buf.toString();
    s = s.replaceAll(
      RegExp(r'[^\p{L}\p{N}\s\-]+', unicode: true),
      ' ',
    );
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }
}

class _ScoredAirport {
  final LocalAirport airport;
  final int score;
  _ScoredAirport(this.airport, this.score);
}

class _CityGroup {
  final String country;
  final String countryName;
  String cityName;
  String cityIata;
  int bestScore;
  final List<Airports> airports;

  _CityGroup({
    required this.country,
    required this.countryName,
    required this.cityName,
    required this.cityIata,
    required this.bestScore,
    required this.airports,
  });
}
