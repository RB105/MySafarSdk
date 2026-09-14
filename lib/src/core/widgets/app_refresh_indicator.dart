import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

/// Ilova ranglariga moslangan pull-to-refresh — spinner brend rangida,
/// foni karta rangida (light/dark). Standart M3 `RefreshIndicator` o'rniga
/// barcha sahifalarda shu ishlatiladi.
class AppRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final double displacement;
  final double edgeOffset;

  const AppRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.displacement = 40,
    this.edgeOffset = 0,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: ProjectTheme.brandColor,
      backgroundColor: context.color.primaryContainer,
      displacement: displacement,
      edgeOffset: edgeOffset,
      strokeWidth: 2.5,
      onRefresh: onRefresh,
      child: child,
    );
  }
}
