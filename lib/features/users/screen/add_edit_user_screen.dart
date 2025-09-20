// features/users/screens/add_edit_user_screen.dart
import 'package:driver_tracker_app/features/users/controller/users_controller.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:driver_tracker_app/data/models/user_model.dart' as local;

class AddEditUserScreen extends StatefulWidget {
  final local.User? userToEdit; // Pass null for Add, pass a User for Edit

  const AddEditUserScreen({Key? key, this.userToEdit}) : super(key: key);

  @override
  State<AddEditUserScreen> createState() => _AddEditUserScreenState();
}

class _AddEditUserScreenState extends State<AddEditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late UsersController _usersController;

  // Controllers for form fields
  // UID is NOT controlled by a TextEditingController as it's the document ID
  late TextEditingController _emailController;
  late TextEditingController _nameController;
  late TextEditingController _roleController; // Consider Dropdown
  late TextEditingController _phoneNumberController;
  late TextEditingController _statusController; // Consider Dropdown
  late TextEditingController _assignedVehicleIdController; // Consider picker
  late TextEditingController _passwordController; // Only for Add

  @override
  void initState() {
    super.initState();
    _usersController = Get.find<UsersController>();

    // Initialize controllers with existing data if editing
    // UID is not initialized in a controller as it's not user-editable
    _emailController = TextEditingController(
      text: widget.userToEdit?.email ?? '',
    );
    _nameController = TextEditingController(
      text: widget.userToEdit?.name ?? '',
    );
    _roleController = TextEditingController(
      text: widget.userToEdit?.role ?? 'driver',
    );
    _phoneNumberController = TextEditingController(
      text: widget.userToEdit?.phoneNumber ?? '',
    );
    _statusController = TextEditingController(
      text: widget.userToEdit?.status ?? 'offline',
    );
    _assignedVehicleIdController = TextEditingController(
      text: widget.userToEdit?.assignedVehicleId ?? '',
    );
    _passwordController =
        TextEditingController(); // Initialize password controller
  }

  @override
  void dispose() {
    // Dispose all controllers
    _emailController.dispose();
    _nameController.dispose();
    _roleController.dispose();
    _phoneNumberController.dispose();
    _statusController.dispose();
    _assignedVehicleIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handles saving logic for both Add and Edit
  void _saveUser() async {
    // Make method async
    if (_formKey.currentState!.validate()) {
      final isEditing = widget.userToEdit != null;

      if (isEditing) {
        // --- Update Existing User ---
        // UID comes from the existing user object
        final updatedUser = local.User(
          uid: widget.userToEdit!.uid, // Use existing UID (Document ID)
          email: _emailController.text.trim(),
          name: _nameController.text.trim(),
          role: _roleController.text.trim(),
          phoneNumber: _phoneNumberController.text.trim().isNotEmpty
              ? _phoneNumberController.text.trim()
              : null,
          profileImage: null, // Not handled in this form
          assignedVehicleId: _assignedVehicleIdController.text.trim().isNotEmpty
              ? _assignedVehicleIdController.text.trim()
              : null,
          status: _statusController.text.trim(),
          driverStats: widget.userToEdit?.driverStats,
          assignmentHistory: widget.userToEdit?.assignmentHistory ?? [],
        );

        await _usersController.updateUser(updatedUser);
        // Navigate back after successful update
        if (mounted) Get.back(result: true); // Pass result back if needed
      } else {
        // --- Add New User ---
        // Requires creating Firebase Auth user first
        String email = _emailController.text.trim();
        String password = _passwordController.text.trim();
        String name = _nameController.text.trim();
        String role = _roleController.text.trim();
        String status = _statusController.text.trim();
        String? phoneNumber = _phoneNumberController.text.trim().isNotEmpty
            ? _phoneNumberController.text.trim()
            : null;

        if (password.isEmpty) {
          Get.snackbar(
            "Input Error",
            "Please enter a temporary password for the new user.",
          );
          return;
        }

        try {
          // 1. Create Firebase Auth User (Requires admin privileges on client)
          final firebase_auth.UserCredential userCredential =
              await firebase_auth.FirebaseAuth.instance
                  .createUserWithEmailAndPassword(
                    email: email,
                    password: password,
                  );
          String generatedUid = userCredential.user!.uid;
          print("INFO: Firebase Auth user created with UID: $generatedUid");

          // 2. Create Firestore User Document using the generated UID
          final newUser = local.User(
            uid: generatedUid, // Use the generated UID from Firebase Auth
            email: email,
            name: name,
            role: role,
            phoneNumber: phoneNumber,
            profileImage: null, // Default
            assignedVehicleId: null, // Initially not assigned
            status: status, // Use status from form
            driverStats: null, // Default
            assignmentHistory: [], // Default
          );

          await _usersController.createUser(newUser);
          // Navigate back after successful creation
          if (mounted) {
            Get.snackbar("Success", "User account created successfully.");
            Get.back(result: true); // Pass result back if needed
          }
        } on firebase_auth.FirebaseAuthException catch (e) {
          String message =
              "Failed to create user account in Firebase Authentication.";
          if (e.code == 'email-already-in-use') {
            message = "The email address is already in use by another account.";
          } else if (e.code == 'invalid-email') {
            message = "The email address is invalid.";
          } else if (e.code == 'operation-not-allowed') {
            message = "Email/password accounts are not enabled in Firebase.";
          } else if (e.code == 'weak-password') {
            message = "The password is too weak.";
          }
          // Log the specific error for debugging (don't expose internal errors to UI in production)
          print(
            "FIREBASE_AUTH_ERROR (Create User): Code=${e.code}, Message=${e.message}",
          );
          if (mounted) Get.snackbar("Auth Error", message);
        } catch (e) {
          // Catch any other unexpected errors during the process
          print("UNEXPECTED_ERROR (Create User): $e");
          if (mounted)
            Get.snackbar(
              "Error",
              "An unexpected error occurred while creating the user: $e",
            );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.userToEdit != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit User' : 'Add New User'),
        // Optional: Add a save icon button in the AppBar
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.save),
        //     onPressed: _saveUser,
        //   ),
        // ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Assign the form key
          child: ListView(
            children: [
              // --- UID Display (Read-only, only shown when editing) ---
              if (isEditing)
                TextFormField(
                  initialValue:
                      widget.userToEdit?.uid ??
                      'Unknown UID', // Show UID if editing
                  enabled: false, // Make it non-editable
                  decoration: InputDecoration(
                    labelText: 'User UID (Auto-generated by Firebase Auth)',
                    helperText:
                        'This ID is managed by the system and cannot be changed.',
                  ),
                ),

              // --- Password Field (Only for Adding New Users) ---
              if (!isEditing)
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Temporary Password *',
                    hintText: 'Enter a strong temporary password',
                  ),
                  obscureText: true, // Hide password input
                  validator: (value) {
                    if (!isEditing && (value == null || value.isEmpty)) {
                      return 'Please enter a temporary password';
                    }
                    // Optional: Add password strength validation
                    // if (value!.length < 6) {
                    //   return 'Password must be at least 6 characters';
                    // }
                    return null;
                  },
                ),

              // --- Email Field ---
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email *'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  // Basic email validation
                  if (!GetUtils.isEmail(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),

              // --- Name Field ---
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name *'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),

              // --- Role Field ---
              // Consider using DropdownButtonFormField for predefined roles (admin, manager, driver)
              TextFormField(
                controller: _roleController,
                decoration: InputDecoration(
                  labelText: 'Role *',
                  helperText: 'e.g., admin, manager, driver',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a role';
                  }
                  // Optional: Validate against known roles
                  // List<String> validRoles = ['admin', 'manager', 'driver'];
                  // if (!validRoles.contains(value.toLowerCase())) {
                  //   return 'Role must be admin, manager, or driver';
                  // }
                  return null;
                },
              ),

              // --- Phone Number Field ---
              TextFormField(
                controller: _phoneNumberController,
                decoration: InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),

              // --- Status Field ---
              // Consider using DropdownButtonFormField (active, offline, onRide)
              TextFormField(
                controller: _statusController,
                decoration: InputDecoration(
                  labelText: 'Status *',
                  helperText: 'e.g., active, offline, onRide',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a status';
                  }
                  return null;
                },
              ),

              // --- Assigned Vehicle ID Field (Optional, mainly for drivers) ---
              TextFormField(
                controller: _assignedVehicleIdController,
                decoration: InputDecoration(
                  labelText: 'Assigned Vehicle ID',
                  helperText: 'Leave blank if not assigned. For drivers only.',
                ),
              ),

              // --- Spacer ---
              const SizedBox(height: 20),

              // --- Save Button ---
              Obx(
                () => ElevatedButton(
                  onPressed: _usersController.isProcessing.value
                      ? null // Disable button while processing
                      : _saveUser, // Call the save logic
                  child: _usersController.isProcessing.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditing ? 'Update User' : 'Create User'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
