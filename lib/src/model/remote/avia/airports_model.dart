class AirPortsModel {
  String? countryIataCode;
  String? countryName;
  String? cityName;
  String? cityIataCode;
  List<Airports>? airports;

  AirPortsModel(
      {this.countryIataCode,
      this.countryName,
      this.cityName,
      this.cityIataCode,
      this.airports});

  AirPortsModel.fromJson(Map<String, dynamic> json) {
    countryIataCode = json['countryIataCode'] ?? "";
    countryName = json['countryName'] ?? "";
    cityName = json['cityName'] ?? "";
    cityIataCode = json['cityIataCode'] ?? "";

    airports = json['airports'] != null
        ? (json['airports'] as List)
            .map(
              (element) => Airports.fromJson(element),
            )
            .toList()
        : <Airports>[];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['countryIataCode'] = countryIataCode;
    data['countryName'] = countryName;
    data['cityName'] = cityName;
    data['cityIataCode'] = cityIataCode;
    if (airports != null) {
      data['airports'] = airports!.map((v) => v.toJson()).toList();
    }
    return data;
  }

  AirPortsModel copyWith({
    String? countryIataCode,
    String? countryName,
    String? cityName,
    String? cityIataCode,
    List<Airports>? airports,
  }) {
    return AirPortsModel(
      countryIataCode: countryIataCode ?? this.countryIataCode,
      countryName: countryName ?? this.countryName,
      cityName: cityName ?? this.cityName,
      cityIataCode: cityIataCode ?? this.cityIataCode,
      airports: airports ?? this.airports,
    );
  }

  @override
  String toString() {
    return "AirPortsModel (cityIataCode : $cityIataCode )";
  }
}

class Airports {
  String? airportName;
  String? airportIataCode;

  Airports({this.airportName, this.airportIataCode});

  Airports.fromJson(Map<String, dynamic> json) {
    airportName = json['airportName'] ?? "";
    airportIataCode = json['airportIataCode'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['airportName'] = airportName;
    data['airportIataCode'] = airportIataCode;
    return data;
  }
}
