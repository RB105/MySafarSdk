// Creator: Ravshanov Anzor
// Created: 24.09.2026

import 'dart:math' as math;

import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/tools/formatters.dart' show ElementFormatter;
import 'package:mysafar_sdk/src/core/widgets/plane_silhouette.dart';
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart'
    show Arr, FlightElement, FlightSegment;

/// Bron sahifasi tepasidagi marshrut: ikki nuqta va ular orasidagi egri
/// chiziq. Ekran ochilganda strelka birinchi nuqtadan chiqib, shu chiziq
/// bo'ylab ikkinchi nuqtaga borib to'xtaydi (bir marta).
///
/// Borish-kelish bo'lsa tepada "Borish / Qaytish" tugmalari chiqadi va
/// yo'nalish almashtirilganda animatsiya qaytadan o'ynaydi. Bir tomonga
/// bo'lsa tugmalar umuman ko'rsatilmaydi.
class RouteArcHero extends StatefulWidget {
  const RouteArcHero({super.key, required this.element, this.onDetails});

  final FlightElement element;

  /// "Tafsilotlar" tugmasi; `null` bo'lsa tugma chiqmaydi.
  final VoidCallback? onDetails;

  @override
  State<RouteArcHero> createState() => _RouteArcHeroState();
}

class _RouteArcHeroState extends State<RouteArcHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    // Samolyot shoshmasdan uchadi — bir yo'l ~3 soniya.
    duration: const Duration(milliseconds: 3200),
  );

  int _direction = 0;

  /// Animatsiyasi allaqachon o'ynagan yo'nalishlar — har biri faqat BIR
  /// MARTA uchadi, keyingi almashtirishlarda yakuniy holat darhol chiqadi.
  final Set<int> _played = {0};

  List<List<FlightSegment>> get _directions {
    final all = widget.element.segments ?? const <FlightSegment>[];
    if (all.isEmpty) return const [];
    final out = widget.element.getSegmentsByDirection(0);
    final back = widget.element.getSegmentsByDirection(1);
    return [
      if (out.isNotEmpty) out else all,
      if (back.isNotEmpty) back,
    ];
  }

  @override
  void initState() {
    super.initState();
    // Sahifa ochilishi bilan bir marta uchib o'tadi.
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectDirection(int index) {
    if (index == _direction) return;
    HapticFeedback.selectionClick();
    setState(() => _direction = index);
    if (_played.add(index)) {
      _controller.forward(from: 0);
    } else {
      // Bu yo'nalish oldin ko'rilgan — samolyot darhol manzilda.
      _controller.value = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dirs = _directions;
    if (dirs.isEmpty) return const SizedBox.shrink();

    final segments = dirs[_direction.clamp(0, dirs.length - 1)];
    final isDark = context.isDarkMode;

    // Ikki qatlam (namuna ilovadagi kabi):
    //  1) butun tepa qismni bo'yaydigan yumshoq moviy "yuvish" — pastga
    //     borgan sari so'nib, sahifa foniga qo'shilib ketadi;
    //  2) ustida markazi biroz chap-yuqorida bo'lgan bulutsimon yorug'lik.
    final Color blue =
        Color.lerp(ProjectTheme.brandColor, ProjectTheme.blueBg, 0.4)!;
    final Color wash =
        isDark ? blue.withValues(alpha: 0.22) : blue.withValues(alpha: 0.20);
    final Color cloud = isDark
        ? blue.withValues(alpha: 0.42)
        : Colors.white.withValues(alpha: 0.55);

    return Container(
      width: double.infinity,
      color: context.backgroundColor,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [wash, wash, wash.withValues(alpha: 0)],
            stops: const [0, 0.55, 1],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.2, -0.35),
              radius: 0.9,
              colors: [
                cloud,
                cloud.withValues(alpha: cloud.a * 0.4),
                cloud.withValues(alpha: 0),
              ],
              stops: const [0, 0.5, 1],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (dirs.length > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: _DirectionTabs(
                    selected: _direction,
                    onSelect: _selectDirection,
                  ),
                ),
              _RouteArc(
                key: ValueKey(_direction),
                progress: _controller,
                origin: _PointLabel.from(segments.first.dep),
                destination: _PointLabel.from(segments.last.arr),
                // Qaytishda marshrut teskari yo'nalishda chiziladi.
                reversed: _direction == 1,
                onDetails: widget.onDetails,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nuqta yozuvi: shahar, aeroport kodi, vaqt va sana.
class _PointLabel {
  const _PointLabel({
    required this.city,
    required this.code,
    required this.time,
    required this.date,
  });

  final String city;
  final String code;
  final String time;
  final String date;

  static _PointLabel from(Arr point) {
    final code = point.airport?.code ?? point.city?.code ?? '';
    String city = point.city?.title ?? '';
    // SDK'da aeroportlar bazasi alohida isolate'da — sinxron qidiruv yo'q,
    // shahar nomi kelmasa IATA kod ko'rsatiladi.
    if (city.isEmpty) city = code;
    return _PointLabel(
      city: city,
      code: code,
      time: (point.time ?? '').trim(),
      date: _shortDate(point.date),
    );
  }

  /// "29 Okt"
  static String _shortDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final d = DateTime.tryParse(raw);
    if (d == null) return raw;
    return '${d.day} ${ElementFormatter.formatMonth(d.month)}';
  }

  String get meta {
    if (time.isEmpty) return date;
    if (date.isEmpty) return time;
    return '$time - $date';
  }
}

class _DirectionTabs extends StatelessWidget {
  const _DirectionTabs({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _tab(context, 0, 'when'.tr()),
        const SizedBox(width: 10),
        _tab(context, 1, 'return'.tr()),
      ],
    );
  }

  Widget _tab(BuildContext context, int index, String label) {
    final isDark = context.isDarkMode;
    final active = index == selected;
    final Color background = active
        ? (isDark ? Colors.white : ProjectTheme.brandColor)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white);
    final Color text = active
        ? (isDark ? ProjectTheme.textColorLight : Colors.white)
        : (isDark ? Colors.white : ProjectTheme.textColorLight);

    return GestureDetector(
      onTap: () => onSelect(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(24),
          border: active
              ? null
              : Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.06),
                ),
        ),
        child: Text(
          label,
          style: context.textTheme.bodyMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: text,
          ),
        ),
      ),
    );
  }
}

/// Egri chiziq, ikki nuqta, uchuvchi strelka va "Tafsilotlar" tugmasi.
class _RouteArc extends StatelessWidget {
  const _RouteArc({
    super.key,
    required this.progress,
    required this.origin,
    required this.destination,
    required this.reversed,
    this.onDetails,
  });

  final Animation<double> progress;
  final _PointLabel origin;
  final _PointLabel destination;

  /// Qaytish: chiqish nuqtasi yuqori o'ngda, borish nuqtasi pastki chapda.
  final bool reversed;
  final VoidCallback? onDetails;

  /// Marshrut maydoni ekran balandligining 55% ini egallaydi (kichik
  /// ekranlarda ham yozuvlar sig'ishi uchun kamida 330 px).
  static double _heightOf(BuildContext context) =>
      math.max(330.0, MediaQuery.sizeOf(context).height * 0.55);

  @override
  Widget build(BuildContext context) {
    final line = context.isDarkMode ? Colors.white : ProjectTheme.brandColor;
    final height = _heightOf(context);

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, height);
          final start = _startPoint(size);
          final end = _endPoint(size);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: progress,
                  builder: (context, _) => CustomPaint(
                    painter: _ArcPainter(
                      start: start,
                      end: end,
                      t: Curves.easeInOutCubic.transform(progress.value),
                      color: line,
                      ringColor: context.backgroundColor,
                    ),
                  ),
                ),
              ),
              // Yozuv joyi nuqtaning BALANDLIGIGA qarab tanlanadi: pastki
              // nuqtaniki ostida, yuqoridagisiniki ustida. Shu sabab borish
              // va qaytish bir xil ko'rinadi, yozuvlar nuqtalar orasiga
              // tushib qolmaydi.
              _label(context, origin, start, size, below: start.dy > end.dy),
              _label(context, destination, end, size, below: end.dy > start.dy),
              if (onDetails != null)
                Positioned(
                  left: 16,
                  bottom: 34,
                  child: _DetailsPill(onTap: onDetails!),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Borishda pastki chap, qaytishda yuqori o'ng.
  Offset _startPoint(Size size) => reversed ? _topDot(size) : _bottomDot(size);

  Offset _endPoint(Size size) => reversed ? _bottomDot(size) : _topDot(size);

  /// Yuqori (CHAP) nuqta — qo'nish joyi, yozuvi ustida.
  Offset _topDot(Size size) => Offset(size.width * 0.18, size.height * 0.24);

  /// Pastki (O'NG) nuqta — uchish joyi, yozuvi ostida.
  Offset _bottomDot(Size size) => Offset(size.width * 0.74, size.height * 0.78);

  Widget _label(
    BuildContext context,
    _PointLabel point,
    Offset dot,
    Size size, {
    required bool below,
  }) {
    final isDark = context.isDarkMode;
    final muted = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : ProjectTheme.secondaryTextLight;
    final title = isDark ? Colors.white : ProjectTheme.textColorLight;

    // Yozuv nuqtaning tagida (uchish) yoki ustida (qo'nish) turadi va
    // markazi nuqtaga to'g'ri keladi; ekran chetiga tayanib qolmasin.
    // Chap yarmidagi nuqtaning yozuvi chap chetdan (nuqta bilan bir
    // chiziqda), o'ngdagisiniki o'ng chetdan tekislanadi — matn nuqtadan
    // uzoqlashib, ekran o'rtasiga surilib qolmaydi.
    final bool onLeft = dot.dx < size.width / 2;
    const double width = 230;
    final double left = onLeft
        ? math.max(16.0, dot.dx - 22)
        : math.min(size.width - width - 16, dot.dx + 22 - width);
    final align = onLeft ? TextAlign.left : TextAlign.right;

    return Positioned(
      left: left,
      width: width,
      top: below ? dot.dy + 22 : dot.dy - 74,
      child: Column(
        crossAxisAlignment:
            onLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          RichText(
            textAlign: align,
            text: TextSpan(
              children: [
                TextSpan(
                  text: point.city,
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: title,
                  ),
                ),
                if (point.code.isNotEmpty)
                  TextSpan(
                    text: ' ${point.code}',
                    style: context.textTheme.bodyLarge?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: muted,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            point.meta,
            textAlign: align,
            style: context.textTheme.bodyMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsPill extends StatelessWidget {
  const _DetailsPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Material(
      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.20)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            'flight_details_action'.tr(),
            style: context.textTheme.bodyMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Egri chiziqni [t] ulushigacha chizadi, uchida strelka; ikkala nuqta
/// doim ko'rinadi.
class _ArcPainter extends CustomPainter {
  const _ArcPainter({
    required this.start,
    required this.end,
    required this.t,
    required this.color,
    required this.ringColor,
  });

  final Offset start;
  final Offset end;

  /// 0..1 — chiziqning chizilgan ulushi.
  final double t;
  final Color color;

  /// Nuqta atrofidagi halqa — sahifa foni rangida.
  final Color ringColor;

  /// Nuqtaning tashqi radiusi (halqa bilan).
  static const double _dotRing = 13;

  /// Samolyot o'lchami (burnidan dumigacha).
  static const double _planeSize = 34;

  @override
  void paint(Canvas canvas, Size size) {
    // Boshqaruv nuqtasi pastki burchakka tortilgan — chiziq avval sekin,
    // keyin tikroq ko'tariladi (skrinshotdagi yoy).
    final control = Offset(
      start.dx + (end.dx - start.dx) * 0.78,
      start.dy - (start.dy - end.dy) * 0.17,
    );
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

    final metric = path.computeMetrics().first;
    // Samolyot nuqtaning ICHIGA kirmasin: to'xtash joyi nuqta radiusi va
    // samolyotning yarim uzunligi qadar oldinroq — burni nuqtaga tegib
    // turadi, ustiga chiqmaydi.
    final maxLength = math.max(0.0, metric.length - _dotRing - _planeSize / 2);
    final drawnLength = maxLength * t.clamp(0.0, 1.0);
    // Uzuq chiziq: qisqa bo'laklar va orasida bo'shliq.
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    const double dash = 7;
    const double gap = 5;
    for (double d = 0; d < drawnLength; d += dash + gap) {
      canvas.drawPath(
        metric.extractPath(d, math.min(d + dash, drawnLength)),
        linePaint,
      );
    }

    // Chiziq uchida — samolyot, urinma bo'yicha burilgan.
    final tip = metric.getTangentForOffset(drawnLength);
    if (tip != null && t > 0.02) {
      // Samolyot silueti — chipta tafsiloti headeri bilan bir xil chizma.
      drawPlaneSilhouette(
        canvas,
        position: tip.position,
        angle: tip.angle,
        size: _planeSize,
        color: color,
        shadeColor: ringColor,
      );
    }

    _drawDot(canvas, start);
    _drawDot(canvas, end);
  }

  /// Yorug'lik → fon rangidagi halqa → to'la doira: nuqta chiziq ustida
  /// aniq ajralib turadi (skrinshotdagi kabi).
  void _drawDot(Canvas canvas, Offset center) {
    canvas.drawCircle(
      center,
      18,
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawCircle(center, 13, Paint()..color = ringColor);
    canvas.drawCircle(center, 9, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.t != t ||
      old.start != start ||
      old.end != end ||
      old.color != color ||
      old.ringColor != ringColor;
}
