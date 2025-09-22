import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:driver_tracker_app/data/models/models.dart';
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
            onPressed: () => authController.logout(),
          ),
        ],
      ),
      body: Obx(() {
        // PURE admin / manager list – no driver branches
        return _adminVehicleList();
      }),
      floatingActionButton:
          authController.userRole.value == 'admin' ||
              authController.userRole.value == 'manager'
          ? FloatingActionButton(
              heroTag: 'addVehicle',
              tooltip: 'Add Vehicle',
              onPressed: () => Get.to(() => AddEditVehicleScreen()),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  /* ----------  ADMIN / MANAGER ONLY LIST  ---------- */
  Widget _adminVehicleList() {
    return controller.vehicles.isEmpty
        ? const Center(child: Text("No vehicles found"))
        : ListView.builder(
            itemCount: controller.vehicles.length,
            itemBuilder: (_, i) {
              final v = controller.vehicles[i];
              final statusColor = controller.getVehicleStatusColor(v);
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
                        'Status: ${controller.getVehicleStatusText(v)}',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'edit') {
                        Get.to(() => AddEditVehicleScreen(vehicleToEdit: v));
                      } else if (val == 'delete') {
                        _confirmDelete(v);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          );
  }

  /* ----------  ADMIN DIALOGS  ---------- */
  Future<void> _confirmDelete(Vehicle v) async {
    final ok = await Get.defaultDialog<bool>(
      title: 'Delete Vehicle',
      middleText: 'Delete ${v.name}? This cannot be undone.',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () => Get.back(result: true),
    );
    if (ok == true) await controller.deleteVehicle(v.id);
  }
}
