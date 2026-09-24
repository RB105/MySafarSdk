import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/tools/formatters.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart'
    show Arr, FlightElement, FlightSegment;
import 'package:mysafar_sdk/src/model/remote/profile/confirmed_ticket_models.dart'
    show Book, CbaggageClass, ConfirmedTicketArr, ConfirmedTicketSegment;
import 'package:mysafar_sdk/src/view/booking/widget/booking_form_fields.dart'
    show BookingFormStyle;
import 'package:mysafar_sdk/src/view/booking/widget/support_widget.dart'
    show BookingCard;

/// Bitta yo'nalish (borish / qaytish) — kartadagi qator uchun.
class BookingSummaryLeg {
  const BookingSummaryLeg({
    required this.from,
    required this.to,
    this.date = '',
    this.depTime = '',
    this.arrTime = '',
    this.transfers = 0,
  });

  final String from;
  final String to;

  /// Xom sana (`dd.MM.yyyy` / `dd-MM-yyyy`) — kartada hafta kuni bilan.
  final String date;
  final String depTime;
  final String arrTime;
  final int transfers;
}

/// Bagaj / qo'l yuki me'yori. [weight] 0 — og'irlik ko'rsatilmagan.
class BookingBaggageInfo {
  const BookingBaggageInfo({
    required this.included,
    this.piece = 1,
    this.weight = 0,
  });

  final bool included;
  final int piece;
  final int weight;
}

/// "Nima uchun to'lanmoqda" kartasining ko'rinish modeli (№23) — tanlangan
/// reysdan ([FlightElement], bron oqimida) yoki buyurtma modelidan ([Book],
/// "Buyurtmalarim"dan to'lovga kelinganda) quriladi. `null` qoidalar
/// (ma'lumot kelmagan) kartada ko'rsatilmaydi.
class BookingFlightSummary {
  const BookingFlightSummary({
    required this.legs,
    this.passengerCount = 0,
    this.baggage,
    this.cabinBaggage,
    this.isRefundable,
    this.isExchangeable,
  });

  final List<BookingSummaryLeg> legs;
  final int passengerCount;
  final BookingBaggageInfo? baggage;
  final BookingBaggageInfo? cabinBaggage;
  final bool? isRefundable;
  final bool? isExchangeable;

  bool get isEmpty => legs.isEmpty;

  /// Qidiruv natijasidagi reysdan.
  factory BookingFlightSummary.fromFlight(FlightElement flight,
      {required int passengerCount}) {
    final segs = flight.segments ?? const <FlightSegment>[];
    final legs = <int, List<FlightSegment>>{};
    for (final s in segs) {
      legs.putIfAbsent(s.direction, () => <FlightSegment>[]).add(s);
    }

    BookingBaggageInfo? baggage;
    BookingBaggageInfo? cabin;
    if (segs.isNotEmpty) {
      // FlightElement.getBaggage() bilan bir xil qoida.
      final anyZeroWeight = segs.any((s) => s.baggage.weight == 0);
      baggage = BookingBaggageInfo(
        included: flight.isBaggage != false,
        piece: _min(segs.map((s) => s.baggage.piece)),
        weight: anyZeroWeight ? 0 : _min(segs.map((s) => s.baggage.weight)),
      );
      // FlightElement.withCBaggage() / getCBaggage() bilan bir xil qoida.
      final positive =
          segs.map((s) => s.cbaggage.weight).where((w) => w > 0).toList();
      cabin = BookingBaggageInfo(
        included: flight.withCBaggage(),
        piece: _min(segs.map((s) => s.cbaggage.piece)),
        weight: positive.isEmpty ? 0 : _min(positive),
      );
    }

    return BookingFlightSummary(
      legs: [
        for (final leg in legs.values)
          if (leg.isNotEmpty)
            BookingSummaryLeg(
              from: _flightCity(leg.first.dep),
              to: _flightCity(leg.last.arr),
              date: leg.first.dep.date ?? '',
              depTime: leg.first.dep.time ?? '',
              arrTime: leg.last.arr.time ?? '',
              transfers: leg.length - 1,
            ),
      ],
      passengerCount: passengerCount,
      baggage: baggage,
      cabinBaggage: cabin,
      isRefundable: flight.isRefund ?? false,
      isExchangeable: flight.isExchangeable(),
    );
  }

  /// "Buyurtmalarim"dagi buyurtmadan (`response.data.book`).
  factory BookingFlightSummary.fromOrder(Book? book) {
    final segs = book?.flight?.segments ?? const <ConfirmedTicketSegment>[];
    final legs = <int, List<ConfirmedTicketSegment>>{};
    for (final s in segs) {
      legs
          .putIfAbsent(s.direction ?? 0, () => <ConfirmedTicketSegment>[])
          .add(s);
    }

    return BookingFlightSummary(
      legs: [
        for (final leg in legs.values)
          if (leg.isNotEmpty)
            BookingSummaryLeg(
              from: _orderCity(leg.first.dep),
              to: _orderCity(leg.last.arr),
              date: leg.first.dep?.date ?? '',
              depTime: leg.first.dep?.time ?? '',
              arrTime: leg.last.arr?.time ?? '',
              transfers: leg.length - 1,
            ),
      ],
      passengerCount: book?.passengers?.length ?? 0,
      baggage: _orderBaggage(segs.map((s) => s.baggage)),
      cabinBaggage: _orderBaggage(segs.map((s) => s.cbaggage)),
      isRefundable: _orderFlag(segs.map((s) => s.isRefund)) ??
          _orderFlag(segs.expand((s) =>
              (s.parametersForEachPassenger ?? []).map((p) => p.isRefundable))),
      isExchangeable: _orderFlag(segs.map((s) => s.isChange)) ??
          _orderFlag(segs.expand((s) => (s.parametersForEachPassenger ?? [])
              .map((p) => p.isExchangeable))),
    );
  }

  static int _min(Iterable<int> values) =>
      values.isEmpty ? 0 : values.reduce((a, b) => a < b ? a : b);

  static String _flightCity(Arr arr) {
    final city = (arr.city?.title ?? '').trim();
    if (city.isNotEmpty) return city;
    return arr.airport?.code ?? '';
  }

  static String _orderCity(ConfirmedTicketArr? arr) {
    final city = (arr?.city?.title ?? '').trim();
    if (city.isNotEmpty) return city;
    return (arr?.airport?.code ?? arr?.airport?.title ?? '').trim();
  }

  /// Barcha segmentlarda me'yor kelgan bo'lsa — umumiy (eng kichik) me'yor;
  /// ma'lumot yo'q bo'lsa `null` (kartada ko'rsatilmaydi).
  static BookingBaggageInfo? _orderBaggage(Iterable<CbaggageClass?> items) {
    final list = items.toList();
    if (list.isEmpty || list.any((b) => b == null)) return null;
    final all = list.cast<CbaggageClass>();
    final included =
        all.every((b) => (b.piece ?? 0) > 0 || (b.weight ?? 0) > 0);
    if (!included) return const BookingBaggageInfo(included: false);
    final weights = all.map((b) => b.weight ?? 0);
    return BookingBaggageInfo(
      included: true,
      piece: _min(all.map((b) => (b.piece ?? 0) > 0 ? b.piece! : 1)),
      weight: weights.any((w) => w <= 0) ? 0 : _min(weights),
    );
  }

  /// Hammasi `true` — `true`; biri `false` — `false`; ma'lumot yo'q — `null`.
  static bool? _orderFlag(Iterable<bool?> values) {
    final known = values.whereType<bool>().toList();
    if (known.isEmpty) return null;
    return known.every((v) => v);
  }

  /// Bagaj matni ("1x23 kg", "Bagajli", "Bagajsiz").
  static String baggageLabel(BookingBaggageInfo info) {
    if (!info.included) return "no_baggage".tr();
    if (info.weight <= 0) return "with_baggage".tr();
    return "${info.piece > 0 ? info.piece : 1}x${info.weight} kg";
  }

  /// Qo'l yuki matni ("Qo'l yuki: 1x10 kg", "Qo'l yukisiz").
  static String cabinLabel(BookingBaggageInfo info) {
    if (!info.included) return "no_luggage".tr();
    final piece = info.piece > 0 ? info.piece : 1;
    return "luggage_size".tr(namedArgs: {
      "count": info.weight > 0 ? "${piece}x${info.weight} kg" : "$piece",
    });
  }
}

/// Tasdiqlash va to'lov sahifalaridagi ixcham "nima uchun to'lanmoqda"
/// kartasi (№23): har bir yo'nalish (shahar → shahar, sana, vaqt,
/// almashishlar), yo'lovchilar soni, bagaj / qo'l yuki va qaytarish /
/// almashtirish shartlari. Ma'lumot [BookingFlightSummary] dan olinadi —
/// u reysdan ([FlightElement]) yoki buyurtma modelidan quriladi.
class BookingFlightSummaryCard extends StatelessWidget {
  /// Tanlangan reysdan (bron oqimi).
  const BookingFlightSummaryCard({
    super.key,
    required FlightElement this.flight,
    required this.passengerCount,
  }) : summary = null;

  /// Tayyor ko'rinish modelidan (masalan, buyurtmadan).
  const BookingFlightSummaryCard.fromSummary(
    BookingFlightSummary this.summary, {
    super.key,
  })  : flight = null,
        passengerCount = 0;

  final FlightElement? flight;
  final int passengerCount;
  final BookingFlightSummary? summary;

  @override
  Widget build(BuildContext context) {
    final data = summary ??
        BookingFlightSummary.fromFlight(flight!,
            passengerCount: passengerCount);
    if (data.isEmpty) return const SizedBox.shrink();
    final legs = data.legs;

    final baggage = data.baggage;
    final cabin = data.cabinBaggage;
    final isRefund = data.isRefundable;
    final isExchangeable = data.isExchangeable;

    final rules = <(String, String)>[
      if (baggage != null)
        (
          baggage.included
              ? Assets.ticketsBaggagePositiveIcon
              : Assets.ticketsBaggageNegativeIcon,
          BookingFlightSummary.baggageLabel(baggage),
        ),
      if (cabin != null)
        (
          cabin.included
              ? Assets.ticketsLuggageIcon
              : Assets.ticketsLuggageNegativeIcon,
          BookingFlightSummary.cabinLabel(cabin),
        ),
      if (isRefund != null)
        (
          isRefund ? Assets.ticketsReturnSuccessIcon : Assets.ticketsReturnIcon,
          isRefund ? "refundable".tr() : "unrefundable".tr(),
        ),
      if (isExchangeable != null)
        (
          isExchangeable
              ? Assets.ticketsReplaceGreenIcon
              : Assets.ticketsReplaceRedIcon,
          isExchangeable ? "exchangeable".tr() : "unexchangeable".tr(),
        ),
    ];

    final Color muted = BookingFormStyle.label(context);
    final Color divider = context.color.outline.withValues(alpha: 0.6);
    final int passengerCountShown = data.passengerCount;

    return BookingCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "trip_summary_title".tr(),
                    style: context.textTheme.bodyLarge
                        ?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                if (passengerCountShown > 0)
                  Text(
                    "${"passengers".tr()}: $passengerCountShown",
                    style: context.textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: muted,
                    ),
                  ),
              ],
            ),
          ),
          for (int i = 0; i < legs.length; i++) ...[
            if (i > 0)
              Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                  color: divider),
            _LegRow(leg: legs[i]),
          ],
          if (rules.isNotEmpty) ...[
            Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Wrap(
                spacing: 16,
                runSpacing: 10,
                children: [
                  for (final (icon, label) in rules)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(icon, width: 18, height: 18),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            label,
                            style: context.textTheme.bodySmall?.copyWith(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// Bitta yo'nalish: "Toshkent → Istanbul", ostida sana, uchish–qo'nish
/// vaqti va almashishlar soni.
class _LegRow extends StatelessWidget {
  const _LegRow({required this.leg});

  final BookingSummaryLeg leg;

  static String _date(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return '';
    try {
      return ElementFormatter.formatWithWeekDay(value);
    } catch (_) {
      return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final transfers = leg.transfers;
    final bool isDark = context.isDarkMode;
    final Color accent =
        isDark ? ProjectTheme.accentLight : ProjectTheme.brandColor;

    final details = [
      _date(leg.date),
      if (leg.depTime.isNotEmpty || leg.arrTime.isNotEmpty)
        "${ElementFormatter.formatTime(leg.depTime)} – "
            "${ElementFormatter.formatTime(leg.arrTime)}",
      transfers == 0
          ? "ticket_chip_direct".tr()
          : "transfer_count".tr(namedArgs: {"count": "$transfers"}),
    ].where((s) => s.trim().isNotEmpty).join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: SvgPicture.asset(
              Assets.ticketsAirplaneIcon,
              width: 18,
              height: 18,
              colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${leg.from} → ${leg.to}",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  style: context.textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                    color: BookingFormStyle.label(context),
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
