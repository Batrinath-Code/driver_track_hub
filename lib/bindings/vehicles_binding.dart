// bindings/vehicles_binding.dart
import 'package:get/get.dart';
import 'package:driver_tracker_app/features/auth/controllers/auth_controller.dart'; // Adjust import path
import 'package:driver_tracker_app/features/vehicles/controllers/vehicles_controller.dart';

class VehiclesBinding extends Bindings {
  @override
  void dependencies() {
    // Get the AuthController instance to check the role
    final authController =
        Get.find<
          AuthController
        >(); // Assumes AuthController is already put/initialized

    // Check if the user is authenticated and has the correct role
    if (authController.userRole == 'admin' ||
        authController.userRole == 'manager') {
      // If authorized, initialize and provide the VehiclesController
      Get.lazyPut<VehiclesController>(() => VehiclesController());
    } else {
      // If NOT authorized, prevent navigation or redirect
      // Option 1: Show an error/snackbar and don't navigate
      // Get.snackbar("Access Denied", "You don't have permission to view vehicles.");
      // Get.back(); // Go back to the previous screen if possible, or stay on current

      // Option 2: Redirect to an unauthorized screen (you'd need to create this)
      // Get.offAllNamed('/unauthorized');

      // Option 3: Simply don't initialize the controller or screen
      // In this case, GetPage's page function won't be called if binding fails.
      // We'll use a check in the route definition itself (see step 3)
      print(
        "Unauthorized access attempt to /vehicles by user with role: ${authController.userRole}",
      );
      // You might want to navigate away or show an error here
      // For now, we rely on the route definition check
    }
  }
}
