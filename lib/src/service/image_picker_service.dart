import 'dart:io' show File;
import 'package:flutter/material.dart' show debugPrint;
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  static Future<File?> selectImage(ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(source: source);
      if (image == null) return null;
      File? img = File(image.path);
      return img;
    } catch (e) {
      debugPrint("Siz camer yoki galarydan rasm olmadingiz");
      return null;
    }
  }
}
