// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysafar_sdk/src/core/tools/lang_helper.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/tools/formatters.dart';
import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart';
import 'package:mysafar_sdk/src/core/widgets/main_button_widget.dart';
import 'package:mysafar_sdk/src/cubit/booking/ticketed_search/ticketed_booking_search_cubit.dart';
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightPrice, FluffyUzs;
import 'package:mysafar_sdk/src/model/remote/booking/booking_create_model.dart';
import 'package:mysafar_sdk/src/model/remote/profile/confirmed_ticket_models.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mysafar_sdk/src/view/booking/booking_confirm_page.dart';
import 'package:mysafar_sdk/src/view/booking/widget/custom_input_field_widget.dart';
import 'package:mysafar_sdk/src/view/profile/src/expire_time_widget.dart';
import 'package:mysafar_sdk/src/view/profile/src/my_ticket_widget.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class TicketedBookingSearchPage extends StatelessWidget {
  static const routeName = '/ticketed-booking-search';

  final String? billingId;

  const TicketedBookingSearchPage({super.key, this.billingId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TicketedBookingSearchCubit(),
      child: _TicketedBookingSearchView(initialBillingId: billingId),
    );
  }
}

class _TicketedBookingSearchView extends StatefulWidget {
  final String? initialBillingId;

  const _TicketedBookingSearchView({this.initialBillingId});

  @override
  State<_TicketedBookingSearchView> createState() =>
      _TicketedBookingSearchViewState();
}

class _TicketedBookingSearchViewState
    extends State<_TicketedBookingSearchView> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    debugPrint('TicketedBookingSearchPage OPENED billingId=${widget.initialBillingId}');
    final id = widget.initialBillingId;
    if (id != null && id.isNotEmpty) {
      _controller.text = id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<TicketedBookingSearchCubit>().searchTicket(id);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search() {
    final id = _controller.text.trim();
    if (id.isEmpty) return;
    FocusScope.of(context).unfocus();
    context.read<TicketedBookingSearchCubit>().searchTicket(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text("ticketed_payment_title".tr(), style: context.textTheme.titleLarge),
      ),
      body: Column(
        children: [
          _buildSearchCard(context),
          Expanded(
            child: BlocBuilder<TicketedBookingSearchCubit,
                TicketedBookingSearchState>(
              builder: (context, state) => _buildBody(context, state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: context.color.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.shadowDown,
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12, top: 12, bottom: 12),
              child: CustomInputField(
                controller: _controller,
                label: "ticket_id_hint".tr(),
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.none,
                textInputAction: TextInputAction.search,
                showError: false,
                onFieldSubmitted: (_) => _search(),
                perfex: Icon(
                  Icons.airplane_ticket_outlined,
                  color: context.color.outline,
                  size: 20,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: BlocBuilder<TicketedBookingSearchCubit,
                TicketedBookingSearchState>(
              builder: (context, state) {
                final isLoading = state is TicketedBookingSearchLoading;
                return SizedBox(
                  height: 50,
                  width: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _search,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ProjectTheme.brandColor,
                      disabledBackgroundColor:
                          ProjectTheme.brandColor.withAlpha(100),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.search,
                            color: Colors.white, size: 22),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, TicketedBookingSearchState state) {
    if (state is TicketedBookingSearchInitial) return _buildEmptyState(context);
    if (state is TicketedBookingSearchLoading) {
      return Center(
        child: CircularProgressIndicator(color: context.color.primary),
      );
    }
    if (state is TicketedBookingSearchError) {
      return _buildErrorState(context, state.error);
    }
    if (state is TicketedBookingSearchSuccess) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: MyTicketWidget(ticketsModel: state.ticket),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'packages/mysafar_sdk/assets/img/home/icons/search_ticket_ic.png',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          Text(
            "ticket_id_search_hint".tr(),
            style: context.textTheme.headlineMedium?.copyWith(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ProjectTheme.error.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.error_outline, size: 48, color: ProjectTheme.error),
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: context.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 180,
              child: MainButtonWidget(title: "retry_search".tr(), onTap: _search),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketResultCard extends StatefulWidget {
  final ConfirmedTicketsModel ticket;

  const _TicketResultCard({required this.ticket});

  @override
  State<_TicketResultCard> createState() => _TicketResultCardState();
}

class _TicketResultCardState extends State<_TicketResultCard> {
  bool _isLoading = false;

  Future<void> _downloadAndOpen(String url, String fileName) async {
    try {
      setState(() => _isLoading = true);
      final appDir = await getApplicationSupportDirectory();
      final targetDir = Directory(p.join(appDir.path, 'mysafar'));
      if (!await targetDir.exists()) await targetDir.create(recursive: true);
      final filePath = p.join(targetDir.path, "$fileName.pdf");
      await Dio().download(url, filePath);
      await OpenFile.open(filePath);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("file_open_error".tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final responseData = widget.ticket.response?.data;
    if (responseData == null) return const SizedBox.shrink();

    final status = widget.ticket.callbackStatus ?? "";
    final segments = responseData.book?.flight?.segments ?? [];
    final order = responseData.book?.order;
    final passengers = responseData.book?.passengers ?? [];

    return Container(
      decoration: BoxDecoration(
        color: context.color.primaryContainer,
        boxShadow: context.shadowDown,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, status),
          context.szBoxHeight16,
          Divider(color: context.color.outline.withAlpha(80), height: 1),
          context.szBoxHeight16,
          _buildInfoRow(
            context,
            label: "ticket_tariff_label".tr(),
            value: segments.isNotEmpty
                ? ElementFormatter.getClassName(
                    segments[0]
                            .parametersForEachPassenger?[0]
                            .flightClass
                            ?.code ??
                        "",
                    dataLang(),
                  )
                : "—",
            icon: Icons.local_offer_outlined,
          ),
          context.szBoxHeight12,
          _buildInfoRow(
            context,
            label: "passenger".tr(),
            value: ElementFormatter.getPassengerAgeSummary(passengers),
            icon: Icons.people_outline,
          ),
          if (passengers.isNotEmpty) ...[
            context.szBoxHeight12,
            _buildInfoRow(
              context,
              label: "orderer_label".tr(),
              value:
                  "${passengers[0].name?.first ?? ""} ${passengers[0].name?.last ?? ""}",
              icon: Icons.person_outline,
              valueColor: context.color.primary,
            ),
          ],
          context.szBoxHeight12,
          _buildInfoRow(
            context,
            label: "total_amount_label".tr(),
            value:
                "${ElementFormatter.formatNumberWithSpaces(order?.price?.uzs?.amount ?? 0)} UZS",
            icon: Icons.payments_outlined,
            valueColor: context.color.primary,
          ),
          context.szBoxHeight16,
          _buildActionButton(context, status, responseData),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String status) {
    final statusColor = status == 'Booked'
        ? ProjectTheme.warning
        : status == 'Ticketed'
            ? ProjectTheme.success
            : context.color.primary;

    final statusLabel = status == 'Booked'
        ? 'status_booked'.tr()
        : status == 'Ticketed'
            ? 'status_ticketed'.tr()
            : status;

    return Row(
      children: [
        Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor.withAlpha(80)),
          ),
          child: Text(
            statusLabel,
            style: context.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: statusColor,
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            Clipboard.setData(
              ClipboardData(text: widget.ticket.billingId ?? ""),
            ).then((_) {
              ProjectDialogs.showCustomToast(context, "id_copied".tr());
            });
          },
          child: Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: context.color.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.color.primary.withAlpha(60)),
            ),
            child: Row(
              children: [
                Text(
                  "ID: ${widget.ticket.billingId}",
                  style: context.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: context.color.primary,
                  ),
                ),
                context.szBoxWidth4,
                Icon(Icons.copy, size: 12, color: context.color.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: context.color.outline.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: context.color.onSurface.withAlpha(160)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.textTheme.headlineMedium?.copyWith(
                  fontSize: 12,
                  color: context.color.onSurface.withAlpha(120),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String status,
    ConfirmTicketResponseData responseData,
  ) {
    final trId = widget.ticket.transaction?.trId ?? "";

    switch (status) {
      case 'Booked':
        final canPay =
            ElementFormatter.expireStatus(widget.ticket.createdAt ?? "");
        if (!canPay) return const SizedBox.shrink();
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              backgroundColor: context.color.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: context.color.primary.withAlpha(45),
            ),
            onPressed: () {
              final price = FlightPrice(
                uzs: FluffyUzs(
                  amount: ElementFormatter.formatNumberWithSpaces(
                    responseData.book?.order?.price?.uzs?.amount ?? 0,
                  ),
                ),
                rub: null,
                usd: null,
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookingConfirmPage(
                    passengerNumber:
                        responseData.book?.passengers?.length ?? 0,
                    bookingCreateModel: BookingCreateModel(
                      billingId:
                          responseData.book?.order?.billingNumber.toString() ??
                              "",
                      trId: trId,
                      createdAt: widget.ticket.createdAt,
                    ),
                    price: price,
                  ),
                ),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.credit_card_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  "make_payment".tr(),
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                ExpireTimeText(createdAt: widget.ticket.createdAt ?? ""),
              ],
            ),
          ),
        );

      case 'Ticketed':
      case 'Paid':
        final pdfUrl =
            responseData.book?.tickets?[0].documents?.ticketReceipt ?? "";
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: context.color.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _isLoading
                ? null
                : () => _downloadAndOpen(pdfUrl, widget.ticket.billingId ?? ""),
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: context.color.primary,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 22,
                        width: 22,
                        child: Image.asset("packages/mysafar_sdk/assets/img/booking/pfd_icon.png"),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "download_e_ticket_short".tr(),
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.color.primary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
