part of 'ticket_page.dart';

/// ═══════════════════════════════════════════════════════════════════
///  CHIPTA KARTALARI (qidiruv natijalari)
///  ─────────────────────────────────────────────────────────────────
///  • Tepada: aviakompaniya logosi/nomi va belgilar (eng arzon, ekonom,
///    loukoster).
///  • Har bir yo'nalish uchun vaqt chizig'i: jo'nash vaqti + kod ←
///    davomiylik, chiziq, almashish → qo'nish vaqti (+1 kun) + kod.
///  • Pastda: bagaj/qo'l yuki/joylar va narx.
/// ═══════════════════════════════════════════════════════════════════

/// Karta ranglari — light/dark temaga moslashadi.
class _TixTheme {
  final Color card;
  final Color hi; // asosiy matn (navy/oq)
  final Color mid; // ikkilamchi kulrang matn
  final Color line; // ajratkich
  final Color tonal; // neytral yumshoq fon (teglar, chiplar)
  final bool dark;

  const _TixTheme({
    required this.card,
    required this.hi,
    required this.mid,
    required this.line,
    required this.tonal,
    required this.dark,
  });

  static const Color rose = Color(0xFFF43F5E);
  static const Color amber = Color(0xFFD97706);

  static const _light = _TixTheme(
    card: Colors.white,
    hi: Color(0xFF16244A),
    mid: Color(0xFF7A849E),
    line: Color(0xFFE8ECF3),
    tonal: Color(0xFFF1F4F9),
    dark: false,
  );

  static const _dark = _TixTheme(
    card: Color(0xFF2F2F2F),
    hi: Colors.white,
    mid: Color(0xFF9BA3B5),
    line: Color(0x22FFFFFF),
    tonal: Color(0x14FFFFFF),
    dark: true,
  );

  /// MaterialApp joriy temasi — `themeProvider.isDark` emas (nested embed'da
  /// platform brightness bilan mos kelmasligi mumkin).
  static _TixTheme of(BuildContext context) =>
      context.isDarkMode ? _dark : _light;

  static TextStyle style(double size, FontWeight weight, Color color,
          {double? height}) =>
      TextStyle(
        // Paket shrifti — host app ichida ham Gilroy topilsin.
        fontFamily: "packages/mysafar_sdk/Gilroy",
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );

  List<BoxShadow> get cardShadow => dark
      ? const []
      : const [
          BoxShadow(
            color: Color(0x0F202A44),
            blurRadius: 14,
            offset: Offset(0, 4),
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

/// Ikki sana orasidagi kunlar farqi (qo'nish ertasi kuni bo'lsa +1).
int _tixDayDiff(String? from, String? to) {
  DateTime? parse(String? raw) {
    final s = (raw ?? '').trim();
    if (s.isEmpty) return null;
    final parts = s.contains('-') ? s.split('-') : s.split('.');
    if (parts.length != 3) return null;
    final bool yearFirst = parts[0].length == 4;
    final d = int.tryParse(yearFirst ? parts[2] : parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(yearFirst ? parts[0] : parts[2]);
    if (d == null || m == null || y == null) return null;
    return DateTime(y, m, d);
  }

  final a = parse(from);
  final b = parse(to);
  if (a == null || b == null) return 0;
  return b.difference(a).inDays;
}

/// ═══════════════════════════════════════════════════════════════════
///  ASOSIY CHIPTA KARTASI
/// ═══════════════════════════════════════════════════════════════════
class _FigmaTicketCard extends StatefulWidget {
  final FlightElement flightElement;

  /// 0 → one-way, 1 → round-trip, 2 → multi-city
  final int tripType;

  /// Ro'yxatdagi eng arzon reys — "Eng arzon" belgisi.
  final bool isCheapest;

  /// Eng arzon (1- va 2-) kartalarda "Ekonom" belgisi.
  final bool showEconomBadge;

  const _FigmaTicketCard({
    required this.flightElement,
    required this.tripType,
    this.isCheapest = false,
    this.showEconomBadge = false,
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
    final segmentList = f.getSegmentList();
    final directions = [
      for (int i = 0; i < segmentList.length; i++)
        if (segmentList[i].isNotEmpty) (i, segmentList[i]),
    ];
    final price =
        Provider.of<CurrencyProvider>(context).getElementPrice(f.price);
    final allSegments = [for (final d in directions) ...d.$2];
    final bool labelLegs = widget.tripType != 0 || directions.length > 1;

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: t.cardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              AnalyticsService().trackButtonTap('ticket_select');
              TicketInfoPage.show(context, f);
            },
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: _CardHeader(
                    segments: allSegments,
                    flight: f,
                    isCheapest: widget.isCheapest,
                    showEconom: widget.showEconomBadge,
                  ),
                ),
                for (int k = 0; k < directions.length; k++) ...[
                  if (k > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(height: 1, thickness: 1, color: t.line),
                    ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, k == 0 ? 14 : 12, 16, 12),
                    child: _LegBlock(
                      flight: f,
                      dirIndex: directions[k].$1,
                      segments: directions[k].$2,
                      label: labelLegs
                          ? _legLabel(widget.tripType, k, directions[k].$2)
                          : null,
                    ),
                  ),
                ],
                _CardFooter(flight: f, price: price),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// "Borish · 24 iyul, pay" / "Qaytish · ..." / "2-reys · ...".
  static String _legLabel(int tripType, int index, List<FlightSegment> segs) {
    final String name;
    if (tripType == 1) {
      name = (index == 0 ? "when" : "return").tr();
    } else {
      final raw = "race_number".tr(namedArgs: {"num": "${index + 1}"});
      name = raw.isEmpty ? raw : raw[0].toUpperCase() + raw.substring(1);
    }
    final date = _tixDateWithWeekday(segs.first.dep.date);
    return date.isEmpty ? name : "$name · $date";
  }
}

/// Karta tepasi: aviakompaniya(lar) va belgilar.
class _CardHeader extends StatelessWidget {
  final List<FlightSegment> segments;
  final FlightElement flight;
  final bool isCheapest;
  final bool showEconom;

  const _CardHeader({
    required this.segments,
    required this.flight,
    required this.isCheapest,
    required this.showEconom,
  });

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[
      if (flight.isVtrip == true) _LowcostPill(flightElement: flight),
      if (showEconom) const _EconomBadge(),
      if (isCheapest) const _CheapestBadge(),
    ];
    if (badges.isEmpty) return _LogoStack(segments: segments);

    // Belgilar sig'masa keyingi qatorga o'tadi (uzun tarjimalar, kichik ekran).
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _LogoStack(segments: segments)),
        const SizedBox(width: 8),
        Flexible(
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 6,
            runSpacing: 4,
            children: badges,
          ),
        ),
      ],
    );
  }
}

/// Bitta yo'nalish (leg): ixtiyoriy sarlavha va vaqt chizig'i.
class _LegBlock extends StatelessWidget {
  final FlightElement flight;
  final int dirIndex;
  final List<FlightSegment> segments;

  /// Borish-kelish / murakkab marshrutda: "Borish · 24 iyul, pay".
  final String? label;

  const _LegBlock({
    required this.flight,
    required this.dirIndex,
    required this.segments,
    this.label,
  });

  /// Yo'nalishdagi almashishlar (layover) umumiy davomiyligi, daqiqada.
  int _layoverSum() {
    int sum = 0;
    for (int i = 0; i < segments.length - 1; i++) {
      sum += flight.getLayoverMinutes(segments, i);
    }
    return sum;
  }

  static String _code(String? airport, String? city) {
    final a = (airport ?? '').trim();
    return a.isNotEmpty ? a : (city ?? '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    final first = segments.first;
    final last = segments.last;

    final transfers = flight.getTransferCount(dirIndex);
    final duration =
        ElementFormatter.formatDuration(flight.getDirDuration(dirIndex));
    final dayDiff = _tixDayDiff(first.dep.date, last.arr.date);

    // Almashish aeroportlari kodlari (masalan "SVO").
    final stops = [
      for (int i = 0; i < segments.length - 1; i++)
        _code(segments[i].arr.airport?.code, segments[i].arr.city?.code),
    ].where((c) => c.isNotEmpty).toList();

    final String transferText = transfers == 0
        ? "ticket_chip_direct".tr()
        : "ticket_transfer_info".tr(namedArgs: {
            "count": "$transfers",
            "duration": ElementFormatter.formatDuration(_layoverSum()),
          });

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          Text(
            label!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _TixTheme.style(12.5, FontWeight.w600, t.mid),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TimeColumn(
              time: ElementFormatter.formatTime(first.dep.time ?? ''),
              code: _code(first.dep.airport?.code, first.dep.city?.code),
              city: first.dep.city?.title ?? '',
              alignEnd: false,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  children: [
                    Text(
                      duration,
                      maxLines: 1,
                      style: _TixTheme.style(12, FontWeight.w600, t.mid),
                    ),
                    const SizedBox(height: 4),
                    _RouteLine(stops: transfers, color: t.line, dark: t.dark),
                    const SizedBox(height: 4),
                    Text(
                      stops.isNotEmpty && transfers > 0
                          ? "$transferText · ${stops.take(2).join(', ')}"
                          : transferText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: _TixTheme.style(
                        12,
                        FontWeight.w600,
                        transfers == 0 ? _kTixGreen : _TixTheme.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            _TimeColumn(
              time: ElementFormatter.formatTime(last.arr.time ?? ''),
              code: _code(last.arr.airport?.code, last.arr.city?.code),
              city: last.arr.city?.title ?? '',
              alignEnd: true,
              dayDiff: dayDiff,
            ),
          ],
        ),
      ],
    );
  }
}

/// Vaqt (katta), aeroport kodi va shahar.
class _TimeColumn extends StatelessWidget {
  final String time;
  final String code;
  final String city;
  final bool alignEnd;
  final int dayDiff;

  const _TimeColumn({
    required this.time,
    required this.code,
    required this.city,
    required this.alignEnd,
    this.dayDiff = 0,
  });

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 64, maxWidth: 104),
      child: Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  maxLines: 1,
                  style:
                      _TixTheme.style(19, FontWeight.w800, t.hi, height: 1.1),
                ),
                if (dayDiff > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(
                      "+$dayDiff",
                      style:
                          _TixTheme.style(11, FontWeight.w800, _TixTheme.rose),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            code,
            maxLines: 1,
            style: _TixTheme.style(13, FontWeight.w700, t.hi),
          ),
          if (city.isNotEmpty)
            Text(
              city,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: alignEnd ? TextAlign.end : TextAlign.start,
              style: _TixTheme.style(12, FontWeight.w500, t.mid),
            ),
        ],
      ),
    );
  }
}

/// Jo'nash va qo'nish orasidagi chiziq: uchlarida nuqtalar, o'rtada samolyot,
/// almashishlar soniga qarab kichik nuqtalar.
class _RouteLine extends StatelessWidget {
  final int stops;
  final Color color;
  final bool dark;

  const _RouteLine({
    required this.stops,
    required this.color,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final Color dot = dark ? Colors.white54 : const Color(0xFFB7C0D3);
    Widget endDot() => Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: dot, width: 1.5),
          ),
        );
    Widget line() => Expanded(child: Container(height: 1.5, color: color));
    Widget stopDot() => Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: _TixTheme.amber,
            shape: BoxShape.circle,
          ),
        );

    return SizedBox(
      height: 16,
      child: Row(
        children: [
          endDot(),
          line(),
          if (stops > 0) ...[
            for (int i = 0; i < stops.clamp(0, 2); i++) ...[
              stopDot(),
              line(),
            ],
          ],
          Transform.rotate(
            angle: 0.785398, // 45° — og'ma samolyot o'ngga qaraydi
            child: SvgPicture.asset(
              Assets.iconsPlaceAirportIcon,
              width: 16,
              height: 16,
              colorFilter: ColorFilter.mode(
                ProjectTheme.brandColor,
                BlendMode.srcIn,
              ),
            ),
          ),
          line(),
          endDot(),
        ],
      ),
    );
  }
}

/// Karta pasti: joylar / qo'l yuki / bagaj va narx.
class _CardFooter extends StatelessWidget {
  final FlightElement flight;
  final String price;

  const _CardFooter({required this.flight, required this.price});

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.line)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          Expanded(child: _TicketAmenityPills(flight: flight)),
          const SizedBox(width: 10),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                price,
                maxLines: 1,
                style: _TixTheme.style(19, FontWeight.w800, t.hi),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Yashil "Eng arzon" belgisi.
class _CheapestBadge extends StatelessWidget {
  const _CheapestBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _kTixGreen.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "ticket_chip_cheapest".tr(),
        maxLines: 1,
        style: _TixTheme.style(11.5, FontWeight.w700, _kTixGreen),
      ),
    );
  }
}

/// Aviakompaniya sarlavhasi:
///  • Barcha segmentlar BITTA aviakompaniyaniki bo'lsa — logo + nom.
///  • Bir nechta bo'lsa — ustma-ust logolar (max 3) va birinchisining nomi
///    "+N" bilan.
class _LogoStack extends StatelessWidget {
  final List<FlightSegment> segments;

  const _LogoStack({required this.segments});

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);

    final seen = <String>{};
    final codes = <String>[];
    String firstTitle = '';
    for (final s in segments) {
      if (seen.add(s.carrier.code)) {
        codes.add(s.carrier.code);
        if (codes.length == 1) firstTitle = s.carrier.title;
      }
    }
    if (codes.isEmpty) return const SizedBox.shrink();

    const double size = 28;
    const double step = 18;
    final shown = codes.take(3).toList();
    final String title =
        codes.length == 1 ? firstTitle : "$firstTitle +${codes.length - 1}";

    return Row(
      children: [
        SizedBox(
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
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _TixTheme.style(14, FontWeight.w700, t.hi),
          ),
        ),
      ],
    );
  }
}

/// Dumaloq aviakompaniya logotipi (oq plitka ichida).
class _AirlineCircle extends StatelessWidget {
  final String code;
  final double size;

  const _AirlineCircle({required this.code, this.size = 28});

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

/// Neytral "Ekonom" tegi.
class _EconomBadge extends StatelessWidget {
  const _EconomBadge();

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: t.tonal,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "klass_e".tr().trim(),
        maxLines: 1,
        style: _TixTheme.style(11.5, FontWeight.w700, t.mid),
      ),
    );
  }
}

/// Karta pastidagi joy / qo'l yuki / bagaj — ikonka (rangli ma'no) va
/// sokin yozuv.
class _TicketAmenityPills extends StatelessWidget {
  final FlightElement flight;

  const _TicketAmenityPills({required this.flight});

  @override
  Widget build(BuildContext context) {
    final seats = flight.getSeatCount();
    final withHand = flight.withCBaggage();
    final handText = flight.getCBaggage();
    final isBag = flight.isBaggage ?? false;
    final bagLabel = flight.getBaggage();

    return Wrap(
      spacing: 12,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _AmenityPill(
          iconAsset: withHand
              ? Assets.ticketsLuggageIcon
              : Assets.ticketsLuggageNegativeIcon,
          label: handText,
          positive: withHand,
        ),
        _AmenityPill(
          iconAsset: isBag
              ? Assets.ticketsBaggagePositiveIcon
              : Assets.ticketsBaggageNegativeIcon,
          label: bagLabel,
          positive: isBag,
        ),
        if (seats > 0)
          _AmenityPill(
            iconAsset: Assets.ticketsSeatIcon,
            label: "$seats",
            positive: true,
          ),
      ],
    );
  }
}

class _AmenityPill extends StatelessWidget {
  final String iconAsset;
  final String label;
  final bool positive;

  const _AmenityPill({
    required this.iconAsset,
    required this.label,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    final Color accent = positive ? _kTixGreen : _TixTheme.rose;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          iconAsset,
          width: 15,
          height: 15,
          colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          maxLines: 1,
          style: _TixTheme.style(12.5, FontWeight.w600, t.mid),
        ),
      ],
    );
  }
}

/// Loukoster tegi — bosilganda tafsilot sheet ochiladi.
class _LowcostPill extends StatelessWidget {
  final FlightElement flightElement;

  const _LowcostPill({required this.flightElement});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _TixTheme.rose.withAlpha(24),
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ProjectDialogs.showLowcostSheet(context, flightElement),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "lowcost".tr(),
                maxLines: 1,
                style: _TixTheme.style(11.5, FontWeight.w700, _TixTheme.rose),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 12,
                height: 12,
                child: SvgPicture.asset(
                  Assets.ticketsExclamationIcon,
                  colorFilter:
                      const ColorFilter.mode(_TixTheme.rose, BlendMode.srcIn),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Natijalar yuklanayotgan paytdagi skelet — yangi karta shaklida.
class _TicketCardSkeleton extends StatelessWidget {
  final bool isReturn;

  const _TicketCardSkeleton({required this.isReturn});

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
        );
    Widget leg() => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [bar(56, 18), const SizedBox(height: 6), bar(36, 12)],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  bar(48, 10),
                  const SizedBox(height: 8),
                  bar(double.infinity, 2),
                  const SizedBox(height: 8),
                  bar(64, 10),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [bar(56, 18), const SizedBox(height: 6), bar(36, 12)],
            ),
          ],
        );

    return Column(
      children: [
        for (int i = 0; i < 3; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(20),
              boxShadow: t.cardShadow,
            ),
            padding: const EdgeInsets.all(16),
            child: Shimmer.fromColors(
              baseColor: t.dark ? Colors.white12 : const Color(0xFFE9EDF3),
              highlightColor: t.dark ? Colors.white24 : const Color(0xFFF7F9FC),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      bar(120, 14),
                    ],
                  ),
                  const SizedBox(height: 16),
                  leg(),
                  if (isReturn) ...[const SizedBox(height: 18), leg()],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      bar(110, 12),
                      const Spacer(),
                      bar(96, 18),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════
///  PUBLIC CONTAINERS — ticket_page.dart switch'i ulardan foydalanadi.
/// ═══════════════════════════════════════════════════════════════════
class _SingleDateFlightContainer extends StatelessWidget {
  final FlightElement flightElement;
  final bool isCheapest;
  final bool showEconomBadge;

  const _SingleDateFlightContainer({
    required this.flightElement,
    this.isCheapest = false,
    this.showEconomBadge = false,
  });

  @override
  Widget build(BuildContext context) => _FigmaTicketCard(
        flightElement: flightElement,
        tripType: 0,
        isCheapest: isCheapest,
        showEconomBadge: showEconomBadge,
      );
}

class _ReturnDateFlightContainer extends StatelessWidget {
  final FlightElement flightElement;
  final bool isCheapest;
  final bool showEconomBadge;

  const _ReturnDateFlightContainer({
    required this.flightElement,
    this.isCheapest = false,
    this.showEconomBadge = false,
  });

  @override
  Widget build(BuildContext context) => _FigmaTicketCard(
        flightElement: flightElement,
        tripType: 1,
        isCheapest: isCheapest,
        showEconomBadge: showEconomBadge,
      );
}

class _MultipleDateFlightContainer extends StatelessWidget {
  final FlightElement flightElement;
  final bool isCheapest;
  final bool showEconomBadge;

  const _MultipleDateFlightContainer({
    required this.flightElement,
    this.isCheapest = false,
    this.showEconomBadge = false,
  });

  @override
  Widget build(BuildContext context) => _FigmaTicketCard(
        flightElement: flightElement,
        tripType: 2,
        isCheapest: isCheapest,
        showEconomBadge: showEconomBadge,
      );
}

/// ═══════════════════════════════════════════════════════════════════
///  NATIJA YO'Q / XATO HOLATI — boshi berk ko'cha bo'lmasin.
/// ═══════════════════════════════════════════════════════════════════

/// "Bilet topilmadi" yoki xato holati: [_TicketsEmptyView] (ikonka, sarlavha,
/// izoh) + ostida joriy dialoglardagi [SdkDialogButton] juftligi — asosiy va
/// ikkilamchi amal (masalan, "Qidiruvni o'zgartirish" / "Qayta qidirish").
class _NoResultsView extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  const _NoResultsView({
    required this.title,
    this.subtitle,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TicketsEmptyView(title: title, subtitle: subtitle),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SdkDialogButton(label: primaryLabel, onPressed: onPrimary),
              const SizedBox(height: 10),
              SdkDialogButton(
                label: secondaryLabel,
                onPressed: onSecondary,
                variant: SdkDialogButtonVariant.secondary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
