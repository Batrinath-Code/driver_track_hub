// app/app.dart (Corrected)
import 'package:driver_tracker_app/app/routes.dart';
import 'package:driver_tracker_app/core/theme/theme_controller.dart'; // Import ThemeController
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Import Get

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- Find the ThemeController instance ---
    final themeController = Get.find<ThemeController>();
    // Debug log

    return GetMaterialApp(
      title: 'Driver Tracker App',
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.initial,
      getPages: AppRoutes.routes,
      // --- Define Light Theme ---
      theme: ThemeData(
        useMaterial3: true, // Use Material 3 design
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        // Add more light theme customizations here if needed
      ),
      // --- Define Dark Theme (This was missing) ---
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        // Add more dark theme customizations here if needed
      ),
      // --- Bind themeMode from ThemeController (This was missing) ---
      themeMode: themeController.themeMode,
    );
  }
}
