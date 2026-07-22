// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'dart:math' as math;

import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mysafar_sdk/src/core/config/dio_client.dart' show DioClient;
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/tools/lang_helper.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/tools/formatters.dart';
import 'package:mysafar_sdk/src/core/tools/project_assets.dart';
import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart';
import 'package:mysafar_sdk/src/model/remote/booking/booking_create_model.dart';
import 'package:mysafar_sdk/src/model/remote/profile/confirmed_ticket_models.dart';
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart'
    show AnalyticsService;
import 'package:mysafar_sdk/src/view/booking/booking_confirm_page.dart';
import 'package:mysafar_sdk/src/view/booking/widget/dashedline.dart';
import 'package:mysafar_sdk/src/view/profile/src/expire_time_widget.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightPrice, FluffyUzs;

/// Bitta buyurtma kartasi — "posadka taloni" (boarding pass) uslubida:
/// yuqorida parvoz ma'lumoti (yirik vaqtlar + marshrut chizig'i), o'rtada
/// ikki chetidan "kesilgan" perforatsiya, pastda esa stub — tarif,
/// yo'lovchilar, narx va holatga mos amal tugmasi.

part 'my_ticket_info_line.dart';

class MyTicketWidget extends StatefulWidget {
  final ConfirmedTicketsModel ticketsModel;

  const MyTicketWidget({super.key, required this.ticketsModel});

  @override
  State<MyTicketWidget> createState() => _MyTicketWidgetState();
}

class _MyTicketWidgetState extends State<MyTicketWidget> {
  bool _isLoading = false;

  /// Perforatsiya "kesik"larining radiusi.
  static const double _notchRadius = 10;

  Future<void> downloadAndOpenFile(String url, String fileName) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final Directory appDir = await getApplicationSupportDirectory();
      final Directory targetDir = Directory(p.join(appDir.path, 'mysafar'));

      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final String filePath = p.join(targetDir.path, "$fileName.pdf");

      await DioClient.downloadFile(url, filePath);

      await OpenFilex.open(filePath);
    } catch (e) {

      AnalyticsService().trackApiError(
        endpoint: url,
        method: 'GET',
        errorType: 'ticket_download_error',
        error: e,
      );
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Faylni ochishda xatolik yuz berdi")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  /// Qorong'u temada brand ko'k kartada "cho'kib" ketadi — ochroq aksent
  /// ishlatiladi.
  Color get _accent => context.themeProvider.isDark
      ? ProjectTheme.accentLight
      : ProjectTheme.brandColor;

  @override
  Widget build(BuildContext context) {
    ConfirmTicketResponseData responseData =
        widget.ticketsModel.response!.data!;
    String callbackStatus = widget.ticketsModel.callbackStatus ?? "";
    final isDark = context.themeProvider.isDark;
    final segments = responseData.book?.flight?.segments ?? [];
    final Widget? action = _actionFor(callbackStatus, responseData);

    return Container(
      decoration: BoxDecoration(
        color: context.color.primaryContainer,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(80)
                : const Color(0x80C6C7C9).withAlpha(110),
            offset: const Offset(0, 4),
            blurRadius: 14,
          ),
        ],
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        border: Border.all(
          color:
              isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(8),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Parvoz qismi ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: _statusChip(callbackStatus)),
                    const SizedBox(width: 8),
                    _idChip(),
                  ],
                ),
                const SizedBox(height: 16),
                for (int i = 0; i < segments.length; i++) ...[
                  if (i > 0) const SizedBox(height: 16),
                  _segmentBlock(segments[i]),
                ],
              ],
            ),
          ),
          // ── Perforatsiya (yirtish chizig'i) ──
          _perforation(context),
          // ── Stub qismi ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoLine(
                  icon: Icons.airline_seat_recline_normal_rounded,
                  label: "tarif".tr(),
                  value: ElementFormatter.getClassName(
                      _flightClassCode(responseData),
                      dataLang(context.locale.languageCode)),
                  accent: _accent,
                ),
                const SizedBox(height: 10),
                _InfoLine(
                  icon: Icons.people_alt_rounded,
                  label: "passengerss".tr(),
                  value: ElementFormatter.getPassengerAgeSummary(
                      responseData.book!.passengers),
                  accent: _accent,
                ),
                const SizedBox(height: 10),
                _InfoLine(
                  icon: Icons.verified_user_rounded,
                  label: "order_confirmed".tr(),
                  value: _firstPassengerName(responseData),
                  accent: _accent,
                  valueColor: _accent,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "total_price".tr(),
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _secondaryColor(context),
                        ),
                      ),
                    ),
                    Text(
                      "${ElementFormatter.formatNumberWithSpaces(responseData.book?.order?.price?.uzs?.amount ?? 0)} UZS",
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _accent,
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

  Color _secondaryColor(BuildContext context) => context.themeProvider.isDark
      ? ProjectTheme.secondaryTextDark
      : ProjectTheme.secondaryTextLight;

  // ──────────────────────────────────────────────────────────────────
  //  HEADER CHIPLARI
  // ──────────────────────────────────────────────────────────────────

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

  /// Rangli, lekin bosiq (tint) holat chipi. Matn rangi o'qilishi uchun
  /// yorug' temada quyuqlashtiriladi, qorong'usida ochlashtiriladi.
  Widget _statusChip(String status) {
    final isDark = context.themeProvider.isDark;
    final Color c = _statusColor(status);
    final Color textColor = isDark
        ? Color.lerp(c, Colors.white, 0.25)!
        : Color.lerp(c, Colors.black, 0.30)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withAlpha(isDark ? 46 : 26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withAlpha(110), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              status.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
                color: textColor,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Buyurtma raqami — bosilganda nusxalanadi.
  Widget _idChip() {
    final isDark = context.themeProvider.isDark;
    return GestureDetector(
      onTap: () {
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _accent.withAlpha(isDark ? 40 : 16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _accent.withAlpha(100), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "ID: ${widget.ticketsModel.billingId}",
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
                color: _accent,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.copy_rounded, size: 12, color: _accent),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  //  SEGMENT (MARSHRUT) BLOKI
  // ──────────────────────────────────────────────────────────────────

  /// Bitta segment: aviakompaniya qatori + posadka taloni uslubidagi
  /// marshrut qatori (yirik vaqtlar, punktir parvoz chizig'i, davomiylik).
  Widget _segmentBlock(ConfirmedTicketSegment segment) {
    final secondary = _secondaryColor(context);
    final date = _segmentDate(segment);
    final metaParts = <String>[
      if ((segment.carrier?.title ?? '').isNotEmpty) segment.carrier!.title!,
      if ((segment.flightNumber ?? '').isNotEmpty) segment.flightNumber!,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _carrierLogo(segment),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                metaParts.join(' • '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: secondary,
                ),
              ),
            ),
            if (date.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                date,
                style: context.textTheme.bodySmall?.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: secondary,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _endpoint(
              time: segment.dep?.time ?? "",
              code: segment.dep?.airport?.code ?? "",
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
              alignEnd: true,
            ),
          ],
        ),
      ],
    );
  }

  /// Marshrut cheti: yirik vaqt + aeroport kodi.
  Widget _endpoint({
    required String time,
    required String code,
    required bool alignEnd,
  }) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          ElementFormatter.formatTime(time),
          style: context.textTheme.bodyLarge?.copyWith(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          code,
          style: context.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: _secondaryColor(context),
          ),
        ),
      ],
    );
  }

  /// Punktir "parvoz chizig'i": ○ ─ ─ ✈ ─ ─ ○ va ostida davomiylik.
  Widget _routePath(String duration) {
    final isDark = context.themeProvider.isDark;
    final dashColor =
        isDark ? Colors.white.withAlpha(45) : const Color(0xffCBD3DD);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _pathDot(),
            const SizedBox(width: 4),
            Expanded(child: DashedLine(color: dashColor)),
            const SizedBox(width: 6),
            Transform.rotate(
              angle: math.pi / 2,
              child: Icon(Icons.flight_rounded, size: 16, color: _accent),
            ),
            const SizedBox(width: 6),
            Expanded(child: DashedLine(color: dashColor)),
            const SizedBox(width: 4),
            _pathDot(),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          duration,
          style: context.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _secondaryColor(context),
          ),
        ),
      ],
    );
  }

  Widget _pathDot() {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _accent, width: 1.5),
      ),
    );
  }

  /// Aviakompaniya logosi — yuklanmasa parvoz belgisi ko'rsatiladi.
  Widget _carrierLogo(ConfirmedTicketSegment segment) {
    final isDark = context.themeProvider.isDark;
    return Container(
      width: 26,
      height: 26,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(15) : _accent.withAlpha(16),
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(40) : _accent.withAlpha(50),
          width: 1,
        ),
      ),
      child: ClipOval(
        child: Image.network(
          ProjectAssets.getSegmentProviderImg(
              segment.provider?.supplier?.code ?? ""),
          cacheWidth: 72,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.flight_takeoff_rounded,
            size: 13,
            color: _accent,
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  //  PERFORATSIYA
  // ──────────────────────────────────────────────────────────────────

  /// Chipta "yirtish" chizig'i: ikki chetda sahifa foni rangidagi yarim
  /// doira "kesik"lar va o'rtada punktir. Kesiklar karta chetiga chiqib
  /// turadi (Clip.none) — haqiqiy talon effekti.
  Widget _perforation(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    final Color bg = context.backgroundColor;
    final Color rim =
        isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(8);
    final dashColor =
        isDark ? Colors.white.withAlpha(35) : const Color(0xffDBDCDF);
    return SizedBox(
      height: _notchRadius * 2,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: _notchRadius + 8),
            child: DashedLine(color: dashColor),
          ),
          Positioned(left: -_notchRadius, child: _notch(bg, rim)),
          Positioned(right: -_notchRadius, child: _notch(bg, rim)),
        ],
      ),
    );
  }

  Widget _notch(Color bg, Color rim) {
    return Container(
      width: _notchRadius * 2,
      height: _notchRadius * 2,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: rim, width: 1),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  //  HOLATGA MOS AMAL TUGMASI
  // ──────────────────────────────────────────────────────────────────

  /// Holatga qarab tugma: Booked (muddati o'tmagan) — to'lovga o'tish,
  /// Ticketed/Paid — chiptani yuklab olish, qolganlarida tugma yo'q
  /// (holat chipi o'zi yetarli).
  Widget? _actionFor(String status, ConfirmTicketResponseData responseData) {
    switch (status) {
      case 'Booked':
        final canPay =
            ElementFormatter.expireStatus(widget.ticketsModel.createdAt ?? "");
        if (!canPay) return null;
        return _buildPayButton(responseData);
      case 'Ticketed':
      case 'Paid':
        return _buildDownloadButton(responseData);
      default:
        return null;
    }
  }

  Widget _buildPayButton(ConfirmTicketResponseData responseData) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
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
                      passengerNumber:
                          responseData.book?.passengers?.length ?? 0,
                      bookingCreateModel: BookingCreateModel(
                          billingId: responseData.book?.order?.billingNumber
                                  .toString() ??
                              "",
                          trId: widget.ticketsModel.transaction?.trId ?? "",
                          createdAt: widget.ticketsModel.createdAt),
                      price: price),
                ));
          },
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  ProjectTheme.brandColor,
                  ProjectTheme.blueBg,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: ProjectTheme.brandColor.withAlpha(100),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.credit_card_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "proceed_to_payment".tr(),
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  ExpireTimeText(createdAt: widget.ticketsModel.createdAt ?? ""),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadButton(ConfirmTicketResponseData responseData) {
    final brand = ProjectTheme.brandColor;
    final isDark = context.themeProvider.isDark;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (!_isLoading) {
              downloadAndOpenFile(_ticketReceiptUrl(responseData),
                  widget.ticketsModel.billingId ?? "");
            }
          },
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: brand, width: 1.4),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  brand.withAlpha(isDark ? 70 : 20),
                  ProjectTheme.blueBg.withAlpha(isDark ? 70 : 20),
                ],
              ),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: brand.withAlpha(60),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [brand, ProjectTheme.blueBg],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: brand.withAlpha(80),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: isDark ? Colors.white : brand,
                          ),
                        )
                      : Text(
                          "download_e_ticket".tr(),
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.white : brand,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                  const SizedBox(width: 8),
                  if (!_isLoading)
                    Icon(
                      Icons.download_rounded,
                      color: isDark ? Colors.white : brand,
                      size: 18,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Stub qatori: bosiq (tint) belgi kvadrati + tavsif + qiymat. Avvalgi
/// gradient-glow uslubidan sokinroq — e'tibor marshrut va narxda qoladi.
