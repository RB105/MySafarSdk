// ignore_for_file: unused_element

import 'dart:math' as math;

import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysafar_sdk/src/core/enum/currency.dart' show AppCurrency;
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/tools/currency_provider.dart'
    show CurrencyProvider;
import 'package:mysafar_sdk/src/core/tools/formatters.dart';
import 'package:mysafar_sdk/src/core/tools/project_assets.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart';
import 'package:mysafar_sdk/src/core/tools/project_utils.dart';
import 'package:mysafar_sdk/src/cubit/tickets/tariff/ticket_tariff_cubit.dart';
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightElement, FlightSegment, Upgrade;
import 'package:flutter_svg/flutter_svg.dart' show SvgPicture;
import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/view/booking/passenger_information_page.dart';
import 'package:mysafar_sdk/src/view/tickets/flight_route_map_test_page.dart';
import 'package:provider/provider.dart' show Provider;
import 'package:shimmer/shimmer.dart' show Shimmer;

class TicketInfoPage extends StatefulWidget {
  final FlightElement flightElement;

  const TicketInfoPage({
    super.key,
    required this.flightElement,
  });

  static const routeName = '/ticketInfo';

  @override
  State<TicketInfoPage> createState() => _TicketInfoPageState();
}

class _TicketInfoPageState extends State<TicketInfoPage> {
  late FlightElement flightElement;

  @override
  void initState() {
    flightElement = widget.flightElement;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final params = ProjectUtils.params;
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final heroHeight = topInset + 232;
    const overlap = 0.0;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: context.backgroundColor,
      body: Stack(
        children: [
          // Hero (fixed at top, behind scrollable content)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: heroHeight,
              child: _TicketHero(
                flightElement: flightElement,
                originCity: params.firstSegmentTitle,
                destinationCity: params.lastSegmentTitle,
                paramsLabel: params.params,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          // Scrollable body — slides over hero on scroll
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: heroHeight - overlap),
                  Container(
                    decoration: BoxDecoration(
                      color: context.backgroundColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    child: Column(
                      children: [
                        _PriceFeatureCard(
                          priceLabel: currencyProvider
                              .getElementPrice(flightElement.price),
                          seatCount: flightElement.getSeatCount(),
                          withCBaggage: flightElement.withCBaggage(),
                          cBaggage: flightElement.withCBaggage()
                              ? flightElement.getCBaggage()
                              : null,
                          isRefund: flightElement.isRefund ?? false,
                          isBaggage: flightElement.isBaggage ?? false,
                          baggageLabel: flightElement.getBaggage(),
                          isExchangeable: flightElement.isExchangeable(),
                          tariffSection: SizedBox(
                            width: double.infinity,
                            child: BlocProvider(
                              create: (context) =>
                                  TicketTariffCubit(flightElement.id),
                              child: BlocConsumer<TicketTariffCubit,
                                  TicketTariffState>(
                                listener: (context, state) {},
                                builder: (context, state) {
                                  if (state is TicketTariffLoadingState) {
                                    final isDark =
                                        context.themeProvider.isDark;
                                    return Padding(
                                      key: const ValueKey('loadingState'),
                                      padding: const EdgeInsets.only(top: 12.0),
                                      child: Shimmer.fromColors(
                                        baseColor: isDark
                                            ? Colors.grey.shade800
                                            : Colors.grey.shade300,
                                        highlightColor: isDark
                                            ? Colors.grey.shade700
                                            : Colors.grey.shade100,
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                  color: context.inputColor,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          16.0)),
                                              child:
                                                  const SizedBox(height: 52)),
                                        ),
                                      ),
                                    );
                                  }
                                  return AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 400),
                                    transitionBuilder: (child, animation) {
                                      return ScaleTransition(
                                        scale: animation,
                                        child: FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: state is TicketTariffSuccessState
                                        ? Padding(
                                            key: const ValueKey('successState'),
                                            padding:
                                                const EdgeInsets.only(top: 12.0),
                                            child: _TariffPickerTile(
                                              onTap: () async {
                                                final result =
                                                    await ProjectDialogs
                                                        .showTariffPicker(
                                                            context,
                                                            state.tariffs,
                                                            flightElement.id);
                                                if (result != null) {
                                                  setState(() {
                                                    flightElement = result;
                                                  });
                                                }
                                              },
                                            ),
                                          )
                                        : state is TicketTariffUnavailableState
                                            ? const Padding(
                                                key: ValueKey(
                                                    'unavailableState'),
                                                padding:
                                                    EdgeInsets.only(top: 12.0),
                                                child: _TariffUnavailableTile(),
                                              )
                                            : const SizedBox.shrink(
                                                key: ValueKey('emptyState'),
                                              ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        context.szBoxHeight16,
                        ..._buildDirections(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Back button on top — always tappable above scrollview
          Positioned(
            top: topInset + 8,
            left: 16,
            child: _CircleIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomInset),
        child: _BookButton(
          priceLabel: currencyProvider.getElementPrice(flightElement.price),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => PassengerInformationPage(
                adt: params.adt,
                chd: params.chd,
                inf: params.inf,
                element: flightElement,
              ),
            ));
          },
        ),
      ),
    );
  }

  String getUpgradePrice(Upgrade upgrade) {
    final currency = context.currencyProvider.currency;
    switch (currency) {
      case AppCurrency.uzs:
        return "${upgrade.increasePrice?.uzs ?? ""} UZS";
      case AppCurrency.usd:
        return "${upgrade.increasePrice?.usd ?? ""} USD";
      case AppCurrency.rub:
        return "${upgrade.increasePrice?.rub ?? ""} RUB";
    }
  }

  List<Widget> _buildDirections(BuildContext context) {
    final segmentList = flightElement.getSegmentList();
    final widgets = <Widget>[];
    for (int i = 0; i < segmentList.length; i++) {
      widgets.add(_FlightDirectionCard(
        flightElement: flightElement,
        segments: segmentList[i],
        directionIndex: i,
      ));
      if (i != segmentList.length - 1) widgets.add(context.szBoxHeight16);
    }
    return widgets;
  }

  /// Reys yo'nalishlaridan IATA kodlari zanjirini ajratadi: har yo'nalish
  /// uchun birinchi uchish + har segmentning qo'nish kodi (peresadkalar
  /// bilan). Natija: (borish, qaytish).
  (List<String>, List<String>) _extractRouteCodes() {
    final segs = flightElement.getSegmentList();

    List<String> codesFor(List<FlightSegment> dir) {
      final codes = <String>[];
      if (dir.isEmpty) return codes;
      final dep = dir.first.dep.airport?.code ?? dir.first.dep.city?.code ?? '';
      if (dep.isNotEmpty) codes.add(dep);
      for (final s in dir) {
        final arr = s.arr.airport?.code ?? s.arr.city?.code ?? '';
        if (arr.isNotEmpty) codes.add(arr);
      }
      return codes;
    }

    final outbound = segs.isNotEmpty ? codesFor(segs[0]) : <String>[];
    final ret = segs.length > 1 ? codesFor(segs[1]) : <String>[];
    return (outbound, ret);
  }

  void _openRouteMap(BuildContext context) {
    final (outbound, ret) = _extractRouteCodes();
    if (outbound.length < 2) return; // marshrut chizish uchun kam
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FlightRouteMapTestPage(
          outboundCodes: outbound,
          returnCodes: ret.length >= 2 ? ret : null,
        ),
      ),
    );
  }
}



// ════════════════════════════════════════════════════════════════════
//  HERO
// ════════════════════════════════════════════════════════════════════

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
    return segs[0].last.arr.airport?.code ??
        segs[0].last.arr.city?.code ??
        '';
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
          // World map background (behind content)
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.18,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    'packages/mysafar_sdk/assets/img/tickets/worls_map.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),

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
                            height: 36,
                            child: CustomPaint(
                              size: const Size(double.infinity, 36),
                              painter: _RouteArcPainter(
                                color: Colors.white.withAlpha(180),
                              ),
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

    // Plane at top of arc
    final planeCenter = Offset(size.width / 2, 8);
    canvas.save();
    canvas.translate(planeCenter.dx, planeCenter.dy);
    canvas.rotate(math.pi / 2);
    final planePaint = Paint()..color = Colors.white;
    final planePath = Path()
      ..moveTo(0, -8)
      ..lineTo(2.5, 2)
      ..lineTo(8, 4)
      ..lineTo(8, 5.5)
      ..lineTo(2.5, 5)
      ..lineTo(1.5, 9)
      ..lineTo(3, 11)
      ..lineTo(3, 12)
      ..lineTo(0, 11)
      ..lineTo(-3, 12)
      ..lineTo(-3, 11)
      ..lineTo(-1.5, 9)
      ..lineTo(-2.5, 5)
      ..lineTo(-8, 5.5)
      ..lineTo(-8, 4)
      ..lineTo(-2.5, 2)
      ..close();
    canvas.drawPath(planePath, planePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RouteArcPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ════════════════════════════════════════════════════════════════════
//  PRICE + FEATURES CARD
// ════════════════════════════════════════════════════════════════════

class _PriceFeatureCard extends StatelessWidget {
  final String priceLabel;
  final int seatCount;
  final bool withCBaggage;
  final String? cBaggage;
  final bool isRefund;
  final bool isBaggage;
  final String baggageLabel;
  final bool isExchangeable;
  final Widget tariffSection;

  const _PriceFeatureCard({
    required this.priceLabel,
    required this.seatCount,
    required this.withCBaggage,
    required this.cBaggage,
    required this.isRefund,
    required this.isBaggage,
    required this.baggageLabel,
    required this.isExchangeable,
    required this.tariffSection,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    final brand = ProjectTheme.brandColor;
    final secondaryColor = isDark
        ? ProjectTheme.secondaryTextDark
        : ProjectTheme.secondaryTextLight;
    final dividerColor =
        isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(14);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.color.primaryContainer,
          borderRadius: BorderRadius.circular(22),
          boxShadow: context.shadowDown,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Price hero
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [brand, ProjectTheme.blueBg],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.confirmation_number_outlined,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "total_price".tr(),
                          style: context.textTheme.bodySmall?.copyWith(
                            color: secondaryColor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            priceLabel,
                            style: context.textTheme.displayMedium?.copyWith(
                              color: brand,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(height: 1, color: dividerColor),
              const SizedBox(height: 14),
              // Feature pills
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FeaturePill(
                    assetPath: Assets.ticketsSeatIcon,
                    label:
                        "seat_count".tr(namedArgs: {"count": "$seatCount"}),
                    accent: ProjectTheme.success,
                    isDark: isDark,
                  ),
                  _FeaturePill(
                    assetPath: withCBaggage
                        ? Assets.ticketsLuggageIcon
                        : Assets.ticketsLuggageNegativeIcon,
                    label: withCBaggage
                        ? "luggage_size".tr(namedArgs: {"count": cBaggage ?? ""})
                        : "no_luggage".tr(),
                    accent:
                        withCBaggage ? ProjectTheme.success : ProjectTheme.error,
                    isDark: isDark,
                  ),
                  _FeaturePill(
                    assetPath: isBaggage
                        ? Assets.ticketsBaggagePositiveIcon
                        : Assets.ticketsBaggageNegativeIcon,
                    label: baggageLabel,
                    accent:
                        isBaggage ? ProjectTheme.success : ProjectTheme.error,
                    isDark: isDark,
                  ),
                  _FeaturePill(
                    assetPath: isRefund
                        ? Assets.ticketsReturnSuccessIcon
                        : Assets.ticketsReturnIcon,
                    label: isRefund ? "refundable".tr() : "unrefundable".tr(),
                    accent: isRefund ? ProjectTheme.success : ProjectTheme.error,
                    isDark: isDark,
                  ),
                  _FeaturePill(
                    assetPath: isExchangeable
                        ? Assets.ticketsReplaceGreenIcon
                        : Assets.ticketsReplaceRedIcon,
                    label: isExchangeable
                        ? "exchangeable".tr()
                        : "unexchangeable".tr(),
                    accent: isExchangeable
                        ? ProjectTheme.success
                        : ProjectTheme.error,
                    isDark: isDark,
                  ),
                ],
              ),
              tariffSection,
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final String assetPath;
  final String label;
  final Color accent;
  final bool isDark;

  const _FeaturePill({
    required this.assetPath,
    required this.label,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? accent.withAlpha(45) : accent.withAlpha(22);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: SvgPicture.asset(assetPath),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _TariffPickerTile extends StatelessWidget {
  final VoidCallback onTap;

  const _TariffPickerTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    final brand =
        isDark ? ProjectTheme.accentLight : ProjectTheme.brandColor;
    final bg = isDark ? brand.withAlpha(38) : brand.withAlpha(22);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: brand.withAlpha(isDark ? 80 : 45),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.style_outlined, color: brand, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "choose_other_tariff".tr(),
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: brand,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: brand, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _TariffUnavailableTile extends StatelessWidget {
  const _TariffUnavailableTile();

  @override
  Widget build(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    final warn = ProjectTheme.warning;
    final bg = isDark ? warn.withAlpha(38) : warn.withAlpha(28);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: warn.withAlpha(isDark ? 80 : 45),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.warning_amber_rounded, color: warn, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "no_other_tariff".tr(),
              style: context.textTheme.bodyMedium?.copyWith(
                color: warn,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  FLIGHT DIRECTION — BOARDING-PASS CARD + VERTICAL TIMELINE
// ════════════════════════════════════════════════════════════════════

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
    final isDark = context.themeProvider.isDark;
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
    final bg = context.backgroundColor;
    final dashColor = context.themeProvider.isDark
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
        .withAlpha(context.themeProvider.isDark ? 150 : 110);
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
    final secondary = context.themeProvider.isDark
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
    final isDark = context.themeProvider.isDark;
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
    final isDark = context.themeProvider.isDark;
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
class _MapRouteButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MapRouteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    final brand =
        isDark ? ProjectTheme.accentLight : ProjectTheme.brandColor;
    final secondary = isDark
        ? ProjectTheme.secondaryTextDark
        : ProjectTheme.secondaryTextLight;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: brand.withAlpha(isDark ? 38 : 20),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: brand.withAlpha(isDark ? 90 : 60)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [ProjectTheme.brandColor, ProjectTheme.blueBg],
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.public_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Marshrutni xaritada ko'rish",
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: brand,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Parvoz yo'lini animatsiyada kuzating",
                      style: context.textTheme.titleSmall?.copyWith(
                        fontSize: 11.5,
                        color: secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: brand, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  BOOK BUTTON
// ════════════════════════════════════════════════════════════════════

class _BookButton extends StatelessWidget {
  final String priceLabel;
  final VoidCallback onTap;

  const _BookButton({required this.priceLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final brand = ProjectTheme.brandColor;
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [brand, ProjectTheme.blueBg],
              ),
              boxShadow: [
                BoxShadow(
                  color: brand.withAlpha(30),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Glossy top highlight
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withAlpha(48),
                          Colors.white.withAlpha(0),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "total_price".tr(),
                              style: TextStyle(
                                color: Colors.white.withAlpha(215),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                priceLabel,
                                maxLines: 1,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // White CTA pill — pops against the gradient
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 9, 9, 9),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "book_ticket".tr(),
                              style: TextStyle(
                                color: brand,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [brand, ProjectTheme.blueBg],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
