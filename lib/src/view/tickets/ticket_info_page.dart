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
import 'package:mysafar_sdk/src/model/local/recom_req_model.dart'
    show RecommendationRequestBody;
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightElement, FlightSegment, Upgrade;
import 'package:flutter_svg/flutter_svg.dart' show SvgPicture;
import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/view/booking/passenger_information_page.dart';
import 'package:mysafar_sdk/src/view/tickets/flight_route_map_test_page.dart';
import 'package:provider/provider.dart' show Provider;
import 'package:shimmer/shimmer.dart' show Shimmer;

part 'ticket_info_price.dart';
part 'ticket_info_flight.dart';
part 'ticket_info_actions.dart';

class TicketInfoPage extends StatefulWidget {
  final FlightElement flightElement;

  const TicketInfoPage({
    super.key,
    required this.flightElement,
  });

  static const routeName = '/ticketInfo';

  /// Chipta tafsilotini bottom sheet sifatida ochadi (navigatsiya o‘rniga).
  static Future<T?> show<T>(BuildContext context, FlightElement flight) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => TicketInfoPage(flightElement: flight),
    );
  }

  @override
  State<TicketInfoPage> createState() => _TicketInfoPageState();
}

class _TicketInfoPageState extends State<TicketInfoPage> {
  static const Radius _sheetTopRadius = Radius.circular(20);

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
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final maxH = MediaQuery.of(context).size.height * 0.92;
    final sheetColor = Theme.of(context).scaffoldBackgroundColor;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: _sheetTopRadius),
      child: Material(
        color: sheetColor,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TicketSheetTopBar(
                topRadius: _sheetTopRadius,
                origin: params.firstSegmentTitle,
                destination: params.lastSegmentTitle,
                subtitle: _sheetSubtitle(params),
                onClose: () => Navigator.of(context).pop(),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                                  final isDark = context.isDarkMode;
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
                                                BorderRadius.circular(16.0),
                                          ),
                                          child: const SizedBox(height: 52),
                                        ),
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
                                                flightElement.id,
                                              );
                                              if (result != null) {
                                                setState(() {
                                                  flightElement = result;
                                                });
                                              }
                                            },
                                          ),
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
                      SizedBox(height: 8 + bottomInset),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: _BookButton(
                    priceLabel: currencyProvider
                        .getElementPrice(flightElement.price),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(MaterialPageRoute(
                        settings: RouteSettings(
                            name: PassengerInformationPage.routeName),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "20 Iyul · 1 yo'lovchi · Ekonom" — skrinshot uslubi.
  String _sheetSubtitle(RecommendationRequestBody params) {
    // params getter: "20 iyul, 1 pass., Ekonom" → middle-dot format
    return params.params
        .replaceAll('.,', ' ·')
        .replaceAll(', ', ' · ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
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
    if (outbound.length < 2) return;
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

/// Bottom sheet yuqori paneli — skrinshot: X · Tashkent → Moscow · meta.
class _TicketSheetTopBar extends StatelessWidget {
  final Radius topRadius;
  final String origin;
  final String destination;
  final String subtitle;
  final VoidCallback onClose;

  const _TicketSheetTopBar({
    required this.topRadius,
    required this.origin,
    required this.destination,
    required this.subtitle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0B1F4A);
    const navyEnd = Color(0xFF12306A);
    final title = origin.isNotEmpty && destination.isNotEmpty
        ? '$origin  →  $destination'
        : (origin.isNotEmpty ? origin : destination);
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [navy, navyEnd],
        ),
        borderRadius: BorderRadius.vertical(top: topRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: topInset > 0 ? topInset : 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: onClose,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Gilroy',
                          height: 1.15,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                          ),
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
    );
  }
}
