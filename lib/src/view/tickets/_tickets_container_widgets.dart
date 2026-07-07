part of 'ticket_page.dart';

/// ═══════════════════════════════════════════════════════════════════
///  FIGMA TICKET CARDS
///  ─────────────────────────────────────────────────────────────────
///  • _FigmaTicketCard — toza oq karta: tepada aviakompaniya logolari +
///    narx; har bir yo'nalish uchun vaqtlar, davomiylik, sana (kelish
///    boshqa kunda bo'lsa — orange) va marshrut.
///  • _DirectFlightsCard — "To'g'ri reyslar": transfersiz reyslarni
///    aviakompaniya kesimida guruhlab, eng arzon narx va jo'nash
///    vaqtlarini ko'rsatadi ("Yana N ta ko'rsatish" bilan ochiladi).
/// ═══════════════════════════════════════════════════════════════════

/// Karta ranglari — light/dark temaga moslashadi.
class _TixTheme {
  final Color card;
  final Color hi; // asosiy matn (navy/oq)
  final Color mid; // ikkilamchi kulrang matn
  final Color line; // ajratkich
  final bool dark;

  const _TixTheme({
    required this.card,
    required this.hi,
    required this.mid,
    required this.line,
    required this.dark,
  });

  static const Color green = Color(0xFF21A038);
  static const Color orange = Color(0xFFF5A623);
  static const Color rose = Color(0xFFF43F5E);

  static const _light = _TixTheme(
    card: Colors.white,
    hi: Color(0xFF16244A),
    mid: Color(0xFF8E99B5),
    line: Color(0xFFEDF0F6),
    dark: false,
  );

  static const _dark = _TixTheme(
    card: Color(0xFF2F2F2F),
    hi: Colors.white,
    mid: Color(0xFF9BA3B5),
    line: Color(0x22FFFFFF),
    dark: true,
  );

  static _TixTheme of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;

  static TextStyle style(double size, FontWeight weight, Color color,
          {double? height}) =>
      TextStyle(
        fontFamily: "Gilroy",
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );

  List<BoxShadow> get cardShadow => dark
      ? const []
      : const [
          BoxShadow(
            color: Color(0x14202A44),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ];
}

/// "27.07.2026" → "27 iyul, chor" (formatlab bo'lmasa — asl matn).
String _tixDateWithWeekday(String? date) {
  if (date == null || date.isEmpty) return '';
  try {
    return ElementFormatter.formatWithWeekDay(date);
  } catch (_) {
    return date;
  }
}

/// ═══════════════════════════════════════════════════════════════════
///  ASOSIY CHIPTA KARTASI (Figma)
/// ═══════════════════════════════════════════════════════════════════
class _FigmaTicketCard extends StatefulWidget {
  final FlightElement flightElement;

  /// 0 → one-way, 1 → round-trip, 2 → multi-city
  final int tripType;

  const _FigmaTicketCard({
    required this.flightElement,
    required this.tripType,
  });

  @override
  State<_FigmaTicketCard> createState() => _FigmaTicketCardState();
}

class _FigmaTicketCardState extends State<_FigmaTicketCard> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    final f = widget.flightElement;
    final directions = f.getSegmentList();
    final price =
        Provider.of<CurrencyProvider>(context).getElementPrice(f.price);

    return AnimatedScale(
      scale: _pressed ? 0.977 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(24),
          boxShadow: t.cardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              AnalyticsService().trackButtonTap('ticket_select');
              Navigator.of(context)
                  .pushNamed(TicketInfoPage.routeName, arguments: f);
            },
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logolar + narx.
                  Row(
                    children: [
                      _LogoStack(segments: f.segments ?? const []),
                      const Spacer(),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            price,
                            maxLines: 1,
                            style: _TixTheme.style(
                                17.5, FontWeight.w800, t.hi),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  for (int i = 0; i < directions.length; i++)
                    if (directions[i].isNotEmpty) ...[
                      if (i > 0) const SizedBox(height: 14),
                      _LegBlock(
                        flight: f,
                        dirIndex: i,
                        segments: directions[i],
                      ),
                    ],
                  if (f.isVtrip == true) ...[
                    const SizedBox(height: 12),
                    _LowcostPill(flightElement: f),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bitta yo'nalish (leg) bloki: vaqtlar+davomiylik, sana(lar)+almashish,
/// marshrut.
class _LegBlock extends StatelessWidget {
  final FlightElement flight;
  final int dirIndex;
  final List<FlightSegment> segments;

  const _LegBlock({
    required this.flight,
    required this.dirIndex,
    required this.segments,
  });

  /// Yo'nalishdagi almashishlar (layover) umumiy davomiyligi, daqiqada.
  int _layoverSum() {
    int sum = 0;
    for (int i = 0; i < segments.length - 1; i++) {
      sum += flight.getLayoverMinutes(segments, i);
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    final first = segments.first;
    final last = segments.last;

    final transfers = flight.getTransferCount(dirIndex);
    final duration =
        ElementFormatter.formatDuration(flight.getDirDuration(dirIndex));

    final depDate = first.dep.date ?? '';
    final arrDate = last.arr.date ?? '';
    // Kelish boshqa kunda bo'lsa — sanasi orange rangda qo'shiladi (Figma).
    final bool arrivesAnotherDay = arrDate.isNotEmpty && arrDate != depDate;

    final String transferText = transfers == 0
        ? "ticket_chip_direct".tr()
        : "ticket_transfer_info".tr(namedArgs: {
            "count": "$transfers",
            "duration": ElementFormatter.formatDuration(_layoverSum()),
          });

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vaqtlar va davomiylik.
        Row(
          children: [
            Expanded(
              child: Text(
                '${first.dep.time ?? ''} - ${last.arr.time ?? ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _TixTheme.style(16.5, FontWeight.w800, t.hi),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              duration,
              style: _TixTheme.style(14.5, FontWeight.w600, t.hi),
            ),
          ],
        ),
        const SizedBox(height: 5),
        // Sana(lar) va almashish ma'lumoti.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: _tixDateWithWeekday(depDate),
                      style: _TixTheme.style(13, FontWeight.w500, t.mid),
                    ),
                    if (arrivesAnotherDay)
                      TextSpan(
                        text: ' - ${_tixDateWithWeekday(arrDate)}',
                        style: _TixTheme.style(
                            13, FontWeight.w600, _TixTheme.orange),
                      ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              transferText,
              style: _TixTheme.style(13, FontWeight.w500, t.mid),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Marshrut.
        Text(
          '${first.dep.city?.title ?? ''} - ${last.arr.city?.title ?? ''}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _TixTheme.style(13, FontWeight.w500, t.mid),
        ),
      ],
    );
  }
}

/// Ustma-ust joylashgan aviakompaniya logolari (noyob, max 3).
class _LogoStack extends StatelessWidget {
  final List<FlightSegment> segments;

  const _LogoStack({required this.segments});

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final codes = <String>[];
    for (final s in segments) {
      if (seen.add(s.carrier.code)) codes.add(s.carrier.code);
    }
    if (codes.isEmpty) return const SizedBox.shrink();

    final shown = codes.take(3).toList();
    const double size = 30;
    const double step = 20;

    return SizedBox(
      height: size,
      width: size + (shown.length - 1) * step,
      child: Stack(
        children: [
          for (int i = 0; i < shown.length; i++)
            Positioned(
              left: i * step,
              child: _AirlineCircle(code: shown[i], size: size),
            ),
        ],
      ),
    );
  }
}

/// Dumaloq aviakompaniya logotipi (oq plitka ichida).
class _AirlineCircle extends StatelessWidget {
  final String code;
  final double size;

  const _AirlineCircle({required this.code, this.size = 30});

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: t.line, width: 1),
      ),
      padding: const EdgeInsets.all(3),
      child: ClipOval(
        child: CachedNetworkImage(
          cacheManager: AppCacheManager.instance,
          imageUrl: ProjectAssets.getSegmentProviderImg(code),
          fit: BoxFit.contain,
          memCacheWidth: 72,
          memCacheHeight: 72,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          placeholder: (_, __) => const SizedBox(),
          errorWidget: (_, __, ___) => Icon(
            Icons.flight_rounded,
            size: size * 0.5,
            color: ProjectTheme.brandColor,
          ),
        ),
      ),
    );
  }
}

/// Lowcost ogohlantirish pill'i — bosilganda tafsilot sheet ochiladi.
class _LowcostPill extends StatelessWidget {
  final FlightElement flightElement;

  const _LowcostPill({required this.flightElement});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ProjectDialogs.showLowcostSheet(context, flightElement),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: _TixTheme.rose.withAlpha(24),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "lowcost".tr(),
                style:
                    _TixTheme.style(12, FontWeight.w700, _TixTheme.rose),
              ),
              const SizedBox(width: 5),
              SizedBox(
                width: 13,
                height: 13,
                child: SvgPicture.asset(
                  Assets.ticketsExclamationIcon,
                  colorFilter: const ColorFilter.mode(
                      _TixTheme.rose, BlendMode.srcIn),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════
///  "TO'G'RI REYSLAR" BLOKI (Figma)
/// ═══════════════════════════════════════════════════════════════════

class _DirectGroup {
  final String code;
  final String title;
  FlightElement cheapest;

  /// direction → shu aviakompaniyaning to'g'ri reyslari jo'nash vaqtlari.
  final Map<int, Set<String>> timesByDir = {};

  _DirectGroup({
    required this.code,
    required this.title,
    required this.cheapest,
  });
}

/// Transfersiz (to'g'ri) reyslarni aviakompaniya bo'yicha guruhlab
/// ko'rsatadi: logo, nom, eng arzon narx, sana va jo'nash vaqtlari
/// (eng arzonining vaqti yashil chip bilan). 2 tadan ortig'i "Yana N ta
/// ko'rsatish" bilan ochiladi. To'g'ri reys bo'lmasa — ko'rinmaydi.
class _DirectFlightsCard extends StatefulWidget {
  final List<FlightElement> flights;
  final int flightType;

  const _DirectFlightsCard({
    required this.flights,
    required this.flightType,
  });

  @override
  State<_DirectFlightsCard> createState() => _DirectFlightsCardState();
}

class _DirectFlightsCardState extends State<_DirectFlightsCard> {
  bool _expanded = false;

  List<_DirectGroup> _buildGroups() {
    final map = <String, _DirectGroup>{};

    for (final f in widget.flights) {
      final dirCount = f.segmentsDirection?.length ?? 0;
      final segments = f.segments;
      if (dirCount == 0 || segments == null || segments.isEmpty) continue;

      // Barcha yo'nalishlari transfersiz bo'lgan reyslar.
      bool allDirect = true;
      for (int i = 0; i < dirCount; i++) {
        if (f.getTransferCount(i) != 0) {
          allDirect = false;
          break;
        }
      }
      if (!allDirect) continue;

      final carrier = segments.first.carrier;
      final group = map.putIfAbsent(
        carrier.code,
        () => _DirectGroup(
            code: carrier.code, title: carrier.title, cheapest: f),
      );
      if (_flightPriceUzs(f) < _flightPriceUzs(group.cheapest)) {
        group.cheapest = f;
      }
      for (int i = 0; i < dirCount; i++) {
        final dirSegments = f.getSegmentsByDirection(i);
        if (dirSegments.isEmpty) continue;
        final time = dirSegments.first.dep.time ?? '';
        if (time.isEmpty) continue;
        group.timesByDir.putIfAbsent(i, () => <String>{}).add(time);
      }
    }

    return map.values.toList()
      ..sort((a, b) =>
          _flightPriceUzs(a.cheapest).compareTo(_flightPriceUzs(b.cheapest)));
  }

  @override
  Widget build(BuildContext context) {
    // Multiway'da bu blok ko'rsatilmaydi.
    if (widget.flightType == 2) return const SizedBox.shrink();

    final groups = _buildGroups();
    if (groups.isEmpty) return const SizedBox.shrink();

    final t = _TixTheme.of(context);
    final visible = _expanded ? groups : groups.take(2).toList();
    final hiddenCount = groups.length - 2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(24),
          boxShadow: t.cardShadow,
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "ticket_direct_flights_title".tr(),
                    style: _TixTheme.style(16, FontWeight.w800, t.hi),
                  ),
                ),
                if (hiddenCount > 0)
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _expanded = !_expanded);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _expanded
                                ? "ticket_show_less".tr()
                                : "ticket_show_more_count".tr(
                                    namedArgs: {"count": "$hiddenCount"}),
                            style: _TixTheme.style(13.5, FontWeight.w600,
                                ProjectTheme.brandColor),
                          ),
                          AnimatedRotation(
                            turns: _expanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.expand_more_rounded,
                              size: 18,
                              color: ProjectTheme.brandColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            for (int i = 0; i < visible.length; i++) ...[
              if (i > 0) Divider(height: 1, thickness: 1, color: t.line),
              _airlineRow(context, t, visible[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _airlineRow(BuildContext context, _TixTheme t, _DirectGroup g) {
    final cheapest = g.cheapest;
    final price =
        Provider.of<CurrencyProvider>(context).getElementPrice(cheapest.price);
    final dirCount = cheapest.segmentsDirection?.length ?? 1;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        HapticFeedback.lightImpact();
        AnalyticsService().trackButtonTap('direct_flight_select');
        Navigator.of(context)
            .pushNamed(TicketInfoPage.routeName, arguments: cheapest);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _AirlineCircle(code: g.code, size: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    g.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _TixTheme.style(15.5, FontWeight.w700, t.hi),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  price,
                  style:
                      _TixTheme.style(15, FontWeight.w800, _TixTheme.green),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: _TixTheme.green,
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (int dir = 0; dir < dirCount; dir++)
              _timesLine(t, g, dir),
          ],
        ),
      ),
    );
  }

  /// "26 iyun  [12:10] 09:45 18:00" qatori — eng arzonining vaqti yashil
  /// chip ichida, qolganlari oddiy matn (max 2 ta).
  Widget _timesLine(_TixTheme t, _DirectGroup g, int dir) {
    final dirSegments = g.cheapest.getSegmentsByDirection(dir);
    if (dirSegments.isEmpty) return const SizedBox.shrink();

    final cheapTime = dirSegments.first.dep.time ?? '';
    final others = (g.timesByDir[dir] ?? const <String>{})
        .where((time) => time != cheapTime)
        .toList()
      ..sort();

    String dateText = '';
    final depDate = dirSegments.first.dep.date ?? '';
    if (depDate.isNotEmpty) {
      try {
        dateText = ElementFormatter.formatDate(depDate);
      } catch (_) {
        dateText = depDate;
      }
    }

    return Padding(
      padding: EdgeInsets.only(top: dir > 0 ? 6.0 : 0),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(
              dateText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _TixTheme.style(12.5, FontWeight.w500, t.mid),
            ),
          ),
          if (cheapTime.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: _TixTheme.green.withAlpha(26),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                cheapTime,
                style:
                    _TixTheme.style(12.5, FontWeight.w700, _TixTheme.green),
              ),
            ),
          for (final time in others.take(2)) ...[
            const SizedBox(width: 12),
            Text(
              time,
              style: _TixTheme.style(
                  12.5, FontWeight.w600, t.hi.withAlpha(200)),
            ),
          ],
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════
///  PUBLIC CONTAINERS — ticket_page.dart switch'i ulardan foydalanadi.
/// ═══════════════════════════════════════════════════════════════════
class _SingleDateFlightContainer extends StatelessWidget {
  final FlightElement flightElement;

  const _SingleDateFlightContainer({required this.flightElement});

  @override
  Widget build(BuildContext context) =>
      _FigmaTicketCard(flightElement: flightElement, tripType: 0);
}

class _ReturnDateFlightContainer extends StatelessWidget {
  final FlightElement flightElement;

  const _ReturnDateFlightContainer({required this.flightElement});

  @override
  Widget build(BuildContext context) =>
      _FigmaTicketCard(flightElement: flightElement, tripType: 1);
}

class _MultipleDateFlightContainer extends StatelessWidget {
  final FlightElement flightElement;

  const _MultipleDateFlightContainer({required this.flightElement});

  @override
  Widget build(BuildContext context) =>
      _FigmaTicketCard(flightElement: flightElement, tripType: 2);
}
