import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and broadcasts [ThemeMode] for light / dark / system.
class ThemeController extends GetxController {
  ThemeController(this._prefs, {ThemeMode initial = ThemeMode.system})
      : mode = initial.obs;

  static const preferenceKey = 'theme_mode';

  final SharedPreferences _prefs;
  final Rx<ThemeMode> mode;

  static Future<ThemeController> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ThemeController(prefs, initial: decode(prefs.getString(preferenceKey)));
  }

  static ThemeMode decode(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String encode(ThemeMode value) {
    switch (value) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<void> setMode(ThemeMode value) async {
    if (mode.value == value) return;
    mode.value = value;
    await _prefs.setString(preferenceKey, encode(value));
    Get.changeThemeMode(value);
  }

  Future<void> cycle() {
    final next = switch (mode.value) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    return setMode(next);
  }

  String get label => switch (mode.value) {
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
        ThemeMode.system => 'System',
      };

  IconData get icon => switch (mode.value) {
        ThemeMode.light => Icons.light_mode_outlined,
        ThemeMode.dark => Icons.dark_mode_outlined,
        ThemeMode.system => Icons.brightness_auto_outlined,
      };
}
