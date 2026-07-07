import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PdfDownloadService {
  static const String _folderName = 'mysafar';

  static Future<PdfDownloadResult> downloadAndOpen({
    required String fileName,
    required String pdfUrl,
  }) async {
    try {
      final filePath = await _getFilePath(fileName);
      final file = File(filePath);

      if (!await file.exists()) {
        await _downloadFile(pdfUrl, filePath);
      }

      await OpenFile.open(filePath);

      return const PdfDownloadResult.success();
    } catch (e) {
      debugPrint('PDF yuklab olishda xatolik: $e');
      return PdfDownloadResult.error(e.toString());
    }
  }

  static Future<String> _getFilePath(String fileName) async {
    final appDir = await getApplicationSupportDirectory();
    final targetDir = Directory(p.join(appDir.path, _folderName));

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    return p.join(targetDir.path, '$fileName.pdf');
  }

  static Future<void> _downloadFile(String url, String filePath) async {
    final dio = Dio();
    await dio.download(url, filePath);
  }
}

class PdfDownloadResult {
  final bool isSuccess;
  final String? errorMessage;

  const PdfDownloadResult._({
    required this.isSuccess,
    this.errorMessage,
  });

  const PdfDownloadResult.success() : this._(isSuccess: true);

  const PdfDownloadResult.error(String message)
      : this._(isSuccess: false, errorMessage: message);
}

