import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/services.dart' show rootBundle;
import 'package:mysafar_sdk/src/model/local/local_airport.dart';
import 'package:mysafar_sdk/src/model/remote/avia/airports_model.dart';

/// Offline multi-language airport search (en / ru / uz).
///
/// Qidiradi: IATA/ICAO, shahar, aeroport nomi, viloyat, davlat nomi va
/// JSON dagi `aliases` (masalan: "qoraqalpogiston" → Nukus, "MOW" → Moskva).
///
/// Og‘ir skoring alohida isolate’da ishlaydi — UI (klaviatura) qotmaydi.
class AirportLocalSearchService {
  AirportLocalSearchService._();
  static final AirportLocalSearchService instance =
      AirportLocalSearchService._();
  factory AirportLocalSearchService() => instance;

  static const _assetPath = 'packages/mysafar_sdk/assets/data/airports_iata.json';

  /// Yo'lovchi reysi bor aeroportlar ro'yxati (`rank`: 1..4, katta = yirikroq).
  static const _rankAssetPath =
      'packages/mysafar_sdk/assets/data/airportsSearch.json';

  /// Backend katalogi — `/avia/airports-mobile` bilgan IATA kodlar.
  static const _catalogueAssetPath =
      'packages/mysafar_sdk/assets/data/airports_api_codes.json';

  SendPort? _workerSend;
  ReceivePort? _responsePort;
  Future<void>? _loadFuture;
  var _nextRequestId = 0;
  final _pending = <int, Completer<List<Map<String, dynamic>>>>{};
  var _ready = false;

  bool get isReady => _ready && _responsePort != null;

  /// Assetni bir marta yuklaydi (idempotent).
  Future<void> ensureLoaded() {
    return _loadFuture ??= _initWorker();
  }

  Future<void> _initWorker() async {
    final raw = await rootBundle.loadString(_assetPath);
    final ranksRaw = await rootBundle.loadString(_rankAssetPath);
    String catalogueRaw = '{}';
    try {
      catalogueRaw = await rootBundle.loadString(_catalogueAssetPath);
    } catch (e) {
      debugPrint('AirportLocalSearchService catalogue asset missing: $e');
    }
    final responsePort = ReceivePort();
    _responsePort = responsePort;

    final handshake = Completer<SendPort>();
    final ready = Completer<void>();

    responsePort.listen((message) {
      if (message is SendPort) {
        if (!handshake.isCompleted) handshake.complete(message);
        return;
      }
      if (message is! Map) return;
      final type = message['type'];
      if (type == 'ready') {
        _ready = true;
        if (kDebugMode) {
          debugPrint(
            'AirportLocalSearchService: loaded ${message['count']} airports, '
            '${message['rankCount']} ranks, '
            '${message['catalogueCount']} catalogue (worker)',
          );
        }
        if (!ready.isCompleted) ready.complete();
      } else if (type == 'result') {
        final id = message['id'] as int;
        final rawList = message['data'];
        final list = <Map<String, dynamic>>[];
        if (rawList is List) {
          for (final item in rawList) {
            if (item is Map) {
              list.add(Map<String, dynamic>.from(item));
            }
          }
        }
        _pending.remove(id)?.complete(list);
      } else if (type == 'error') {
        final id = message['id'];
        final err = message['error']?.toString() ?? 'search error';
        if (id is int) {
          _pending.remove(id)?.completeError(StateError(err));
        } else if (!ready.isCompleted) {
          ready.completeError(StateError(err));
        }
        debugPrint('AirportLocalSearchService worker error: $err');
      }
    });

    await Isolate.spawn(
      _airportSearchWorkerMain,
      responsePort.sendPort,
      debugName: 'airport_local_search',
    );

    _workerSend = await handshake.future;
    _workerSend!.send(<String, dynamic>{
      'type': 'load',
      'json': raw,
      'ranksJson': ranksRaw,
      'catalogueJson': catalogueRaw,
    });
    await ready.future;
  }

  Future<List<AirPortsModel>> _requestResults(Map<String, dynamic> payload) async {
    await ensureLoaded();
    final send = _workerSend;
    if (send == null || !_ready) return const [];

    final id = ++_nextRequestId;
    final completer = Completer<List<Map<String, dynamic>>>();
    _pending[id] = completer;
    send.send(<String, dynamic>{...payload, 'id': id});

    try {
      final maps = await completer.future;
      return maps.map(AirPortsModel.fromJson).toList(growable: false);
    } catch (e, st) {
      debugPrint('AirportLocalSearchService error: $e\n$st');
      return const [];
    }
  }

  /// Elastic-like qidiruv. Natijalar shahar / metro kod bo‘yicha guruhlanadi.
  Future<List<AirPortsModel>> search({
    required String query,
    String lang = 'en',
    int limit = 40,
  }) async {
    return _requestResults(<String, dynamic>{
      'type': 'search',
      'query': query,
      'lang': lang,
      'limit': limit,
    });
  }

  /// Koordinata bo'yicha eng yaqin aeroportlar (JSON dagi `lat`/`lon`).
  Future<List<AirPortsModel>> searchByCoordinates({
    required double lat,
    required double lon,
    String lang = 'en',
    int limit = 5,
    double maxDistanceKm = 400,
  }) async {
    return _requestResults(<String, dynamic>{
      'type': 'searchByCoordinates',
      'lat': lat,
      'lon': lon,
      'lang': lang,
      'limit': limit,
      'maxDistanceKm': maxDistanceKm,
    });
  }

  /// Faqat davlat bo'yicha qidiruv (JSON dan).
  Future<List<AirPortsModel>> searchByCountry({
    required String country,
    String lang = 'en',
    int limit = 40,
  }) async {
    return _requestResults(<String, dynamic>{
      'type': 'searchByCountry',
      'country': country,
      'lang': lang,
      'limit': limit,
    });
  }

  /// Qidiruv normalizatsiyasi: lower, diacritic, apostrof olib tashlash.
  static String normalize(String input) => _normalize(input);
}

// ---------------------------------------------------------------------------
// Worker isolate
// ---------------------------------------------------------------------------

@pragma('vm:entry-point')
void _airportSearchWorkerMain(SendPort mainSend) {
  final inbox = ReceivePort();
  mainSend.send(inbox.sendPort);

  List<_IndexedAirport>? airports;
  Map<String, _IndexedAirport>? byIata;
  Map<String, int>? ranks;
  Map<String, String> apiCatalogue = const {};
  Map<String, List<String>> apiCity = const {};

  inbox.listen((message) {
    if (message is! Map) return;
    final type = message['type'];
    try {
      if (type == 'load') {
        final jsonStr = message['json'] as String;
        final ranksJsonStr = message['ranksJson'] as String? ?? '[]';
        final catalogueJsonStr = message['catalogueJson'] as String? ?? '{}';
        ranks = _parseRanks(ranksJsonStr);
        final parsed = _parseAndIndex(jsonStr);
        airports = parsed.$1;
        byIata = parsed.$2;
        final catalogue = _parseCatalogue(catalogueJsonStr);
        apiCatalogue = catalogue.$1;
        apiCity = catalogue.$2;
        mainSend.send(<String, dynamic>{
          'type': 'ready',
          'count': airports!.length,
          'rankCount': ranks!.length,
          'catalogueCount': apiCatalogue.length,
        });
      } else if (type == 'search') {
        final id = message['id'] as int;
        final list = airports;
        final map = byIata;
        if (list == null || map == null) {
          mainSend.send(<String, dynamic>{
            'type': 'result',
            'id': id,
            'data': <Map<String, dynamic>>[],
          });
          return;
        }
        final results = _searchIndexed(
          airports: list,
          byIata: map,
          ranks: ranks ?? const {},
          apiCatalogue: apiCatalogue,
          apiCity: apiCity,
          query: message['query'] as String? ?? '',
          lang: message['lang'] as String? ?? 'en',
          limit: message['limit'] as int? ?? 40,
        );
        mainSend.send(<String, dynamic>{
          'type': 'result',
          'id': id,
          'data': results.map((e) => e.toJson()).toList(growable: false),
        });
      } else if (type == 'searchByCoordinates') {
        final id = message['id'] as int;
        final list = airports;
        final map = byIata;
        final rankMap = ranks;
        if (list == null || map == null || rankMap == null) {
          mainSend.send(<String, dynamic>{
            'type': 'result',
            'id': id,
            'data': <Map<String, dynamic>>[],
          });
          return;
        }
        final results = _searchByCoordinatesIndexed(
          airports: list,
          byIata: map,
          ranks: rankMap,
          apiCatalogue: apiCatalogue,
          apiCity: apiCity,
          lat: (message['lat'] as num?)?.toDouble() ?? 0,
          lon: (message['lon'] as num?)?.toDouble() ?? 0,
          lang: message['lang'] as String? ?? 'en',
          limit: message['limit'] as int? ?? 5,
          maxDistanceKm:
              (message['maxDistanceKm'] as num?)?.toDouble() ?? 400,
        );
        mainSend.send(<String, dynamic>{
          'type': 'result',
          'id': id,
          'data': results.map((e) => e.toJson()).toList(growable: false),
        });
      } else if (type == 'searchByCountry') {
        final id = message['id'] as int;
        final list = airports;
        final map = byIata;
        if (list == null || map == null) {
          mainSend.send(<String, dynamic>{
            'type': 'result',
            'id': id,
            'data': <Map<String, dynamic>>[],
          });
          return;
        }
        final results = _searchByCountryIndexed(
          airports: list,
          byIata: map,
          ranks: ranks ?? const {},
          apiCatalogue: apiCatalogue,
          apiCity: apiCity,
          country: message['country'] as String? ?? '',
          lang: message['lang'] as String? ?? 'en',
          limit: message['limit'] as int? ?? 40,
        );
        mainSend.send(<String, dynamic>{
          'type': 'result',
          'id': id,
          'data': results.map((e) => e.toJson()).toList(growable: false),
        });
      }
    } catch (e, st) {
      mainSend.send(<String, dynamic>{
        'type': 'error',
        'id': message['id'],
        'error': '$e\n$st',
      });
    }
  });
}

(List<_IndexedAirport>, Map<String, _IndexedAirport>) _parseAndIndex(
  String jsonStr,
) {
  final decoded = jsonDecode(jsonStr);
  if (decoded is! Map) {
    throw StateError('airports_iata.json must be a JSON object');
  }
  final list = <_IndexedAirport>[];
  final byIata = <String, _IndexedAirport>{};
  for (final entry in decoded.entries) {
    final value = entry.value;
    if (value is! Map) continue;
    final airport = LocalAirport.fromJson(Map<String, dynamic>.from(value));
    if (airport.iata.trim().isEmpty) continue;
    final indexed = _IndexedAirport.fromAirport(airport);
    list.add(indexed);
    byIata[indexed.iata] = indexed;
  }
  list.sort((a, b) => a.popularRank.compareTo(b.popularRank));
  return (list, byIata);
}

Map<String, int> _parseRanks(String jsonStr) {
  final map = <String, int>{};
  try {
    final decoded = jsonDecode(jsonStr);
    if (decoded is List) {
      for (final e in decoded) {
        if (e is! Map) continue;
        final iata = (e['iata']?.toString() ?? '').toUpperCase();
        final rank = (e['rank'] as num?)?.toInt();
        if (iata.isEmpty || rank == null || rank <= 0) continue;
        map[iata] = rank;
      }
    }
  } catch (_) {}
  return map;
}

/// Backend `/avia/airports-mobile` katalogi: IATA → shahar IATA.
(Map<String, String>, Map<String, List<String>>) _parseCatalogue(String jsonStr) {
  try {
    final decoded = jsonDecode(jsonStr);
    if (decoded is! Map) return (const {}, const {});
    final catalogue = decoded.map(
      (k, v) => MapEntry(k.toString().toUpperCase(), v.toString().toUpperCase()),
    );
    final byCity = <String, List<String>>{};
    catalogue.forEach((code, city) {
      (byCity[city] ??= <String>[]).add(code);
    });
    return (Map<String, String>.from(catalogue), byCity);
  } catch (_) {
    return (const {}, const {});
  }
}

/// Shahar guruhidagi QO'SHIMCHA aeroport ko'rsatiladimi?
bool _isBookableChild({
  required _IndexedAirport a,
  required String groupCityIata,
  required Map<String, String> apiCatalogue,
  required Map<String, List<String>> apiCity,
  required Map<String, _IndexedAirport> byIata,
  required Map<String, int> ranks,
}) {
  if (a.isCityCode) return true;
  // Katalog yuklanmagan bo'lsa hech narsani yashirmaymiz.
  if (apiCatalogue.isEmpty) return true;
  if (!_cityIsMajor(
    groupCityIata,
    apiCity: apiCity,
    byIata: byIata,
    ranks: ranks,
  )) {
    return true;
  }
  final group = apiCatalogue[a.iata.toUpperCase()];
  if (group == null) return false;
  return group == groupCityIata.toUpperCase();
}

bool _cityIsMajor(
  String cityIata, {
  required Map<String, List<String>> apiCity,
  required Map<String, _IndexedAirport> byIata,
  required Map<String, int> ranks,
}) {
  final code = cityIata.toUpperCase();
  if (code.isEmpty) return false;
  if ((apiCity[code]?.length ?? 0) > 1) return true;
  final city = byIata[code];
  if (city != null && city.isCityCode) return true;
  if (ranks.isEmpty) return false;
  return (ranks[code] ?? 0) >= 2;
}

/// Yo'lovchi reysi bo'lmaydigan obyektlar (koordinata qidiruvida chetlanadi).
final RegExp _nonCommercial = RegExp(
  r'air ?base|air force|military|heliport|airstrip|seaplane|balloonport|naval|army|airfield',
  caseSensitive: false,
);

/// O'zbekistondan eng ko'p uchiladigan yo'nalishlar (yuqoridagi — ustunroq).
const List<String> _popularFromUz = [
  'MOW',
  'IST',
  'SAW',
  'DXB',
  'AYT',
  'ALA',
  'NQZ',
  'LED',
  'SVO',
  'DME',
  'VKO',
  'FRU',
  'DYU',
  'ASB',
  'GYD',
  'ESB',
  'ADB',
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
  'TAS',
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

const Map<String, String> _cityMergeTo = {
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

List<AirPortsModel> _searchIndexed({
  required List<_IndexedAirport> airports,
  required Map<String, _IndexedAirport> byIata,
  required Map<String, int> ranks,
  required Map<String, String> apiCatalogue,
  required Map<String, List<String>> apiCity,
  required String query,
  required String lang,
  required int limit,
}) {
  final q = _normalize(query);
  if (q.isEmpty) return const [];

  final scored = <_ScoredAirport>[];
  for (final a in airports) {
    final score = _score(a, q, lang);
    if (score > 0) {
      scored.add(_ScoredAirport(a, score));
    }
  }

  if (scored.isEmpty) return const [];

  return _groupScoredResults(
    scored,
    byIata: byIata,
    ranks: ranks,
    apiCatalogue: apiCatalogue,
    apiCity: apiCity,
    lang: lang,
    limit: limit,
    maxCandidates: 400,
    maxScanBreakAt: 50,
  );
}

List<AirPortsModel> _searchByCoordinatesIndexed({
  required List<_IndexedAirport> airports,
  required Map<String, _IndexedAirport> byIata,
  required Map<String, int> ranks,
  required Map<String, String> apiCatalogue,
  required Map<String, List<String>> apiCity,
  required double lat,
  required double lon,
  required String lang,
  required int limit,
  required double maxDistanceKm,
}) {
  final candidates = <_ScoredAirport>[];

  for (final a in airports) {
    if (a.isCityCode) continue;
    if (a.lat == 0 && a.lon == 0) continue;
    if (_nonCommercial.hasMatch(a.nameEn)) continue;

    final rank = ranks[a.iata] ?? 0;
    if (ranks.isNotEmpty && rank <= 0) continue;

    final d = _distanceKm(lat, lon, a.lat, a.lon);
    if (d > maxDistanceKm) continue;

    var score = ((1 - d / maxDistanceKm) * 10000).round();
    score += rank * 800;
    candidates.add(_ScoredAirport(a, score < 1 ? 1 : score));
  }

  if (candidates.isEmpty) return const [];

  return _groupScoredResults(
    candidates,
    byIata: byIata,
    ranks: ranks,
    apiCatalogue: apiCatalogue,
    apiCity: apiCity,
    lang: lang,
    limit: limit,
    maxCandidates: 200,
    maxScanBreakAt: 30,
  );
}

List<AirPortsModel> _searchByCountryIndexed({
  required List<_IndexedAirport> airports,
  required Map<String, _IndexedAirport> byIata,
  required Map<String, int> ranks,
  required Map<String, String> apiCatalogue,
  required Map<String, List<String>> apiCity,
  required String country,
  required String lang,
  required int limit,
}) {
  final q = _normalize(country);
  if (q.isEmpty) return const [];

  final scored = <_ScoredAirport>[];
  for (final a in airports) {
    final score = _scoreCountry(a, q);
    if (score > 0) {
      scored.add(_ScoredAirport(a, score));
    }
  }

  if (scored.isEmpty) return const [];

  return _groupScoredResults(
    scored,
    byIata: byIata,
    ranks: ranks,
    apiCatalogue: apiCatalogue,
    apiCity: apiCity,
    lang: lang,
    limit: limit,
    maxCandidates: 1200,
    maxScanBreakAt: 30,
  );
}

int _scoreCountry(_IndexedAirport a, String q) {
  final boost = a.popularRank >= 9999 ? 0 : 5000 - a.popularRank * 40;

  if (a.countryLower.isNotEmpty && a.countryLower == q) return 9000 + boost;

  final names = <String>[a.countryEnNorm, a.countryRuNorm, a.countryUzNorm];
  for (final name in names) {
    if (name.isEmpty) continue;
    if (name == q) return 8500 + boost;
  }
  if (q.length < 2) return 0;

  for (final name in names) {
    if (name.isEmpty) continue;
    if (name.startsWith(q)) return 8000 + boost;
  }
  if (q.length >= 3) {
    for (final name in names) {
      if (name.isEmpty) continue;
      if (name.contains(q)) return 7500 + boost;
    }
  }
  return 0;
}

double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusKm = 6371.0;
  final dLat = _toRad(lat2 - lat1);
  final dLon = _toRad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRad(lat1)) *
          math.cos(_toRad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

double _toRad(double deg) => deg * math.pi / 180.0;

List<AirPortsModel> _groupScoredResults(
  List<_ScoredAirport> scored, {
  required Map<String, _IndexedAirport> byIata,
  required Map<String, int> ranks,
  required Map<String, String> apiCatalogue,
  required Map<String, List<String>> apiCity,
  required String lang,
  required int limit,
  required int maxCandidates,
  required int maxScanBreakAt,
}) {
  scored.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    final pop = _popularRank(b.airport).compareTo(_popularRank(a.airport));
    if (pop != 0) return pop;
    if (a.airport.isCityCode != b.airport.isCityCode) {
      return a.airport.isCityCode ? -1 : 1;
    }
    return a.airport.cityName(lang).compareTo(b.airport.cityName(lang));
  });

  final groups = <String, _CityGroup>{};
  final maxScan = scored.length < maxCandidates ? scored.length : maxCandidates;

  for (var i = 0; i < maxScan; i++) {
    final item = scored[i];
    final a = item.airport;

    final groupKey = _groupKey(a);
    final preferredCityIata = _preferredCityIata(a);

    final group = groups.putIfAbsent(
      groupKey,
      () => _CityGroup(
        country: a.country,
        countryName: a.countryName(lang),
        cityName: a.cityName(lang),
        cityIata: preferredCityIata,
        bestScore: item.score,
        airports: [],
      ),
    );

    if (item.score > group.bestScore) {
      group.bestScore = item.score;
      final nice = a.cityName(lang);
      if (nice.isNotEmpty &&
          (group.cityName.isEmpty || a.isCityCode || _popularRank(a) < 50)) {
        group.cityName = nice;
      }
    }
    if (a.isCityCode ||
        preferredCityIata.length == 3 &&
            _popularRankCode(preferredCityIata) <
                _popularRankCode(group.cityIata)) {
      group.cityIata = preferredCityIata;
    }

    if (a.isCityCode) {
      for (final code in a.metroAirports) {
        final child = byIata[code];
        if (child == null || child.isCityCode) continue;
        if (!_isBookableChild(
          a: child,
          groupCityIata: group.cityIata,
          apiCatalogue: apiCatalogue,
          apiCity: apiCity,
          byIata: byIata,
          ranks: ranks,
        )) {
          continue;
        }
        group.airports.add(
          Airports(
            airportName: child.airportName(lang),
            airportIataCode: child.iata,
          ),
        );
      }
      if (a.metroAirports.isEmpty) {
        group.airports.add(
          Airports(
            airportName: a.airportName(lang),
            airportIataCode: a.iata,
          ),
        );
      }
    } else {
      // Guruhning birinchi (eng yuqori ballli) aeroporti — shaharning o'zi,
      // u doim ko'rsatiladi. Keyingilari faqat backend katalogida bo'lsa.
      final isCityItself =
          a.iata.toUpperCase() == group.cityIata.toUpperCase();
      if (!isCityItself &&
          !_isBookableChild(
            a: a,
            groupCityIata: group.cityIata,
            apiCatalogue: apiCatalogue,
            apiCity: apiCity,
            byIata: byIata,
            ranks: ranks,
          )) {
        continue;
      }

      group.airports.add(
        Airports(
          airportName: a.airportName(lang),
          airportIataCode: a.iata,
        ),
      );
      if (a.cityCode.isNotEmpty && group.airports.length == 1) {
        final metro = byIata[a.cityCode];
        if (metro != null && metro.isCityCode) {
          group.cityIata = metro.iata;
          group.cityName = metro.cityName(lang);
          for (final code in metro.metroAirports) {
            final child = byIata[code];
            if (child == null) continue;
            if (!_isBookableChild(
              a: child,
              groupCityIata: group.cityIata,
              apiCatalogue: apiCatalogue,
              apiCity: apiCity,
              byIata: byIata,
              ranks: ranks,
            )) {
              continue;
            }
            group.airports.add(
              Airports(
                airportName: child.airportName(lang),
                airportIataCode: child.iata,
              ),
            );
          }
        }
      }
    }

    if (groups.length >= limit && i > maxScanBreakAt) break;
  }

  // Backend katalogidagi shahar aeroportlarini guruhga to'ldirish.
  if (apiCity.isNotEmpty) {
    for (final g in groups.values) {
      final city = g.cityIata.toUpperCase();
      for (final code in apiCity[city] ?? const <String>[]) {
        if (code == city) continue;
        final child = byIata[code];
        if (child == null || child.isCityCode) continue;
        final already = g.airports.any(
          (e) => (e.airportIataCode ?? '').toUpperCase() == code,
        );
        if (already) continue;
        g.airports.add(
          Airports(
            airportName: child.airportName(lang),
            airportIataCode: child.iata,
          ),
        );
      }
    }
  }

  final ordered = groups.values.toList()
    ..sort((a, b) {
      final byScore = b.bestScore.compareTo(a.bestScore);
      if (byScore != 0) return byScore;
      return _popularRankCode(a.cityIata).compareTo(_popularRankCode(b.cityIata));
    });

  return ordered.take(limit).map((g) {
    final cityCode = g.cityIata.toUpperCase();
    final unique = <String, Airports>{};
    for (final ap in g.airports) {
      final code = (ap.airportIataCode ?? '').toUpperCase();
      if (code.isEmpty) continue;
      unique.putIfAbsent(code, () => ap);
    }
    final cityIsMetro = byIata[cityCode]?.isCityCode ?? false;
    if (cityIsMetro || unique.length <= 1) {
      unique.remove(cityCode);
    }

    return AirPortsModel(
      countryIataCode: g.country,
      countryName: g.countryName,
      cityName: g.cityName,
      cityIataCode: g.cityIata,
      airports: unique.values.toList(),
    );
  }).toList();
}

String _groupKey(_IndexedAirport a) {
  if (a.cityCode.isNotEmpty) {
    return '${a.country}|city:${a.cityCode}';
  }
  if (a.isCityCode) {
    return '${a.country}|city:${a.iata}';
  }
  final merge = _cityMergeTo[a.cityEnNorm];
  if (merge != null) {
    return '${a.country}|city:$merge';
  }
  for (final c in [a.cityUzNorm, a.cityRuNorm, a.cityRawNorm]) {
    final m = _cityMergeTo[c];
    if (m != null) return '${a.country}|city:$m';
  }
  return '${a.country}|${a.cityEnNorm}';
}

String _preferredCityIata(_IndexedAirport a) {
  if (a.isCityCode && a.iata.isNotEmpty) return a.iata;
  if (a.cityCode.isNotEmpty) return a.cityCode;
  return _cityMergeTo[a.cityEnNorm] ??
      _cityMergeTo[a.cityUzNorm] ??
      a.iata;
}

int _popularRank(_IndexedAirport a) {
  final codes = <String>{
    a.iata,
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

int _popularBoost(_IndexedAirport a) {
  final rank = _popularRank(a);
  if (rank >= 9999) return 0;
  return 5000 - rank * 40;
}

int _score(_IndexedAirport a, String q, String lang) {
  final boost = _popularBoost(a);

  if (a.iataLower == q) return (a.isCityCode ? 11000 : 10000) + boost;
  if (a.cityCodeLower.isNotEmpty && a.cityCodeLower == q) {
    return 10500 + boost;
  }
  if (a.icaoLower.isNotEmpty && a.icaoLower == q) return 9500 + boost;
  if (q.isNotEmpty && a.iataLower.startsWith(q)) {
    return (a.isCityCode ? 9200 : 9000) + q.length * 10 + boost;
  }
  if (q.isNotEmpty &&
      a.cityCodeLower.isNotEmpty &&
      a.cityCodeLower.startsWith(q)) {
    return 9100 + q.length * 10 + boost;
  }
  if (q.isNotEmpty && a.icaoLower.isNotEmpty && a.icaoLower.startsWith(q)) {
    return 8800 + q.length * 10 + boost;
  }

  final city = a.cityNorm(lang);
  final airport = a.airportNorm(lang);
  final state = a.stateNorm(lang);
  final country = a.countryNorm(lang);

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
  consider(a.cityEnNorm, 6950);
  consider(a.cityRawNorm, 6900);
  consider(airport, 6000);
  consider(a.airportEnNorm, 5900);
  consider(state, 5000);
  consider(a.stateEnNorm, 4900);
  consider(country, 4000);
  consider(a.countryEnNorm, 4000);
  consider(a.countryRuNorm, 4000);
  consider(a.countryUzNorm, 4000);
  consider(a.countryLower, 3500);

  if (a.searchTokens.contains(q)) {
    best = best < 7500 ? 7500 : best;
  } else {
    for (final t in a.searchTokens) {
      if (q.isNotEmpty && t.startsWith(q)) {
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
      ..write(a.cityEnNorm)
      ..write(' ')
      ..write(airport)
      ..write(' ')
      ..write(state)
      ..write(' ')
      ..write(country)
      ..write(' ')
      ..write(a.countryEnNorm)
      ..write(' ')
      ..write(a.countryRuNorm)
      ..write(' ')
      ..write(a.countryUzNorm)
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

String _normalize(String input) {
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

/// Oldindan normalizatsiya qilingan qidiruv yozuvi (har qidiruvda normalize yo‘q).
class _IndexedAirport {
  final String iata;
  final String iataLower;
  final String icaoLower;
  final String cityCode;
  final String cityCodeLower;
  final String country;
  final String countryLower;
  final bool isCityCode;
  final List<String> metroAirports;
  final Set<String> searchTokens;

  final String cityRawNorm;
  final String cityEnNorm;
  final String cityRuNorm;
  final String cityUzNorm;
  final String airportEnNorm;
  final String airportRuNorm;
  final String airportUzNorm;
  final String stateEnNorm;
  final String stateRuNorm;
  final String stateUzNorm;
  final String countryEnNorm;
  final String countryRuNorm;
  final String countryUzNorm;

  /// Display (asli) nomlar.
  final String cityEn;
  final String cityRu;
  final String cityUz;
  final String airportEn;
  final String airportRu;
  final String airportUz;
  final String countryEn;
  final String countryRu;
  final String countryUz;

  final double lat;
  final double lon;
  final String nameEn;
  final int popularRank;

  const _IndexedAirport({
    required this.iata,
    required this.iataLower,
    required this.icaoLower,
    required this.cityCode,
    required this.cityCodeLower,
    required this.country,
    required this.countryLower,
    required this.isCityCode,
    required this.metroAirports,
    required this.searchTokens,
    required this.cityRawNorm,
    required this.cityEnNorm,
    required this.cityRuNorm,
    required this.cityUzNorm,
    required this.airportEnNorm,
    required this.airportRuNorm,
    required this.airportUzNorm,
    required this.stateEnNorm,
    required this.stateRuNorm,
    required this.stateUzNorm,
    required this.countryEnNorm,
    required this.countryRuNorm,
    required this.countryUzNorm,
    required this.cityEn,
    required this.cityRu,
    required this.cityUz,
    required this.airportEn,
    required this.airportRu,
    required this.airportUz,
    required this.countryEn,
    required this.countryRu,
    required this.countryUz,
    required this.lat,
    required this.lon,
    required this.nameEn,
    required this.popularRank,
  });

  factory _IndexedAirport.fromAirport(LocalAirport a) {
    final en = a.names['en'];
    final ru = a.names['ru'];
    final uz = a.names['uz'];
    final cityEn = (en?.city.isNotEmpty == true) ? en!.city : a.city;
    final cityRu = (ru?.city.isNotEmpty == true) ? ru!.city : cityEn;
    final cityUz = (uz?.city.isNotEmpty == true) ? uz!.city : cityEn;
    final airportEn = (en?.airport.isNotEmpty == true) ? en!.airport : a.name;
    final airportRu =
        (ru?.airport.isNotEmpty == true) ? ru!.airport : airportEn;
    final airportUz =
        (uz?.airport.isNotEmpty == true) ? uz!.airport : airportEn;
    final stateEn = (en?.state.isNotEmpty == true) ? en!.state : a.state;
    final stateRu = (ru?.state.isNotEmpty == true) ? ru!.state : stateEn;
    final stateUz = (uz?.state.isNotEmpty == true) ? uz!.state : stateEn;
    final countryEn = a.countryNames['en'] ?? a.country;
    final countryRu = a.countryNames['ru'] ?? countryEn;
    final countryUz = a.countryNames['uz'] ?? countryEn;

    final tokens = <String>{};
    for (final t in a.searchTokens) {
      final n = _normalize(t);
      if (n.isNotEmpty) tokens.add(n);
    }

    final codes = <String>{
      a.iata.toUpperCase(),
      if (a.cityCode.isNotEmpty) a.cityCode,
    };
    var rank = 9999;
    for (final c in codes) {
      final r = _popularRankCode(c);
      if (r < rank) rank = r;
    }

    return _IndexedAirport(
      iata: a.iata.toUpperCase(),
      iataLower: a.iata.toLowerCase(),
      icaoLower: a.icao.toLowerCase(),
      cityCode: a.cityCode,
      cityCodeLower: a.cityCode.toLowerCase(),
      country: a.country,
      countryLower: a.country.toLowerCase(),
      isCityCode: a.isCityCode,
      metroAirports: a.metroAirports,
      searchTokens: tokens,
      cityRawNorm: _normalize(a.city),
      cityEnNorm: _normalize(cityEn),
      cityRuNorm: _normalize(cityRu),
      cityUzNorm: _normalize(cityUz),
      airportEnNorm: _normalize(airportEn),
      airportRuNorm: _normalize(airportRu),
      airportUzNorm: _normalize(airportUz),
      stateEnNorm: _normalize(stateEn),
      stateRuNorm: _normalize(stateRu),
      stateUzNorm: _normalize(stateUz),
      countryEnNorm: _normalize(countryEn),
      countryRuNorm: _normalize(countryRu),
      countryUzNorm: _normalize(countryUz),
      cityEn: cityEn,
      cityRu: cityRu,
      cityUz: cityUz,
      airportEn: airportEn,
      airportRu: airportRu,
      airportUz: airportUz,
      countryEn: countryEn,
      countryRu: countryRu,
      countryUz: countryUz,
      lat: a.lat,
      lon: a.lon,
      nameEn: airportEn,
      popularRank: rank,
    );
  }

  String cityName(String lang) {
    switch (_lang(lang)) {
      case 'uz':
        return cityUz;
      case 'ru':
        return cityRu;
      default:
        return cityEn;
    }
  }

  String airportName(String lang) {
    switch (_lang(lang)) {
      case 'uz':
        return airportUz;
      case 'ru':
        return airportRu;
      default:
        return airportEn;
    }
  }

  String countryName(String lang) {
    switch (_lang(lang)) {
      case 'uz':
        return countryUz;
      case 'ru':
        return countryRu;
      default:
        return countryEn;
    }
  }

  String cityNorm(String lang) {
    switch (_lang(lang)) {
      case 'uz':
        return cityUzNorm;
      case 'ru':
        return cityRuNorm;
      default:
        return cityEnNorm;
    }
  }

  String airportNorm(String lang) {
    switch (_lang(lang)) {
      case 'uz':
        return airportUzNorm;
      case 'ru':
        return airportRuNorm;
      default:
        return airportEnNorm;
    }
  }

  String stateNorm(String lang) {
    switch (_lang(lang)) {
      case 'uz':
        return stateUzNorm;
      case 'ru':
        return stateRuNorm;
      default:
        return stateEnNorm;
    }
  }

  String countryNorm(String lang) {
    switch (_lang(lang)) {
      case 'uz':
        return countryUzNorm;
      case 'ru':
        return countryRuNorm;
      default:
        return countryEnNorm;
    }
  }

  static String _lang(String lang) {
    final l = lang.toLowerCase();
    if (l.startsWith('uz')) return 'uz';
    if (l.startsWith('ru')) return 'ru';
    return 'en';
  }
}

class _ScoredAirport {
  final _IndexedAirport airport;
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
