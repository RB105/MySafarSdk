import 'dart:math' show Random;
import 'package:intl/intl.dart' show DateFormat;
import 'package:mysafar_sdk/src/model/local/recom_req_model.dart';
import 'package:mysafar_sdk/src/model/remote/avia/airports_model.dart';

class DestinationMapConstants {
  DestinationMapConstants._();

  static const double initialZoom = 14.0;
  static const double defaultZoom = 14.0;

  static const double placeholderMarkerSize = 72.0;
  static const double imageMarkerSize = 120.0;
  static const double markerBorderRadius = 20.0;
  static const double markerInnerMargin = 5.0;

  static const String tashkentIataCode = 'TAS';
  static const String tashkentCityName = 'Tashkent';

  static const int minDaysFromNow = 5;
  static const int maxDaysFromNow = 10;
}

class DestinationTicketHelper {
  DestinationTicketHelper._();

  static RecommendationRequestBody createTicketRequest({
    required String destinationCode,
    required String destinationName,
  }) {
    final fromAirport = AirPortsModel(
      cityIataCode: DestinationMapConstants.tashkentIataCode,
      cityName: DestinationMapConstants.tashkentCityName,
    );

    final toAirport = AirPortsModel(
      cityIataCode: destinationCode,
      cityName: destinationName,
    );

    final departureDate = _getRandomDepartureDate();
    final formattedDate = DateFormat('dd.MM.yyyy').format(departureDate);

    final segment = RecommendationReqBodySegment(
      from: fromAirport,
      to: toAirport,
      date: formattedDate,
    );

    return RecommendationRequestBody(
      adt: 1,
      chd: 0,
      inf: 0,
      segments: [segment],
      flight_Type: 0,
      klass: 'a',
    );
  }

  static DateTime _getRandomDepartureDate() {
    final random = Random();
    final daysToAdd = DestinationMapConstants.minDaysFromNow +
        random.nextInt(
            DestinationMapConstants.maxDaysFromNow - DestinationMapConstants.minDaysFromNow + 1);
    return DateTime.now().add(Duration(days: daysToAdd));
  }
}

