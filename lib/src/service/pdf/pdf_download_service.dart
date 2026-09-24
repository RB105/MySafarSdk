import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:mysafar_sdk/src/core/config/dio_client.dart' show DioClient;
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PdfDownloadService {
  static const String _folderName = 'mysafar';

  /// PDF'ni yuklab (bo'lsa — mavjudini), tizim ko'ruvchisida ochadi.
  ///
  /// №30: fayl foydalanuvchi ko'ra oladigan joyga saqlanadi (iOS — Documents,
  /// "Fayllar" ilovasida ko'rinadi; Android — ilovaning tashqi papkasi).
  /// Ochish natijasi tekshiriladi: PDF ko'ruvchi yo'q bo'lsa jim qolmasdan
  /// [PdfDownloadResult.noViewer] qaytadi — chaqiruvchi brauzerda ochishni
  /// taklif qiladi. [forceDownload] — faylni har doim qayta yuklash.
  static Future<PdfDownloadResult> downloadAndOpen({
    required String fileName,
    required String pdfUrl,
    bool forceDownload = false,
  }) async {
    String? filePath;
    try {
      filePath = await _getFilePath(fileName);
      final file = File(filePath);

      if (forceDownload || !await file.exists() || await file.length() == 0) {
        await _downloadFile(pdfUrl, filePath);
      }
    } catch (e) {
      debugPrint('PDF yuklab olishda xatolik: $e');
      return PdfDownloadResult.error(e.toString());
    }

    try {
      final result = await OpenFilex.open(filePath, type: 'application/pdf');
      return resultFromOpen(result.type, result.message, filePath);
    } catch (e) {
      debugPrint('PDF ochishda xatolik: $e');
      return PdfDownloadResult.noViewer(filePath, e.toString());
    }
  }

  /// PDF'ni faqat yuklab (bo'lsa — mavjudini qaytarib) lokal yo'lini beradi —
  /// tizim "Ulashish" oynasiga fayl sifatida uzatish uchun (№30).
  static Future<String> download({
    required String fileName,
    required String pdfUrl,
    bool forceDownload = false,
  }) async {
    final filePath = await _getFilePath(fileName);
    final file = File(filePath);
    if (forceDownload || !await file.exists() || await file.length() == 0) {
      await _downloadFile(pdfUrl, filePath);
    }
    return filePath;
  }

  /// `open_filex` natijasini [PdfDownloadResult] ga o'giradi.
  @visibleForTesting
  static PdfDownloadResult resultFromOpen(
      ResultType type, String message, String filePath) {
    switch (type) {
      case ResultType.done:
        return PdfDownloadResult.success(filePath);
      case ResultType.noAppToOpen:
      case ResultType.permissionDenied:
      case ResultType.error:
        return PdfDownloadResult.noViewer(filePath, message);
      case ResultType.fileNotFound:
        return PdfDownloadResult.error(message);
    }
  }

  /// Chipta havolasini tashqi brauzerda ochadi — u yerda PDF ko'rish,
  /// yuklab olish va ulashish mumkin (ko'ruvchi bo'lmaganda zaxira yo'l).
  static Future<bool> openInBrowser(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('PDF havolasi ochilmadi: $e');
      return false;
    }
  }

  static Future<String> _getFilePath(String fileName) async {
    final baseDir = await _baseDirectory();
    final targetDir = Directory(p.join(baseDir.path, _folderName));

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    return p.join(targetDir.path, '${_safeFileName(fileName)}.pdf');
  }

  /// iOS: Documents (host `UIFileSharingEnabled` bersa "Fayllar"da ko'rinadi,
  /// ko'ruvchida "Ulashish" tugmasi bor). Android: ilovaning tashqi papkasi
  /// (ruxsat talab qilmaydi, fayl menejerda ko'rinadi); bo'lmasa — ichki.
  static Future<Directory> _baseDirectory() async {
    try {
      if (Platform.isIOS) return await getApplicationDocumentsDirectory();
      if (Platform.isAndroid) {
        final external = await getExternalStorageDirectory();
        if (external != null) return external;
      }
    } catch (_) {
      // Zaxira — ichki papka.
    }
    return getApplicationSupportDirectory();
  }

  /// Fayl nomidagi yo'l ajratuvchi va taqiqlangan belgilarni almashtiradi.
  @visibleForTesting
  static String safeFileNameForTest(String name) => _safeFileName(name);

  static String _safeFileName(String name) {
    final cleaned = name.trim().replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_');
    return cleaned.isEmpty ? 'ticket' : cleaned;
  }

  static Future<void> _downloadFile(String url, String filePath) async {
    await DioClient.downloadFile(url, filePath);
  }
}

class PdfDownloadResult {
  final bool isSuccess;

  /// Fayl yuklandi, lekin telefonda uni ochadigan ilova topilmadi.
  final bool noViewer;
  final String? filePath;
  final String? errorMessage;

  const PdfDownloadResult._({
    required this.isSuccess,
    this.noViewer = false,
    this.filePath,
    this.errorMessage,
  });

  const PdfDownloadResult.success([String? filePath])
      : this._(isSuccess: true, filePath: filePath);

  const PdfDownloadResult.noViewer(String filePath, [String? message])
      : this._(
          isSuccess: false,
          noViewer: true,
          filePath: filePath,
          errorMessage: message,
        );

  const PdfDownloadResult.error(String message)
      : this._(isSuccess: false, errorMessage: message);
}
