// Creator: Ravshanov Anzor
// Created: 24.09.2026

import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/tools/currency_provider.dart'
    show CurrencyProvider;
import 'package:mysafar_sdk/src/core/tools/formatters.dart' show ElementFormatter;
import 'package:mysafar_sdk/src/core/tools/sdk_sheets.dart'
    show showSdkModalBottomSheet;
import 'package:mysafar_sdk/src/core/widgets/fare_status_icon.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart'
    show Arr, FlightElement, FlightSegment;
import 'package:provider/provider.dart' show Provider;

/// "Parvoz tafsilotlari" varag'i — tarif, narx, shartlar va reys jadvali.
///
/// Faqat allaqachon olingan [element] ma'lumotidan quriladi, hech qanday
/// so'rov yuborilmaydi.
Future<void> showFlightDetailsSheet(
  BuildContext context,
  FlightElement element, {
  int passengerCount = 1,
}) {
  return showSdkModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FlightDetailsSheet(
      element: element,
      passengerCount: passengerCount,
    ),
  );
}

class _FlightDetailsSheet extends StatelessWidget {
  const _FlightDetailsSheet({
    required this.element,
    required this.passengerCount,
  });

  final FlightElement element;
  final int passengerCount;

  @override
  Widget build(BuildContext context) {
    final segments = element.segments ?? const <FlightSegment>[];
    final maxHeight = MediaQuery.of(context).size.height * 0.9;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'flight_details_title'.tr(),
                    style: context.textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _muted(context),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 22),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FareCard(element: element, passengerCount: passengerCount),
                  const SizedBox(height: 22),
                  for (var i = 0; i < segments.length; i++) ...[
                    if (i > 0) const SizedBox(height: 24),
                    _SegmentBlock(segment: segments[i]),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    'local_time_note'.tr(),
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      height: 1.35,
                      color: _muted(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  style: ProjectTheme.blueButtonStyle,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('close'.tr()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _muted(BuildContext context) => context.isDarkMode
    ? ProjectTheme.secondaryTextDark
    : ProjectTheme.secondaryTextLight;

/// Tarif kartasi: nom, narx va shartlar (chipta sahifasidagi kabi).
class _FareCard extends StatelessWidget {
  const _FareCard({required this.element, required this.passengerCount});

  final FlightElement element;
  final int passengerCount;

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final name = (element.fareFamilyMarketingName?.trim().isNotEmpty ?? false)
        ? element.fareFamilyMarketingName!.trim()
        : (element.fareFamilyType?.trim() ?? '');

    final rules = <(String, String, bool)>[
      (
        element.withCBaggage()
            ? Assets.ticketsLuggageIcon
            : Assets.ticketsLuggageNegativeIcon,
        element.withCBaggage()
            ? "luggage_size".tr(namedArgs: {"count": element.getCBaggage()})
            : "no_luggage".tr(),
        element.withCBaggage(),
      ),
      (
        (element.isBaggage ?? false)
            ? Assets.ticketsBaggagePositiveIcon
            : Assets.ticketsBaggageNegativeIcon,
        element.getBaggage(),
        element.isBaggage ?? false,
      ),
      (
        element.isExchangeable()
            ? Assets.ticketsReplaceGreenIcon
            : Assets.ticketsReplaceRedIcon,
        element.isExchangeable() ? "exchangeable".tr() : "unexchangeable".tr(),
        element.isExchangeable(),
      ),
      (
        (element.isRefund ?? false)
            ? Assets.ticketsReturnSuccessIcon
            : Assets.ticketsReturnIcon,
        (element.isRefund ?? false) ? "refundable".tr() : "unrefundable".tr(),
        element.isRefund ?? false,
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: context.color.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.isDarkMode
              ? Colors.white
              : context.color.outline.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _muted(context),
                  ),
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.isDarkMode
                      ? Colors.white
                      : ProjectTheme.brandColor,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 15,
                  color: context.isDarkMode
                      ? ProjectTheme.textColorLight
                      : Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            currencyProvider.getElementPrice(element.price),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.titleLarge?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "fare_for_passengers".tr(namedArgs: {"count": "$passengerCount"}),
            style: context.textTheme.bodySmall?.copyWith(
              fontSize: 12.5,
              color: _muted(context),
            ),
          ),
          const SizedBox(height: 18),
          for (final (icon, label, positive) in rules)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  FareStatusIcon(asset: icon, positive: positive),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontSize: 13.5,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: positive ? null : _muted(context),
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
}

/// Bitta reys: tashuvchi, reys raqami, davomiyligi va vaqt jadvali.
class _SegmentBlock extends StatelessWidget {
  const _SegmentBlock({required this.segment});

  final FlightSegment segment;

  @override
  Widget build(BuildContext context) {
    final muted = _muted(context);
    final flightNo = segment.flightNumber.trim();
    final aircraft = segment.aircraft.code.trim().isNotEmpty
        ? segment.aircraft.code.trim()
        : segment.aircraft.title.trim();
    final subtitle = [
      if (flightNo.isNotEmpty)
        'flight_number'.tr(namedArgs: {'number': flightNo}),
      if (aircraft.isNotEmpty) aircraft,
    ].join(' - ');
    final duration =
        ElementFormatter.formatDuration(segment.duration.flight.common);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          segment.carrier.title,
          style: context.textTheme.bodyLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: context.textTheme.bodyMedium
                ?.copyWith(fontSize: 15, color: muted),
          ),
        ],
        if (duration.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            duration,
            style: context.textTheme.bodyMedium
                ?.copyWith(fontSize: 15, color: muted),
          ),
        ],
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 96,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _time(context, segment.dep),
                    _time(context, segment.arr),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _TimelineBar(color: ProjectTheme.blueBg),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _place(context, segment.dep),
                    _place(context, segment.arr),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _time(BuildContext context, Arr point) {
    final muted = _muted(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          (point.time ?? '').trim(),
          style: context.textTheme.bodyLarge?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _dateLabel(point.date),
          style: context.textTheme.bodyMedium
              ?.copyWith(fontSize: 14, color: muted),
        ),
      ],
    );
  }

  Widget _place(BuildContext context, Arr point) {
    final muted = _muted(context);
    final code = point.airport?.code ?? point.city?.code ?? '';
    String city = point.city?.title ?? '';
    // SDK'da aeroportlar bazasi alohida isolate'da — sinxron qidiruv yo'q,
    // shahar nomi kelmasa IATA kod ko'rsatiladi.
    if (city.isEmpty) city = code;
    final airport = [
      if ((point.airport?.title ?? '').isNotEmpty) point.airport!.title,
      if (code.isNotEmpty) code,
    ].join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          city,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodyLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (airport.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            airport,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodyMedium
                ?.copyWith(fontSize: 14, height: 1.3, color: muted),
          ),
        ],
      ],
    );
  }

  /// "29 okt, Pay"
  static String _dateLabel(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final d = DateTime.tryParse(raw);
    if (d == null) return raw;
    const weekdays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final month = ElementFormatter.formatMonth(d.month).toLowerCase();
    final weekday = weekdays[d.weekday - 1].tr();
    return '${d.day} $month, $weekday';
  }
}

/// Ikki nuqtani bog'lovchi vertikal chiziq.
class _TimelineBar extends StatelessWidget {
  const _TimelineBar({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    Widget dot() => Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
        );

    return Column(
      children: [
        const SizedBox(height: 8),
        dot(),
        Expanded(child: Container(width: 2, color: color)),
        dot(),
        const SizedBox(height: 8),
      ],
    );
  }
}
