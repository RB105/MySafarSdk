/// `/avia/monthly-price-calendar` javobi.
///
/// ```json
/// {
///   "prices": {
///     "2026-07-28": {
///       "price": {"UZS": "2 881 830", "RUB": "19 111", "USD": "244", "raw": 2881830},
///       "flight_id": "...", "carrier_code": "HH", "duration": 320,
///       "is_baggage": false, "departure_time": "10:30", "arrival_time": "13:50"
///     }
///   },
///   "currency": "UZS", "from": "TAS", "to": "IST", "start_date": "2026-07-28"
/// }
/// ```
class TicketDatePriceModel {
  List<DatePrice>? uzsPrices;
  List<DatePrice>? rubPrices;
  List<DatePrice>? usdPrices;

  /// Kun bo'yicha qo'shimcha ma'lumot (reys vaqti, bagaj, davomiylik).
  Map<String, DayFlightInfo> flights;

  String? from;
  String? to;
  String? startDate;

  TicketDatePriceModel({
    this.uzsPrices,
    this.rubPrices,
    this.usdPrices,
    Map<String, DayFlightInfo>? flights,
    this.from,
    this.to,
    this.startDate,
  }) : flights = flights ?? <String, DayFlightInfo>{};

  TicketDatePriceModel.fromJson(Map<String, dynamic> json)
      : flights = <String, DayFlightInfo>{} {
    uzsPrices = [];
    rubPrices = [];
    usdPrices = [];
    from = json['from']?.toString();
    to = json['to']?.toString();
    startDate = json['start_date']?.toString();

    final prices = json['prices'];
    if (prices is Map) {
      final entries = prices.entries.toList()
        ..sort((a, b) => '${a.key}'.compareTo('${b.key}'));
      for (final entry in entries) {
        final key = '${entry.key}';
        final date = _parseDate(key);
        if (date == null) continue;

        final value = entry.value;
        if (value is! Map) continue;
        final price = value['price'];
        if (price is! Map) continue;

        _add(uzsPrices!, date, price['UZS'] ?? price['uzs']);
        _add(rubPrices!, date, price['RUB'] ?? price['rub']);
        _add(usdPrices!, date, price['USD'] ?? price['usd']);

        flights[key] = DayFlightInfo.fromJson(
          Map<String, dynamic>.from(value),
        );
      }
      return;
    }

    // Eski format (`{"uzs": {"2025-04-29": "551571"}}`) — moslik uchun.
    for (final entry in const [('uzs', 0), ('rub', 1), ('usd', 2)]) {
      final data = json[entry.$1];
      if (data is! Map) continue;
      final target = switch (entry.$2) {
        0 => uzsPrices!,
        1 => rubPrices!,
        _ => usdPrices!,
      };
      data.forEach((key, value) {
        final date = _parseDate('$key');
        if (date != null) _add(target, date, value);
      });
    }
  }

  /// Kun bo'yicha reys ma'lumoti (bo'lsa).
  DayFlightInfo? infoFor(DateTime date) {
    final key = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    return flights[key];
  }

  static void _add(List<DatePrice> target, DateTime date, dynamic raw) {
    final sum = _normalize(raw);
    if (sum == null) return;
    target.add(DatePrice(date: date, sum: sum));
  }

  /// "2 881 830" / 2881830 → "2881830"; bo'sh yoki nol bo'lsa null.
  static String? _normalize(dynamic raw) {
    if (raw == null) return null;
    final text = raw
        .toString()
        .replaceAll(' ', '')
        .replaceAll(' ', '')
        .replaceAll(' ', '')
        .replaceAll(',', '.');
    if (text.isEmpty) return null;
    final value = double.tryParse(text);
    if (value == null || value <= 0) return null;
    return text;
  }

  static DateTime? _parseDate(String dateStr) {
    try {
      return DateTime.parse(dateStr); // '2026-07-28'
    } catch (e) {
      return null;
    }
  }
}

/// Kalendardagi bitta kunning eng arzon reysi haqida qisqacha ma'lumot.
class DayFlightInfo {
  final String flightId;
  final String carrierCode;
  final int duration;
  final bool isBaggage;
  final bool isRefundable;
  final String departureTime;
  final String arrivalTime;
  final String departureAirport;
  final String arrivalAirport;

  const DayFlightInfo({
    required this.flightId,
    required this.carrierCode,
    required this.duration,
    required this.isBaggage,
    required this.isRefundable,
    required this.departureTime,
    required this.arrivalTime,
    required this.departureAirport,
    required this.arrivalAirport,
  });

  factory DayFlightInfo.fromJson(Map<String, dynamic> json) {
    return DayFlightInfo(
      flightId: json['flight_id']?.toString() ?? '',
      carrierCode: json['carrier_code']?.toString() ?? '',
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      isBaggage: json['is_baggage'] == true,
      isRefundable: json['is_refundable'] == true,
      departureTime: json['departure_time']?.toString() ?? '',
      arrivalTime: json['arrival_time']?.toString() ?? '',
      departureAirport: json['departure_airport']?.toString() ?? '',
      arrivalAirport: json['arrival_airport']?.toString() ?? '',
    );
  }
}

class DatePrice {
  DateTime? date;
  String? sum;

  DatePrice({this.date, this.sum});
}
