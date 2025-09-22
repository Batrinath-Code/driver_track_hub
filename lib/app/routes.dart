// app/routes.dart (Example - adjust based on your actual screens)
import 'package:driver_tracker_app/features/auth/screens/login_screen.dart'; // Keep Login
import 'package:driver_tracker_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:driver_tracker_app/features/trips/controllers/trip_controller.dart';
import 'package:driver_tracker_app/features/users/screen/users_screen.dart';
import 'package:driver_tracker_app/features/vehicles/controllers/vehicles_controller.dart';
import 'package:driver_tracker_app/features/vehicles/screens/vehicles_screen.dart';
import 'package:driver_tracker_app/data/models/models.dart';
import 'package:get/get.dart';

class AppRoutes {
  static const initial = '/login'; // Start at login

  static final routes = [
    GetPage(name: '/login', page: () => LoginScreen()),
    GetPage(
      name: '/dashboard',
      page: () => DashboardScreen(),
      binding: BindingsBuilder(() {
        Get.put(TripController());
        Get.put(VehicleRepository());
      }),
    ),
    GetPage(
      name: '/vehicles',
      page: () => VehiclesScreen(),
      binding: BindingsBuilder(() {
        // 👈  fresh every time
        Get.put(VehiclesController());
      }),
    ),
    GetPage(name: '/users', page: () => UsersScreen()),
    // Add other routes as needed (e.g., Add/Edit Vehicle, Ride Screen)
    // GetPage(name: '/add-edit-vehicle', page: () => AddEditVehicleScreen()),
  ];
}
