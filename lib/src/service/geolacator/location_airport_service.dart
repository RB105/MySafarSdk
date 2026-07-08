import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as loc;
import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/model/remote/avia/airports_model.dart';
import 'package:mysafar_sdk/src/service/avia_service.dart';

class LocationAirportService {
  static final LocationAirportService _instance = LocationAirportService._internal();
  factory LocationAirportService() => _instance;
  LocationAirportService._internal();

  final loc.Location _location = loc.Location();
  final AviaService _aviaService = AviaService();

  // Cache for the session
  AirPortsModel? _cachedNearbyAirport;
  bool _hasAttemptedLocation = false;
  DateTime? _lastAttemptTime;

  /// Check if we already have a cached airport
  AirPortsModel? get cachedNearbyAirport => _cachedNearbyAirport;
  bool get hasAttemptedLocation => _hasAttemptedLocation;

  /// Clear cache (call this when app restarts or user logs out)
  void clearCache() {
    _cachedNearbyAirport = null;
    _hasAttemptedLocation = false;
    _lastAttemptTime = null;
  }

  /// Get nearby airport based on current location
  Future<AirPortsModel?> getNearbyAirport({String? lang}) async {
    // Return cached result if available
    if (_cachedNearbyAirport != null) {
      debugPrint("LocationAirportService: Returning cached nearby airport: ${_cachedNearbyAirport?.cityName}");
      return _cachedNearbyAirport;
    }

    // Allow retry after 5 minutes if previously failed
    final now = DateTime.now();
    if (_hasAttemptedLocation && _cachedNearbyAirport == null) {
      if (_lastAttemptTime != null && 
          now.difference(_lastAttemptTime!).inMinutes < 5) {
        debugPrint("LocationAirportService: Already attempted recently, returning null");
        return null;
      }
      // Reset for retry
      _hasAttemptedLocation = false;
    }

    _hasAttemptedLocation = true;
    _lastAttemptTime = now;

    try {
      debugPrint("LocationAirportService: Starting location fetch...");
      
      // Check if location service is enabled
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

      // Check permission
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

      // Shahar darajasidagi aniqlik yetarli — tezroq (va batareyaga yengil)
      // fix olish uchun balanced aniqlikni o'rnatamiz. Bu 15s timeout'ga
      // borib qolish ehtimolini kamaytiradi.
      try {
        await _location.changeSettings(accuracy: loc.LocationAccuracy.balanced);
      } catch (_) {}

      // Get current location with timeout. Timeout bo'lsa stacktrace bilan xato
      // tashlamay, shunchaki null qaytaramiz (GPS fix topilmadi — normal holat).
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

      // Get city name from coordinates using geocoding
      List<Placemark> placemarks = [];
      try {
        placemarks = await Geocoding().placemarkFromCoordinates(
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
        return null;
      }

      if (placemarks.isEmpty) {
        debugPrint("LocationAirportService: No placemarks found for location");
        return null;
      }

      final placemark = placemarks.first;
      debugPrint("LocationAirportService: Placemark - locality: ${placemark.locality}, admin: ${placemark.administrativeArea}, country: ${placemark.country}");
      
      String searchQuery = placemark.locality ?? placemark.administrativeArea ?? '';
      
      if (searchQuery.isEmpty) {
        debugPrint("LocationAirportService: No city name found in placemark");
        return null;
      }

      debugPrint("LocationAirportService: Searching airport for city: $searchQuery");

      // Search for airport by city name
      final response = await _aviaService.getAirports(
        part: searchQuery,
        lang: lang ?? 'en',
      );

      if (response is NetworkSuccessResponse) {
        final airports = response.data as List<AirPortsModel>;
        debugPrint("LocationAirportService: Found ${airports.length} airports");
        if (airports.isNotEmpty) {
          _cachedNearbyAirport = airports.first;
          debugPrint("LocationAirportService: Selected nearby airport: ${_cachedNearbyAirport?.cityName} (${_cachedNearbyAirport?.cityIataCode})");
          return _cachedNearbyAirport;
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

  /// Check if location permission is granted without requesting
  Future<bool> isLocationPermissionGranted() async {
    try {
      final permission = await _location.hasPermission();
      return permission == loc.PermissionStatus.granted ||
          permission == loc.PermissionStatus.grantedLimited;
    } catch (e) {
      return false;
    }
  }

  /// Request location permission
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

