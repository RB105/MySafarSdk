import 'dart:ui';

import 'package:mysafar_sdk/src/core/router/navigation_service.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

/// Toast kalitlari uchun o'zbekcha default — lang JSON yuklanmagan yoki
/// kalit topilmasa raw `snake_case` o'rniga shu matn chiqadi.
const Map<String, String> _uzToastDefaults = {
  'press_again_to_exit': 'Chiqish uchun yana bosing',
  'home_fill_search': "Yo'nalish va sanani tanlang",
  'same_airport_warning':
      "Uchish va qo'nish shaharlari bir xil bo'lmasligi kerak",
  'profile_success_update':
      "Profil ma'lumotlari muvaffaqiyatli o'zgartirildi",
  'error_other': 'Xatolik yuz berdi. Iltimos, qayta urinib ko‘ring',
};

String _uzDefaultFor(String key) =>
    _uzToastDefaults[key] ?? 'Xatolik yuz berdi. Iltimos, qayta urinib ko‘ring';

/// Banner turi — dizayn va ikonka shunga qarab o'zgaradi.
enum AppMessageType {
  success,
  warning,
  error,
}

OverlayEntry? _activeEntry;

/// Tarjima kaliti bo'yicha xabar.
void showToastTr(
  String key, {
  AppMessageType type = AppMessageType.error,
  BuildContext? context,
  Duration duration = const Duration(milliseconds: 2800),
}) {
  showAppMessage(
    key.tr(defaultValue: _uzDefaultFor(key)),
    type: type,
    context: context,
    duration: duration,
  );
}

/// Tayyor matn (API xato, exception va hokazo).
/// Default: [AppMessageType.error] — eski `showToastMessage` chaqiriqlari uchun.
void showToastMessage(
  String title, {
  AppMessageType type = AppMessageType.error,
  BuildContext? context,
  Duration duration = const Duration(milliseconds: 2800),
}) {
  showAppMessage(title, type: type, context: context, duration: duration);
}

void showSuccessMessage(
  String message, {
  BuildContext? context,
  Duration duration = const Duration(milliseconds: 2800),
}) =>
    showAppMessage(
      message,
      type: AppMessageType.success,
      context: context,
      duration: duration,
    );

void showWarningMessage(
  String message, {
  BuildContext? context,
  Duration duration = const Duration(milliseconds: 2800),
}) =>
    showAppMessage(
      message,
      type: AppMessageType.warning,
      context: context,
      duration: duration,
    );

void showErrorMessage(
  String message, {
  BuildContext? context,
  Duration duration = const Duration(milliseconds: 2800),
}) =>
    showAppMessage(
      message,
      type: AppMessageType.error,
      context: context,
      duration: duration,
    );

/// Yagona iOS-style top banner (success / warning / error).
void showAppMessage(
  String message, {
  AppMessageType type = AppMessageType.error,
  BuildContext? context,
  Duration duration = const Duration(milliseconds: 2800),
}) {
  final text = message.trim();
  if (text.isEmpty) return;

  final overlay = _resolveOverlay(context);
  if (overlay == null) return;

  _dismissActive();

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _AppMessageHost(
      message: text,
      type: type,
      duration: duration,
      onFinished: () {
        if (_activeEntry == entry) {
          _activeEntry = null;
          entry.remove();
        }
      },
    ),
  );

  _activeEntry = entry;
  overlay.insert(entry);
}

OverlayState? _resolveOverlay(BuildContext? context) {
  if (context != null) {
    try {
      return Overlay.maybeOf(context, rootOverlay: true);
    } catch (_) {}
  }
  return NavigationService.navigatorKey.currentState?.overlay;
}

void _dismissActive() {
  final entry = _activeEntry;
  _activeEntry = null;
  entry?.remove();
}

class _AppMessageHost extends StatefulWidget {
  final String message;
  final AppMessageType type;
  final Duration duration;
  final VoidCallback onFinished;

  const _AppMessageHost({
    required this.message,
    required this.type,
    required this.duration,
    required this.onFinished,
  });

  @override
  State<_AppMessageHost> createState() => _AppMessageHostState();
}

class _AppMessageHostState extends State<_AppMessageHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    reverseDuration: const Duration(milliseconds: 280),
  );

  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    Future.delayed(widget.duration, _close);
  }

  Future<void> _close() async {
    if (_closing || !mounted) return;
    _closing = true;
    await _controller.reverse();
    if (mounted) widget.onFinished();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _MessagePalette.of(widget.type, isDark);

    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final slide = Tween<Offset>(
      begin: const Offset(0, -1.15),
      end: Offset.zero,
    ).animate(curved);

    final fade = Tween<double>(begin: 0, end: 1).animate(curved);
    final scale = Tween<double>(begin: 0.94, end: 1).animate(curved);
    final topInset = MediaQuery.paddingOf(context).top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: slide,
        child: FadeTransition(
          opacity: fade,
          child: ScaleTransition(
            scale: scale,
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, topInset + 8, 12, 0),
                child: GestureDetector(
                  onTap: _close,
                  onVerticalDragUpdate: (details) {
                    if (details.primaryDelta != null &&
                        details.primaryDelta! < -6) {
                      _close();
                    }
                  },
                  child: _BannerCard(
                    message: widget.message,
                    colors: colors,
                    isDark: isDark,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final String message;
  final _MessagePalette colors;
  final bool isDark;

  const _BannerCard({
    required this.message,
    required this.colors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark
        ? ProjectTheme.cardColorDark.withValues(alpha: 0.88)
        : ProjectTheme.cardColorLight.withValues(alpha: 0.92);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.accent.withValues(alpha: isDark ? 0.45 : 0.28),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.accent.withValues(alpha: isDark ? 0.22 : 0.14),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: (isDark ? Colors.black : const Color(0xFFC6C7C9))
                    .withValues(alpha: isDark ? 0.45 : 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.wash.withValues(alpha: isDark ? 0.28 : 0.55),
                cardBg,
              ],
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colors.accent,
                        colors.accent.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.accent.withValues(
                              alpha: isDark ? 0.22 : 0.12,
                            ),
                            border: Border.all(
                              color: colors.accent.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Icon(
                            colors.icon,
                            size: 18,
                            color: colors.accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: context.textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                              color: isDark
                                  ? ProjectTheme.textColorDark
                                  : ProjectTheme.textColorLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessagePalette {
  final Color accent;
  final Color wash;
  final IconData icon;

  const _MessagePalette({
    required this.accent,
    required this.wash,
    required this.icon,
  });

  factory _MessagePalette.of(AppMessageType type, bool isDark) {
    switch (type) {
      case AppMessageType.success:
        return _MessagePalette(
          accent: ProjectTheme.success,
          wash: isDark
              ? ProjectTheme.success.withValues(alpha: 0.18)
              : ProjectTheme.greenBgLight,
          icon: Icons.check_circle_rounded,
        );
      case AppMessageType.warning:
        return _MessagePalette(
          accent: ProjectTheme.warning,
          wash: isDark
              ? ProjectTheme.warning.withValues(alpha: 0.18)
              : const Color(0xFFFBF3D5),
          icon: Icons.warning_amber_rounded,
        );
      case AppMessageType.error:
        return _MessagePalette(
          accent: ProjectTheme.error,
          wash: isDark
              ? ProjectTheme.error.withValues(alpha: 0.18)
              : ProjectTheme.redBgLight,
          icon: Icons.error_rounded,
        );
    }
  }
}
