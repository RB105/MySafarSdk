import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Resolves airport IATA codes to geographic coordinates using a bundled,
/// fully offline dataset (OpenFlights, ~6000 airports) shipped at
/// `assets/data/airports.json` in the form `{ "IATA": [lat, lon] }`.
///
/// Use [coordinatesOf] to look up a 3-letter IATA code; it returns
/// `[latitude, longitude]` or `null` when the code is unknown.
class AirportLocator {
  AirportLocator._();

  static Map<String, List<double>>? _cache;
  static Future<void>? _loading;

  /// Metropolitan / renamed codes the airport dataset does not contain on its
  /// own (e.g. multi-airport city codes). Checked as a fallback after the
  /// bundled dataset.
  static const Map<String, List<double>> _supplement = {
    'NQZ': [51.0222, 71.4669], // Astana (Nursultan Nazarbayev Intl.)
    'TSE': [51.0222, 71.4669], // Astana (legacy code)
    'MOW': [55.7558, 37.6173], // Moscow (metropolitan)
    'LON': [51.5074, -0.1278], // London (metropolitan)
    'NYC': [40.7128, -74.0060], // New York (metropolitan)
    'PAR': [48.8566, 2.3522], // Paris (metropolitan)
    'MIL': [45.4642, 9.1900], // Milan (metropolitan)
    'IEV': [50.4501, 30.5234], // Kyiv (metropolitan)
    'STO': [59.3293, 18.0686], // Stockholm (metropolitan)
  };

  static Future<void> _ensureLoaded() {
    if (_cache != null) return Future.value();
    return _loading ??= () async {
      try {
        final raw = await rootBundle.loadString('assets/data/airports.json');
        final decoded = json.decode(raw) as Map<String, dynamic>;
        _cache = decoded.map(
          (key, value) => MapEntry(
            key,
            [
              (value[0] as num).toDouble(),
              (value[1] as num).toDouble(),
            ],
          ),
        );
      } catch (_) {
        _cache = <String, List<double>>{};
      }
    }();
  }

  /// Returns `[latitude, longitude]` for the given IATA [code], or `null`
  /// when the code is invalid or not present in the dataset.
  static Future<List<double>?> coordinatesOf(String code) async {
    final iata = code.trim().toUpperCase();
    if (iata.length != 3) return null;
    await _ensureLoaded();
    return _cache?[iata] ?? _supplement[iata];
  }
}
