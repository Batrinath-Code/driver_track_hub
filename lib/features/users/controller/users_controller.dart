// features/users/controllers/users_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:driver_tracker_app/data/models/user_model.dart' as local;
import 'package:driver_tracker_app/data/repositories/user_repository.dart';
import 'dart:developer' as developer;

class UsersController extends GetxController {
  final UserRepository _repository = UserRepository();

  var users = <local.User>[].obs;
  var isLoading = true.obs;
  var isProcessing = false.obs; // For add/edit/delete operations

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  void fetchUsers() async {
    try {
      isLoading(true);
      _repository.getUsersStream().listen(
        (userList) {
          users.assignAll(userList);
          isLoading(false);
        },
        onError: (error) {
          developer.log("Stream error fetching users: $error");
          isLoading(false);
          Get.snackbar(
            "Error",
            "Failed to load users.",
            backgroundColor: Get.theme.colorScheme.error,
            colorText: Get.theme.colorScheme.onError,
          );
        },
      );
    } catch (e) {
      developer.log("Error fetching users: $e");
      isLoading(false);
      Get.snackbar(
        "Error",
        "Failed to load users.",
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  local.User? getUserById(String uid) {
    try {
      return users.firstWhere((user) => user.uid == uid);
    } catch (e) {
      developer.log("User with UID $uid not found in local list.");
      return null;
    }
  }

  // --- CRUD Operations ---

  Future<void> createUser(local.User newUser) async {
    try {
      isProcessing(true);

      // Optional: Check if Firebase Auth user exists (complex client-side)
      // bool authUserExists = await _repository.doesAuthUserExist(newUser.email);
      // if (!authUserExists) {
      //   Get.snackbar("Error", "Firebase Auth user with this email does not exist. Create Auth user first.");
      //   return;
      // }

      bool success = await _repository.createUser(newUser);
      if (success) {
        // fetchUsers(); // Stream should update the list
        Get.snackbar(
          "Success",
          "User created successfully.",
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );
      } else {
        Get.snackbar(
          "Error",
          "Failed to create user.",
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      }
    } catch (e) {
      developer.log("Controller error creating user: $e");
      Get.snackbar(
        "Error",
        "Failed to create user: $e",
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isProcessing(false);
    }
  }

  Future<void> updateUser(local.User updatedUser) async {
    try {
      isProcessing(true);
      bool success = await _repository.updateUser(updatedUser);
      if (success) {
        // fetchUsers(); // Stream should update the list
        Get.snackbar(
          "Success",
          "User updated successfully.",
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );
      } else {
        Get.snackbar(
          "Error",
          "Failed to update user.",
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      }
    } catch (e) {
      developer.log("Controller error updating user: $e");
      Get.snackbar(
        "Error",
        "Failed to update user: $e",
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isProcessing(false);
    }
  }

  Future<void> deleteUser(String uid) async {
    // Confirmation dialog is recommended before deleting
    final confirm = await Get.defaultDialog(
      title: "Confirm Delete",
      middleText: "Are you sure you want to delete this user?",
      textConfirm: "Yes",
      textCancel: "No",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () => Get.back(result: true),
      onCancel: () => Get.back(result: false),
    );

    if (confirm == true) {
      try {
        isProcessing(true);
        bool success = await _repository.deleteUserCascade(uid);
        if (success) {
          // fetchUsers(); // Stream should update the list
          Get.snackbar(
            "Success",
            "User deleted successfully.",
            backgroundColor: Get.theme.colorScheme.primary,
            colorText: Get.theme.colorScheme.onPrimary,
          );
        } else {
          Get.snackbar(
            "Error",
            "Failed to delete user.",
            backgroundColor: Get.theme.colorScheme.error,
            colorText: Get.theme.colorScheme.onError,
          );
        }
      } catch (e) {
        developer.log("Controller error deleting user: $e");
        Get.snackbar(
          "Error",
          "Failed to delete user: $e",
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      } finally {
        isProcessing(false);
      }
    }
  }

  // Helper method to create a default/empty User object for adding
  local.User createEmptyUser() {
    // Note: UID usually comes from Firebase Auth. For creation, it might be generated or input.
    // This is a placeholder. In practice, you'd get the UID after creating the Auth user.
    return local.User(
      uid: '', // Will be set after Auth user creation or input
      email: '',
      name: '',
      role: 'driver', // Default role
      phoneNumber: null,
      profileImage: null,
      assignedVehicleId: null,
      status: 'offline', // Default status
      driverStats: null,
      assignmentHistory: [],
    );
  }

  @override
  void onClose() {
    super.onClose();
  }
}
