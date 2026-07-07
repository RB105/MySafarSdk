import 'package:fluttertoast/fluttertoast.dart';

import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

void showToastMessage(String title) {
  Fluttertoast.showToast(
      msg: title,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0);
}
