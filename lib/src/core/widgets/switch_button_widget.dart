import 'package:flutter/services.dart' show HapticFeedback;
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

/// SDK'ning yagona switch'i — iOS va Android'da bir xil ko'rinish: yoqiq
/// holatda brend rangli trek, o'chiqda neytral kulrang, oq "thumb" yumshoq
/// soya bilan.
class SwitchButtonWidget extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const SwitchButtonWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const double _width = 50;
  static const double _height = 30;
  static const double _padding = 3;
  static const Duration _duration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final Color offTrack = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : const Color(0xFFDDE2EA);

    return Semantics(
      toggled: value,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!value);
        },
        child: AnimatedContainer(
          duration: _duration,
          curve: Curves.easeOutCubic,
          width: _width,
          height: _height,
          padding: const EdgeInsets.all(_padding),
          decoration: BoxDecoration(
            color: value ? ProjectTheme.brandColor : offTrack,
            borderRadius: BorderRadius.circular(_height / 2),
          ),
          child: AnimatedAlign(
            duration: _duration,
            curve: Curves.easeOutCubic,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: _height - _padding * 2,
              height: _height - _padding * 2,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
