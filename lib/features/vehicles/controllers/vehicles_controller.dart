import 'dart:async';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:driver_tracker_app/data/models/vehicle_model.dart';
import 'package:driver_tracker_app/data/repositories/vehicle_repository.dart';
import 'package:driver_tracker_app/features/auth/controllers/auth_controller.dart';

/// Pure ADMIN / MANAGER vehicle CRUD + view.
/// All driver flows (select, end ride, report issue) removed.
class VehiclesController extends GetxController {
  /* ----------  repo / subscription  ---------- */
  final VehicleRepository _repository = VehicleRepository();
  StreamSubscription<List<Vehicle>>? _vehicleSub;

  /* ----------  obs  ---------- */
  var vehicles = <Vehicle>[].obs;
  var isLoading = true.obs;
  var isProcessing = false.obs;

  /* ----------  life-cycle  ---------- */
  @override
  void onInit() {
    super.onInit();
    _startOrStopStream();
    ever(AuthController.to.firebaseUser, (_) => _startOrStopStream());
  }

  @override
  void onClose() {
    _vehicleSub?.cancel();
    super.onClose();
  }

  /* ----------  stream  ---------- */
  void _startOrStopStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _vehicleSub?.cancel();
      vehicles.clear();
      isLoading(false);
      return;
    }

    _vehicleSub?.cancel();
    isLoading(true);

    _vehicleSub = _repository.getVehiclesStream().listen(
      (list) {
        vehicles.assignAll(list);
        isLoading(false);
      },
      onError: (e) {
        log('Vehicle stream error: $e');
        isLoading(false);
      },
    );
  }

  /* ----------  admin/manager CRUD  ---------- */
  Vehicle? getVehicleById(String id) {
    try {
      return vehicles.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  String getVehicleStatusText(Vehicle v) => v.status;
  Color getVehicleStatusColor(Vehicle v) {
    switch (v.status) {
      case 'idle':
        return Colors.green;
      case 'active':
        return Colors.orange;
      case 'underMaintenance':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> deleteVehicle(String vehicleId) async {
    final role = Get.find<AuthController>().userRole.value;
    if (role != 'admin' && role != 'manager') {
      Get.snackbar(
        "Permission Denied",
        "Only Admins or Managers can delete vehicles.",
      );
      return;
    }

    try {
      isProcessing(true);
      final success = await _repository.deleteVehicle(vehicleId);
      if (success) {
        Get.snackbar("Success", "Vehicle deleted");
      } else {
        Get.snackbar("Error", "Delete failed");
      }
    } catch (e) {
      log("Delete error: $e");
      Get.snackbar("Error", "Could not delete vehicle");
    } finally {
      isProcessing(false);
    }
  }

  Future<void> createVehicle(Vehicle v) async {
    isProcessing(true);
    try {
      await _repository.createVehicle(v);
      Get.snackbar("Success", "Vehicle added");
      Get.back(); // close editor
    } catch (e) {
      Get.snackbar("Error", "Could not add vehicle");
    } finally {
      isProcessing(false);
    }
  }

  Future<void> updateVehicle(Vehicle v) async {
    isProcessing(true);
    try {
      await _repository.updateVehicle(v);
      Get.snackbar("Success", "Vehicle updated");
      Get.back(); // close editor
    } catch (e) {
      Get.snackbar("Error", "Could not update vehicle");
    } finally {
      isProcessing(false);
    }
  }
}
