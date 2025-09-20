// features/vehicles/controllers/vehicles_controller.dart (Additions/Modifications)
import 'dart:async';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:driver_tracker_app/data/models/vehicle_model.dart';
import 'package:driver_tracker_app/data/repositories/vehicle_repository.dart';
import 'package:driver_tracker_app/features/auth/controllers/auth_controller.dart'; // To get user role
import 'package:cloud_firestore/cloud_firestore.dart';

class VehiclesController extends GetxController {
  /* ----------  repository / subscription  ---------- */
  final VehicleRepository _repository = VehicleRepository();
  StreamSubscription<List<Vehicle>>? _vehicleSub;

  /* ----------  obs variables  ---------- */
  var vehicles = <Vehicle>[].obs;
  var isLoading = true.obs;
  var isProcessing = false.obs;
  var assignmentLoaded = false.obs; // NEW – assignment fetch complete

  /* ----------  driver-specific  ---------- */
  var currentDriverAssignedVehicleId = ''.obs;
  var currentAssignedVehicle = Rxn<Vehicle>();

  /* ----------  life-cycle  ---------- */
  @override
  void onInit() {
    super.onInit();
    _startOrStopStream(); // first decision
    ever(AuthController.to.firebaseUser, (_) => _startOrStopStream());
  }

  /* ----------  stream start / stop  ---------- */
  void _startOrStopStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _clearAll();
      return;
    }

    /* auth present – (re)start stream */
    _vehicleSub?.cancel();
    isLoading(true);
    assignmentLoaded(false);

    _vehicleSub = _repository.getVehiclesStream().listen(
      (list) {
        vehicles.assignAll(list);
        isLoading(false);
        _fetchCurrentUserAssignmentIfNeeded(); // kicks off assignment fetch
      },
      onError: (e) {
        log('Stream error: $e');
        isLoading(false);
        assignmentLoaded(true); // mark finished even on error
      },
    );
  }

  /* ----------  assignment fetch  ---------- */
  Future<void> _fetchCurrentUserAssignmentIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _clearAssignmentState();
      assignmentLoaded(true);
      return;
    }

    final auth = Get.find<AuthController>();

    /* wait until AuthController finishes its own load */
    if (auth.isLoading.value) {
      await auth.isLoading.stream.firstWhere((l) => !l);
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final role = auth.userRole.value;
    log("Checking assignment for ${user.uid}, role: $role");

    if (role == 'driver') {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          _clearAssignmentState();
          assignmentLoaded(true);
          return;
        }

        final data = userDoc.data() as Map<String, dynamic>?;
        final assignedId = data?['assignedVehicleId'] ?? '';

        currentDriverAssignedVehicleId.value = assignedId;

        if (assignedId.isEmpty) {
          _clearAssignmentState();
          assignmentLoaded(true);
          return;
        }

        final vehicle = await _repository.getVehicleById(assignedId);
        if (vehicle == null) {
          _clearAssignmentState();
          assignmentLoaded(true);
          if (Get.key?.currentState?.mounted == true) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => Get.snackbar(
                "Data Error",
                "Assigned vehicle data is missing.",
              ),
            );
          }
          return;
        }

        currentAssignedVehicle.value = vehicle;
        assignmentLoaded(true);
        log("Driver ${user.uid} assigned to vehicle ${vehicle.id}");
      } catch (e) {
        log("Error fetching driver assignment: $e");
        _clearAssignmentState();
        assignmentLoaded(true);
      }
    } else {
      /* not a driver */
      _clearAssignmentState();
      assignmentLoaded(true);
    }
  }

  /* ----------  helpers  ---------- */
  void _clearAssignmentState() {
    currentDriverAssignedVehicleId.value = '';
    currentAssignedVehicle.value = null;
  }

  bool isAssignedVehicle(String vehicleId) =>
      vehicleId == currentDriverAssignedVehicleId.value;

  /* ----------  UI guard – used by screen  ---------- */
  bool get isDriverFullyReady {
    final auth = Get.find<AuthController>();
    return !isLoading.value &&
        assignmentLoaded.value &&
        auth.firebaseUser.value != null;
  }

  /* ----------  existing methods (unchanged)  ---------- */
  Vehicle? getVehicleById(String id) {
    try {
      return vehicles.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  // --- Helper method to get the status text for UI display ---
  String getVehicleStatusText(Vehicle vehicle) {
    switch (vehicle.status) {
      case 'idle':
        return 'Available';
      case 'active':
        // Check if current driver owns this active vehicle
        if (isAssignedVehicle(vehicle.id)) {
          return 'Your Ride (Active)';
        } else {
          return 'In Use'; // By another driver
        }
      case 'underMaintenance':
        return 'Under Maintenance';
      default:
        return vehicle.status; // Fallback
    }
  }

  // --- Helper method to get status color for UI display ---
  Color getVehicleStatusColor(Vehicle vehicle) {
    switch (vehicle.status) {
      case 'idle':
        return Colors.green;
      case 'active':
        // Check if current driver owns this active vehicle
        if (isAssignedVehicle(vehicle.id)) {
          return Colors.blue; // Your active ride
        } else {
          return Colors.orange; // In use by someone else
        }
      case 'underMaintenance':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> selectVehicle(Vehicle vehicle) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    log("DEBUG selectVehicle: Called by user UID: ${currentUser?.uid}");
    if (currentUser == null) {
      Get.snackbar("Error", "No user logged in.");
      return;
    }

    final String driverUserId = currentUser.uid;
    final authController = Get.find<AuthController>();
    final String userRole = authController.userRole.value;

    // --- Check 1: Is the user a DRIVER? ---
    if (userRole != 'driver') {
      Get.snackbar(
        "Not Allowed",
        "Only drivers can select vehicles.",
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return;
    }

    // --- Check 2: Is the DRIVER already assigned? ---
    // This check uses the observable state maintained by the controller
    if (currentDriverAssignedVehicleId.value.isNotEmpty) {
      Get.snackbar(
        "Assignment Error",
        "You are already assigned to a vehicle. Please end the current ride/assignment first.",
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return;
    }

    // --- Check 3: Is the Vehicle actually IDLE? (Redundant if list is filtered, but safe) ---
    if (vehicle.status != 'idle') {
      Get.snackbar(
        "Not Available",
        "Selected vehicle '${vehicle.name}' is not available (Status: ${vehicle.status}). Please select an idle vehicle.",
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return;
    }

    // --- Check 4: Is the Vehicle already assigned to someone else?
    // Although the UI should prevent selecting non-idle, double-checking vehicle state is good.
    // The repository transaction also checks this, but early feedback is better.
    if (vehicle.currentDriverId != null &&
        vehicle.currentDriverId!.isNotEmpty) {
      Get.snackbar(
        "Assignment Conflict",
        "Vehicle '${vehicle.name}' is unexpectedly assigned to another driver. Please refresh the list.",
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return; // Prevent attempting assignment
    }

    try {
      isProcessing(true);

      // --- ATTEMPT ASSIGNMENT ---
      // This call will trigger the repository's transaction.
      // Based on the schema's strict security rules, this is likely to fail for drivers.
      await _repository.assignDriverToVehicle(vehicle.id, driverUserId);

      // --- IF SUCCESSFUL (Requires updated security rules or backend function) ---
      Get.snackbar(
        "Success",
        "Vehicle '${vehicle.name}' assigned successfully!",
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );

      // Update local state observables
      currentDriverAssignedVehicleId.value = vehicle.id;
      currentAssignedVehicle.value =
          vehicle; // Update the assigned vehicle observable

      // --- Navigate to the next screen (e.g., start ride) ---
      // Uncomment the line below if you have a ride start screen
      // Get.toNamed('/start-ride'); // Or whatever your ride start route is
    } on FirebaseException catch (e) {
      log(
        "Firebase error assigning vehicle '${vehicle.id}' to driver '$driverUserId': ${e.message}",
      );
      String message = "Failed to assign vehicle.";
      // --- EXPECTED ERROR if security rules haven't changed ---
      if (e.code == 'permission-denied') {
        message =
            "Permission denied. You cannot directly assign yourself to a vehicle. Please contact an administrator or use the backend request feature if implemented.";
        // This message reflects the conflict between the desired UI flow and the strict schema rules.
      } else if (e.code == 'not-found') {
        message = "Vehicle or User document not found.";
      } else if (e.code == 'aborted') {
        // Transaction aborted due to failed precondition
        // The transaction logic in the repository throws exceptions for various checks
        // (e.g., vehicle not idle, driver already assigned).
        // These might manifest as 'aborted' or the specific exception message.
        // The exact error message from the repository's transaction will be in e.message.
        message =
            e.message ??
            "Assignment failed due to a conflict or precondition check.";
      }
      Get.snackbar(
        "Assignment Error",
        message,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } catch (e) {
      // Catch any other errors thrown by the repository transaction logic (e.g., validation errors)
      log(
        "Error assigning vehicle '${vehicle.id}' to driver '$driverUserId': $e",
      );
      Get.snackbar(
        "Assignment Failed",
        "An unexpected error occurred: $e",
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isProcessing(false);
    }
  }

  Future<void> endCurrentRide() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Get.snackbar("Error", "No user logged in.");
      return;
    }

    final String driverUserId = currentUser.uid;
    final authController = Get.find<AuthController>();
    final String userRole = authController.userRole.value;

    if (userRole != 'driver') {
      Get.snackbar("Not Allowed", "Only drivers can end rides.");
      return;
    }

    if (currentDriverAssignedVehicleId.value.isEmpty) {
      Get.snackbar("Error", "You are not currently assigned to a vehicle.");
      return;
    }

    // Confirm action
    final bool? confirm = await Get.defaultDialog(
      title: "End Ride",
      middleText:
          "Are you sure you want to end your current ride?\nThis will make the vehicle available for others.",
      textConfirm: "Yes, End Ride",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () => Get.back(result: true),
      onCancel: () => Get.back(result: false),
    );

    if (confirm != true) return; // User cancelled

    try {
      isProcessing(true);
      await _repository.endRideAndAssignment(
        vehicleId: currentDriverAssignedVehicleId.value,
        driverUserId: driverUserId,
      );
      Get.snackbar("Success", "Ride ended successfully. Vehicle is now idle.");
      // Refresh data or update observables
      // Clear assignment observables
      currentDriverAssignedVehicleId.value = '';
      currentAssignedVehicle.value = null;
      // Optionally navigate away or update UI state
    } on FirebaseException catch (e) {
      log("Firebase error ending ride: ${e.message}");
      String message = "Failed to end ride.";
      if (e.code == 'permission-denied') {
        message =
            "Permission denied. You might not be able to end the ride directly. Contact admin.";
      }
      Get.snackbar("Ride End Error", message);
    } catch (e) {
      log("Error ending ride: $e");
      Get.snackbar("Ride End Failed", e.toString());
    } finally {
      isProcessing(false);
    }
  }

  Future<void> reportIssue(String description) async {
    // Description passed from UI
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Get.snackbar("Error", "No user logged in.");
      return;
    }

    final String driverUserId = currentUser.uid;
    final authController = Get.find<AuthController>();
    final String userRole = authController.userRole.value;

    if (userRole != 'driver') {
      Get.snackbar("Not Allowed", "Only drivers can report issues.");
      return;
    }

    if (currentDriverAssignedVehicleId.value.isEmpty) {
      Get.snackbar("Error", "You are not currently assigned to a vehicle.");
      return;
    }

    if (description.trim().isEmpty) {
      Get.snackbar(
        "Invalid Input",
        "Please provide a description of the issue.",
      );
      return;
    }

    try {
      isProcessing(true);
      String? issueId = await _repository.reportVehicleIssue(
        vehicleId: currentDriverAssignedVehicleId.value,
        reportedByUserId: driverUserId,
        description: description.trim(),
      );

      if (issueId != null) {
        // --- NEW: Update Vehicle Status ---
        // After successfully reporting the issue, update the vehicle status.
        // Use the repository's updateVehicleStatus method.
        await _repository.updateVehicleStatus(
          currentDriverAssignedVehicleId.value, // Vehicle ID
          'underMaintenance', // New Status
        );

        Get.snackbar(
          "Issue Reported & Vehicle Updated",
          "Your issue has been reported successfully (ID: $issueId). The vehicle status is now 'Under Maintenance'.",
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );

        // Optionally, perform other actions after reporting and updating status
      } else {
        Get.snackbar("Error", "Failed to report the issue.");
      }
    } on FirebaseException catch (e) {
      log(
        "Firebase error reporting issue or updating vehicle status: ${e.message}",
      );
      // Differentiate error messages if needed, but often the main message is sufficient
      Get.snackbar(
        "Report Error",
        "Failed to report issue or update vehicle status: ${e.message}",
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } catch (e) {
      log("Unexpected error reporting issue or updating vehicle status: $e");
      Get.snackbar(
        "Report Failed",
        "An unexpected error occurred: $e",
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isProcessing(false);
    }
  }

  /// Deletes a vehicle. Typically called by Admins or Managers.
  Future<void> deleteVehicle(String vehicleId) async {
    // Confirmation is handled in the UI (_confirmDeleteVehicle dialog)
    // This method just performs the action.

    final authController = Get.find<AuthController>();
    final String userRole = authController.userRole.value;

    // Double-check role in the controller method as well
    if (userRole != 'admin' && userRole != 'manager') {
      Get.snackbar(
        "Permission Denied",
        "Only Admins or Managers can delete vehicles.",
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return;
    }

    try {
      isProcessing(true);
      bool success = await _repository.deleteVehicle(vehicleId);

      if (success) {
        Get.snackbar(
          "Success",
          "Vehicle deleted successfully.",
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );
      } else {
        Get.snackbar(
          "Delete Failed",
          "Failed to delete the vehicle.",
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      }
    } on FirebaseException catch (e) {
      log("Firebase error deleting vehicle '$vehicleId': ${e.message}");
      String message = "Failed to delete vehicle.";
      if (e.code == 'permission-denied') {
        message = "Permission denied. You cannot delete vehicles.";
      }
      Get.snackbar(
        "Delete Error",
        message,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } catch (e) {
      log("Unexpected error deleting vehicle '$vehicleId': $e");
      Get.snackbar(
        "Delete Failed",
        "An unexpected error occurred: $e",
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isProcessing(false);
    }
  }

  void _clearAll() {
    _vehicleSub?.cancel();
    _vehicleSub = null;
    vehicles.clear();
    currentDriverAssignedVehicleId.value = '';
    currentAssignedVehicle.value = null;
    assignmentLoaded(false);
    isLoading(false);
    isProcessing(false);
  }

  @override
  void onClose() {
    _clearAll();
    super.onClose();
  }
}
