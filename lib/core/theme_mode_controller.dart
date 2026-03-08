import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyThemeMode = 'pref_theme_mode';

/// Controla la preferencia de tema (claro / oscuro / sistema) y la persiste.
class ThemeModeController {
  ThemeModeController() : notifier = ValueNotifier<ThemeMode>(ThemeMode.system);

  final ValueNotifier<ThemeMode> notifier;

  static String _toStorage(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static ThemeMode _fromStorage(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }

  /// Carga la preferencia guardada y actualiza [notifier].
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    notifier.value = _fromStorage(prefs.getString(_keyThemeMode));
  }

  /// Guarda la preferencia y actualiza [notifier].
  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, _toStorage(mode));
    notifier.value = mode;
  }
}
