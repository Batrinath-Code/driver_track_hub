// data/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid; // Document ID is the UID
  final String email;
  final String name;
  final String role; // admin, driver, manager
  final String? phoneNumber;
  final String? profileImage;
  final String? assignedVehicleId; // For drivers
  final String status; // active, offline, onRide
  final Map<String, dynamic>?
  driverStats; // {totalRides, totalDistance, completedMaintenance, rating}
  final List<String> assignmentHistory; // List of vehicle IDs

  User({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.phoneNumber,
    this.profileImage,
    this.assignedVehicleId,
    required this.status,
    this.driverStats,
    required this.assignmentHistory,
  });

  factory User.fromJson(Map<String, dynamic> json, [String? uid]) {
    // The UID is usually the document ID, but we can accept it as a parameter too
    String userId = uid ?? json['uid'] ?? '';

    return User(
      uid: userId,
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'driver', // Default role
      phoneNumber: json['phoneNumber'],
      profileImage: json['profileImage'],
      assignedVehicleId: json['assignedVehicleId'],
      status: json['status'] ?? 'offline', // Default status
      driverStats: json['driverStats'] is Map ? json['driverStats'] : null,
      assignmentHistory: List<String>.from(json['assignmentHistory'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'assignedVehicleId': assignedVehicleId,
      'status': status,
      'driverStats': driverStats,
      'assignmentHistory': assignmentHistory,
    };
  }
}
