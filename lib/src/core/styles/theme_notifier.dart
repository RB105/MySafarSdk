import 'package:flutter/material.dart'
    show
        Brightness,
        ChangeNotifier,
        ThemeMode,
        WidgetsBinding,
        WidgetsBindingObserver;
import 'package:mysafar_sdk/src/core/config/sdk_storage.dart';

class ThemeNotifier extends ChangeNotifier with WidgetsBindingObserver {
  static const _key = 'theme_mode';
  static const _userPickedKey = 'theme_mode_user_picked';

  ThemeMode _currentMode = ThemeMode.system;

  /// [initialMode] — `MySafarConfig.themeMode` (host). Berilsa shu sessiyada
  /// ishlatiladi. `null` bo'lsa: foydalanuvchi Sozlamalardan tanlagan bo'lsa
  /// storage'dan, aks holda `ThemeMode.system` (terminal `b` ishlaydi).
  ThemeNotifier({ThemeMode? initialMode}) {
    WidgetsBinding.instance.addObserver(this);
    if (initialMode != null) {
      _currentMode = initialMode;
    } else if (sdkStorage().read(_userPickedKey) == true) {
      final index = sdkStorage().read(_key) ?? 0;
      _currentMode =
          ThemeMode.values[index.clamp(0, ThemeMode.values.length - 1)];
    } else {
      // Default: system — platform brightness (`b` dev tools) kuzatiladi.
      _currentMode = ThemeMode.system;
    }
  }

  ThemeMode get themeMode => _currentMode;

  bool get isDark {
    if (_currentMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _currentMode == ThemeMode.dark;
  }

  void setTheme(ThemeMode mode) {
    _currentMode = mode;
    sdkStorage().write(_key, mode.index);
    sdkStorage().write(_userPickedKey, true);
    notifyListeners();
  }

  @override
  void didChangePlatformBrightness() {
    if (_currentMode == ThemeMode.system) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
