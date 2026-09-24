import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/widgets/sdk_dialog.dart';
import 'package:mysafar_sdk/src/core/widgets/toast_widget.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/service/pdf/pdf_download_service.dart';

/// Chipta PDF'ini ochish uchun umumiy UI oqimi (№30): yuklab, tizim
/// ko'ruvchisida ochadi; ochilmasa (ko'ruvchi yo'q / xato) jim qolmasdan
/// "Brauzerda ochish" taklif qilinadi — brauzerda PDF'ni ko'rish, saqlash va
/// ulashish mumkin.
class TicketPdfActions {
  const TicketPdfActions._();

  static Future<PdfDownloadResult?> downloadAndOpen(
    BuildContext context, {
    required String? url,
    required String fileName,
    bool forceDownload = false,
  }) async {
    final pdfUrl = (url ?? '').trim();
    if (pdfUrl.isEmpty) {
      showErrorMessage('ticket_url_not_found'.tr(), context: context);
      return null;
    }
    final result = await PdfDownloadService.downloadAndOpen(
      fileName: fileName,
      pdfUrl: pdfUrl,
      forceDownload: forceDownload,
    );
    if (result.isSuccess || !context.mounted) return result;
    await offerBrowser(context, pdfUrl, noViewer: result.noViewer);
    return result;
  }

  /// Chipta PDF'ini yuklab, tizim "Ulashish" oynasini ochadi (Telegram,
  /// pochta, "Fayllar"ga saqlash va h.k.). iPad/Mac'da oyna [originContext]
  /// (bosilgan tugma) ustidan chiqadi — aks holda iPad'da crash bo'ladi.
  /// Xato bo'lsa toast ko'rsatiladi va `false` qaytadi.
  static Future<bool> share(
    BuildContext context, {
    required String? url,
    required String fileName,
    BuildContext? originContext,
  }) async {
    final pdfUrl = (url ?? '').trim();
    if (pdfUrl.isEmpty) {
      showErrorMessage('ticket_url_not_found'.tr(), context: context);
      return false;
    }
    // Rect yuklashdan OLDIN olinadi — keyin tugma daraxtdan chiqib ketishi mumkin.
    final origin = shareOriginOf(originContext ?? context);
    try {
      // Har safar yangidan yuklanadi: fayl nomi bir xil bo'lib qolsa (billingId
      // bo'lmasa `ticket.pdf`) yoki chipta qayta chiqarilgan bo'lsa, eski /
      // boshqa buyurtmaning PDF'i ulashilib ketmasin.
      final path = await PdfDownloadService.download(
        fileName: fileName,
        pdfUrl: pdfUrl,
        forceDownload: true,
      );
      // SharePlus.instance faqat 11+ da bor; pubspec diapazoni 7.2.2 dan
      // boshlangani uchun hamma versiyada mavjud Share.shareXFiles ishlatiladi.
      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(path, mimeType: 'application/pdf')],
        subject: fileName,
        sharePositionOrigin: origin,
      );
      return true;
    } catch (e) {
      debugPrint('PDF ulashishda xatolik: $e');
      if (context.mounted) {
        showErrorMessage('share_error'.tr(), context: context);
      }
      return false;
    }
  }

  /// Widget'ning ekrandagi to'rtburchagi (iPad share popover'i uchun).
  static Rect? shareOriginOf(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    return rect.isEmpty ? null : rect;
  }

  /// Chiptani brauzerda ochishni taklif qiluvchi oyna.
  static Future<void> offerBrowser(
    BuildContext context,
    String url, {
    bool noViewer = false,
  }) async {
    final open = await showSdkAlert<bool>(
      context: context,
      icon: Assets.iconsDialogWarningIcon,
      tone: SdkDialogTone.warning,
      title: noViewer ? 'pdf_no_viewer_title'.tr() : 'file_open_error'.tr(),
      message: 'pdf_open_in_browser_hint'.tr(),
      actions: [
        SdkDialogAction(label: 'open_in_browser'.tr(), value: true),
        SdkDialogAction(
          label: 'close'.tr(),
          value: false,
          variant: SdkDialogButtonVariant.secondary,
        ),
      ],
    );
    if (open != true || !context.mounted) return;
    await openInBrowser(context, url);
  }

  /// Havolani tashqi brauzerda ochadi; bo'lmasa xato ko'rsatadi.
  static Future<void> openInBrowser(BuildContext context, String? url) async {
    final pdfUrl = (url ?? '').trim();
    if (pdfUrl.isEmpty) {
      showErrorMessage('ticket_url_not_found'.tr(), context: context);
      return;
    }
    final launched = await PdfDownloadService.openInBrowser(pdfUrl);
    if (!launched && context.mounted) {
      showErrorMessage('file_open_error'.tr(), context: context);
    }
  }
}
