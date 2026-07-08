// ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/tools/lang_helper.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/tools/formatters.dart';
import 'package:mysafar_sdk/src/core/tools/project_assets.dart';
import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart';
import 'package:mysafar_sdk/src/model/remote/booking/booking_create_model.dart';
import 'package:mysafar_sdk/src/model/remote/profile/confirmed_ticket_models.dart';
import 'package:mysafar_sdk/src/view/booking/booking_confirm_page.dart';
import 'package:mysafar_sdk/src/view/booking/widget/dashedline.dart';
import 'package:mysafar_sdk/src/view/profile/src/expire_time_widget.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightPrice, FluffyUzs;

class MyTicketWidget extends StatefulWidget {
  final ConfirmedTicketsModel ticketsModel;

  const MyTicketWidget({super.key, required this.ticketsModel});

  @override
  State<MyTicketWidget> createState() => _MyTicketWidgetState();
}

class _MyTicketWidgetState extends State<MyTicketWidget> {
  bool _isLoading = false;

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

      final Dio dio = Dio();
      await dio.download(url, filePath);

      await OpenFilex.open(filePath);
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    ConfirmTicketResponseData responseData =
        widget.ticketsModel.response!.data!;
    String callback_status = widget.ticketsModel.callbackStatus ?? "";
    final isDark = context.themeProvider.isDark;
    final brand = ProjectTheme.brandColor;
    final statusColor = _statusColor(callback_status);
    final dashedColor = isDark
        ? Colors.white.withAlpha(35)
        : const Color(0xffDBDCDF);
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
            spreadRadius: 0,
          ),
        ],
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(15)
              : Colors.black.withAlpha(8),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [brand, ProjectTheme.blueBg],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: brand.withAlpha(90),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.flight_takeoff_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [statusColor, statusColor.withAlpha(205)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withAlpha(80),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        callback_status.tr(),
                        style: context.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(
                          text: "${widget.ticketsModel.billingId}"),
                    ).then(
                      (value) {
                        ProjectDialogs.showCustomToast(
                            // ignore: use_build_context_synchronously
                            context,
                            "ID nusxalandi");
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ProjectTheme.blueBg,
                          ProjectTheme.blueBg.withAlpha(205),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: ProjectTheme.blueBg.withAlpha(80),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "ID: ${widget.ticketsModel.billingId}",
                          style: context.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.copy_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: DashedLine(color: dashedColor),
            ),
            context.szBoxHeight8,
            _segmentBuilder(responseData.book?.flight?.segments ?? []),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: DashedLine(color: dashedColor),
            ),
            _InfoLine(
              icon: Icons.airline_seat_recline_normal_rounded,
              label: "tarif".tr(),
              value: ElementFormatter.getClassName(
                  _flightClassCode(responseData),
                  dataLang(context.locale.languageCode)),
              accent: brand,
            ),
            const SizedBox(height: 10),
            _InfoLine(
              icon: Icons.people_alt_rounded,
              label: "passengerss".tr(),
              value: ElementFormatter.getPassengerAgeSummary(
                  responseData.book!.passengers),
              accent: brand,
            ),
            const SizedBox(height: 10),
            _InfoLine(
              icon: Icons.verified_user_rounded,
              label: "order_confirmed".tr(),
              value: _firstPassengerName(responseData),
              accent: brand,
              valueColor: brand,
            ),
            context.szBoxHeight12,
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [brand, ProjectTheme.blueBg],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: brand.withAlpha(80),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.payments_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "total_price".tr(),
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withAlpha(220),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    "${ElementFormatter.formatNumberWithSpaces(responseData.book!.order!.price!.uzs!.amount ?? 0)} UZS",
                    style: context.textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            context.szBoxHeight12,
            getStatusWidget(
                widget.ticketsModel.callbackStatus ?? "",
                responseData,
                widget.ticketsModel.transaction?.trId ?? "",
                widget.ticketsModel),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Booked':
        return ProjectTheme.warning;
      case 'Ticketed':
      case 'Paid':
        return ProjectTheme.success;
      default:
        return ProjectTheme.brandColor;
    }
  }

  Widget _segmentBuilder(List<ConfirmedTicketSegment> ticketSegments) {
    final segments = ticketSegments;
    final brand = ProjectTheme.brandColor;
    final isDark = context.themeProvider.isDark;
    final secondaryColor = isDark
        ? ProjectTheme.secondaryTextDark
        : ProjectTheme.secondaryTextLight;
    return ListView.separated(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: segments.length,
      separatorBuilder: (BuildContext context, int index) {
        return context.szBoxHeight16;
      },
      itemBuilder: (context, index) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withAlpha(15)
                    : brand.withAlpha(18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withAlpha(40)
                      : brand.withAlpha(50),
                  width: 1,
                ),
              ),
              child: ClipOval(
                child: Image.network(
                  ProjectAssets.getSegmentProviderImg(
                      segments[index].provider?.supplier?.code ?? ""),
                  cacheWidth: 100,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${ElementFormatter.formatTime(segments[index].dep?.time ?? "")} → ${ElementFormatter.formatTime(segments[index].arr?.time ?? "")}",
                    style: context.textTheme.bodyLarge?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        segments[index].dep?.airport?.code ?? "",
                        style: context.textTheme.bodySmall?.copyWith(
                          color: secondaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      Icon(Icons.arrow_right_alt_rounded,
                          size: 14, color: secondaryColor),
                      Text(
                        segments[index].arr?.airport?.code ?? "",
                        style: context.textTheme.bodySmall?.copyWith(
                          color: secondaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: isDark
                    ? LinearGradient(
                        colors: [brand, ProjectTheme.blueBg],
                      )
                    : null,
                color: isDark ? null : brand.withAlpha(22),
                borderRadius: BorderRadius.circular(20),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: brand.withAlpha(80),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 12,
                    color: isDark ? Colors.white : brand,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ElementFormatter.formatDuration(
                        segments[index].duration?.flight?.common ?? 0),
                    style: context.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: isDark ? Colors.white : brand,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget getStatusWidget(String status, ConfirmTicketResponseData responseData,
      String trId, ConfirmedTicketsModel ticketModel) {
    switch (status) {
      case 'Booked':
        final canPay = ElementFormatter.expireStatus(
            widget.ticketsModel.createdAt ?? "");
        if (!canPay) return const SizedBox.shrink();
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
                          responseData.book!.order!.price!.uzs!.amount ??
                              0),
                    ),
                    rub: null,
                    usd: null);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingConfirmPage(
                          passengerNumber:
                              responseData.book?.passengers?.length ?? 0,
                          bookingCreateModel: BookingCreateModel(
                              billingId: responseData
                                      .book?.order?.billingNumber
                                      .toString() ??
                                  "",
                              trId: trId,
                              createdAt: ticketModel.createdAt),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14),
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
                      ExpireTimeText(
                          createdAt:
                              widget.ticketsModel.createdAt ?? ""),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      case 'Ticketed':
      case 'Paid':
        return _buildDownloadButton(responseData);
      default:
        return SizedBox.shrink();
    }
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
              downloadAndOpenFile(
                  _ticketReceiptUrl(responseData),
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

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final Color? valueColor;

  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    final secondaryColor = isDark
        ? ProjectTheme.secondaryTextDark
        : ProjectTheme.secondaryTextLight;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent, accent.withAlpha(180)],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: accent.withAlpha(70),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: context.textTheme.bodyMedium?.copyWith(
              color: secondaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 7,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: context.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
