// Creator: Ravshanov Anzor
// Created: 24.09.2026

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';

/// Bron yaratilayotganda ko'rsatiladigan TO'LIQ EKRAN (ilgari dialog edi).
///
/// Fon — sekin suzib yuradigan firuza gradient: bir nechta yumshoq dog'
/// doimiy aylanma yo'l bo'ylab siljiydi, shuning uchun rang jonli ko'rinadi.
/// Orqaga qaytarib bo'lmaydi: so'rov tugagach sahifa o'zi yopiladi.
class BookingProgressPage extends StatefulWidget {
  const BookingProgressPage({super.key});

  static const String routeName = '/bookingProgress';

  /// Ochiq route va u turgan navigator — yopish context'ga bog'liq emas:
  /// ostidagi sahifa yopilib ketgan bo'lsa ham progress sahifasi osilib
  /// qolmaydi.
  static Route<void>? _route;
  static NavigatorState? _navigator;

  /// Sahifa hozir ochiqmi.
  static bool get isOpen => _route != null;

  /// Sahifani ochadi (bir marta).
  ///
  /// SDK navigatorida ochiladi (`rootNavigator: false`): embed rejimida root
  /// navigator HOST ilovaniki — u yerga push qilinsa, SDK back handleri
  /// (`SdkEmbedBackHandler`) uni ko'rmasdi va yopishda host route'i
  /// yopilib ketishi mumkin edi.
  ///
  /// [RawDialogRoute] (PageRoute emas) — screen_view / voronka analitikasi
  /// "ekran" deb yozmaydi, ostidagi sahifa context'i tirik qoladi.
  static void show(BuildContext context) {
    if (_route != null) return;
    final navigator = Navigator.of(context);
    late final RawDialogRoute<void> route;
    route = RawDialogRoute<void>(
      settings: const RouteSettings(name: routeName),
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => const BookingProgressPage(),
      transitionBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    );
    _route = route;
    _navigator = navigator;
    navigator.push(route).whenComplete(() {
      // Qanday yopilmasin — holat tozalanadi, keyingi show() ishlaydi.
      if (identical(_route, route)) {
        _route = null;
        _navigator = null;
      }
    });
  }

  /// Ochiq bo'lsa yopadi. Faqat O'ZINI yopadi: tepada boshqa route bo'lsa
  /// ham uni emas, aynan progress route'ini olib tashlaydi.
  static void dismiss() {
    final route = _route;
    final navigator = _navigator;
    _route = null;
    _navigator = null;
    if (route == null || navigator == null || !navigator.mounted) return;
    if (!route.isActive) return;
    if (route.isCurrent) {
      navigator.pop();
    } else {
      navigator.removeRoute(route);
    }
  }

  @override
  State<BookingProgressPage> createState() => _BookingProgressPageState();
}

class _BookingProgressPageState extends State<BookingProgressPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Bron yuborilgan — foydalanuvchi orqaga qaytib oqimni buzmasin.
      canPop: false,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _FluidPainter(_controller.value),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Spacer(flex: 5),
                    Text(
                      'booking_progress_title'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'packages/mysafar_sdk/Gilroy',
                        fontSize: 27,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'booking_progress_subtitle'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'packages/mysafar_sdk/Gilroy',
                        fontSize: 16,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                    const Spacer(flex: 4),
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const Spacer(flex: 1),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quyuq moviy "mesh" fon: to'yingan rang dog'lari ekran bo'ylab katta
/// amplitudada suzadi, ustidan qiya yorug'lik chizig'i sekin o'tadi.
///
/// Palitra — ilovaning brend ko'ki atrofida: tungi ko'k, brend ko'ki,
/// osmon ko'ki va indigo. Dog'lar bir-biriga aralashib, rang doim o'zgarib
/// turgandek ko'rinadi.
class _FluidPainter extends CustomPainter {
  const _FluidPainter(this.t);

  /// 0..1 — bitta to'liq aylanish.
  final double t;

  static const Color _night = Color(0xFF071A3D); // tungi ko'k (asos)
  static const Color _brand = Color(0xFF0057BE); // brend ko'ki
  static const Color _sky = Color(0xFF00A8FF); // osmon ko'ki
  static const Color _indigo = Color(0xFF4B3FD8); // indigo
  static const Color _deep = Color(0xFF0A2E6E); // chuqur ko'k

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final w = size.width;
    final h = size.height;
    final a = t * 2 * math.pi;

    // Asos — to'q tungi ko'k.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_deep, _night],
        ).createShader(rect),
    );

    // Katta, to'yingan dog'lar — har biri o'z tezligi va yo'li bilan.
    // Amplituda katta: harakat ko'z bilan aniq sezilsin.
    _blob(canvas,
        center: Offset(w * (0.25 + 0.35 * math.cos(a)),
            h * (0.25 + 0.18 * math.sin(a * 2))),
        radius: w * 0.95,
        color: _brand,
        opacity: 0.95);
    _blob(canvas,
        center: Offset(w * (0.80 + 0.30 * math.cos(a + 2.1)),
            h * (0.45 + 0.22 * math.sin(a + 2.1))),
        radius: w * 0.85,
        color: _sky,
        opacity: 0.75);
    _blob(canvas,
        center: Offset(w * (0.35 + 0.40 * math.sin(a * 1.5 + 4)),
            h * (0.80 + 0.15 * math.cos(a + 4))),
        radius: w * 1.0,
        color: _indigo,
        opacity: 0.85);
    _blob(canvas,
        center: Offset(w * (0.60 + 0.30 * math.sin(a + 1)),
            h * (0.95 + 0.10 * math.cos(a * 2 + 1))),
        radius: w * 0.8,
        color: _night,
        opacity: 0.9);

    // Qiya yorug'lik chizig'i — ekran bo'ylab sekin siljiydi (namunadagi
    // kabi yumshoq "shu'la").
    final shift = math.sin(a) * 0.35;
    canvas.drawRect(
      rect,
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = LinearGradient(
          begin: Alignment(-1, -0.2 + shift),
          end: Alignment(1, 0.6 + shift),
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.14),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0.35, 0.5, 0.65],
        ).createShader(rect),
    );
  }

  void _blob(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
    required double opacity,
  }) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: opacity * 0.45),
            color.withValues(alpha: 0),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_FluidPainter old) => old.t != t;
}
