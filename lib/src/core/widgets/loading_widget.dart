import 'package:mysafar_sdk/src/core/styles/theme_notifier.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:provider/provider.dart';

class LoadingWidget extends StatelessWidget {
  final double? width;
  final double? strokeAlign;
  final Color? color;
  const LoadingWidget({super.key, this.width, this.color, this.strokeAlign});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator.adaptive(
          strokeWidth: width ?? 4,
          strokeAlign: strokeAlign ?? 0,
          valueColor:
              AlwaysStoppedAnimation<Color>(color ?? context.theme.primaryColor)),
    );
  }
}

class LoadingWidgetButton extends StatelessWidget {
  final double? width;
  final double? strokeAlign;
  final Color? color;
  const LoadingWidgetButton(
      {super.key, this.width, this.color, this.strokeAlign});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeNotifier>(context);
    return CircularProgressIndicator.adaptive(
        strokeWidth: width ?? 2,
        strokeAlign: strokeAlign ?? -3,
        valueColor: AlwaysStoppedAnimation<Color>(
            color ?? (themeProvider.isDark ? Colors.black : Colors.white)));
  }
}
