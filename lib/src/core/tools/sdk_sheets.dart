import 'package:flutter/cupertino.dart' show CupertinoSheetRoute;
import 'package:flutter/widgets.dart';

/// Flutter'ning `showCupertinoSheet`'i sheet'ni doim ROOT navigatorga push
/// qiladi — embed rejimda bu host app'ning (masalan Unired) navigatori bo'lib,
/// SDK'ning provider/theme/lokalizatsiya konteksti u yerda mavjud emas
/// (ProviderNotFound / theme crash). Bu wrapper sheet'ni eng yaqin (SDK ichki)
/// navigatorda ochadi.
Future<T?> showSdkCupertinoSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool enableDrag = true,
}) {
  return Navigator.of(context).push<T>(
    CupertinoSheetRoute<T>(builder: builder, enableDrag: enableDrag),
  );
}
