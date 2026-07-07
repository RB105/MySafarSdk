class TicketDatePriceModel {
  List<DatePrice>? uzsPrices;
  List<DatePrice>? rubPrices;
  List<DatePrice>? usdPrices;

  TicketDatePriceModel({this.uzsPrices, this.rubPrices, this.usdPrices});

  TicketDatePriceModel.fromJson(Map<String, dynamic> json) {
    uzsPrices = [];
    rubPrices = [];
    usdPrices = [];

    final uzsData = json['uzs'] as Map<String, dynamic>?;
    final rubData = json['rub'] as Map<String, dynamic>?;
    final usdData = json['usd'] as Map<String, dynamic>?;

    if (uzsData != null) {
      uzsData.forEach((key, value) {
        uzsPrices!.add(DatePrice(
          date: _parseDate(key),
          sum: value.toString(),
        ));
      });
    }

    if (rubData != null) {
      rubData.forEach((key, value) {
        rubPrices!.add(DatePrice(
          date: _parseDate(key),
          sum: value.toString(),
        ));
      });
    }

    if (usdData != null) {
      usdData.forEach((key, value) {
        usdPrices!.add(DatePrice(
          date: _parseDate(key),
          sum: value.toString(),
        ));
      });
    }
  }

  static DateTime? _parseDate(String dateStr) {
    try {
      return DateTime.parse(dateStr); // Parse '2025-04-29' into DateTime
    } catch (e) {
      return null; // If invalid, return null
    }
  }
}

class DatePrice {
  DateTime? date;
  String? sum;

  DatePrice({this.date, this.sum});
}
