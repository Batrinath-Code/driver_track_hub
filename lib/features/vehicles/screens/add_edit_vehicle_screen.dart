// features/vehicles/screens/add_edit_vehicle_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:driver_tracker_app/data/models/vehicle_model.dart';
import 'package:driver_tracker_app/features/vehicles/controllers/vehicles_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp

class AddEditVehicleScreen extends StatefulWidget {
  final Vehicle? vehicleToEdit; // Pass null for Add, pass a Vehicle for Edit

  const AddEditVehicleScreen({Key? key, this.vehicleToEdit}) : super(key: key);

  @override
  State<AddEditVehicleScreen> createState() => _AddEditVehicleScreenState();
}

class _AddEditVehicleScreenState extends State<AddEditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  late VehiclesController _vehiclesController;

  // Controllers for form fields
  late TextEditingController _nameController;
  late TextEditingController _regNumberController;
  late TextEditingController _carColorController;
  late TextEditingController _statusController; // Consider using Dropdown
  // Add controllers for other fields as needed (imageUrl, etc.)

  @override
  void initState() {
    super.initState();
    _vehiclesController =
        Get.find<VehiclesController>(); // Get the controller instance

    // Initialize controllers with existing data if editing
    _nameController = TextEditingController(
      text: widget.vehicleToEdit?.name ?? '',
    );
    _regNumberController = TextEditingController(
      text: widget.vehicleToEdit?.regNumber ?? '',
    );
    _carColorController = TextEditingController(
      text: widget.vehicleToEdit?.carColor ?? '',
    );
    _statusController = TextEditingController(
      text: widget.vehicleToEdit?.status ?? 'idle',
    );
    // Initialize other controllers...
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regNumberController.dispose();
    _carColorController.dispose();
    _statusController.dispose();
    // Dispose other controllers...
    super.dispose();
  }

  void _saveVehicle() {
    if (_formKey.currentState!.validate()) {
      // Create a Vehicle object from form data
      // Use widget.vehicleToEdit?.id for edit, '' for new (Firestore generates ID)
      final vehicle = Vehicle(
        id: widget.vehicleToEdit?.id ?? '',
        name: _nameController.text.trim(),
        carColor: _carColorController.text.trim(),
        imageUrl: '', // Add logic for image URL if needed
        mainImageUrl: '',
        regNumber: _regNumberController.text.trim(),
        status: _statusController.text.trim(),
        currentDriverId: widget
            .vehicleToEdit
            ?.currentDriverId, // Keep existing driver if any?
        lastLocation:
            widget.vehicleToEdit?.lastLocation, // Keep existing location?
        // Use server timestamp for new vehicles, or keep existing for edit?
        lastUpdated: Timestamp.now(), // This will be updated by server anyway
        currentMaintenance: widget.vehicleToEdit?.currentMaintenance,
        assignmentHistory: widget.vehicleToEdit?.assignmentHistory ?? [],
        maintenanceRecordIds: widget.vehicleToEdit?.maintenanceRecordIds ?? [],
        issueRecordIds: widget.vehicleToEdit?.issueRecordIds ?? [],
      );

      if (widget.vehicleToEdit == null) {
        // Add new vehicle
        // _vehiclesController.createVehicle(vehicle);
      } else {
        // Update existing vehicle
        // _vehiclesController.updateVehicle(vehicle);
      }

      // Navigate back
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.vehicleToEdit != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Vehicle' : 'Add New Vehicle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Vehicle Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a vehicle name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _regNumberController,
                decoration: InputDecoration(labelText: 'Registration Number'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter registration number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _carColorController,
                decoration: InputDecoration(labelText: 'Color'),
              ),
              TextFormField(
                controller: _statusController,
                decoration: InputDecoration(
                  labelText: 'Status (idle, active, underMaintenance)',
                ),
              ),
              // Add fields for imageUrl, etc. as needed
              // Consider using DropdownButtonFormField for status
              SizedBox(height: 20),
              Obx(
                () => ElevatedButton(
                  onPressed: _vehiclesController.isProcessing.value
                      ? null
                      : _saveVehicle,
                  child: _vehiclesController.isProcessing.value
                      ? CircularProgressIndicator()
                      : Text(isEditing ? 'Update Vehicle' : 'Add Vehicle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
