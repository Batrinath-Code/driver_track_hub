import 'package:driver_tracker_app/app/app.dart';
import 'package:driver_tracker_app/core/theme/theme_controller.dart';
import 'package:driver_tracker_app/features/auth/controllers/auth_controller.dart';
import 'package:driver_tracker_app/features/vehicles/controllers/vehicles_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Register your controller globally
  Get.put(ThemeController());
  Get.put(AuthController());
  Get.put(VehiclesController());

  runApp(const MyApp());
}
