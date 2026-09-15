// ignore_for_file: unused_element
// part of ticket_info_page.dart

part of 'ticket_info_page.dart';

/// Bitta yo'nalish (borish yoki qaytish) kartasi: sarlavha va reys
/// bosqichlari vaqt chizig'i.
class _FlightDirectionCard extends StatelessWidget {
  final FlightElement flightElement;
  final List<FlightSegment> segments;
  final int directionIndex;

  /// Borish-kelish bo'lsa "Borish" / "Qaytish" belgisi ko'rsatiladi.
  final bool showDirectionLabel;

  const _FlightDirectionCard({
    required this.flightElement,
    required this.segments,
    required this.directionIndex,
    this.showDirectionLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return _TiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: _DirectionHeader(
              flightElement: flightElement,
              segments: segments,
              directionIndex: directionIndex,
              showDirectionLabel: showDirectionLabel,
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: context.color.outline.withValues(alpha: 0.6),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 16, 14),
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
  final bool showDirectionLabel;

  const _DirectionHeader({
    required this.flightElement,
    required this.segments,
    required this.directionIndex,
    required this.showDirectionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final brand = ProjectTheme.brandColor;
    final Color accent = isDark ? Colors.white : brand;
    final muted = _tiMuted(context);

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
      transfers > 0
          ? "transfer_count".tr(namedArgs: {"count": "$transfers"})
          : "noTransfer".tr(),
    ];

    final titleStyle = context.textTheme.bodyLarge
        ?.copyWith(fontWeight: FontWeight.w700, fontSize: 16);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : brand.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SvgPicture.asset(
            directionIndex == 0
                ? Assets.iconsTicketTakeoffIcon
                : Assets.iconsTicketLandingIcon,
            width: 22,
            height: 22,
            colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
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
                    child: Text(fromCity,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward_rounded,
                        size: 16, color: muted),
                  ),
                  Flexible(
                    child: Text(toCity,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                infoParts.join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: muted,
                ),
              ),
            ],
          ),
        ),
        if (showDirectionLabel) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _tiTonal(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              (directionIndex == 0 ? "when" : "return").tr(),
              style: context.textTheme.bodySmall?.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: muted,
              ),
            ),
          ),
        ],
      ],
    );
  }
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

      // Jo'nash
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

      // Reys (aviakompaniya, davomiylik, samolyot)
      rows.add(_railRow(
        context,
        above: true,
        below: true,
        node: _airlineAvatar(context, seg.carrier.code),
        content: _legInfo(context, seg),
      ));

      // Yetib kelish
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

      // Almashish
      if (!isLast) {
        final mins = flightElement.getLayoverMinutes(segments, i);
        final changed = flightElement.hasAirportChange(segments, i);
        final changeText =
            changed ? flightElement.getAirportChangeText(segments, i) : '';
        rows.add(_railRow(
          context,
          above: true,
          below: true,
          node: const SizedBox.shrink(),
          content: _layover(context, mins, changeText),
        ));
      }
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }

  // ── Qator karkasi: chapda chiziq + tugun, o'ngda kontent ───────────
  Widget _railRow(
    BuildContext context, {
    required bool above,
    required bool below,
    required Widget node,
    required Widget content,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: CustomPaint(
              painter: _RailPainter(
                color: context.color.outline,
                above: above,
                below: below,
              ),
              child: Center(child: node),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: content,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tugunlar ────────────────────────────────────────────────────────
  Widget _endpointDot(BuildContext context, {required bool filled}) {
    final brand = ProjectTheme.brandColor;
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: filled ? brand : context.color.primaryContainer,
        shape: BoxShape.circle,
        border: Border.all(color: brand, width: 2.5),
      ),
    );
  }

  Widget _airlineAvatar(BuildContext context, String code) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: context.color.primaryContainer,
        shape: BoxShape.circle,
        border: Border.all(color: context.color.outline),
      ),
      child: ClipOval(
        child: Image.network(
          ProjectAssets.getSegmentProviderImg(code),
          fit: BoxFit.cover,
          // 28px avatar — decode hajmini cheklab xotira sarfini kamaytiramiz.
          cacheWidth: 64,
          cacheHeight: 64,
          errorBuilder: (_, __, ___) => Container(
            color: _tiTonal(context),
            alignment: Alignment.center,
            child:
                Icon(Icons.flight_rounded, size: 14, color: _tiMuted(context)),
          ),
        ),
      ),
    );
  }

  // ── Kontent ─────────────────────────────────────────────────────────
  Widget _endpoint(
    BuildContext context, {
    String? time,
    String? city,
    String? airTitle,
    String? airCode,
    String? terminal,
    String? date,
  }) {
    final muted = _tiMuted(context);
    final airport = _airportText(airTitle, airCode, terminal);
    final dateStr = (date ?? '').isNotEmpty
        ? ElementFormatter.formatWithWeekDay(date!)
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              ElementFormatter.formatTime(time ?? ''),
              style: context.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                city ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            if (dateStr.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  dateStr,
                  style: context.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: muted,
                  ),
                ),
              ),
          ],
        ),
        if (airport.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              airport,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(
                fontSize: 12.5,
                height: 1.3,
                color: muted,
              ),
            ),
          ),
      ],
    );
  }

  Widget _legInfo(BuildContext context, FlightSegment seg) {
    final muted = _tiMuted(context);

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
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
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
                    color: _tiTonal(context),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    cls,
                    style: context.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: muted,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (detailParts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              detailParts.join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(
                fontSize: 12.5,
                height: 1.3,
                color: muted,
              ),
            ),
          ),
      ],
    );
  }

  /// Almashish bloki — neytral fon; faqat aeroport o'zgarsa ogohlantirish
  /// rangida ajraladi (muhim ma'lumot).
  Widget _layover(BuildContext context, int mins, String changeText) {
    final warn = ProjectTheme.warning;
    final dur = ElementFormatter.formatDuration(mins);
    final title = dur.isNotEmpty
        ? "${"transfer_title".tr()} · $dur"
        : "transfer_title".tr();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _tiTonal(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                Assets.iconsTicketTransferIcon,
                width: 16,
                height: 16,
                colorFilter:
                    ColorFilter.mode(_tiMuted(context), BlendMode.srcIn),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
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
                  SvgPicture.asset(
                    Assets.iconsBookingAlertIcon,
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(warn, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      changeText,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 12.5,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: warn,
                      ),
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
    return term.isNotEmpty ? "$base · T$term" : base;
  }
}

/// Tugun ustidan va/yoki ostidan o'tadigan ingichka vertikal chiziq.
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
      ..strokeWidth = 1.5;
    if (above) canvas.drawLine(Offset(x, 0), Offset(x, cy), paint);
    if (below) canvas.drawLine(Offset(x, cy), Offset(x, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _RailPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.above != above ||
      oldDelegate.below != below;
}
