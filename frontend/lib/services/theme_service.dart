import 'package:flutter/material.dart';

class ThemeService {
  static final ValueNotifier<bool> isDarkMode =
      ValueNotifier(false);

  static void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
  }
}
