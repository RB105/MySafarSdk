import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_earth_globe/globe_coordinates.dart';
import 'package:flutter_earth_globe/point.dart';
import 'package:flutter_earth_globe/point_connection.dart';
import 'package:flutter_earth_globe/point_connection_style.dart';
import 'package:mysafar_sdk/src/core/tools/airport_locator.dart';

/// A static 3D globe that visualises a flight route: the departure and arrival
/// airports are plotted as labelled points, joined by an arc, with a plane
/// marker at the middle of the route. Coordinates are resolved from the
/// [originCode]/[destCode] IATA codes via the offline [AirportLocator].
class RouteGlobeWidget extends StatefulWidget {
  final String originCode;
  final String destCode;

  const RouteGlobeWidget({
    super.key,
    required this.originCode,
    required this.destCode,
  });

  @override
  State<RouteGlobeWidget> createState() => _RouteGlobeWidgetState();
}

class _RouteGlobeWidgetState extends State<RouteGlobeWidget> {
  late final FlutterEarthGlobeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FlutterEarthGlobeController(
      surface: const AssetImage('assets/img/tickets/earth_day.jpg'),
      // Static globe — no auto-rotation.
      isRotating: false,
      zoom: 0,
      showAtmosphere: true,
      atmosphereColor: Colors.lightBlueAccent,
    );
    _buildRoute();
  }

  Future<void> _buildRoute() async {
    final origin = await AirportLocator.coordinatesOf(widget.originCode);
    final dest = await AirportLocator.coordinatesOf(widget.destCode);
    if (!mounted) return;

    if (origin != null) {
      _controller.addPoint(_airportPoint('origin', origin, widget.originCode));
    }
    if (dest != null) {
      _controller.addPoint(_airportPoint('dest', dest, widget.destCode));
    }

    if (origin != null && dest != null) {
      final start = GlobeCoordinates(origin[0], origin[1]);
      final end = GlobeCoordinates(dest[0], dest[1]);

      // The route line between the two airports.
      _controller.addPointConnection(PointConnection(
        id: 'route',
        start: start,
        end: end,
        style: const PointConnectionStyle(
          type: PointConnectionType.solid,
          color: Colors.white,
          lineWidth: 2,
        ),
      ));

      // Plane marker at the middle of the route, rotated along its bearing.
      final mid = _greatCircleMidpoint(origin, dest);
      final bearing = _bearing(origin, dest);
      _controller.addPoint(Point(
        id: 'plane',
        coordinates: GlobeCoordinates(mid[0], mid[1]),
        isLabelVisible: true,
        style: const PointStyle(color: Colors.transparent, size: 0),
        labelBuilder: (context, point, isHovering, isVisible) =>
            Transform.rotate(
          angle: bearing,
          child: const Icon(Icons.flight, color: Colors.white, size: 22),
        ),
      ));

      // Centre the camera on the route so both airports stay in view.
      _controller.focusOnCoordinates(GlobeCoordinates(mid[0], mid[1]));
    } else if (origin != null) {
      _controller.focusOnCoordinates(GlobeCoordinates(origin[0], origin[1]));
    } else if (dest != null) {
      _controller.focusOnCoordinates(GlobeCoordinates(dest[0], dest[1]));
    }
  }

  /// A labelled white airport marker.
  Point _airportPoint(String id, List<double> coords, String label) => Point(
        id: id,
        coordinates: GlobeCoordinates(coords[0], coords[1]),
        label: label,
        isLabelVisible: true,
        labelTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        style: const PointStyle(color: Colors.white, size: 5),
      );

  /// Great-circle midpoint of two `[lat, lon]` coordinates (degrees).
  List<double> _greatCircleMidpoint(List<double> a, List<double> b) {
    final lat1 = _rad(a[0]), lon1 = _rad(a[1]);
    final lat2 = _rad(b[0]), lon2 = _rad(b[1]);
    final dLon = lon2 - lon1;
    final bx = math.cos(lat2) * math.cos(dLon);
    final by = math.cos(lat2) * math.sin(dLon);
    final latm = math.atan2(
      math.sin(lat1) + math.sin(lat2),
      math.sqrt((math.cos(lat1) + bx) * (math.cos(lat1) + bx) + by * by),
    );
    final lonm = lon1 + math.atan2(by, math.cos(lat1) + bx);
    return [_deg(latm), _deg(lonm)];
  }

  /// Initial bearing from `a` to `b` in radians (0 = north, clockwise).
  double _bearing(List<double> a, List<double> b) {
    final lat1 = _rad(a[0]), lat2 = _rad(b[0]);
    final dLon = _rad(b[1] - a[1]);
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return math.atan2(y, x);
  }

  double _rad(double deg) => deg * math.pi / 180.0;
  double _deg(double rad) => rad * 180.0 / math.pi;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0;
        final maxH =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 200.0;
        final side = maxW < maxH ? maxW : maxH;
        final radius = side > 0 ? side * 0.42 : 80.0;
        // RotatingGlobe centres its sphere on MediaQuery.size. Override it with
        // the box size so the globe centres inside this header box instead of
        // the whole screen.
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(size: Size(maxW, maxH)),
          child: FlutterEarthGlobe(
            controller: _controller,
            radius: radius,
            alignment: Alignment.center,
          ),
        );
      },
    );
  }
}
