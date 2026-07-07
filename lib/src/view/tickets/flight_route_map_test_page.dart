// ignore_for_file: depend_on_referenced_packages

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:mysafar_sdk/src/core/styles/theme.dart' show ProjectTheme;
import 'package:mysafar_sdk/src/core/tools/airport_locator.dart';

/// Reys marshrutini 2D xaritada ko'rsatuvchi test sahifasi.
///
/// Borish va qaytish uchun alohida IATA ro'yxatlari kiritiladi
/// (masalan borish `TAS, IST, JFK`, qaytish `JFK, DXB, TAS`). "Boshlash"
/// bosilganda:
///  - borish marshruti samolyot bilan ketma-ket uchiladi, oxirgi aeroportda
///    qo'nadi;
///  - agar qaytish bo'lsa, qo'nish aeroportida 2 soniya turadi, so'ng:
///     • qaytish o'sha aeroportdan boshlansa — samolyot joyida 180° buriladi;
///     • boshqa aeroportdan boshlansa (open-jaw) — kamera o'sha aeroportga
///       o'tib, qaytishni shu yerdan boshlaydi;
///  - qaytish marshruti ham oxirgi qo'nish nuqtasigacha uchiladi.
class FlightRouteMapTestPage extends StatefulWidget {
  static const routeName = '/flightRouteMapTest';

  /// Ticket info'dan ochilganda — borish va qaytish IATA kodlari ro'yxati.
  /// `null` bo'lsa, sahifa test rejimida (input maydonlari bilan) ishlaydi;
  /// berilsa input/"Boshlash" o'rniga appbar'da kodlar ko'rsatiladi va
  /// xarita ochilishi bilan animatsiya darhol boshlanadi.
  final List<String>? outboundCodes;
  final List<String>? returnCodes;

  const FlightRouteMapTestPage({
    super.key,
    this.outboundCodes,
    this.returnCodes,
  });

  @override
  State<FlightRouteMapTestPage> createState() => _FlightRouteMapTestPageState();
}

class _FlightRouteMapTestPageState extends State<FlightRouteMapTestPage>
    with TickerProviderStateMixin {
  static const Color _routeColor = Color(0xFF2E5CFF);

  /// Uchish paytidagi yaqin zoom (aeroport ko'rinadi).
  static const double _zoomNear = 8.5;

  /// Qo'nish paytidagi zoom — uchishnikidan kattaroq (yaqinroq ko'rinish).
  static const double _zoomLand = 11.0;

  /// Parvoz o'rtasidagi uzoq zoom (baland parvoz hissi).
  static const double _zoomFar = 2.4;

  /// Bitta segment (uchish→qo'nish) animatsiyasi davomiyligi.
  static const Duration _segmentDuration = Duration(milliseconds: 6500);

  /// Borish tugagach qaytishdan oldin qo'nib turish vaqti.
  static const Duration _layoverDelay = Duration(seconds: 2);

  /// Uchish/qo'nish paytidagi eng kichik o'lcham koeffitsienti.
  static const double _planeMinScale = 0.72;

  /// Parvoz o'rtasidagi eng katta o'lcham koeffitsienti.
  static const double _planeMaxScale = 1.32;

  final TextEditingController _outboundController =
      TextEditingController(text: 'TAS, IST, JFK');
  final TextEditingController _returnController =
      TextEditingController(text: 'JFK, DXB, TAS');

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  List<_AirportPoint> _outbound = [];
  List<_AirportPoint> _return = [];

  BitmapDescriptor? _arrowIcon;
  AnimationController? _segCtrl; // joriy segment/burilish animatsiyasi

  /// iOS'da kamera yangilanishini "orqa-bosim" bilan cheklash uchun: oldingi
  /// `moveCamera` tugamaguncha yangisini yubormaymiz (platform kanali toshib
  /// ilova qotib qolmasligi uchun).
  bool _cameraBusy = false;

  /// Kamerani har kadr emas, ~60fps (16ms) dan tez yangilamaslik uchun
  /// vaqt bo'yicha throttling. Har bir `moveCamera`dan keyin yangilanadi.
  int _lastCameraMoveMs = 0;

  /// Samolyot rasmi o'lchami: parvozda kattalashadi, qo'nishda kichiklashadi.
  /// `setState`siz har kadrda yangilanadi (faqat overlay qayta chiziladi).
  final ValueNotifier<double> _planeScale =
      ValueNotifier<double>(_planeMinScale);

  /// Samolyot ikonkasi yo'nalishi (radian): xarita aylanmaydi, ikonkaning
  /// o'zi harakat yo'nalishiga qarab buriladi. `setState`siz yangilanadi.
  final ValueNotifier<double> _planeHeading = ValueNotifier<double>(0);

  bool _loading = false;
  bool _showPlane = false;
  int _animGen = 0; // har yangi animatsiyada o'zgaradi (eskisini to'xtatadi)
  String? _error;

  /// Ticket info'dan ochilganmi (kodlar tashqaridan berilgan).
  bool get _fromTicket => widget.outboundCodes != null;

  @override
  void initState() {
    super.initState();
    // Ticket info'dan ochilgan bo'lsa, kelgan kodlarni maydonlarga joylaymiz.
    if (_fromTicket) {
      _outboundController.text = widget.outboundCodes!.join(', ');
      _returnController.text = (widget.returnCodes ?? const []).join(', ');
    }
    // Sahifa ochilishi bilan marshrutni tugma bosmasdan ko'rsatamiz.
    WidgetsBinding.instance.addPostFrameCallback((_) => _buildRoute());
  }

  @override
  void dispose() {
    _animGen++; // davom etayotgan animatsiyani to'xtatadi
    _segCtrl?.dispose();
    _segCtrl = null;
    _planeScale.dispose();
    _planeHeading.dispose();
    _outboundController.dispose();
    _returnController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  /// Animatsiyani to'xtatish kerakmi (yangi avlod boshlandi yoki widget ketdi).
  bool _stop(int gen) => gen != _animGen || !mounted;

  // ───────────────────────── Marshrutni qurish ─────────────────────────

  Future<void> _buildRoute() async {
    if (mounted) FocusScope.of(context).unfocus();

    final outboundCodes = _parseCodes(_outboundController.text);
    if (outboundCodes.length < 2) {
      setState(() =>
          _error = 'Borish uchun kamida 2 ta IATA kodi kiriting (masalan TAS, IST).');
      return;
    }
    final returnCodes = _parseCodes(_returnController.text);

    setState(() {
      _loading = true;
      _error = null;
    });

    final (outbound, unknownOut) = await _resolveCodes(outboundCodes);
    final (ret, unknownRet) = await _resolveCodes(returnCodes);

    final unknown = [...unknownOut, ...unknownRet];
    if (unknown.isNotEmpty) {
      setState(() {
        _loading = false;
        _error = 'Quyidagi kod(lar) topilmadi: ${unknown.join(', ')}';
      });
      return;
    }

    _outbound = outbound;
    _return = ret.length >= 2 ? ret : []; // qaytish faqat 2+ nuqta bo'lsa
    _arrowIcon ??= await _buildArrowIcon();

    final markers = <Marker>{};
    final polylines = <Polyline>{};

    final all = [..._outbound, ..._return];
    for (var i = 0; i < all.length; i++) {
      markers.add(_airportMarker(all[i], i == 0, i == all.length - 1, i));
    }
    _addSegments(_outbound, 'out', markers, polylines);
    _addSegments(_return, 'ret', markers, polylines);

    if (!mounted) return;
    setState(() {
      _markers
        ..clear()
        ..addAll(markers);
      _polylines
        ..clear()
        ..addAll(polylines);
      _loading = false;
    });

    await _startFlightAnimation();
  }

  /// IATA kodlarini koordinatali nuqtalarga aylantiradi; topilmaganlarini
  /// ikkinchi ro'yxatda qaytaradi.
  Future<(List<_AirportPoint>, List<String>)> _resolveCodes(
      List<String> codes) async {
    final points = <_AirportPoint>[];
    final unknown = <String>[];
    for (final code in codes) {
      final coord = await AirportLocator.coordinatesOf(code);
      if (coord == null) {
        unknown.add(code);
      } else {
        points.add(_AirportPoint(code, LatLng(coord[0], coord[1])));
      }
    }
    return (points, unknown);
  }

  /// Bir yo'nalish (borish yoki qaytish) uchun polyline va strelkalarni quradi.
  void _addSegments(
    List<_AirportPoint> pts,
    String prefix,
    Set<Marker> markers,
    Set<Polyline> polylines,
  ) {
    for (var i = 0; i < pts.length - 1; i++) {
      final from = pts[i].position;
      final to = pts[i + 1].position;

      polylines.add(
        Polyline(
          polylineId: PolylineId('${prefix}_seg_$i'),
          points: _greatCircleArc(from, to, steps: 72),
          color: _routeColor,
          width: 4,
          patterns: [PatternItem.dash(24), PatternItem.gap(12)],
        ),
      );

      for (final f in const [0.22, 0.5, 0.78]) {
        final at = _interpolate(from, to, f);
        final ahead = _interpolate(from, to, math.min(f + 0.02, 1.0));
        markers.add(
          Marker(
            markerId: MarkerId('${prefix}_arrow_${i}_$f'),
            position: at,
            icon: _arrowIcon!,
            anchor: const Offset(0.5, 0.5),
            flat: true,
            rotation: _bearing(at, ahead),
            zIndexInt: 2,
          ),
        );
      }
    }
  }

  // ──────────────────────── Parvoz animatsiyasi ───────────────────────

  Future<void> _startFlightAnimation() async {
    if (_mapController == null || _outbound.length < 2) return;

    final gen = ++_animGen;
    if (!mounted) return;
    _cameraBusy = false;
    _planeScale.value = _planeMinScale; // yerga yaqin — kichik
    setState(() => _showPlane = true);

    // 1. Borish boshlanish nuqtasiga yaqinlashamiz.
    await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_outbound.first.position, _zoomNear));
    if (_stop(gen)) return;
    // Samolyotni birinchi segment yo'nalishiga qaratamiz.
    _setHeading(_outbound.first.position, _outbound[1].position);
    await Future.delayed(const Duration(milliseconds: 900));

    // 2. Borish segmentlari (oxirgi aeroportda qo'nadi).
    if (!await _flySegments(_outbound, gen, firstStartZoom: _zoomNear)) return;

    // 3. Qaytish bo'lsa.
    if (_return.length >= 2) {
      // Borish qo'nish aeroportida 2 soniya turamiz.
      if (_stop(gen)) return;
      await Future.delayed(_layoverDelay);
      if (_stop(gen)) return;

      final arrival = _outbound.last;
      final retStart = _return.first;
      double retFirstStartZoom;

      if (_samePlace(arrival.position, retStart.position)) {
        // Aynan o'sha aeroportdan uchadi — samolyot joyida buriladi (~180°).
        final inBearing = _bearing(
            _outbound[_outbound.length - 2].position, arrival.position);
        final outBearing = _bearing(retStart.position, _return[1].position);
        await _rotateInPlace(arrival.position, inBearing, outBearing, gen);
        if (_stop(gen)) return;
        retFirstStartZoom = _zoomLand; // joyida qoldik (qo'nish zoomida)
      } else {
        // Boshqa aeroportdan boshlanadi (open-jaw) — kamera o'sha aeroportga
        // o'tadi va qaytish shu yerdan boshlanadi.
        await _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(retStart.position, _zoomNear));
        if (_stop(gen)) return;
        _setHeading(retStart.position, _return[1].position);
        await Future.delayed(const Duration(milliseconds: 700));
        retFirstStartZoom = _zoomNear;
      }

      // 4. Qaytish segmentlari.
      if (!await _flySegments(_return, gen, firstStartZoom: retFirstStartZoom)) {
        return;
      }
    }

    if (_stop(gen)) return;
    setState(() => _showPlane = false);
  }

  /// Ketma-ket segmentlarni uchadi; oraliq (peresadka) nuqtalarida qisqa
  /// to'xtaydi. Animatsiya to'xtatilsa `false` qaytaradi.
  Future<bool> _flySegments(
    List<_AirportPoint> pts,
    int gen, {
    required double firstStartZoom,
  }) async {
    for (var i = 0; i < pts.length - 1; i++) {
      if (_stop(gen)) return false;
      // Birinchi segment berilgan zoomdan, keyingilari oldingi qo'nish
      // zoomidan (_zoomLand) boshlanadi — segmentlar orasida sakrash bo'lmaydi.
      final startZoom = i == 0 ? firstStartZoom : _zoomLand;
      await _animateSegment(
        pts[i].position,
        pts[i + 1].position,
        gen,
        startZoom: startZoom,
        endZoom: _zoomLand,
      );
      if (_stop(gen)) return false;
      if (i < pts.length - 2) {
        await Future.delayed(const Duration(milliseconds: 800));
      }
    }
    return true;
  }

  /// Bitta segment (from→to) bo'ylab kamerani samolyot bilan harakatlantiradi.
  /// Xarita shimol tepada qoladi (bearing 0); samolyot ikonkasi yo'nalishga
  /// buriladi. Zoom: [startZoom] (uchish) → uzoq (parvoz) → [endZoom] (qo'nish).
  Future<void> _animateSegment(
    LatLng from,
    LatLng to,
    int gen, {
    required double startZoom,
    required double endZoom,
  }) async {
    final controller =
        AnimationController(vsync: this, duration: _segmentDuration);
    _segCtrl = controller;
    _cameraBusy = false;
    final curved = CurvedAnimation(parent: controller, curve: Curves.easeInOut);

    void tick() {
      if (_stop(gen)) return;
      final t = curved.value;
      final pos = _interpolate(from, to, t);
      // Yo'nalish: nuqtadan biroz oldin/keyin orasidagi burilish (uchlarida
      // bir xil nuqta tushib qolmasligi uchun behind→ahead).
      final behind = _interpolate(from, to, math.max(t - 0.02, 0.0));
      final ahead = _interpolate(from, to, math.min(t + 0.02, 1.0));
      _setHeading(behind, ahead);
      // sin(pi*t): t=0→0 (yaqin), t=0.5→1 (uzoq), t=1→0 (yaqin).
      final wave = math.sin(math.pi * t);
      // "Yaqin" zoom t bo'yicha startZoom→endZoom ga suriladi (qo'nish zoomi
      // uchishnikidan kattaroq bo'lishi mumkin); o'rtada _zoomFar ga tushadi.
      final near = startZoom + (endZoom - startZoom) * t;
      final zoom = near - (near - _zoomFar) * wave;
      // Samolyot: parvozda (o'rtada) kattalashadi, qo'nishda kichiklashadi.
      _planeScale.value =
          _planeMinScale + (_planeMaxScale - _planeMinScale) * wave;
      // Kamerani "orqa-bosim" + vaqt throttling bilan yangilaymiz: oldingi
      // moveCamera tugamasa yoki oxirgi yangilanishdan 16ms (~60fps) o'tmasa
      // bu kadrni o'tkazib yuboramiz. Aks holda har kadrgi moveCamera iOS
      // platform kanalini toshirib ilovani qotirib qo'yadi.
      if (_cameraBusy || _mapController == null) return;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (nowMs - _lastCameraMoveMs < 16) return;
      _lastCameraMoveMs = nowMs;
      _cameraBusy = true;
      _mapController!
          .moveCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: pos, zoom: zoom),
            ),
          )
          .whenComplete(() => _cameraBusy = false);
    }

    curved.addListener(tick);
    await _runController(controller);

    // Oxirgi kadr o'tkazib yuborilgan bo'lishi mumkin — segment yakunida
    // kamerani aniq qo'nish nuqtasiga (yaqin zoomda) qo'yamiz.
    if (!_stop(gen)) {
      _planeScale.value = _planeMinScale;
      await _mapController?.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: to, zoom: endZoom),
        ),
      );
    }
  }

  /// Samolyot qo'ngan aeroportda joyida [fromBearing]→[toBearing] burchakka
  /// buriladi (qisqa yo'nalishli yoy bo'yicha). Xarita aylanmaydi — faqat
  /// samolyot ikonkasi buriladi. Bir xil yo'lda qaytishda bu ~180° burilish.
  Future<void> _rotateInPlace(
      LatLng at, double fromBearing, double toBearing, int gen) async {
    final controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _segCtrl = controller;
    _planeScale.value = _planeMinScale; // yerda buriladi — kichik
    final curved = CurvedAnimation(parent: controller, curve: Curves.easeInOut);

    // Qisqa yo'nalishli burchak farqi: [-180, 180].
    var delta = (toBearing - fromBearing) % 360;
    if (delta > 180) delta -= 360;

    // Kamera qo'nish aeroportida, shimol tepada (qo'nish zoomida) turadi.
    _mapController?.moveCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: at, zoom: _zoomLand),
    ));

    void tick() {
      if (_stop(gen)) return;
      // Kamera emas, samolyot ikonkasi buriladi.
      _planeHeading.value =
          (fromBearing + delta * curved.value) * math.pi / 180.0;
    }

    curved.addListener(tick);
    await _runController(controller);
  }

  /// Samolyot ikonkasini [from]→[to] yo'nalishiga buradi (radian).
  void _setHeading(LatLng from, LatLng to) {
    _planeHeading.value = _bearing(from, to) * math.pi / 180.0;
  }

  /// Controllerni forward qiladi va xavfsiz tozalaydi (sahifa yopilsa ham).
  Future<void> _runController(AnimationController controller) async {
    try {
      await controller.forward();
    } catch (_) {
      // Sahifa yopilib controller dispose qilingan bo'lishi mumkin — e'tiborsiz.
    } finally {
      if (identical(_segCtrl, controller)) {
        controller.dispose();
        _segCtrl = null;
      }
    }
  }

  // ───────────────────────────── Yordamchilar ──────────────────────────

  List<String> _parseCodes(String raw) {
    return raw
        .toUpperCase()
        .split(RegExp(r'[\s,\-/>]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Ikki nuqta bir xil aeroportmi (koordinatalari deyarli teng).
  bool _samePlace(LatLng a, LatLng b) {
    return (a.latitude - b.latitude).abs() < 1e-4 &&
        (a.longitude - b.longitude).abs() < 1e-4;
  }

  Marker _airportMarker(
      _AirportPoint point, bool isFirst, bool isLast, int index) {
    final double hue;
    final String label;
    if (isFirst) {
      hue = BitmapDescriptor.hueGreen; // boshlang'ich uchish
      label = 'Uchish';
    } else if (isLast) {
      hue = BitmapDescriptor.hueRed; // oxirgi qo'nish
      label = 'Oxirgi qo\'nish';
    } else {
      hue = BitmapDescriptor.hueOrange; // oraliq / peresadka
      label = 'Oraliq / peresadka';
    }

    return Marker(
      markerId: MarkerId('apt_${index}_${point.code}'),
      position: point.position,
      icon: BitmapDescriptor.defaultMarkerWithHue(hue),
      zIndexInt: 3,
      infoWindow: InfoWindow(title: point.code, snippet: label),
    );
  }

  // ───────────────────── Geometriya (great-circle) ─────────────────────

  static double _rad(double deg) => deg * math.pi / 180.0;
  static double _deg(double rad) => rad * 180.0 / math.pi;

  /// Ikki nuqta orasidagi (egilgan) yoyni [steps] ta nuqta bilan quradi.
  List<LatLng> _greatCircleArc(LatLng from, LatLng to, {int steps = 64}) {
    final list = <LatLng>[];
    for (var i = 0; i <= steps; i++) {
      list.add(_interpolate(from, to, i / steps));
    }
    return list;
  }

  /// Yoy egriligi koeffitsienti: segment uzunligiga nisbatan yon siljish.
  /// 0 → to'g'ri great-circle chiziq; kattaroq → ko'proq egilgan yoy.
  /// Egilish borish va qaytish yo'llarini ustma-ust tushishdan saqlaydi.
  static const double _arcCurvature = 0.14;

  /// `from`→`to` segmenti bo'ylab [f] (0..1) nuqtasi — yengil o'ng egrilik
  /// bilan. Borish-qaytish bir xil shaharlar orasida bo'lsa ham, har yo'nalish
  /// o'z o'ng tomoniga egilgani uchun chiziqlar ajralib turadi.
  LatLng _interpolate(LatLng from, LatLng to, double f) {
    final base = _greatCircleInterp(from, to, f);

    final d = _angularDistance(from, to);
    if (d < 1e-9) return base;

    // O'rtada eng katta, ikki uchida nol bo'lgan yon siljish (radian).
    final offset = _arcCurvature * d * math.sin(math.pi * f);
    if (offset.abs() < 1e-12) return base;

    // Segment yo'nalishining o'ng perpendikulyari bo'ylab siljitamiz.
    final bearing = _bearingRad(from, to) + math.pi / 2;
    return _destinationPoint(base, bearing, offset);
  }

  /// Sof great-circle bo'ylab [f] (0..1) nuqtasi (egriliksiz).
  LatLng _greatCircleInterp(LatLng from, LatLng to, double f) {
    final lat1 = _rad(from.latitude), lon1 = _rad(from.longitude);
    final lat2 = _rad(to.latitude), lon2 = _rad(to.longitude);

    final d = _angularDistance(from, to);
    if (d == 0) return from;

    final a = math.sin((1 - f) * d) / math.sin(d);
    final b = math.sin(f * d) / math.sin(d);

    final x = a * math.cos(lat1) * math.cos(lon1) +
        b * math.cos(lat2) * math.cos(lon2);
    final y = a * math.cos(lat1) * math.sin(lon1) +
        b * math.cos(lat2) * math.sin(lon2);
    final z = a * math.sin(lat1) + b * math.sin(lat2);

    final lat = math.atan2(z, math.sqrt(x * x + y * y));
    final lon = math.atan2(y, x);
    return LatLng(_deg(lat), _deg(lon));
  }

  /// Ikki nuqta orasidagi burchak masofasi (radian).
  double _angularDistance(LatLng from, LatLng to) {
    final lat1 = _rad(from.latitude), lon1 = _rad(from.longitude);
    final lat2 = _rad(to.latitude), lon2 = _rad(to.longitude);
    return 2 *
        math.asin(
          math.sqrt(
            math.pow(math.sin((lat1 - lat2) / 2), 2) +
                math.cos(lat1) *
                    math.cos(lat2) *
                    math.pow(math.sin((lon1 - lon2) / 2), 2),
          ),
        );
  }

  /// `from`→`to` yo'nalishi (radian, shimoldan soat strelkasi bo'yicha).
  double _bearingRad(LatLng from, LatLng to) {
    final lat1 = _rad(from.latitude), lat2 = _rad(to.latitude);
    final dLon = _rad(to.longitude - from.longitude);
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return math.atan2(y, x);
  }

  /// [start] nuqtadan [bearing] (radian) yo'nalishida [angularDist] (radian)
  /// masofadagi nuqta.
  LatLng _destinationPoint(LatLng start, double bearing, double angularDist) {
    final lat1 = _rad(start.latitude), lon1 = _rad(start.longitude);
    final lat2 = math.asin(
      math.sin(lat1) * math.cos(angularDist) +
          math.cos(lat1) * math.sin(angularDist) * math.cos(bearing),
    );
    final lon2 = lon1 +
        math.atan2(
          math.sin(bearing) * math.sin(angularDist) * math.cos(lat1),
          math.cos(angularDist) - math.sin(lat1) * math.sin(lat2),
        );
    return LatLng(_deg(lat2), _deg(lon2));
  }

  /// `from`→`to` yo'nalishi (0..360, shimoldan soat strelkasi bo'yicha).
  double _bearing(LatLng from, LatLng to) {
    return (_deg(_bearingRad(from, to)) + 360) % 360;
  }

  /// Shimolga (yuqoriga) qaragan strelka iconi — marker rotation bilan
  /// yo'nalishga buriladi.
  Future<BitmapDescriptor> _buildArrowIcon({double size = 56}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final fill = Paint()
      ..color = _routeColor
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.06
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size * 0.5, size * 0.12) // uchi (shimol)
      ..lineTo(size * 0.84, size * 0.84) // o'ng past
      ..lineTo(size * 0.5, size * 0.64) // o'rta tirqish
      ..lineTo(size * 0.16, size * 0.84) // chap past
      ..close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);

    final image =
        await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return BitmapDescriptor.defaultMarker;
    return BitmapDescriptor.bytes(data.buffer.asUint8List());
  }

  // ──────────────────────────────── UI ────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Test rejimida input bilan; ticket rejimida kodlar appbar'da.
          if (!_fromTicket) _buildInputBar(),
          if (_error != null) _buildError(),
          Expanded(child: _buildMap()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (!_fromTicket) {
      return AppBar(title: const Text('Reys marshruti (test)'));
    }
    final hasReturn = (widget.returnCodes ?? const []).length >= 2;
    return AppBar(
      backgroundColor: ProjectTheme.brandColor,
      foregroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: hasReturn ? 78 : 60,
      title: _buildCodesBar(),
    );
  }

  /// Appbar'da borish (va bo'lsa qaytish) IATA kodlari zanjiri.
  Widget _buildCodesBar() {
    final out = widget.outboundCodes ?? const [];
    final ret = widget.returnCodes ?? const [];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _codesRow(Icons.flight_takeoff_rounded, out),
        if (ret.length >= 2) ...[
          const SizedBox(height: 4),
          _codesRow(Icons.flight_land_rounded, ret),
        ],
      ],
    );
  }

  Widget _codesRow(IconData icon, List<String> codes) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            codes.join('  →  '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        children: [
          TextField(
            controller: _outboundController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Borish (IATA kodlari)',
              hintText: 'TAS, IST, JFK',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.flight_takeoff, size: 20),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _returnController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Qaytish (ixtiyoriy)',
              hintText: 'JFK, DXB, TAS',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.flight_land, size: 20),
            ),
            onSubmitted: (_) => _buildRoute(),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _buildRoute,
              style: ElevatedButton.styleFrom(
                backgroundColor: _routeColor,
                foregroundColor: Colors.white,
              ),
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow_rounded),
              label: const Text('Boshlash'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        _error!,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  Widget _buildMap() {
    return Stack(
      alignment: Alignment.center,
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(41.2995, 69.2401), // Toshkent
            zoom: 3,
          ),
          markers: _markers,
          polylines: _polylines,
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          onMapCreated: (controller) {
            _mapController = controller;
            // Xarita marshrutdan kechroq tayyor bo'lsa, animatsiyani
            // shu yerda ishga tushiramiz.
            if (_outbound.length >= 2) _startFlightAnimation();
          },
        ),
        // Kamera samolyotni markazda ushlab turadi, shuning uchun samolyot
        // ikonkasini ekran markazida statik joylashtiramiz — kamera bearing
        // bilan harakatlanib, samolyot doim oldinga uchayotgandek ko'rinadi.
        if (_showPlane) _buildPlaneOverlay(),
      ],
    );
  }

  Widget _buildPlaneOverlay() {
    return IgnorePointer(
      // O'lcham parvozda kattalashadi, qo'nishda kichiklashadi (setState'siz).
      child: ValueListenableBuilder<double>(
        valueListenable: _planeScale,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        // Xarita aylanmaydi — ikonkaning o'zi harakat yo'nalishiga buriladi.
        child: ValueListenableBuilder<double>(
          valueListenable: _planeHeading,
          builder: (context, heading, child) => Transform.rotate(
            // Samolyot silueti tabiatan to'g'ri tepaga (shimolga) qaragan,
            // shuning uchun tuzatishsiz to'g'ridan-to'g'ri yo'nalishga buramiz —
            // tumshuq aniq marshrut chizig'i ustida bo'ladi.
            angle: heading,
            child: child,
          ),
          child: CustomPaint(
            size: const Size(58, 60),
            painter: _PlanePainter(_routeColor),
          ),
        ),
      ),
    );
  }
}

/// Aeroport nuqtasi: IATA kodi + koordinatasi.
class _AirportPoint {
  final String code;
  final LatLng position;

  const _AirportPoint(this.code, this.position);
}

/// Ustdan ko'rinishdagi real samolyot (layner) siluetini chizadi.
/// Tumshug'i to'g'ri tepaga (shimolga) qaragan — `Transform.rotate` bilan
/// harakat yo'nalishiga buriladi.
class _PlanePainter extends CustomPainter {
  final Color color;

  const _PlanePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    Offset p(double x, double y) => Offset(x * w, y * h);

    // Siluet konturi: tumshuqdan boshlab soat strelkasi bo'yicha — fyuzelyaj,
    // orqaga qiyshaygan qanot, dum (gorizontal stabilizator), dum uchi va
    // chap tomon ko'zgusi.
    final outline = <Offset>[
      p(0.50, 0.02), // tumshuq (tepa, shimol)
      p(0.585, 0.20), // o'ng fyuzelyaj
      p(0.585, 0.32), // qanot oldingi qirrasi (ildiz)
      p(0.99, 0.52), // o'ng qanot uchi (old)
      p(0.99, 0.61), // o'ng qanot uchi (orqa)
      p(0.585, 0.47), // qanot orqa qirrasi (ildiz)
      p(0.585, 0.80), // fyuzelyaj — dumgacha
      p(0.80, 0.92), // o'ng stabilizator uchi (old)
      p(0.80, 0.99), // o'ng stabilizator uchi (orqa)
      p(0.535, 0.90), // stabilizator ildizi
      p(0.50, 1.00), // dum uchi (past)
      p(0.465, 0.90), // — chap ko'zgu —
      p(0.20, 0.99),
      p(0.20, 0.92),
      p(0.415, 0.80),
      p(0.415, 0.47),
      p(0.01, 0.61),
      p(0.01, 0.52),
      p(0.415, 0.32),
      p(0.415, 0.20),
    ];

    final path = Path()..addPolygon(outline, true);

    // Yengil soya — xaritada ajralib turishi uchun.
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.5), 2.0, false);

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_PlanePainter oldDelegate) => oldDelegate.color != color;
}
