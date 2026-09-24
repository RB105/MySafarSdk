// ignore_for_file: unused_element
// part of ticket_info_page.dart

part of 'ticket_info_page.dart';

class _TicketHero extends StatelessWidget {
  final FlightElement flightElement;
  final String originCity;
  final String destinationCity;
  final String paramsLabel;
  final VoidCallback onBack;

  const _TicketHero({
    required this.flightElement,
    required this.originCity,
    required this.destinationCity,
    required this.paramsLabel,
    required this.onBack,
  });

  String get _originCode {
    final segs = flightElement.getSegmentList();
    if (segs.isEmpty || segs[0].isEmpty) return '';
    return segs[0].first.dep.airport?.code ??
        segs[0].first.dep.city?.code ??
        '';
  }

  String get _destCode {
    final segs = flightElement.getSegmentList();
    if (segs.isEmpty || segs[0].isEmpty) return '';
    return segs[0].last.arr.airport?.code ?? segs[0].last.arr.city?.code ?? '';
  }

  String get _depDate {
    final segs = flightElement.getSegmentList();
    if (segs.isEmpty || segs[0].isEmpty) return '';
    return ElementFormatter.formatWithWeekDay(segs[0].first.dep.date ?? '');
  }

  String get _duration {
    final segs = flightElement.getSegmentList();
    if (segs.isEmpty) return '';
    return ElementFormatter.formatDuration(flightElement.getDirDuration(0));
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      child: Stack(
        children: [
          // Gradient background
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ProjectTheme.brandColor,
                    const Color(0xFF00306B),
                  ],
                ),
              ),
            ),
          ),
          // Soft accent glow
          Positioned(
            top: -40,
            right: -30,
            child: IgnorePointer(
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(28),
                ),
              ),
            ),
          ),
          // Ilovadagi dunyo xaritasi foni (`worls_map.png`) SDK'da yo'q —
          // qatlam tushirib qoldirildi.

          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: onBack,
                    ),
                    Expanded(
                      child: Text(
                        "ticket_details_title".tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            originCity,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _originCode,
                            style: TextStyle(
                              color: Colors.white.withAlpha(200),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          SizedBox(
                            // To'liq kenglik shart — aks holda Stack samolyot
                            // ikonkasi bo'yicha kichrayib, yoy ikki nuqtaga
                            // yopishib qoladi.
                            width: double.infinity,
                            height: 36,
                            child: Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                // Punktir yoy + uchlaridagi nuqtalar.
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _RouteArcPainter(
                                      color: Colors.white.withAlpha(180),
                                    ),
                                  ),
                                ),
                                // Yoy tepasidagi samolyot — Material 'flight'
                                // ikonkasi (simmetrik, tiniq). Standart holatda
                                // tepaga qaraydi; 90° o'ngga buramiz — reys
                                // yo'nalishi (chapdan o'ngga) bo'yicha uchadi.
                                Transform.rotate(
                                  angle: math.pi / 2,
                                  child: const Icon(
                                    Icons.flight_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _duration,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            destinationCity,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _destCode,
                            style: TextStyle(
                              color: Colors.white.withAlpha(200),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          _depDate,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (paramsLabel.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      paramsLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withAlpha(45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _RouteArcPainter extends CustomPainter {
  final Color color;

  _RouteArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final path = Path();
    final start = Offset(6, size.height - 6);
    final end = Offset(size.width - 6, size.height - 6);
    final control = Offset(size.width / 2, 0);
    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

    // Dashed effect
    final metric = path.computeMetrics().first;
    const dash = 4.0;
    const gap = 4.0;
    double distance = 0;
    while (distance < metric.length) {
      final segment = metric.extractPath(distance, distance + dash);
      canvas.drawPath(segment, paint);
      distance += dash + gap;
    }

    // End dots
    final dotPaint = Paint()..color = color;
    canvas.drawCircle(start, 3, dotPaint);
    canvas.drawCircle(end, 3, dotPaint);
    // Samolyot yoy ustida alohida widget (Icons.flight_rounded) sifatida
    // chiziladi — bu yerda faqat yoy va uchlaridagi nuqtalar.
  }

  @override
  bool shouldRepaint(covariant _RouteArcPainter oldDelegate) =>
      oldDelegate.color != color;
}
