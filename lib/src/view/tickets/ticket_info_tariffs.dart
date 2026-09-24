// Creator: Ravshanov Anzor
// Created: 24.09.2026

part of 'ticket_info_page.dart';

/// Tariflar lentasi: gorizontal suriladigan kartalar.
///
/// Tanlangan kartada TO'LIQ narx, qolganlarida esa tanlanganiga nisbatan
/// farq ("+18 000 UZS" / "−42 000 UZS") ko'rsatiladi. Tariflar hali
/// yuklanayotgan bo'lsa yoki umuman kelmasa — bitta joriy karta qoladi.
///
/// SDK: tanlangan karta doim JORIY [flightElement] ni ko'rsatadi — tekshiruvdan
/// (`get-flight-info`) keyin u yangilangan narx/token bilan almashadi, pastdagi
/// tugma narxi bilan bir xil bo'lsin. [selectedIndex] `-1` bo'lsa (joriy reys
/// tariflar ro'yxatida topilmadi, №61) — joriy reys alohida birinchi karta
/// bo'lib turadi, ro'yxatdagi hech bir tarif jimgina tanlanmaydi.
class _TariffCarousel extends StatelessWidget {
  const _TariffCarousel({
    required this.flightElement,
    required this.tariffs,
    required this.selectedIndex,
    required this.loading,
    required this.passengerCount,
    required this.onSelect,
  });

  /// Joriy (tanlangan) reys — tariflar bo'lmasa shu o'zi ko'rsatiladi.
  final FlightElement flightElement;
  final List<FlightTariffModel> tariffs;
  final int selectedIndex;
  final bool loading;
  final int passengerCount;
  final ValueChanged<int> onSelect;

  bool get _inList => selectedIndex >= 0 && selectedIndex < tariffs.length;

  /// Tanlash uchun muqobil bor-yo'qligi: joriy reys ro'yxatda bo'lsa — kamida
  /// ikki tarif, bo'lmasa — kamida bittasi.
  bool get _hasTariffs => _inList ? tariffs.length > 1 : tariffs.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            // Keyingi karta chetidan ko'rinib tursin — surish mumkinligi
            // shundan bilinadi.
            final cardWidth = constraints.maxWidth - 46;
            final selectedPrice =
                _amount(currencyProvider, flightElement.price);

            Widget currentCard({required int index, required bool check}) =>
                _TariffFareCard(
                  flight: flightElement,
                  name: _tariffName(flightElement, index),
                  priceLabel:
                      currencyProvider.getElementPrice(flightElement.price),
                  diffLabel: null,
                  passengerCount: passengerCount,
                  isSelected: true,
                  showCheck: check,
                  onTap: null,
                );

            final cards = <Widget>[
              if (!_hasTariffs)
                currentCard(index: 0, check: false)
              else ...[
                // Joriy reys ro'yxatda yo'q — alohida birinchi karta.
                if (!_inList) currentCard(index: 0, check: true),
                for (var index = 0; index < tariffs.length; index++)
                  if (index == selectedIndex)
                    currentCard(index: index, check: true)
                  else
                    Builder(builder: (context) {
                      final flight = tariffs[index].flight;
                      final price = _amount(currencyProvider, flight.price);
                      return _TariffFareCard(
                        flight: flight,
                        name: _tariffName(flight, index),
                        priceLabel:
                            currencyProvider.getElementPrice(flight.price),
                        diffLabel: _diffLabel(price, selectedPrice),
                        passengerCount: passengerCount,
                        isSelected: false,
                        showCheck: true,
                        onTap: () => onSelect(index),
                      );
                    }),
              ],
              // Tariflar hali kelmagan — keyingi karta o'rnida shimmer turadi va
              // javob kelishi bilan haqiqiy karta bilan almashadi.
              if (loading) const _TariffCardShimmer(),
            ];

            // Kartalar bir xil balandlikda — eng balandiga tenglashadi
            // (matn ikki qatorga tushsa ham kesilmaydi).
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      SizedBox(width: cardWidth, child: cards[i]),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Tarif nomi: marketing nomi → turi → "Tarif N".
  static String _tariffName(FlightElement flight, int index) {
    final marketing = flight.fareFamilyMarketingName?.trim() ?? '';
    if (marketing.isNotEmpty) return marketing;
    final type = flight.fareFamilyType?.trim() ?? '';
    if (type.isNotEmpty) return type;
    return '${"tariff".tr()} ${index + 1}';
  }

  /// Narx — tanlangan valyutada (bo'lmasa UZS, `getElementPrice` bilan bir
  /// xil qoida: [CurrencyProvider.resolveElementPrice]).
  static ({double value, AppCurrency currency})? _amount(
      CurrencyProvider provider, FlightPrice? price) {
    final resolved =
        CurrencyProvider.resolveElementPrice(price, provider.currency);
    if (resolved == null) return null;
    return (value: resolved.value, currency: resolved.currency);
  }

  /// "+18 000 UZS" / "−42 000 UZS"; farq bo'lmasa yoki narxlar turli
  /// valyutada kelgan bo'lsa — null (to'liq narx ko'rsatiladi).
  static String? _diffLabel(
    ({double value, AppCurrency currency})? price,
    ({double value, AppCurrency currency})? selected,
  ) {
    if (price == null ||
        selected == null ||
        price.currency != selected.currency) {
      return null;
    }
    final diff = (price.value - selected.value).round();
    if (diff == 0) return null;
    final sign = diff > 0 ? '+' : '−';
    return '$sign${_groupDigits(diff.abs())} ${price.currency.label}';
  }

  /// 1234567 → "1 234 567".
  static String _groupDigits(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

/// "Tariflarni yuklayapmiz" — pastki panelda, narx tugmasi o'rnida turadi.
///
/// Indikator ikkala platformada ham iOS ko'rinishida: shu ekrandagi ikkinchi
/// spinner (tugma ichidagisi) bilan bir xil bo'lsin uchun.
class _TariffsLoadingRow extends StatelessWidget {
  const _TariffsLoadingRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CupertinoActivityIndicator(
          radius: 9,
          color: _tiMuted(context),
        ),
        const SizedBox(width: 10),
        Text(
          'tariffs_loading'.tr(),
          style: context.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _tiMuted(context),
          ),
        ),
      ],
    );
  }
}

/// Tarif kartasi yuqori zonasining bazaviy balandligi (textScale = 1).
/// Ichidagi (qator balandliklari `height:` bilan qat'iy): belgi qatori 26 +
/// 8 + narx 26.4 + 4 + yo'lovchi 15 + padding 14/12 = ~105; qolgani zaxira.
const double _tariffTopHeight = 116;

/// Tarif kartasi o'rnidagi shimmer — ma'lumot kelguncha shu turadi.
/// Shakli haqiqiy karta bilan bir xil (yuqori zona + perforatsiya), shunda
/// javob kelganda karta "sakramaydi".
class _TariffCardShimmer extends StatelessWidget {
  const _TariffCardShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
    final topHeight = _tariffTopHeight * scale;
    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
        );

    return ClipPath(
      clipper: _TicketClipper(notchY: topHeight, radius: 20, notchRadius: 9),
      child: ColoredBox(
        color: context.color.primaryContainer,
        child: Stack(
          children: [
            // Yuqori zonaning sokin foni — shimmer TASHQARISIDA, aks holda
            // butun zona bir tekis bo'yalib ketadi.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topHeight,
              child: ColoredBox(color: _tiTonal(context)),
            ),
            Shimmer.fromColors(
              baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              highlightColor:
                  isDark ? Colors.grey.shade700 : Colors.grey.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: topHeight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          bar(90, 12),
                          const SizedBox(height: 10),
                          bar(150, 24),
                          const SizedBox(height: 8),
                          bar(110, 12),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < 4; i++) ...[
                          if (i > 0) const SizedBox(height: 12),
                          Row(
                            children: [
                              bar(20, 20),
                              const SizedBox(width: 8),
                              bar(120 + (i.isEven ? 30 : 0), 12),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bitta tarif kartasi — "chipta" ko'rinishida.
///
/// Ikki zona: yuqorida nom + narx (yoki farq) + yo'lovchi soni, pastda
/// tarif shartlari. Zonalar orasida perforatsiya: ikki yon chetdan yarim
/// doira o'yilgan va punktir chiziq tortilgan. Tanlangan kartaning yuqori
/// zonasi brend gradientida, chetiga kontur tortiladi.
class _TariffFareCard extends StatelessWidget {
  const _TariffFareCard({
    required this.flight,
    required this.name,
    required this.priceLabel,
    required this.diffLabel,
    required this.passengerCount,
    required this.isSelected,
    required this.showCheck,
    required this.onTap,
  });

  final FlightElement flight;
  final String name;
  final String priceLabel;

  /// Tanlanmagan tarifda — tanlanganiga nisbatan farq.
  final String? diffLabel;
  final int passengerCount;
  final bool isSelected;
  final bool showCheck;
  final VoidCallback? onTap;

  static const _radius = 20.0;
  static const _notchRadius = 9.0;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    // Tanlangan karta yumshoq to'q kontur va belgi bilan ajraladi.
    final muted = _tiMuted(context);
    // Aviakompaniya — birinchi yo'nalishning birinchi reysi (marketing
    // tashuvchi); tarif shu kompaniyaniki.
    final dirs = flight.getSegmentList();
    final carrierCode = dirs.isNotEmpty && dirs.first.isNotEmpty
        ? dirs.first.first.carrier.code.trim()
        : '';

    // Yuqori zona balandligi qat'iy — perforatsiya aynan shu chiziqda.
    // Matn kattalashtirilgan bo'lsa zona ham shunga yarasha o'sadi
    // (ichidagi barcha matn bir qatorli, shuning uchun sig'ishi kafolatli).
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
    final topHeight = _tariffTopHeight * scale;

    final rules = <(String, String, bool)>[
      (
        flight.withCBaggage()
            ? Assets.ticketsLuggageIcon
            : Assets.ticketsLuggageNegativeIcon,
        flight.withCBaggage()
            ? "luggage_size".tr(namedArgs: {"count": flight.getCBaggage()})
            : "no_luggage".tr(),
        flight.withCBaggage(),
      ),
      (
        (flight.isBaggage ?? false)
            ? Assets.ticketsBaggagePositiveIcon
            : Assets.ticketsBaggageNegativeIcon,
        flight.getBaggage(),
        flight.isBaggage ?? false,
      ),
      (
        flight.isExchangeable()
            ? Assets.ticketsReplaceGreenIcon
            : Assets.ticketsReplaceRedIcon,
        flight.isExchangeable() ? "exchangeable".tr() : "unexchangeable".tr(),
        flight.isExchangeable(),
      ),
      (
        (flight.isRefund ?? false)
            ? Assets.ticketsReturnSuccessIcon
            : Assets.ticketsReturnIcon,
        (flight.isRefund ?? false) ? "refundable".tr() : "unrefundable".tr(),
        flight.isRefund ?? false,
      ),
    ];

    // Yuqori zona — doim sokin tonal fon, matn to'q.
    final Color topText = _tiText(context);
    final Color topMuted = muted;
    final Decoration topDecoration = BoxDecoration(color: _tiTonal(context));

    // Tanlangan karta — yumshoq to'q kulrang chegara (qop-qora og'ir ko'rinardi).
    final borderColor = isSelected
        ? _tiSelected(context)
        : context.color.outline.withValues(alpha: isDark ? 0.35 : 0.7);
    final perforation = isDark
        ? Colors.white.withValues(alpha: 0.22)
        : Colors.black.withValues(alpha: 0.14);

    return Stack(
      children: [
        ClipPath(
          clipper: _TicketClipper(
            notchY: topHeight,
            radius: _radius,
            notchRadius: _notchRadius,
          ),
          child: Material(
            color: context.color.primaryContainer,
            child: InkWell(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Yuqori zona: nom · narx · yo'lovchi ─────────────────
                  SizedBox(
                    height: topHeight,
                    child: DecoratedBox(
                      decoration: topDecoration,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (carrierCode.isNotEmpty) ...[
                                  _CarrierLogo(code: carrierCode),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: Text(
                                    name.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        context.textTheme.bodySmall?.copyWith(
                                      fontSize: 12,
                                      height: 1.2,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: topMuted,
                                    ),
                                  ),
                                ),
                                if (showCheck)
                                  _SelectMark(selected: isSelected),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              diffLabel ?? priceLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.titleLarge?.copyWith(
                                fontSize: 24,
                                height: 1.1,
                                fontWeight: FontWeight.w800,
                                color: topText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "fare_for_passengers"
                                  .tr(namedArgs: {"count": "$passengerCount"}),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.bodySmall?.copyWith(
                                fontSize: 12.5,
                                height: 1.2,
                                color: topMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // ── Pastki zona: shartlar ────────────────────────────────
                  // MUHIM: bu yerda `Spacer` ishlatilmaydi — kartalar
                  // balandligi `IntrinsicHeight` bilan tenglashtiriladi, u esa
                  // cho'ziluvchi bo'shliqni o'lchay olmaydi (layout xatosi).
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final (icon, label, positive) in rules)
                          _FareRuleItem(
                            iconAsset: icon,
                            label: label,
                            positive: positive,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Kontur + perforatsiya chizig'i — klip ustidan, bosishga xalaqit
        // bermaydi.
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _TicketOutlinePainter(
                notchY: topHeight,
                radius: _radius,
                notchRadius: _notchRadius,
                borderColor: borderColor,
                borderWidth: isSelected ? 1.6 : 1,
                perforationColor: perforation,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Aviakompaniya logosi — oq yumaloq "plitka" ichida, gradient ustida ham,
/// sokin fonda ham bir xil o'qiladi. Rasm yuklanmasa samolyot ikonkasi.
class _CarrierLogo extends StatelessWidget {
  const _CarrierLogo({required this.code});

  final String code;

  static const _size = 26.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          ProjectAssets.getSegmentProviderImg(code),
          fit: BoxFit.contain,
          cacheWidth: 72,
          cacheHeight: 72,
          errorBuilder: (_, __, ___) => Icon(
            Icons.flight_rounded,
            size: 14,
            color: ProjectTheme.brandColor,
          ),
        ),
      ),
    );
  }
}

/// Tanlangan tarif belgisi — o'ng yuqori burchakda.
///
/// Tanlanganda: "verified" muhri (Phosphor `seal-check`, MIT) — to'lqinsimon
/// chetli to'q nishon, ✓ ichidan fon ko'rinib turadi. Tanlanmaganda:
/// ingichka halqa.
/// Animatsiyasiz — tanlash bilan bir zumda almashadi.
class _SelectMark extends StatelessWidget {
  const _SelectMark({required this.selected});

  final bool selected;

  static const _size = 26.0;

  @override
  Widget build(BuildContext context) {
    if (!selected) {
      return Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: context.color.outline.withValues(alpha: 0.9),
            width: 1.5,
          ),
        ),
      );
    }
    return SvgPicture.asset(
      Assets.ticketsTariffCheckIcon,
      width: _size,
      height: _size,
      // Tasdiq belgisi doim yashil (natijalar kartasidagi yashil bilan bir xil).
      colorFilter:
          const ColorFilter.mode(Color(0xFF16A34A), BlendMode.srcIn),
    );
  }
}

/// Tanlangan tarif chegarasi — matn rangidan yumshoqroq to'q kulrang
/// (qop-qora emas), qorong'i rejimda — xira oq.
Color _tiSelected(BuildContext context) => context.isDarkMode
    ? Colors.white.withValues(alpha: 0.55)
    : const Color(0xFF667085);

/// Chipta shakli: burchaklari yumaloq to'rtburchak, ikki yon chetida
/// `notchY` balandligida yarim doira o'yiqlar.
Path _ticketPath(Size size, double notchY, double radius, double notchRadius) {
  final base = Path()
    ..addRRect(RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    ));
  final notches = Path()
    ..addOval(Rect.fromCircle(center: Offset(0, notchY), radius: notchRadius))
    ..addOval(Rect.fromCircle(
      center: Offset(size.width, notchY),
      radius: notchRadius,
    ));
  return Path.combine(PathOperation.difference, base, notches);
}

class _TicketClipper extends CustomClipper<Path> {
  final double notchY;
  final double radius;
  final double notchRadius;

  const _TicketClipper({
    required this.notchY,
    required this.radius,
    required this.notchRadius,
  });

  @override
  Path getClip(Size size) => _ticketPath(size, notchY, radius, notchRadius);

  @override
  bool shouldReclip(covariant _TicketClipper oldClipper) =>
      oldClipper.notchY != notchY ||
      oldClipper.radius != radius ||
      oldClipper.notchRadius != notchRadius;
}

/// Chipta konturi va o'yiqlar orasidagi punktir perforatsiya.
class _TicketOutlinePainter extends CustomPainter {
  final double notchY;
  final double radius;
  final double notchRadius;
  final Color borderColor;
  final double borderWidth;
  final Color perforationColor;

  const _TicketOutlinePainter({
    required this.notchY,
    required this.radius,
    required this.notchRadius,
    required this.borderColor,
    required this.borderWidth,
    required this.perforationColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Kontur — chiziq yarmi klipdan tashqariga chiqmasin uchun
    // yo'lni yarim qalinlikka ichkariga siqamiz.
    final inset = borderWidth / 2;
    final innerSize = Size(size.width - borderWidth, size.height - borderWidth);
    canvas.save();
    canvas.translate(inset, inset);
    canvas.drawPath(
      _ticketPath(innerSize, notchY - inset, radius - inset, notchRadius),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );
    canvas.restore();

    // Perforatsiya — o'yiqdan o'yiqqa punktir.
    final dashPaint = Paint()
      ..color = perforationColor
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    const dash = 5.0;
    const gap = 4.0;
    double x = notchRadius + 6;
    final end = size.width - notchRadius - 6;
    while (x < end) {
      final to = (x + dash) < end ? (x + dash) : end;
      canvas.drawLine(Offset(x, notchY), Offset(to, notchY), dashPaint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _TicketOutlinePainter oldDelegate) =>
      oldDelegate.notchY != notchY ||
      oldDelegate.radius != radius ||
      oldDelegate.notchRadius != notchRadius ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.borderWidth != borderWidth ||
      oldDelegate.perforationColor != perforationColor;
}
