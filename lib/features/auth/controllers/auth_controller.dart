// features/auth/controllers/auth_controller.dart
import 'dart:developer' as developer; // Import for developer.log
import 'package:driver_tracker_app/features/vehicles/controllers/vehicles_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  var firebaseUser = Rx<User?>(null);
  var userRole = ''.obs; // Starts empty
  var userName = ''.obs;
  var userUid = ''.obs;
  var isLoading = false.obs;

  User? get currentUser => firebaseUser.value;

  @override
  void onInit() {
    super.onInit();
    developer.log("AuthController: onInit called");
    _auth.authStateChanges().listen((User? user) {
      developer.log(
        "AuthController: authStateChanges listener triggered. User: ${user?.uid ?? 'null'}",
      );
      firebaseUser.value = user;
      if (user != null) {
        developer.log(
          "AuthController: User is signed in (${user.uid}), fetching user data...",
        );
        _fetchUserData(user.uid); // Fetch Firestore data when user logs in
      } else {
        developer.log(
          "AuthController: User is signed out, clearing user data...",
        );
        _clearUserData();
        if (Get.currentRoute != '/login') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Get.currentRoute != '/login') {
              Get.offAllNamed('/login');
            }
          });
        }
      }
    });
  }

  Future<void> _fetchUserData(String uid) async {
    try {
      isLoading(true);
      developer.log(
        "AuthController: Starting to fetch user data for UID: $uid",
      );
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic>? userData =
            userDoc.data() as Map<String, dynamic>?;
        if (userData != null) {
          // --- CRUCIAL: Ensure userRole is set BEFORE navigation ---
          String fetchedRole =
              userData['role'] ?? 'driver'; // Default to 'driver' if missing
          userRole.value = fetchedRole;
          userName.value = userData['name'] ?? 'Unknown User';
          userUid.value = uid;

          developer.log(
            "AuthController: User data fetched successfully. UID: $uid, Name: ${userName.value}, Role: ${userRole.value}",
          );

          // --- Call navigation function HERE, AFTER userRole is set ---
          _navigateBasedOnRole(userRole.value);
        } else {
          developer.log(
            "AuthController: Warning: User data for $uid is null/empty.",
          );
          // Set defaults even in error case to avoid undefined state
          _setDefaultsAndNavigate();
        }
      } else {
        developer.log(
          "AuthController: Error: User document for UID $uid does not exist in Firestore.",
        );
        // Set defaults even if doc missing
        _setDefaultsAndNavigate();
        // Consider: Get.snackbar("Error", "User data not found.");
        // await logout(); // Maybe logout if user doc is missing?
      }
    } catch (e) {
      developer.log(
        "AuthController: Error fetching user data for UID $uid: $e",
      );
      // Set defaults even on fetch error
      _setDefaultsAndNavigate();
      // Consider navigating to login on fetch error
      // Get.offAllNamed('/login');
    } finally {
      isLoading(false);
    }
  }

  // Helper to set defaults and navigate if user data fetch fails/is incomplete
  void _setDefaultsAndNavigate() {
    userRole.value = 'driver'; // Or 'none' or handle error state differently
    userName.value = 'Unknown User';
    userUid.value = '';
    developer.log(
      "AuthController: Setting default role 'driver' due to data issue and navigating.",
    );
    _navigateBasedOnRole(userRole.value); // Navigate with default
  }

  void _clearUserData() {
    userRole.value = '';
    userName.value = '';
    userUid.value = '';
    developer.log("AuthController: User data cleared.");
    // Navigation handled by the authStateChanges listener
  }

  void _navigateBasedOnRole(String role) {
    developer.log("AuthController: Navigating based on role: '$role'");
    Future.microtask(() {
      Get.offAllNamed('/dashboard');
    });
  }

  Future<void> login() async {
    try {
      isLoading(true);
      developer.log(
        "AuthController: Attempting login with email: ${emailCtrl.text}",
      );
      await _auth.signInWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text.trim(),
      );
      // Success logic (navigation, clearing fields) is now handled by
      // the authStateChanges listener and _fetchUserData
      emailCtrl.clear();
      passwordCtrl.clear();
    } on FirebaseAuthException catch (e) {
      developer.log(
        "AuthController: FirebaseAuthException during login: ${e.code} - ${e.message}",
      );
      String message = "Login failed.";
      if (e.code == 'user-not-found') {
        message = "No user found for that email.";
      } else if (e.code == 'wrong-password') {
        message = "Wrong password provided.";
      } else {
        message = e.message ?? "An unknown error occurred.";
      }
      Get.snackbar("Login Error", message);
    } catch (e) {
      developer.log("AuthController: Unexpected error during login: $e");
      // Get.snackbar("Login Failed", e.toString());
    } finally {
      isLoading(false);
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    /*  👇  destroy VehiclesController (and any other)  */
    Get.delete<VehiclesController>(force: true);
    /*  👇  now navigate  */
    Get.offAllNamed('/login');
  }

  @override
  void onClose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }
}
