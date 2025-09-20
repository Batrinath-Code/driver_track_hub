import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:driver_tracker_app/data/models/vehicle_model.dart';
import 'package:driver_tracker_app/features/vehicles/controllers/vehicles_controller.dart';
import 'package:driver_tracker_app/features/auth/controllers/auth_controller.dart';
import 'package:driver_tracker_app/features/vehicles/screens/add_edit_vehicle_screen.dart';

class VehiclesScreen extends StatelessWidget {
  VehiclesScreen({super.key});

  final VehiclesController controller = Get.find();
  final AuthController authController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vehicles"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthController().logout(),
          ),
        ],
      ),
      body: Obx(() {
        /*  ➜  SINGLE guard waits for list + assignment  */
        if (!controller.isDriverFullyReady) {
          return const Center(child: CircularProgressIndicator());
        }

        final role = authController.userRole.value;
        final isDriver = role == 'driver';
        final isAdminOrMgr = role == 'admin' || role == 'manager';
        final currentUid = authController.firebaseUser.value!.uid;
        final assignedV = controller.currentAssignedVehicle.value;

        /*  show card only when THIS driver is assigned  */
        if (isDriver &&
            assignedV != null &&
            assignedV.currentDriverId == currentUid) {
          return Column(
            children: [
              _assignedCard(context, assignedV),
              Expanded(child: _vehicleList(isDriver, isAdminOrMgr)),
            ],
          );
        }

        /*  plain list  */
        return _vehicleList(isDriver, isAdminOrMgr);
      }),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (authController.userRole.value == 'admin')
            FloatingActionButton(
              heroTag: 'users',
              tooltip: 'Manage Users',
              onPressed: () => Get.toNamed('/users'),
              child: const Icon(Icons.people),
            ),
          const SizedBox(height: 10),
          if (authController.userRole.value == 'admin' ||
              authController.userRole.value == 'manager')
            FloatingActionButton(
              heroTag: 'addVehicle',
              tooltip: 'Add Vehicle',
              onPressed: () => Get.to(() => AddEditVehicleScreen()),
              child: const Icon(Icons.add),
            ),
        ],
      ),
    );
  }

  /* ----------  assigned-driver card  ---------- */
  Widget _assignedCard(BuildContext context, Vehicle v) {
    return Card(
      margin: const EdgeInsets.all(8),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your Current Vehicle",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(v.name, style: const TextStyle(fontSize: 16)),
            Text('Reg: ${v.regNumber}'),
            Text(
              'Status: ${controller.getVehicleStatusText(v)}',
              style: TextStyle(
                color: controller.getVehicleStatusColor(v),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Obx(
              () => controller.isProcessing.value
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showReportDialog(v),
                          icon: const Icon(Icons.report_problem, size: 18),
                          label: const Text("Report Issue"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _confirmEndRide(),
                          icon: const Icon(Icons.stop, size: 18),
                          label: const Text("End Ride"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /* ----------  vehicle list  ---------- */
  Widget _vehicleList(bool isDriver, bool isAdminOrMgr) {
    return controller.vehicles.isEmpty
        ? const Center(child: Text("No vehicles found"))
        : ListView.builder(
            itemCount: controller.vehicles.length,
            itemBuilder: (_, i) {
              final v = controller.vehicles[i];
              final isMine = controller.isAssignedVehicle(v.id);
              final statusTxt = controller.getVehicleStatusText(v);
              final statusClr = controller.getVehicleStatusColor(v);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: v.imageUrl.isEmpty
                      ? const Icon(Icons.directions_car)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            v.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                  title: Text(v.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reg: ${v.regNumber}'),
                      Text(
                        'Status: $statusTxt',
                        style: TextStyle(
                          color: statusClr,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /*  driver select button  */
                      if (isDriver &&
                          v.status == 'idle' &&
                          !isMine &&
                          !controller.isProcessing.value)
                        ElevatedButton(
                          onPressed: () => _selectConfirm(v),
                          child: const Text("Select"),
                        ),
                      /*  admin/manager popup  */
                      if (isAdminOrMgr)
                        PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'edit') {
                              Get.to(
                                () => AddEditVehicleScreen(vehicleToEdit: v),
                              );
                            } else if (val == 'delete') {
                              _confirmDelete(v);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  /* ----------  dialog helpers  ---------- */
  Future<void> _selectConfirm(Vehicle v) async {
    final ok = await Get.defaultDialog<bool>(
      title: "Select Vehicle",
      middleText: "Select ${v.name} (${v.regNumber}) ?",
      textConfirm: "Select",
      textCancel: "Cancel",
      onConfirm: () => Get.back(result: true),
    );
    if (ok == true) await controller.selectVehicle(v);
  }

  Future<void> _confirmDelete(Vehicle v) async {
    final ok = await Get.defaultDialog<bool>(
      title: "Delete Vehicle",
      middleText: "Delete ${v.name}? This cannot be undone.",
      textConfirm: "Delete",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () => Get.back(result: true),
    );
    if (ok == true) await controller.deleteVehicle(v.id);
  }

  Future<void> _showReportDialog(Vehicle v) async {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final res = await Get.defaultDialog<String>(
      title: "Report Issue",
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Describe the problem…",
            border: OutlineInputBorder(),
          ),
          validator: (t) => t!.trim().isEmpty ? "Required" : null,
        ),
      ),
      textConfirm: "Submit",
      textCancel: "Cancel",
      onConfirm: () {
        if (formKey.currentState!.validate())
          Get.back(result: ctrl.text.trim());
      },
    );
    if (res != null && res.isNotEmpty) await controller.reportIssue(res);
    ctrl.dispose();
  }

  Future<void> _confirmEndRide() async {
    final ok = await Get.defaultDialog<bool>(
      title: "End Ride",
      middleText: "End your current ride and free the vehicle?",
      textConfirm: "End Ride",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () => Get.back(result: true),
    );
    if (ok == true) await controller.endCurrentRide();
  }
}
