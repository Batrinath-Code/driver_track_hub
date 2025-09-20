// data/models/vehicle_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Vehicle {
  final String id;
  final String name;
  final String carColor;
  final String imageUrl;
  final String mainImageUrl;
  final String regNumber;
  final String status; // idle, active, underMaintenance
  final String? currentDriverId;
  final Map<String, dynamic>? lastLocation; // {latitude: ..., longitude: ...}
  final Timestamp lastUpdated;
  final Map<String, dynamic>?
  currentMaintenance; // {issue: ..., startDate: ..., estimatedEndDate: ..., status: ...}
  final List<String> assignmentHistory; // List of driver IDs
  final List<String> maintenanceRecordIds; // List of maintenance record IDs
  final List<String> issueRecordIds; // List of issue record IDs

  Vehicle({
    required this.id,
    required this.name,
    required this.carColor,
    required this.imageUrl,
    required this.mainImageUrl,
    required this.regNumber,
    required this.status,
    this.currentDriverId,
    this.lastLocation,
    required this.lastUpdated,
    this.currentMaintenance,
    required this.assignmentHistory,
    required this.maintenanceRecordIds,
    required this.issueRecordIds,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json, [String? id]) {
    return Vehicle(
      id: id ?? json['id'] ?? '',
      name: json['name'] ?? '',
      carColor: json['carColor'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      mainImageUrl: json['mainImageUrl'] ?? '',
      regNumber: json['regNumber'] ?? '',
      status: json['status'] ?? 'idle',
      currentDriverId: json['currentDriverId'],
      lastLocation: json['lastLocation'] is Map ? json['lastLocation'] : null,
      lastUpdated: json['lastUpdated'] ?? Timestamp.now(),
      currentMaintenance: json['currentMaintenance'] is Map
          ? json['currentMaintenance']
          : null,
      assignmentHistory: List<String>.from(json['assignmentHistory'] ?? []),
      maintenanceRecordIds: List<String>.from(
        json['maintenanceRecordIds'] ?? [],
      ),
      issueRecordIds: List<String>.from(json['issueRecordIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'carColor': carColor,
      'imageUrl': imageUrl,
      'mainImageUrl': mainImageUrl,
      'regNumber': regNumber,
      'status': status,
      'currentDriverId': currentDriverId,
      'lastLocation': lastLocation,
      'lastUpdated': lastUpdated,
      'currentMaintenance': currentMaintenance,
      'assignmentHistory': assignmentHistory,
      'maintenanceRecordIds': maintenanceRecordIds,
      'issueRecordIds': issueRecordIds,
    };
  }

  @override
  String toString() {
    return 'Vehicle(id: $id, name: $name, regNumber: $regNumber, status: $status, currentDriverId: $currentDriverId)';
  }
}
