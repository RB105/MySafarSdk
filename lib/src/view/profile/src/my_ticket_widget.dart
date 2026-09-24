// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:math' as math;

import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/tools/lang_helper.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/tools/formatters.dart';
import 'package:mysafar_sdk/src/core/tools/project_assets.dart';
import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart';
import 'package:mysafar_sdk/src/core/widgets/toast_widget.dart'
    show AppMessageType;
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/model/remote/booking/booking_create_model.dart';
import 'package:mysafar_sdk/src/model/remote/profile/confirmed_ticket_models.dart';
import 'package:mysafar_sdk/src/model/remote/profile/order_status_classifier.dart';
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart'
    show AnalyticsService;
import 'package:mysafar_sdk/src/service/pdf/ticket_pdf_actions.dart';
import 'package:mysafar_sdk/src/view/booking/booking_confirm_page.dart';
import 'package:mysafar_sdk/src/view/booking/widget/payment_countdown_card.dart';
import 'package:mysafar_sdk/src/view/profile/src/order_rebook.dart';

import '../../../model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightPrice, FluffyUzs;

/// Bitta buyurtma kartasi — qidiruv natijalari kartasi bilan bir xil uslub:
/// tepada holat va buyurtma raqami, har bir parvoz uchun vaqt chizig'i,
/// ostida tarif/yo'lovchilar/buyurtmachi, umumiy narx va holatga mos amal.

part 'my_ticket_info_line.dart';

class MyTicketWidget extends StatefulWidget {
  final ConfirmedTicketsModel ticketsModel;

  const MyTicketWidget({super.key, required this.ticketsModel});

  @override
  State<MyTicketWidget> createState() => _MyTicketWidgetState();
}

class _MyTicketWidgetState extends State<MyTicketWidget> {
  bool _isLoading = false;

  /// "Ulashish" (PDF yuklanib share sheet ochilguncha).
  bool _isSharing = false;

  /// Ko'p segmentli (multi-marshrut / vtrip) biletda karta juda uzayib
  /// ketmasligi uchun boshida FAQAT birinchi parvoz ko'rsatiladi. Foydalanuvchi
  /// tugmani bosganda qolgan segmentlar ochiladi, qayta bosilganda yig'iladi.
  bool _segmentsExpanded = false;

  /// To'lov uchun qolgan soniyalar — har soniyada faqat taymer kartasi
  /// qayta chiziladi, butun buyurtma kartasi emas.
  final ValueNotifier<int> _remaining = ValueNotifier<int>(0);
  Timer? _countdown;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void didUpdateWidget(covariant MyTicketWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ro'yxat yangilangach element boshqa buyurtmaga tegishli bo'lishi mumkin.
    if (oldWidget.ticketsModel.createdAt != widget.ticketsModel.createdAt ||
        oldWidget.ticketsModel.orderStatus != widget.ticketsModel.orderStatus) {
      _startCountdown();
    }
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _remaining.dispose();
    super.dispose();
  }

  /// Qolgan vaqt har safar `createdAt` dan hisoblanadi (№88) — ilova fonda
  /// bo'lganda taymer orqada qolmaydi.
  int _computeRemaining() => ElementFormatter()
      .bookingExpireRemainingSeconds(widget.ticketsModel.createdAt ?? '');

  void _startCountdown() {
    _countdown?.cancel();
    _countdown = null;
    _remaining.value = _computeRemaining();
    if (!OrderStatusClassifier.isAwaitingPayment(
            widget.ticketsModel.orderStatus) ||
        _remaining.value <= 0) {
      return;
    }
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = _computeRemaining();
      _remaining.value = left;
      if (left <= 0) {
        timer.cancel();
        _countdown = null;
        // Vaqt tugadi — "To'lovga o'tish" o'rniga "Qayta bron qilish".
        if (mounted) setState(() {});
      }
    });
  }

  /// Chipta PDF'ini (har safar yangisini) yuklab ochadi. Ochilmasa (PDF
  /// ko'ruvchi yo'q) — brauzerda ochish taklif qilinadi (№30).
  Future<void> downloadAndOpenFile(String url, String fileName) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final result = await TicketPdfActions.downloadAndOpen(
        context,
        url: url,
        fileName: fileName,
        forceDownload: true,
      );
      if (result != null && !result.isSuccess && !result.noViewer) {
        AnalyticsService().trackApiError(
          endpoint: url,
          method: 'GET',
          errorType: 'ticket_download_error',
          error: result.errorMessage,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Birinchi segmentdagi birinchi yo'lovchi uchun reys klassi kodi. Bo'sh
  /// ro'yxat yoki null bo'lsa "" qaytaradi (RangeError o'rniga) — getClassName
  /// "" uchun default klass nomini beradi.
  String _flightClassCode(ConfirmTicketResponseData data) {
    final segments = data.book?.flight?.segments;
    if (segments == null || segments.isEmpty) return "";
    final params = segments.first.parametersForEachPassenger;
    if (params == null || params.isEmpty) return "";
    return params.first.flightClass?.code ?? "";
  }

  /// Birinchi yo'lovchining to'liq ismi (bo'lmasa "").
  String _firstPassengerName(ConfirmTicketResponseData data) {
    final passengers = data.book?.passengers;
    if (passengers == null || passengers.isEmpty) return "";
    final name = passengers.first.name;
    return "${name?.first ?? ''} ${name?.last ?? ''}".trim();
  }

  /// Yuklab olinadigan bilet kvitansiyasi URL'i (bo'lmasa "").
  String _ticketReceiptUrl(ConfirmTicketResponseData data) {
    final tickets = data.book?.tickets;
    if (tickets == null || tickets.isEmpty) return "";
    return tickets.first.documents?.ticketReceipt ?? "";
  }

  /// Segment jo'nash sanasi — "12 iyul, jum" ko'rinishida. Format kutilmagan
  /// bo'lsa xom satr, bo'sh bo'lsa "" qaytadi (karta yiqilmaydi).
  String _segmentDate(ConfirmedTicketSegment segment) {
    final raw = segment.dep?.date ?? '';
    if (raw.isEmpty) return '';
    try {
      return ElementFormatter.formatWithWeekDay(raw);
    } catch (_) {
      return raw;
    }
  }

  bool get _isDark => context.isDarkMode;

  Color get _textColor =>
      _isDark ? ProjectTheme.textColorDark : ProjectTheme.textColorLight;

  Color get _muted =>
      _isDark ? ProjectTheme.secondaryTextDark : const Color(0xFF7A849E);

  Color get _line =>
      _isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE8ECF3);

  Color get _tonal =>
      _isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F4F9);

  /// Tarjimalardagi oxirgi ":" belgisini olib tashlaydi ("Tarif:" → "Tarif").
  static String _plain(String text) =>
      text.trim().replaceAll(RegExp(r'[:：]\s*$'), '');

  @override
  Widget build(BuildContext context) {
    ConfirmTicketResponseData responseData =
        widget.ticketsModel.response!.data!;
    // callback_status bo'sh bo'lsa buyurtmaning o'z holati; yozuv farqlari
    // ("ticketed", "canceled") kanonik kalitga keltirilgan.
    final String callbackStatus = widget.ticketsModel.orderStatus;
    final displayStatus = _displayStatus(callbackStatus);
    final segments = responseData.book?.flight?.segments ?? [];
    // Yig'ilgan holatda faqat birinchi parvoz ko'rinadi.
    final visibleSegments = (segments.length > 1 && !_segmentsExpanded)
        ? segments.sublist(0, 1)
        : segments;
    final Widget? action = _actionFor(callbackStatus, responseData);
    final price =
        "${ElementFormatter.formatNumberWithSpaces(responseData.book?.order?.price?.uzs?.amount ?? 0)} UZS";

    return Container(
      decoration: BoxDecoration(
        color: context.color.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0F202A44),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Holat va buyurtma raqami ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            // Chip qolgan butun kenglikni oladi (avval Spacer bilan 50/50
            // bo'linib, uzun holat nomlari qirqilib qolardi).
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: displayStatus.isEmpty
                      ? const SizedBox.shrink()
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: _statusChip(displayStatus),
                        ),
                ),
                const SizedBox(width: 8),
                _idChip(),
              ],
            ),
          ),
          // ── Parvozlar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < visibleSegments.length; i++) ...[
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, thickness: 1, color: _line),
                      ),
                    _segmentBlock(visibleSegments[i]),
                  ],
                ],
              ),
            ),
          ),
          if (segments.length > 1)
            _segmentsToggle(segments.length - 1)
          else
            const SizedBox(height: 14),
          Divider(height: 1, thickness: 1, color: _line),
          // ── Tafsilotlar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InfoLine(
                  label: _plain("tarif".tr()),
                  value: ElementFormatter.getClassName(
                      _flightClassCode(responseData),
                      dataLang(context.locale.languageCode)),
                ),
                _InfoLine(
                  label: _plain("passengerss".tr()),
                  value: ElementFormatter.getPassengerAgeSummary(
                      responseData.book!.passengers),
                ),
                _InfoLine(
                  label: _plain("order_confirmed".tr()),
                  value: _firstPassengerName(responseData),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        _plain("total_price".tr()),
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: _muted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          price,
                          maxLines: 1,
                          style: context.textTheme.bodyLarge?.copyWith(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: _textColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (action != null) ...[
                  const SizedBox(height: 14),
                  action,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  //  HOLAT VA RAQAM CHIPLARI
  // ──────────────────────────────────────────────────────────────────

  /// Booked bo'lsa-yu to'lov muddati o'tgan bo'lsa, chipda
  /// `payment_time_expired` ko'rsatiladi (tugma allaqachon yashiriladi).
  String _displayStatus(String status) {
    if (status == 'Booked' &&
        !ElementFormatter.expireStatus(widget.ticketsModel.createdAt ?? "")) {
      return 'payment_time_expired';
    }
    return status;
  }

  /// Holat rangi — barcha ma'lum statuslar qamrab olingan.
  Color _statusColor(String status) {
    switch (status) {
      case 'Booked':
      case 'AwaitPayment':
        return ProjectTheme.warning;
      case 'Ticketed':
      case 'Paid':
      case 'PartiallyTicketed':
      case 'TicketedWaitingPNR':
        return ProjectTheme.success;
      case 'Cancelled':
      case 'payment_time_expired':
        return ProjectTheme.error;
      case 'Refunded':
      case 'RefundInProcess':
      case 'RefundAuthorized':
      case 'PartiallyRefunded':
        return ProjectTheme.purpleLight;
      default:
        return ProjectTheme.brandColor;
    }
  }

  /// Holat nomi: tarjima; kalit bo'lmasa serverning o'z nomi, u ham
  /// bo'lmasa "RefundInProcess" → "Refund in process" (xom kalit emas).
  String _statusLabel(String status) {
    final serverTitle = widget.ticketsModel.orderStatusTitle;
    final humanized = status
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (_) => ' ')
        .trim();
    final fallback = serverTitle.isNotEmpty
        ? serverTitle
        : (humanized.isEmpty
            ? status
            : humanized[0].toUpperCase() +
                humanized.substring(1).toLowerCase());
    return status.tr(defaultValue: fallback);
  }

  /// Yumshoq fonli holat chipi: rangli nuqta + matn (kontursiz). Uzun
  /// nomlar ("Chipta berildi. Aviakompaniyadan PNR kutilyapti") qirqilmay
  /// bir necha qatorga o'tadi.
  Widget _statusChip(String status) {
    final Color c = _statusColor(status);
    final Color textColor = _isDark
        ? Color.lerp(c, Colors.white, 0.3)!
        : Color.lerp(c, Colors.black, 0.3)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: _isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4.5),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _statusLabel(status),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Buyurtma raqami — bosilganda nusxalanadi.
  Widget _idChip() {
    return Material(
      color: _tonal,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          Clipboard.setData(
            ClipboardData(text: "${widget.ticketsModel.billingId}"),
          ).then(
            (value) {
              ProjectDialogs.showCustomToast(
                  // ignore: use_build_context_synchronously
                  context,
                  "id_copied".tr());
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "№ ${widget.ticketsModel.billingId}",
                style: context.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: _textColor,
                ),
              ),
              const SizedBox(width: 6),
              SvgPicture.asset(
                Assets.iconsOrderCopyIcon,
                width: 14,
                height: 14,
                colorFilter: ColorFilter.mode(_muted, BlendMode.srcIn),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  //  SEGMENT (MARSHRUT) BLOKI
  // ──────────────────────────────────────────────────────────────────

  /// Aviakompaniya + sana, so'ng vaqt chizig'i (vaqt, kod, shahar).
  Widget _segmentBlock(ConfirmedTicketSegment segment) {
    final date = _segmentDate(segment);
    final metaParts = <String>[
      if ((segment.carrier?.title ?? '').isNotEmpty) segment.carrier!.title!,
      if ((segment.flightNumber ?? '').isNotEmpty) segment.flightNumber!,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _carrierLogo(segment),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                metaParts.join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textColor,
                ),
              ),
            ),
            if (date.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                date,
                style: context.textTheme.bodySmall?.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: _muted,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _endpoint(
              time: segment.dep?.time ?? "",
              code: segment.dep?.airport?.code ?? "",
              city: segment.dep?.city?.title ?? "",
              alignEnd: false,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _routePath(
                ElementFormatter.formatDuration(
                    segment.duration?.flight?.common ?? 0),
              ),
            ),
            const SizedBox(width: 10),
            _endpoint(
              time: segment.arr?.time ?? "",
              code: segment.arr?.airport?.code ?? "",
              city: segment.arr?.city?.title ?? "",
              alignEnd: true,
            ),
          ],
        ),
      ],
    );
  }

  /// "Yana N ta ko'rsatish" / "Yashirish" — butun qator bosiladi.
  Widget _segmentsToggle(int hiddenCount) {
    final Color accent = _isDark ? Colors.white : ProjectTheme.brandColor;
    return InkWell(
      onTap: () => setState(() => _segmentsExpanded = !_segmentsExpanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                _segmentsExpanded
                    ? "ticket_show_less".tr()
                    : "ticket_show_more_count"
                        .tr(namedArgs: {"count": "$hiddenCount"}),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: _segmentsExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: SvgPicture.asset(
                Assets.iconsFormChevronDownIcon,
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Marshrut cheti: yirik vaqt, aeroport kodi va shahar.
  Widget _endpoint({
    required String time,
    required String code,
    required String city,
    required bool alignEnd,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 60, maxWidth: 104),
      child: Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              ElementFormatter.formatTime(time),
              style: context.textTheme.bodyLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.1,
                color: _textColor,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            code,
            style: context.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _textColor,
            ),
          ),
          if (city.isNotEmpty)
            Text(
              city,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: alignEnd ? TextAlign.end : TextAlign.start,
              style: context.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _muted,
              ),
            ),
        ],
      ),
    );
  }

  /// Davomiylik, ingichka chiziq va o'rtada samolyot.
  Widget _routePath(String duration) {
    final Color dot = _isDark ? Colors.white54 : const Color(0xFFB7C0D3);
    Widget endDot() => Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: dot, width: 1.5),
          ),
        );
    Widget line() => Expanded(child: Container(height: 1.5, color: _line));

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            duration,
            maxLines: 1,
            style: context.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _muted,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 16,
            child: Row(
              children: [
                endDot(),
                line(),
                Transform.rotate(
                  angle: math.pi / 4,
                  child: SvgPicture.asset(
                    Assets.iconsPlaceAirportIcon,
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(
                        ProjectTheme.brandColor, BlendMode.srcIn),
                  ),
                ),
                line(),
                endDot(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Aviakompaniya logosi — yuklanmasa parvoz belgisi ko'rsatiladi.
  Widget _carrierLogo(ConfirmedTicketSegment segment) {
    return Container(
      width: 28,
      height: 28,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: _line),
      ),
      child: ClipOval(
        child: Image.network(
          ProjectAssets.getSegmentProviderImg(
              segment.provider?.supplier?.code ?? ""),
          cacheWidth: 72,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.flight_rounded,
            size: 14,
            color: ProjectTheme.brandColor,
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  //  HOLATGA MOS AMAL TUGMASI
  // ──────────────────────────────────────────────────────────────────

  /// Holatga qarab tugma: Booked (muddati o'tmagan) — to'lovga o'tish,
  /// muddati o'tgan va parvoz oldinda — qayta bron qilish,
  /// Ticketed/Paid — chiptani yuklab olish, qolganlarida tugma yo'q.
  /// Holatga mos amal (№59): "Yuklab olish" faqat chipta haqiqatan bor
  /// bo'lsa (Ticketed / PartiallyTicketed / TicketedWaitingPNR + havola);
  /// to'langan, lekin chipta hali yo'q — "chipta rasmiylashtirilmoqda".
  Widget? _actionFor(String status, ConfirmTicketResponseData responseData) {
    // To'lov vaqti o'tgan, lekin parvoz hali oldinda — o'sha yo'nalish va
    // sana bo'yicha qayta qidiruv, yo'lovchilar oldindan to'ldiriladi.
    if (OrderRebook.canRebook(widget.ticketsModel)) {
      return _buildRebookAction();
    }
    if (OrderStatusClassifier.isAwaitingPayment(status)) {
      final canPay =
          ElementFormatter.expireStatus(widget.ticketsModel.createdAt ?? "");
      if (!canPay) return null;
      return _buildPayButton(responseData);
    }
    final url = _ticketReceiptUrl(responseData);
    if (OrderStatusClassifier.canDownloadTicket(status, url)) {
      return _buildDownloadButton(responseData);
    }
    if (OrderStatusClassifier.isTicketPending(status, url)) {
      return _buildTicketPendingNote();
    }
    return null;
  }

  /// To'langan, chipta hali chiqmagan — tugma o'rniga izoh.
  Widget _buildTicketPendingNote() {
    final Color c = ProjectTheme.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.withValues(alpha: _isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_top_rounded, size: 20, color: c),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'ticket_being_issued'.tr(),
              style: context.textTheme.bodyMedium?.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: _textColor,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPayment(ConfirmTicketResponseData responseData) {
    final price = FlightPrice(
        uzs: FluffyUzs(
          amount: ElementFormatter.formatNumberWithSpaces(
              responseData.book!.order!.price!.uzs!.amount ?? 0),
        ),
        rub: null,
        usd: null);
    Navigator.push(
        context,
        MaterialPageRoute(
          settings: RouteSettings(name: BookingConfirmPage.routeName),
          builder: (context) => BookingConfirmPage(
              passengerNumber: responseData.book?.passengers?.length ?? 0,
              bookingCreateModel: BookingCreateModel(
                  billingId:
                      responseData.book?.order?.billingNumber.toString() ?? "",
                  trId: widget.ticketsModel.transaction?.trId ?? "",
                  createdAt: widget.ticketsModel.createdAt),
              price: price,
              // Reys kartasi buyurtma ma'lumotidan (yo'nalish, sana, bagaj,
              // qaytarish shartlari) — №23.
              summary: BookingConfirmPage.orderSummary(responseData.book)),
        ));
  }

  /// To'lovga o'tish — to'lov sahifasidagi taymer kartasi
  /// ([PaymentCountdownCard]) va asosiy tugma ([NextButtonWidget] uslubi).
  Widget _buildPayButton(ConfirmTicketResponseData responseData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaymentCountdownCard(remaining: _remaining),
        const SizedBox(height: 10),
        _primaryButton(
          title: "proceed_to_payment".tr(),
          onTap: () {
            // Taymer orqada qolgan bo'lishi mumkin (№88) — bosilganda qayta
            // tekshiramiz: muddat o'tgan bo'lsa to'lov sahifasi ochilmaydi.
            if (!ElementFormatter.expireStatus(
                widget.ticketsModel.createdAt ?? "")) {
              setState(() {});
              ProjectDialogs.showCustomToast(
                  context, 'payment_time_expired'.tr(),
                  type: AppMessageType.warning);
              return;
            }
            _openPayment(responseData);
          },
        ),
      ],
    );
  }

  /// To'lov vaqti tugagan buyurtma — izoh va "Qayta bron qilish".
  Widget _buildRebookAction() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(Icons.info_outline_rounded, size: 18, color: _muted),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                "order_rebook_hint".tr(),
                style: context.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _muted,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _primaryButton(
          title: "order_rebook".tr(),
          onTap: () {
            AnalyticsService().trackButtonTap('order_rebook');
            OrderRebook.open(context, widget.ticketsModel);
          },
        ),
      ],
    );
  }

  /// Asosiy brend tugma — [NextButtonWidget] uslubi: markazda matn va
  /// o'ng strelka, katta shriftda balandligi o'sadi (№32).
  Widget _primaryButton({required String title, required VoidCallback onTap}) {
    final brand = ProjectTheme.brandColor;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: brand.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: brand,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: "packages/mysafar_sdk/Gilroy",
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SvgPicture.asset(
                      Assets.iconsBookingArrowRightIcon,
                      width: 20,
                      height: 20,
                      colorFilter:
                          const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Elektron chiptani yuklab olish + tizim "Ulashish" oynasi (№30).
  Widget _buildDownloadButton(ConfirmTicketResponseData responseData) {
    final url = _ticketReceiptUrl(responseData);
    if (url.isEmpty) return _buildDownloadOnlyButton(responseData);
    return Row(
      children: [
        Expanded(child: _buildDownloadOnlyButton(responseData)),
        const SizedBox(width: 8),
        _buildShareButton(url),
      ],
    );
  }

  /// PDF'ni yuklab tizim "Ulashish" oynasini ochadi (Telegram, pochta,
  /// "Fayllar"ga saqlash). iPad'da oyna shu tugma ustidan chiqadi.
  Widget _buildShareButton(String url) {
    final brand = ProjectTheme.brandColor;
    final Color fg = _isDark ? Colors.white : brand;
    return Material(
      color: _isDark
          ? Colors.white.withValues(alpha: 0.10)
          : brand.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Builder(
        builder: (buttonContext) => InkWell(
          onTap: _isSharing
              ? null
              : () async {
                  HapticFeedback.lightImpact();
                  AnalyticsService().trackButtonTap('ticket_share');
                  setState(() => _isSharing = true);
                  await TicketPdfActions.share(
                    context,
                    url: url,
                    fileName: widget.ticketsModel.billingId ?? '',
                    originContext: buttonContext,
                  );
                  if (mounted) setState(() => _isSharing = false);
                },
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                child: _isSharing
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: fg,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.ios_share_rounded, size: 20, color: fg),
                          const SizedBox(width: 6),
                          Text(
                            'share_ticket'.tr(),
                            maxLines: 1,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: fg,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Elektron chiptani yuklab olish — yumshoq (tonal) brend tugma.
  Widget _buildDownloadOnlyButton(ConfirmTicketResponseData responseData) {
    final brand = ProjectTheme.brandColor;
    final Color fg = _isDark ? Colors.white : brand;
    return Material(
      color: _isDark
          ? Colors.white.withValues(alpha: 0.10)
          : brand.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (!_isLoading) {
            HapticFeedback.lightImpact();
            downloadAndOpenFile(_ticketReceiptUrl(responseData),
                widget.ticketsModel.billingId ?? "");
          }
        },
        child: SizedBox(
          height: 52,
          child: Center(
            child: _isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: fg,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        Assets.iconsOrderDownloadIcon,
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          "download_e_ticket".tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
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
