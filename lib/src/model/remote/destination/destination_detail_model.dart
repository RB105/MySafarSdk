/// Yo'nalish tafsiloti — `POST /v1/destination/detail` javobi (web'dagi
/// mysafar.uz/uz/destinations/... sahifasining ma'lumot manbasi).
/// Barcha maydonlar null-xavfsiz o'qiladi: backend biror bo'limni bermasa,
/// sahifada o'sha bo'lim shunchaki ko'rsatilmaydi.
class DestinationDetailModel {
  final String slug;
  final DestLocalizedText name;
  final DestLocalizedText country;
  final String airportCode;
  final DestinationHero? hero;
  final DestinationQuickInfo? quickInfo;
  final DestinationAbout? about;
  final List<DestinationAttraction> attractions;
  final List<String> gallery;
  final DestinationAviaBlock? aviaBlock;
  final DestinationContact? contact;

  DestinationDetailModel({
    required this.slug,
    required this.name,
    required this.country,
    required this.airportCode,
    this.hero,
    this.quickInfo,
    this.about,
    this.attractions = const [],
    this.gallery = const [],
    this.aviaBlock,
    this.contact,
  });

  factory DestinationDetailModel.fromJson(Map<String, dynamic> json) {
    return DestinationDetailModel(
      slug: json['slug'] ?? '',
      name: DestLocalizedText.fromJson(json['name']),
      country: DestLocalizedText.fromJson(json['country']),
      airportCode: json['airport_code'] ?? '',
      hero: json['hero'] is Map<String, dynamic>
          ? DestinationHero.fromJson(json['hero'])
          : null,
      quickInfo: json['quick_info'] is Map<String, dynamic>
          ? DestinationQuickInfo.fromJson(json['quick_info'])
          : null,
      about: json['about'] is Map<String, dynamic>
          ? DestinationAbout.fromJson(json['about'])
          : null,
      attractions: json['attractions'] is List
          ? [
              for (final e in json['attractions'] as List)
                if (e is Map<String, dynamic>) DestinationAttraction.fromJson(e)
            ]
          : const [],
      gallery: json['gallery'] is List
          ? [
              for (final e in json['gallery'] as List)
                if (e is String && e.isNotEmpty) e
            ]
          : const [],
      aviaBlock: json['avia_block'] is Map<String, dynamic>
          ? DestinationAviaBlock.fromJson(json['avia_block'])
          : null,
      contact: json['contact'] is Map<String, dynamic>
          ? DestinationContact.fromJson(json['contact'])
          : null,
    );
  }
}

/// uz/ru/en tarjimali matn maydoni.
class DestLocalizedText {
  final String uz;
  final String ru;
  final String en;

  const DestLocalizedText({this.uz = '', this.ru = '', this.en = ''});

  factory DestLocalizedText.fromJson(dynamic json) {
    if (json is String) return DestLocalizedText(uz: json, ru: json, en: json);
    if (json is! Map) return const DestLocalizedText();
    return DestLocalizedText(
      uz: (json['uz'] ?? '').toString(),
      ru: (json['ru'] ?? '').toString(),
      en: (json['en'] ?? '').toString(),
    );
  }

  /// Joriy ilova tili bo'yicha qiymat (uz — standart zaxira).
  String byLang(String lang) => switch (lang) {
        'ru' => ru.isNotEmpty ? ru : uz,
        'en' => en.isNotEmpty ? en : uz,
        _ => uz,
      };

  bool get isEmpty => uz.isEmpty && ru.isEmpty && en.isEmpty;
}

int _toInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

/// Sahifa tepasidagi hero: fon rasmi, reyting, belgi va eng arzon narx.
class DestinationHero {
  final String backgroundImage;
  final double rating;
  final String reviewsDisplay;
  final DestLocalizedText badge;
  final int priceUzs;
  final int priceRub;
  final int priceUsd;
  final String date;

  DestinationHero({
    this.backgroundImage = '',
    this.rating = 0,
    this.reviewsDisplay = '',
    this.badge = const DestLocalizedText(),
    this.priceUzs = 0,
    this.priceRub = 0,
    this.priceUsd = 0,
    this.date = '',
  });

  factory DestinationHero.fromJson(Map<String, dynamic> json) {
    return DestinationHero(
      backgroundImage: json['background_image'] ?? '',
      rating: _toDouble(json['rating']),
      reviewsDisplay: (json['reviews_display'] ?? '').toString(),
      badge: DestLocalizedText.fromJson(json['badge']),
      priceUzs: _toInt(json['price_uzs']),
      priceRub: _toInt(json['price_rub']),
      priceUsd: _toInt(json['price_usd']),
      date: json['date'] ?? '',
    );
  }
}

/// 2×2 "tezkor ma'lumot" kartalari.
class DestinationQuickInfo {
  final String flightDuration;
  final DestLocalizedText bestSeason;
  final DestLocalizedText recommendedDuration;
  final DestLocalizedText visaRequirement;

  DestinationQuickInfo({
    this.flightDuration = '',
    this.bestSeason = const DestLocalizedText(),
    this.recommendedDuration = const DestLocalizedText(),
    this.visaRequirement = const DestLocalizedText(),
  });

  factory DestinationQuickInfo.fromJson(Map<String, dynamic> json) {
    return DestinationQuickInfo(
      flightDuration: (json['flight_duration'] ?? '').toString(),
      bestSeason: DestLocalizedText.fromJson(json['best_season']),
      recommendedDuration:
          DestLocalizedText.fromJson(json['recommended_duration']),
      visaRequirement: DestLocalizedText.fromJson(json['visa_requirement']),
    );
  }
}

class DestinationAbout {
  final DestLocalizedText description;
  final DestLocalizedText visaNote;

  DestinationAbout({
    this.description = const DestLocalizedText(),
    this.visaNote = const DestLocalizedText(),
  });

  factory DestinationAbout.fromJson(Map<String, dynamic> json) {
    return DestinationAbout(
      description: DestLocalizedText.fromJson(json['description']),
      visaNote: DestLocalizedText.fromJson(json['visa_note']),
    );
  }
}

class DestinationAttraction {
  final String icon;
  final DestLocalizedText name;
  final DestLocalizedText description;
  final String slug;
  final Map<String, dynamic>? detailJson;

  DestinationAttraction({
    this.icon = '',
    this.name = const DestLocalizedText(),
    this.description = const DestLocalizedText(),
    this.slug = '',
    this.detailJson,
  });

  factory DestinationAttraction.fromJson(Map<String, dynamic> json) {
    final detail = json['detail'];
    return DestinationAttraction(
      icon: (json['icon'] ?? '').toString(),
      name: DestLocalizedText.fromJson(json['name']),
      description: DestLocalizedText.fromJson(json['description']),
      slug: (json['slug'] ?? '').toString(),
      detailJson: detail is Map<String, dynamic> ? detail : null,
    );
  }

  String get previewImage {
    final detail = detailJson;
    if (detail == null) return '';
    final hero = detail['hero'];
    if (hero is Map) {
      final image = (hero['image'] ?? '').toString().trim();
      if (image.isNotEmpty && image != 'null') return image;
    }
    final gallery = detail['gallery'];
    if (gallery is Map) {
      final items = gallery['items'];
      if (items is List) {
        for (final item in items) {
          if (item is! Map) continue;
          if ((item['type'] ?? '').toString() == 'video') continue;
          final image = (item['image'] ?? item['src'] ?? '').toString().trim();
          if (image.isNotEmpty) return image;
        }
      }
    }
    return '';
  }
}

/// "Arzon aviachiptalar" CTA bloki — qidiruv sanasi va narxlar bilan.
class DestinationAviaBlock {
  final String fromIata;
  final String toIata;
  final DestLocalizedText description;
  final int priceUzs;
  final int priceRub;
  final int priceUsd;
  final String date;

  DestinationAviaBlock({
    this.fromIata = '',
    this.toIata = '',
    this.description = const DestLocalizedText(),
    this.priceUzs = 0,
    this.priceRub = 0,
    this.priceUsd = 0,
    this.date = '',
  });

  factory DestinationAviaBlock.fromJson(Map<String, dynamic> json) {
    return DestinationAviaBlock(
      fromIata: json['from_iata'] ?? '',
      toIata: json['to_iata'] ?? '',
      description: DestLocalizedText.fromJson(json['description']),
      priceUzs: _toInt(json['price_uzs']),
      priceRub: _toInt(json['price_rub']),
      priceUsd: _toInt(json['price_usd']),
      date: json['date'] ?? '',
    );
  }
}

class DestinationContact {
  final DestLocalizedText message;
  final String phone;
  final String telegram;

  DestinationContact({
    this.message = const DestLocalizedText(),
    this.phone = '',
    this.telegram = '',
  });

  factory DestinationContact.fromJson(Map<String, dynamic> json) {
    return DestinationContact(
      message: DestLocalizedText.fromJson(json['message']),
      phone: (json['phone'] ?? '').toString(),
      telegram: (json['telegram'] ?? '').toString(),
    );
  }
}
