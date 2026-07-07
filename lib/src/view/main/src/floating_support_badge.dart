import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

/// Shared floating "support" badge shown on the right edge of the home pages.
///
/// Renders a rotated, brand-colored pill that opens the support menu when
/// tapped. An optional [height] lets callers drive a pulsing animation by
/// rebuilding with an animated value; when null the badge sizes to its
/// content.
class FloatingSupportBadge extends StatelessWidget {
  const FloatingSupportBadge({super.key, this.height});

  /// Optional fixed height. When provided the badge is wrapped in a
  /// [SizedBox] of this height (used for the pulsing animation on MainPage).
  final double? height;

  @override
  Widget build(BuildContext context) {
    final Widget badge = RotatedBox(
      quarterTurns: -1,
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ProjectTheme.brandColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(4.0)),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: Text(
              "support_badge_title".tr(),
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );

    return GestureDetector(
      onTap: () => ProjectDialogs.showSupportMenu(context),
      child: badge,
    );
  }
}
