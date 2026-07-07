import 'package:flutter/material.dart'
    show
        Brightness,
        ChangeNotifier,
        ThemeMode,
        WidgetsBinding,
        WidgetsBindingObserver;
import 'package:get_storage/get_storage.dart' show GetStorage;

class ThemeNotifier extends ChangeNotifier with WidgetsBindingObserver {
  static const _key = 'theme_mode';

  ThemeMode _currentMode = ThemeMode.system;

  ThemeNotifier() {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _currentMode;

  bool get isDark {
    if (_currentMode == ThemeMode.system) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _currentMode == ThemeMode.dark;
  }

  void setTheme(ThemeMode mode) {
    _currentMode = mode;
    GetStorage().write(_key, mode.index);
    notifyListeners();
  }

  Future<void> _loadThemeMode() async {
    final index = GetStorage().read(_key) ?? 0;
    _currentMode = ThemeMode.values[index];
    notifyListeners();
  }

  @override
  void didChangePlatformBrightness() {
    if (_currentMode == ThemeMode.system) {
      notifyListeners(); // Rebuild app on system theme change
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}