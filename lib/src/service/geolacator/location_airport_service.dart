import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as loc;
import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/core/config/sdk_storage.dart';
import 'package:mysafar_sdk/src/model/remote/avia/airports_model.dart';
import 'package:mysafar_sdk/src/service/avia/airport_local_search_service.dart';
import 'package:mysafar_sdk/src/service/avia_service.dart';

class LocationAirportService {
  static final LocationAirportService _instance = LocationAirportService._internal();
  factory LocationAirportService() => _instance;
  LocationAirportService._internal();

  final loc.Location _location = loc.Location();
  final AviaService _aviaService = AviaService();
  final AirportLocalSearchService _localSearch =
      AirportLocalSearchService.instance;

  static const _storageKey = 'last_nearby_airport';

  AirPortsModel? _cachedNearbyAirport;
  bool _hasAttemptedLocation = false;
  DateTime? _lastAttemptTime;

  AirPortsModel? get cachedNearbyAirport => _cachedNearbyAirport;
  bool get hasAttemptedLocation => _hasAttemptedLocation;

  AirPortsModel? lastKnownAirport({String? lang}) {
    if (_cachedNearbyAirport != null) return _cachedNearbyAirport;
    try {
      final raw = sdkStorage().read(_storageKey);
      if (raw is! Map) return null;
      final map = Map<String, dynamic>.from(raw);
      final savedLang = map['_lang']?.toString();
      if (lang != null && savedLang != null && savedLang != lang) return null;
      final model = AirPortsModel.fromJson(map);
      if ((model.cityIataCode ?? '').isEmpty) return null;
      return model;
    } catch (e) {
      debugPrint('LocationAirportService: lastKnownAirport read error: $e');
      return null;
    }
  }

  AirPortsModel _remember(AirPortsModel airport, String source, String lang) {
    _cachedNearbyAirport = airport;
    debugPrint(
        "LocationAirportService: [$source] ${airport.cityName} (${airport.cityIataCode})");
    try {
      sdkStorage().write(_storageKey, {...airport.toJson(), '_lang': lang});
    } catch (e) {
      debugPrint('LocationAirportService: cache write error: $e');
    }
    return airport;
  }

  void clearCache() {
    _cachedNearbyAirport = null;
    _hasAttemptedLocation = false;
    _lastAttemptTime = null;
    try {
      sdkStorage().remove(_storageKey);
    } catch (_) {}
  }

  Future<AirPortsModel?> getNearbyAirport({String? lang}) async {
    if (_cachedNearbyAirport != null) {
      debugPrint("LocationAirportService: Returning cached nearby airport: ${_cachedNearbyAirport?.cityName}");
      return _cachedNearbyAirport;
    }

    final now = DateTime.now();
    if (_hasAttemptedLocation && _cachedNearbyAirport == null) {
      if (_lastAttemptTime != null &&
          now.difference(_lastAttemptTime!).inMinutes < 5) {
        debugPrint("LocationAirportService: Already attempted recently, returning null");
        return null;
      }
      _hasAttemptedLocation = false;
    }

    _hasAttemptedLocation = true;
    _lastAttemptTime = now;

    try {
      debugPrint("LocationAirportService: Starting location fetch...");

      bool serviceEnabled = await _location.serviceEnabled();
      debugPrint("LocationAirportService: Service enabled: $serviceEnabled");

      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        debugPrint("LocationAirportService: Service requested, result: $serviceEnabled");
        if (!serviceEnabled) {
          debugPrint("LocationAirportService: Location service not enabled");
          return null;
        }
      }

      loc.PermissionStatus permission = await _location.hasPermission();
      debugPrint("LocationAirportService: Current permission: $permission");

      if (permission == loc.PermissionStatus.denied) {
        debugPrint("LocationAirportService: Requesting permission...");
        permission = await _location.requestPermission();
        debugPrint("LocationAirportService: Permission after request: $permission");
        if (permission != loc.PermissionStatus.granted &&
            permission != loc.PermissionStatus.grantedLimited) {
          debugPrint("LocationAirportService: Location permission not granted");
          return null;
        }
      }

      if (permission == loc.PermissionStatus.deniedForever) {
        debugPrint("LocationAirportService: Location permission denied forever");
        return null;
      }

      try {
        await _location.changeSettings(accuracy: loc.LocationAccuracy.balanced);
      } catch (_) {}

      debugPrint("LocationAirportService: Getting current location...");
      final loc.LocationData locationData;
      try {
        locationData =
            await _location.getLocation().timeout(const Duration(seconds: 15));
      } on TimeoutException {
        debugPrint("LocationAirportService: Location timeout — returning null");
        return null;
      }

      if (locationData.latitude == null || locationData.longitude == null) {
        debugPrint("LocationAirportService: Could not get location coordinates");
        return null;
      }

      debugPrint("LocationAirportService: Current location: ${locationData.latitude}, ${locationData.longitude}");

      List<Placemark> placemarks = [];
      try {
        placemarks = await placemarkFromCoordinates(
          locationData.latitude!,
          locationData.longitude!,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint("LocationAirportService: Geocoding timeout");
            return [];
          },
        );
      } catch (e) {
        debugPrint("LocationAirportService: Geocoding error: $e");
      }

      final placemark = placemarks.isNotEmpty ? placemarks.first : null;

      final byCoords = await _localSearch.searchByCoordinates(
        lat: locationData.latitude!,
        lon: locationData.longitude!,
        lang: lang ?? 'en',
        limit: 5,
      );
      if (byCoords.isNotEmpty) {
        return _remember(byCoords.first, 'local/coords', lang ?? 'en');
      }

      final searchQuery =
          placemark?.locality ?? placemark?.administrativeArea ?? '';
      final countryQuery =
          (placemark?.isoCountryCode?.trim().isNotEmpty == true)
              ? placemark!.isoCountryCode!.trim()
              : (placemark?.country ?? '').trim();

      if (searchQuery.isEmpty && countryQuery.isEmpty) {
        debugPrint("LocationAirportService: No city/country name found in placemark");
        return null;
      }

      if (searchQuery.isNotEmpty) {
        debugPrint("LocationAirportService: Local search by city: $searchQuery");
        final localByCity = await _localSearch.search(
          query: searchQuery,
          lang: lang ?? 'en',
          limit: 5,
        );
        if (localByCity.isNotEmpty) {
          return _remember(localByCity.first, 'local/city', lang ?? 'en');
        }
      }

      if (countryQuery.isNotEmpty) {
        debugPrint("LocationAirportService: Local search by country: $countryQuery");
        final localByCountry = await _localSearch.searchByCountry(
          country: countryQuery,
          lang: lang ?? 'en',
          limit: 10,
        );
        if (localByCountry.isNotEmpty) {
          debugPrint(
              "LocationAirportService: davlat bo'yicha ${localByCountry.length} ta shahar topildi");
          return _remember(localByCountry.first, 'local/country', lang ?? 'en');
        }
      }

      if (searchQuery.isEmpty) {
        debugPrint("LocationAirportService: No city name for API search");
        return null;
      }

      debugPrint("LocationAirportService: Searching airport for city: $searchQuery");

      final response = await _aviaService.getAirports(
        part: searchQuery,
        lang: lang ?? 'en',
      );

      if (response is NetworkSuccessResponse) {
        final airports = response.data as List<AirPortsModel>;
        debugPrint("LocationAirportService: Found ${airports.length} airports");
        if (airports.isNotEmpty) {
          final picked = airports.firstWhere(
            (a) => (a.cityName ?? '').trim().isNotEmpty,
            orElse: () => airports.first,
          );
          return _remember(picked, 'api/city', lang ?? 'en');
        }
      } else if (response is NetworkErrorResponse) {
        debugPrint("LocationAirportService: Airport search error: ${response.error}");
      }

      debugPrint("LocationAirportService: No airports found for city: $searchQuery");
      return null;
    } catch (e, stackTrace) {
      debugPrint("LocationAirportService: Error getting nearby airport: $e");
      debugPrint("LocationAirportService: StackTrace: $stackTrace");
      return null;
    }
  }

  Future<bool> isLocationPermissionGranted() async {
    try {
      final permission = await _location.hasPermission();
      return permission == loc.PermissionStatus.granted ||
          permission == loc.PermissionStatus.grantedLimited;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestLocationPermission() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return false;
      }

      loc.PermissionStatus permission = await _location.hasPermission();
      if (permission == loc.PermissionStatus.denied) {
        permission = await _location.requestPermission();
      }

      return permission == loc.PermissionStatus.granted ||
          permission == loc.PermissionStatus.grantedLimited;
    } catch (e) {
      return false;
    }
  }
}
