import 'package:mysafar_sdk/src/model/remote/destination/destination_detail_model.dart'
    show DestLocalizedText;

/// `POST /v1/destination/list` javobi — web'dagi /uz/destinations
/// sahifasining sahifalangan (page/page_size) ro'yxati.
class DestinationListPageResult {
  final int count;
  final bool hasNext;
  final List<DestinationListItem> items;

  DestinationListPageResult({
    required this.count,
    required this.hasNext,
    required this.items,
  });

  factory DestinationListPageResult.fromJson(Map<String, dynamic> json) {
    return DestinationListPageResult(
      count: _asInt(json['count']),
      hasNext: json['next'] != null,
      items: json['results'] is List
          ? [
              for (final e in json['results'] as List)
                if (e is Map<String, dynamic>) DestinationListItem.fromJson(e)
            ]
          : const [],
    );
  }
}

/// Ro'yxatdagi bitta yo'nalish kartasi ma'lumoti.
class DestinationListItem {
  final int id;
  final String slug;
  final DestLocalizedText badge;
  final String image;
  final double rating;
  final DestLocalizedText cityName;
  final DestLocalizedText country;
  final int priceUzs;
  final int priceRub;
  final int priceUsd;
  final String date;
  final String durationDisplay;
  final String carrier;
  final String arrivalAirport;

  DestinationListItem({
    required this.id,
    required this.slug,
    required this.badge,
    required this.image,
    required this.rating,
    required this.cityName,
    required this.country,
    required this.priceUzs,
    required this.priceRub,
    required this.priceUsd,
    required this.date,
    required this.durationDisplay,
    required this.carrier,
    required this.arrivalAirport,
  });

  factory DestinationListItem.fromJson(Map<String, dynamic> json) {
    return DestinationListItem(
      id: _asInt(json['id']),
      slug: (json['slug'] ?? '').toString(),
      badge: DestLocalizedText.fromJson(json['badge']),
      image: (json['image'] ?? '').toString(),
      rating: _asDouble(json['rating']),
      cityName: DestLocalizedText.fromJson(json['city_name']),
      country: DestLocalizedText.fromJson(json['country']),
      priceUzs: _asInt(json['price_uzs']),
      priceRub: _asInt(json['price_rub']),
      priceUsd: _asInt(json['price_usd']),
      date: (json['date'] ?? '').toString(),
      durationDisplay: (json['duration_display'] ?? '').toString(),
      carrier: (json['carrier'] ?? '').toString(),
      arrivalAirport: (json['arrival_airport'] ?? '').toString(),
    );
  }
}

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double _asDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}
