import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/service/image_picker_service.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';

import 'package:flutter/material.dart';

class ImagePickerWidget extends StatefulWidget {
  const ImagePickerWidget({
    super.key,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  File? file;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: file == null ? Text("editImage".tr()) : const SizedBox.shrink(),
      content: SizedBox(
        height: context.height * 0.2,
        child: Visibility(
          replacement: SizedBox(
            child: file != null
                ? Image.file(
                    file!,
                    fit: BoxFit.cover,
                  )
                : const SizedBox(),
          ),
          visible: file == null,
          child: Column(
            children: [
              SizedBox(
                height: context.height * 0.06,
                child: OutlinedButton(
                    onPressed: () async {
                      file = await ImagePickerService.selectImage(
                          ImageSource.camera);
                      setState(() {});
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.camera_alt_outlined),
                        SizedBox(
                          width: context.width * 0.02,
                        ),
                        Text("camera".tr())
                      ],
                    )),
              ),
              SizedBox(
                height: context.height * 0.02,
              ),
              SizedBox(
                height: context.height * 0.06,
                child: OutlinedButton(
                    onPressed: () async {
                      file = await ImagePickerService.selectImage(
                          ImageSource.gallery);
                      setState(() {});
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.photo_outlined),
                        SizedBox(
                          width: context.width * 0.02,
                        ),
                        Text("gallery".tr())
                      ],
                    )),
              ),
            ],
          ),
        ),
      ),
      actions: file != null
          ? [
              ElevatedButton(
                  onPressed: () {
                    file = null;
                    Navigator.of(context).pop(null);
                  },
                  child: Text("cancel".tr())),
              ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(file);
                  },
                  child: Text("upload".tr()))
            ]
          : null,
    );
  }
}
