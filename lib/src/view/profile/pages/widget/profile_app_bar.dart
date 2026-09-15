import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

/// Fon rangi sahifa (body) bilan bir xil bo'lgan app bar — status bar ham
/// shaffof, shunda tepa qism body'dan ajralib turmaydi.
PreferredSizeWidget sdkBodyColoredAppBar(
  BuildContext context, {
  required String title,
  String? subtitle,
}) {
  final isDark = context.isDarkMode;
  return AppBar(
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: true,
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    systemOverlayStyle:
        (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(statusBarColor: Colors.transparent),
    leading: IconButton(
      onPressed: () => Navigator.of(context).maybePop(),
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
    ),
    title: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodyLarge
              ?.copyWith(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        if (subtitle != null && subtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.headlineSmall?.copyWith(fontSize: 13),
          ),
        ],
      ],
    ),
  );
}
