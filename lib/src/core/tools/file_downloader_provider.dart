import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/widgets/toast_widget.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FileDownloaderProvider extends ChangeNotifier {
  bool isLoading = false;
  Future<void> downloadAndOpenFile(String url, String fileName) async {
    try {
      isLoading = true;
      notifyListeners();

      final Directory appDir = await getApplicationSupportDirectory();
      final Directory targetDir = Directory(p.join(appDir.path, 'mysafar'));

      if (await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final String filePath = p.join(targetDir.path, "$fileName.pdf");
      final File file = File(filePath);

      if (!await file.exists()) {
        final Dio dio = Dio();
        await dio.download(url, filePath);
      }

      await OpenFilex.open(filePath);
    } catch (e) {
      showToastMessage(e.toString());
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
