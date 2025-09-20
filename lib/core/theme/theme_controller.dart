// controllers/theme_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For persistence

class ThemeController extends GetxController {
  static ThemeController get to => Get.find();

  // Observable for the current theme mode
  final _themeMode = ThemeMode.system.obs; // Default to system theme
  ThemeMode get themeMode => _themeMode.value;

  @override
  void onInit() async {
    super.onInit();
    // Load saved theme preference (optional)
    await _loadThemeMode();
  }

  // Method to change theme
  void changeThemeMode(ThemeMode themeMode) async {
    _themeMode.value = themeMode;
    Get.changeThemeMode(themeMode);
    // Save preference (optional)
    await _saveThemeMode(themeMode);
  }

  // Optional: Methods to get specific ThemeData if you define custom ones
  // ThemeData get lightTheme => _lightTheme;
  // ThemeData get darkTheme => _darkTheme;

  // Persistence helpers (requires shared_preferences package)
  Future<void> _saveThemeMode(ThemeMode themeMode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', themeMode.toString());
  }

  Future<void> _loadThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? themeModeString = prefs.getString('theme_mode');
    if (themeModeString != null) {
      // Convert string back to ThemeMode enum
      switch (themeModeString) {
        case 'ThemeMode.light':
          _themeMode.value = ThemeMode.light;
          break;
        case 'ThemeMode.dark':
          _themeMode.value = ThemeMode.dark;
          break;
        case 'ThemeMode.system':
        default:
          _themeMode.value = ThemeMode.system;
      }
    }
  }
}
