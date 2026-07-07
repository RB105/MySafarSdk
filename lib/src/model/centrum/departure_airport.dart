class DepartureAirport {
  String? locationCode;
  String? terminal;

  DepartureAirport({this.locationCode, this.terminal});

  DepartureAirport.fromJson(Map<String, dynamic> json) {
    locationCode = json['@LocationCode'];
    terminal = json['@Terminal'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['@LocationCode'] = locationCode;
    data['@Terminal'] = terminal;
    return data;
  }
}
