import 'dart:io';

import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter/material.dart';

import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/tools/project_assets.dart';
import 'package:mysafar_sdk/src/core/widgets/response_state.dart';
import 'package:mysafar_sdk/src/model/local/ticket_data.dart';
import 'package:mysafar_sdk/src/cubit/profile/tickets/confirmed_tickets_cubit.dart';
import 'package:mysafar_sdk/src/service/pdf/ticket_pdf_actions.dart';
import 'package:mysafar_sdk/src/view/navbar/bottom_nav_bar.dart';

/// Chipta PDF sahifasi
///
/// To'lov muvaffaqiyatli bo'lgandan keyin chipta ma'lumotlarini
/// ko'rsatadi va PDF yuklab olish imkoniyatini beradi.
class TicketPdfPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const TicketPdfPage({super.key, required this.data});

  static const routeName = '/ticketPdf';

  @override
  State<TicketPdfPage> createState() => _TicketPdfPageState();
}

class _TicketPdfPageState extends State<TicketPdfPage> {
  late final TicketData _ticketData;
  bool _isDownloading = false;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _ticketData = TicketData.fromJson(widget.data);
  }

  /// Yuklab ochish; ko'ruvchi bo'lmasa/ochilmasa — brauzerda ochish
  /// taklifi ([TicketPdfActions], №30).
  Future<void> _downloadTicket() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    await TicketPdfActions.downloadAndOpen(
      context,
      url: _ticketData.ticketReceiptUrl,
      fileName: _ticketData.fileName,
    );

    if (mounted) setState(() => _isDownloading = false);
  }

  /// Tizim "Ulashish" oynasi (share_plus, №30). [buttonContext] — iPad'da
  /// popover shu tugma ustidan chiqishi uchun.
  Future<void> _shareTicket(BuildContext buttonContext) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    await TicketPdfActions.share(
      context,
      url: _ticketData.ticketReceiptUrl,
      fileName: _ticketData.fileName,
      originContext: buttonContext,
    );
    if (mounted) setState(() => _isSharing = false);
  }

  /// Zaxira: chiptani brauzerda ochish (ko'ruvchi/ulashish ishlamasa).
  void _openInBrowser() {
    TicketPdfActions.openInBrowser(context, _ticketData.ticketReceiptUrl);
  }

  void _navigateToHome() {
    // Booking yakunlandi — biletlar keshi bekor qilinadi, keyingi ochilishda
    // serverdan qayta yuklanadi.
    ConfirmedTicketsCubit.clearCache();
    Navigator.of(context).pushNamedAndRemoveUntil(
      BottomNavBarPage.routeName,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SafeArea(
        top: Platform.isAndroid,
        bottom: Platform.isAndroid,
        // Kichik ekran / katta shriftda kontent pastdagi suzuvchi tugmalar
        // ostida qolmasin — aylantiriladi, pastda tugmalar uchun joy.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 160),
          child: _buildContent(context),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildBottomButtons(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        'payment_details'.tr(),
        style: context.textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.color.primaryContainer,
        boxShadow: [
          BoxShadow(
            color: context.themeProvider.isDark
                ? Colors.transparent
                : const Color(0x80C6C7C9),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusIcon(),
          context.szBoxHeight8,
          _DetailItem(
            title: 'payment_status'.tr(),
            value: _ticketData.statusTitle ?? '',
          ),
          _DetailItem(
            title: 'ticket_expiry'.tr(),
            value: _ticketData.expire ?? '',
          ),
          _DetailItem(
            title: 'ticket_status'.tr(),
            value: _ticketData.statusSign ?? '',
          ),
          context.szBoxHeight16,
          _buildDownloadTicketButton(context),
          if ((_ticketData.ticketReceiptUrl ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildShareButton(context),
            const SizedBox(height: 4),
            _buildOpenInBrowserButton(context),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    return Icon(
      _ticketData.isSuccessful ? Icons.check_circle : Icons.error,
      size: 48,
      color: _ticketData.isSuccessful ? Colors.green : Colors.red,
    );
  }

  Widget _buildShareButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Builder(
        builder: (buttonContext) => ElevatedButton.icon(
          onPressed: _isSharing ? null : () => _shareTicket(buttonContext),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: context.color.primaryContainer,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: ProjectTheme.brandColor, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: Icon(Icons.ios_share_rounded,
              size: 22, color: ProjectTheme.brandColor),
          label: _isSharing
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ProjectTheme.brandColor,
                  ),
                )
              : Text(
                  'share_ticket'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    color: ProjectTheme.brandColor,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildOpenInBrowserButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: _openInBrowser,
        style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        icon: Icon(Icons.open_in_browser_rounded,
            size: 20, color: ProjectTheme.brandColor),
        label: Text(
          'open_in_browser'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: ProjectTheme.brandColor,
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadTicketButton(BuildContext context) {
    // Qat'iy balandlik o'rniga minimal — katta shriftda matn sig'adi (№32).
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isDownloading ? null : _downloadTicket,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.color.primaryContainer,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: ProjectTheme.brandColor, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: Icon(
            Icons.document_scanner_outlined,
            size: 24,
            color: ProjectTheme.brandColor,
          ),
          label: _isDownloading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ProjectTheme.brandColor,
                  ),
                )
              : Text(
                  'download_ticket'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    color: ProjectTheme.brandColor,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildReceiptButton(context),
          const SizedBox(height: 12),
          _buildHomeButton(context),
        ],
      ),
    );
  }

  Widget _buildReceiptButton(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          ResponseState.successState(
            context,
            'check_creation_note'.tr(),
            () => Navigator.pop(context),
          );
        },
        icon: SizedBox(
          width: 20,
          height: 24,
          child: Image.asset(ProjectAssets.bookingFickalicon),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: context.color.primaryContainer,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: ProjectTheme.brandColor, width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        label: Text(
          'download_receipt'.tr(),
          style: context.textTheme.bodyMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: ProjectTheme.brandColor,
          ),
        ),
      ),
    );
  }

  Widget _buildHomeButton(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _navigateToHome,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: ProjectTheme.brandColor,
          foregroundColor: Colors.white,
        ),
        child: Text(
          'home'.tr(),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// Ma'lumot elementi widgeti
class _DetailItem extends StatelessWidget {
  final String title;
  final String value;

  const _DetailItem({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16, width: double.infinity),
        Text(
          title,
          style: context.textTheme.bodyMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        context.szBoxHeight8,
        Text(
          value,
          style: context.textTheme.bodyLarge?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
