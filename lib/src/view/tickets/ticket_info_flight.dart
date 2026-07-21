// ignore_for_file: unused_element
// part of ticket_info_page.dart

part of 'ticket_info_page.dart';

class _FlightDirectionCard extends StatelessWidget {
  final FlightElement flightElement;
  final List<FlightSegment> segments;
  final int directionIndex;

  const _FlightDirectionCard({
    required this.flightElement,
    required this.segments,
    required this.directionIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.color.primaryContainer,
        borderRadius: BorderRadius.circular(24),
        boxShadow: context.shadowDown,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: _DirectionHeader(
              flightElement: flightElement,
              segments: segments,
              directionIndex: directionIndex,
            ),
          ),
          const _BoardingPassPerforation(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 16, 18),
            child: _FlightTimeline(
              flightElement: flightElement,
              segments: segments,
              directionIndex: directionIndex,
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionHeader extends StatelessWidget {
  final FlightElement flightElement;
  final List<FlightSegment> segments;
  final int directionIndex;

  const _DirectionHeader({
    required this.flightElement,
    required this.segments,
    required this.directionIndex,
  });

  @override
  Widget build(BuildContext context) {
    final brand = ProjectTheme.brandColor;
    final isDark = context.isDarkMode;
    final secondary = isDark
        ? ProjectTheme.secondaryTextDark
        : ProjectTheme.secondaryTextLight;
    final fromCity =
        segments.isNotEmpty ? (segments.first.dep.city?.title ?? '') : '';
    final toCity =
        segments.isNotEmpty ? (segments.last.arr.city?.title ?? '') : '';
    final transfers = flightElement.getTransferCount(directionIndex);
    final dur = ElementFormatter.formatDuration(
        flightElement.getDirDuration(directionIndex));
    final date = flightElement.getDirectionTime(directionIndex);

    final infoParts = <String>[
      if (date.isNotEmpty) date,
      if (dur.isNotEmpty) dur,
      if (transfers > 0)
        "transfer_count".tr(namedArgs: {"count": "$transfers"}),
    ];

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [brand, ProjectTheme.blueBg],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            directionIndex == 0
                ? Icons.flight_takeoff_rounded
                : Icons.flight_land_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      fromCity,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward_rounded,
                        size: 16, color: brand),
                  ),
                  Flexible(
                    child: Text(
                      toCity,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 13, color: secondary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      infoParts.join("  •  "),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall
                          ?.copyWith(fontSize: 12, color: secondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Boarding-pass perforation: a notched, dashed separator that "cuts" the card.
class _BoardingPassPerforation extends StatelessWidget {
  const _BoardingPassPerforation();

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final dashColor = context.isDarkMode
        ? Colors.white.withAlpha(40)
        : Colors.black.withAlpha(26);
    return SizedBox(
      height: 22,
      child: Row(
        children: [
          _notch(bg, left: true),
          Expanded(
            child: Center(
              child: CustomPaint(
                painter: _HDashedPainter(color: dashColor),
                child: const SizedBox(height: 2, width: double.infinity),
              ),
            ),
          ),
          _notch(bg, left: false),
        ],
      ),
    );
  }

  Widget _notch(Color bg, {required bool left}) => Transform.translate(
        offset: Offset(left ? -11 : 11, 0),
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        ),
      );
}

class _FlightTimeline extends StatelessWidget {
  final FlightElement flightElement;
  final List<FlightSegment> segments;
  final int directionIndex;

  const _FlightTimeline({
    required this.flightElement,
    required this.segments,
    required this.directionIndex,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final isFirst = i == 0;
      final isLast = i == segments.length - 1;

      // Departure node
      rows.add(_railRow(
        context,
        above: !isFirst,
        below: true,
        node: _endpointDot(context, filled: true),
        content: _endpoint(
          context,
          time: seg.dep.time,
          city: seg.dep.city?.title,
          airTitle: seg.dep.airport?.title,
          airCode: seg.dep.airport?.code,
          terminal: seg.dep.terminal,
          date: seg.dep.date,
        ),
      ));

      // Flight leg connector
      rows.add(_railRow(
        context,
        above: true,
        below: true,
        node: _airlineAvatar(context, seg.carrier.code),
        content: _legInfo(context, seg),
      ));

      // Arrival node
      rows.add(_railRow(
        context,
        above: true,
        below: !isLast,
        node: _endpointDot(context, filled: false),
        content: _endpoint(
          context,
          time: seg.arr.time,
          city: seg.arr.city?.title,
          airTitle: seg.arr.airport?.title,
          airCode: seg.arr.airport?.code,
          terminal: seg.arr.terminal,
          date: seg.arr.date,
        ),
      ));

      // Layover between legs
      if (!isLast) {
        final mins = flightElement.getLayoverMinutes(segments, i);
        final changed = flightElement.hasAirportChange(segments, i);
        final changeText =
            changed ? flightElement.getAirportChangeText(segments, i) : '';
        rows.add(_railRow(
          context,
          above: true,
          below: true,
          node: _transferNode(context),
          content: _layover(context, mins, changeText),
        ));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }

  // ── Rail row scaffold ──────────────────────────────────────────────
  Widget _railRow(
    BuildContext context, {
    required bool above,
    required bool below,
    required Widget node,
    required Widget content,
  }) {
    final railColor = ProjectTheme.brandColor
        .withAlpha(context.isDarkMode ? 150 : 110);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: CustomPaint(
              painter: _RailPainter(color: railColor, above: above, below: below),
              child: Center(child: node),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: content,
            ),
          ),
        ],
      ),
    );
  }

  // ── Rail nodes ─────────────────────────────────────────────────────
  Widget _endpointDot(BuildContext context, {required bool filled}) {
    final brand = ProjectTheme.brandColor;
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: filled ? brand : context.color.primaryContainer,
        shape: BoxShape.circle,
        border: Border.all(color: brand, width: 3),
      ),
    );
  }

  Widget _airlineAvatar(BuildContext context, String code) {
    final brand = ProjectTheme.brandColor;
    final cardBg = context.color.primaryContainer;
    return Container(
      width: 32,
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: cardBg,
        shape: BoxShape.circle,
        border: Border.all(color: brand.withAlpha(70), width: 1.5),
      ),
      child: ClipOval(
        child: Image.network(
          ProjectAssets.getSegmentProviderImg(code),
          fit: BoxFit.cover,
          // 32px logical avatar — ~2x px ekran zichligi uchun decode hajmini
          // cheklab xotira/CPU sarfini kamaytiramiz.
          cacheWidth: 64,
          cacheHeight: 64,
          errorBuilder: (_, __, ___) => Container(
            color: brand.withAlpha(22),
            alignment: Alignment.center,
            child: Icon(Icons.flight_rounded, size: 14, color: brand),
          ),
        ),
      ),
    );
  }

  Widget _transferNode(BuildContext context) {
    final warn = ProjectTheme.warning;
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.color.primaryContainer,
        shape: BoxShape.circle,
        border: Border.all(color: warn, width: 1.5),
      ),
      child: Icon(Icons.sync_alt_rounded, size: 13, color: warn),
    );
  }

  // ── Rail content ───────────────────────────────────────────────────
  Widget _endpoint(
    BuildContext context, {
    String? time,
    String? city,
    String? airTitle,
    String? airCode,
    String? terminal,
    String? date,
  }) {
    final secondary = context.isDarkMode
        ? ProjectTheme.secondaryTextDark
        : ProjectTheme.secondaryTextLight;
    final airport = _airportText(airTitle, airCode, terminal);
    final dateStr = (date ?? '').isNotEmpty
        ? ElementFormatter.formatWithWeekDay(date!)
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              ElementFormatter.formatTime(time ?? ''),
              style: context.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 19,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                city ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            if (dateStr.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  dateStr,
                  style: context.textTheme.titleSmall
                      ?.copyWith(fontSize: 11, color: secondary),
                ),
              ),
          ],
        ),
        if (airport.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              airport,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.titleSmall
                  ?.copyWith(fontSize: 12, color: secondary),
            ),
          ),
      ],
    );
  }

  Widget _legInfo(BuildContext context, FlightSegment seg) {
    final isDark = context.isDarkMode;
    final brand = ProjectTheme.brandColor;
    final secondary =
        isDark ? ProjectTheme.secondaryTextDark : ProjectTheme.secondaryTextLight;

    final cls = seg.segmentClass.name.trim();
    final dur = ElementFormatter.formatDuration(seg.duration.flight.common);
    final aircraft = seg.aircraft.title.trim();
    final flightNo = seg.flightNumber.trim();
    final carrierCode = seg.carrier.code.trim();
    final flightLabel = flightNo.isNotEmpty
        ? (carrierCode.isNotEmpty ? "$carrierCode-$flightNo" : flightNo)
        : '';

    final detailParts = <String>[
      if (dur.isNotEmpty) dur,
      if (aircraft.isNotEmpty) aircraft,
      if (flightLabel.isNotEmpty) flightLabel,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                seg.carrier.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            if (cls.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: brand.withAlpha(isDark ? 50 : 22),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    cls,
                    style: TextStyle(
                      color: brand,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (detailParts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Row(
              children: [
                Icon(Icons.schedule_rounded, size: 12, color: secondary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    detailParts.join("  •  "),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall
                        ?.copyWith(fontSize: 11.5, color: secondary),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _layover(BuildContext context, int mins, String changeText) {
    final isDark = context.isDarkMode;
    final warn = ProjectTheme.warning;
    final secondary =
        isDark ? ProjectTheme.secondaryTextDark : ProjectTheme.secondaryTextLight;
    final textColor =
        isDark ? ProjectTheme.textColorDark : ProjectTheme.textColorLight;
    final dur = ElementFormatter.formatDuration(mins);
    final title = dur.isNotEmpty
        ? "${"transfer_title".tr()}  •  $dur"
        : "transfer_title".tr();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: warn.withAlpha(isDark ? 38 : 22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: warn.withAlpha(70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.timelapse_rounded, size: 15, color: warn),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          if (changeText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 13, color: warn),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      changeText,
                      style: context.textTheme.titleSmall
                          ?.copyWith(fontSize: 11.5, color: secondary),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _airportText(String? title, String? code, String? terminal) {
    final t = (title ?? '').trim();
    final c = (code ?? '').trim();
    final term = (terminal ?? '').trim();
    final base = t.isNotEmpty ? (c.isNotEmpty && c != t ? "$t ($c)" : t) : c;
    if (base.isEmpty) return term.isNotEmpty ? "T$term" : '';
    return term.isNotEmpty ? "$base  •  T$term" : base;
  }
}

/// Vertical dashed rail line drawn above and/or below the centered node.
class _RailPainter extends CustomPainter {
  final Color color;
  final bool above;
  final bool below;

  _RailPainter({required this.color, required this.above, required this.below});

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dash = 4.0;
    const gap = 5.0;

    void drawSeg(double from, double to) {
      double y = from;
      while (y < to) {
        canvas.drawLine(Offset(x, y), Offset(x, math.min(y + dash, to)), paint);
        y += dash + gap;
      }
    }

    if (above) drawSeg(0, cy);
    if (below) drawSeg(cy, size.height);
  }

  @override
  bool shouldRepaint(covariant _RailPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.above != above ||
      oldDelegate.below != below;
}

/// Horizontal dashed line used by the boarding-pass perforation.
class _HDashedPainter extends CustomPainter {
  final Color color;

  _HDashedPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dash = 6.0;
    const gap = 5.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + dash, size.width), y),
          paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _HDashedPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ════════════════════════════════════════════════════════════════════
//  MAP ROUTE BUTTON
// ════════════════════════════════════════════════════════════════════

/// Reys marshrutini 2D xaritada animatsiyada ko'rsatishga o'tish tugmasi.
