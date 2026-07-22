part of 'ticket_page.dart';

/// ═══════════════════════════════════════════════════════════════════
///  FIGMA TICKET CARDS
///  ─────────────────────────────────────────────────────────────────
///  • _FigmaTicketCard — toza oq karta: tepada aviakompaniya logolari +
///    narx; har bir yo'nalish uchun vaqtlar, davomiylik, sana (kelish
///    boshqa kunda bo'lsa — orange) va marshrut. Barcha kartalar (one-way,
///    return, multiway) bir xil shu ko'rinishda — maxsus birinchi karta yo'q.
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

  /// Ro'yxatdagi eng arzon reys — logo yonida yashil "Eng arzon" belgisi
  /// ko'rsatiladi (web mobil dizayni).
  final bool isCheapest;

  /// Eng arzon (1- va 2-) kartalarda karta tepasida "Ekonom" belgisi.
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
    final directions = f.getSegmentList();
    final price =
        Provider.of<CurrencyProvider>(context).getElementPrice(f.price);

    // Narx faqat birinchi (borish) yo'nalishda ko'rsatiladi — shu yo'nalish
    // indeksini topamiz (odatda 0, lekin bo'sh bo'lsa keyingisiga o'tadi).
    int firstIdx = -1;
    for (int i = 0; i < directions.length; i++) {
      if (directions[i].isNotEmpty) {
        firstIdx = i;
        break;
      }
    }

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
              TicketInfoPage.show(context, f);
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
                  if (widget.showEconomBadge) ...[
                    const _EconomBadge(),
                    const SizedBox(height: 10),
                  ],
                  // Har bir yo'nalish o'z logo+nomi bilan; narx faqat birinchi
                  // (borish) yo'nalishda, logo yonida ko'rsatiladi. Borish va
                  // qaytish orasi divider bilan ajratiladi.
                  for (int i = 0; i < directions.length; i++)
                    if (directions[i].isNotEmpty) ...[
                      if (i > firstIdx)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Divider(
                              height: 1, thickness: 1, color: t.line),
                        ),
                      _LegBlock(
                        flight: f,
                        dirIndex: i,
                        segments: directions[i],
                        price: i == firstIdx ? price : null,
                        showCheapestBadge:
                            widget.isCheapest && i == firstIdx,
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

  /// Faqat birinchi (borish) yo'nalishda beriladi — logo yonida narx
  /// ko'rsatiladi. Qaytish yo'nalishida `null` (narx ko'rsatilmaydi).
  final String? price;

  /// Logo yonida yashil "Eng arzon" belgisi (faqat birinchi yo'nalishda).
  final bool showCheapestBadge;

  const _LegBlock({
    required this.flight,
    required this.dirIndex,
    required this.segments,
    this.price,
    this.showCheapestBadge = false,
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
    // Kelish boshqa kunda bo'lsa — sanasi qizil rangda qo'shiladi (web).
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
        // Shu yo'nalishning aviakompaniya logosi + nomi (vaqtlar tepasida);
        // narx faqat birinchi yo'nalishda, o'ng tomonda.
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(child: _LogoStack(segments: segments)),
                  if (showCheapestBadge) ...[
                    const SizedBox(width: 8),
                    const _CheapestBadge(),
                  ],
                ],
              ),
            ),
            if (price != null) ...[
              const SizedBox(width: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  price!,
                  maxLines: 1,
                  style: _TixTheme.style(17.5, FontWeight.w800, t.hi),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        // Vaqtlar va davomiylik.
        Row(
          children: [
            Expanded(
              child: Text(
                '${ElementFormatter.formatTime(first.dep.time ?? '')} - ${ElementFormatter.formatTime(last.arr.time ?? '')}',
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
                            13, FontWeight.w600, _TixTheme.rose),
                      ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Web dizayni: to'g'ri reys — yashil, almashishli — qizil.
            Text(
              transferText,
              style: _TixTheme.style(13, FontWeight.w600,
                  transfers == 0 ? _kTixGreen : _TixTheme.rose),
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

/// Yashil "Eng arzon" belgisi — ro'yxatdagi eng arzon kartada, logo yonida
/// ko'rsatiladi (web mobil dizayni).
class _CheapestBadge extends StatelessWidget {
  const _CheapestBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: _kTixGreen.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "ticket_chip_cheapest".tr(),
        maxLines: 1,
        style: _TixTheme.style(11.5, FontWeight.w700, _kTixGreen),
      ),
    );
  }
}

/// Aviakompaniya sarlavhasi (Figma standarti):
///  • Reysdagi barcha bo'laklar (segment) BITTA aviakompaniyaga tegishli bo'lsa
///    (to'g'ri yoki transferli, bir yoki ikki tomonlama — farqi yo'q) →
///    yakka logo + aviakompaniya NOMI ko'rsatiladi.
///  • Bir nechta har xil aviakompaniya bo'lsa → faqat ustma-ust logolar
///    (noyob, max 3), nom yozilmaydi.
class _LogoStack extends StatelessWidget {
  final List<FlightSegment> segments;

  const _LogoStack({required this.segments});

  @override
  Widget build(BuildContext context) {
    final t = _TixTheme.of(context);

    // Noyob aviakompaniyalarni (kod → nom) kelish tartibida yig'amiz.
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

    const double size = 30;

    // Bitta aviakompaniya — logo + nom.
    if (codes.length == 1) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AirlineCircle(code: codes.first, size: size),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              firstTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _TixTheme.style(14, FontWeight.w700, t.hi),
            ),
          ),
        ],
      );
    }

    // Bir nechta aviakompaniya — faqat ustma-ust logolar.
    const double step = 20;
    final shown = codes.take(3).toList();
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

/// "Ekonom" belgisi — narx bo'yicha saralangan ro'yxatning eng arzon
/// kartalarida (1- va 2-o'rin) karta tepasida ko'rsatiladigan yashil pill.
class _EconomBadge extends StatelessWidget {
  const _EconomBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: _kTixGreen.withAlpha(26),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        "klass_e".tr().trim(),
        style: _TixTheme.style(12, FontWeight.w700, _kTixGreen),
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
