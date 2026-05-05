import 'package:flutter/material.dart';

class ThemeManager {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

  static void toggleTheme(bool isDark) {
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }
}
