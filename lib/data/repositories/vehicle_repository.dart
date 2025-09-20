// data/repositories/vehicle_repository.dart
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_tracker_app/data/models/vehicle_model.dart';
import 'package:firebase_core/firebase_core.dart'; // For FirebaseException

class VehicleRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _vehiclesCollection = FirebaseFirestore.instance
      .collection('vehicles');

  // --- Modified/Added Stream Methods ---

  /// Gets a stream of ALL vehicles.
  Stream<List<Vehicle>> getVehiclesStream() {
    try {
      return _vehiclesCollection.snapshots().map(
        (snapshot) => snapshot.docs
            .map(
              (doc) =>
                  Vehicle.fromJson(doc.data() as Map<String, dynamic>, doc.id),
            )
            .toList(),
      );
    } catch (e) {
      log("Error getting vehicles stream: $e");
      return Stream.value([]); // Or rethrow e;
    }
  }

  /// Gets a stream of IDLE vehicles only.
  /// Useful for screens where drivers select a vehicle.
  Stream<List<Vehicle>> getIdleVehiclesStream() {
    try {
      return _vehiclesCollection
          .where('status', isEqualTo: 'idle')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(
                  (doc) => Vehicle.fromJson(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ),
                )
                .toList(),
          );
    } catch (e) {
      log("Error getting idle vehicles stream: $e");
      return Stream.value([]); // Or rethrow e;
    }
  }

  // --- Modified CRUD and Assignment Methods ---

  Future<Vehicle?> getVehicleById(String vehicleId) async {
    try {
      DocumentSnapshot doc = await _vehiclesCollection.doc(vehicleId).get();
      if (doc.exists) {
        return Vehicle.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null; // Vehicle not found
    } catch (e) {
      log("Error getting vehicle by ID '$vehicleId': $e");
      return null; // Or rethrow e;
    }
  }

  // Example: Update vehicle status (e.g., put under maintenance)
  // Requires admin/manager role based on security rules
  Future<void> updateVehicleStatus(String vehicleId, String newStatus) async {
    try {
      // Update status and lastUpdated timestamp
      await _vehiclesCollection.doc(vehicleId).update({
        'status': newStatus,
        'lastUpdated': FieldValue.serverTimestamp(), // Update timestamp
      });
      log("Vehicle status updated for ID '$vehicleId' to '$newStatus'.");
    } catch (e) {
      log("Error updating vehicle status for ID '$vehicleId': $e");
      rethrow;
    }
  }

  // Create a new vehicle
  // Requires admin/manager role (enforced by security rules)
  Future<String?> createVehicle(Vehicle vehicle) async {
    try {
      final vehicleData = vehicle.toJson();
      vehicleData.remove('id'); // Firestore generates the document ID

      DocumentReference docRef = await _vehiclesCollection.add(vehicleData);
      log("Vehicle created with ID: ${docRef.id}");
      return docRef.id; // Return the generated ID
    } on FirebaseException catch (e) {
      log("Firebase error creating vehicle: ${e.message}");
      rethrow;
    } catch (e) {
      log("Error creating vehicle: $e");
      return null;
    }
  }

  // Update an existing vehicle
  // Requires admin/manager role (enforced by security rules)
  // Note: This update does not automatically change 'lastUpdated'.
  // If 'lastUpdated' should always change on *any* update, add it here.
  Future<bool> updateVehicle(Vehicle vehicle) async {
    try {
      final vehicleData = vehicle.toJson();
      vehicleData.remove('id'); // 'id' is the document ID, not a field

      await _vehiclesCollection.doc(vehicle.id).update(vehicleData);
      log("Vehicle updated with ID: ${vehicle.id}");
      return true;
    } on FirebaseException catch (e) {
      log("Firebase error updating vehicle '${vehicle.id}': ${e.message}");
      rethrow;
    } catch (e) {
      log("Error updating vehicle '${vehicle.id}': $e");
      return false;
    }
  }

  // Delete a vehicle
  // Requires admin/manager role (enforced by security rules)
  Future<bool> deleteVehicle(String vehicleId) async {
    try {
      await _vehiclesCollection.doc(vehicleId).delete();
      log("Vehicle deleted with ID: $vehicleId");
      return true;
    } on FirebaseException catch (e) {
      log("Firebase error deleting vehicle '$vehicleId': ${e.message}");
      rethrow;
    } catch (e) {
      log("Error deleting vehicle '$vehicleId': $e");
      return false;
    }
  }

  /// Assigns a driver to a vehicle using a Firestore Transaction.
  /// Ensures data consistency and validates schema pre-conditions.
  Future<void> assignDriverToVehicle(
    String vehicleId,
    String driverUserId,
  ) async {
    final FirebaseFirestore db = _firestore;

    return db.runTransaction((transaction) async {
      // 1. Get Document References
      DocumentReference vehicleRef = db.collection('vehicles').doc(vehicleId);
      DocumentReference userRef = db.collection('users').doc(driverUserId);
      CollectionReference assignmentsRef = db.collection('driver_assignments');

      // 2. Get latest snapshots within the transaction
      DocumentSnapshot vehicleSnapshot = await transaction.get(vehicleRef);
      DocumentSnapshot userSnapshot = await transaction.get(userRef);

      // 3. Validate Existence
      if (!vehicleSnapshot.exists) {
        throw Exception("Vehicle with ID '$vehicleId' not found.");
      }
      if (!userSnapshot.exists) {
        throw Exception("User with ID '$driverUserId' not found.");
      }

      // 4. Cast Data
      Map<String, dynamic> vehicleData =
          vehicleSnapshot.data() as Map<String, dynamic>;
      Map<String, dynamic> userData =
          userSnapshot.data() as Map<String, dynamic>;
      Vehicle vehicle = Vehicle.fromJson(vehicleData, vehicleId);
      // User user = User.fromJson(userData, driverUserId); // If needed

      // 5. Validate Schema Rules & Pre-conditions

      // --- Check Driver Assignment (Enforce one vehicle per driver) ---
      // This was checked twice, removing the duplicate.
      String? currentAssignedVehicleId = userData['assignedVehicleId'];
      if (currentAssignedVehicleId != null &&
          currentAssignedVehicleId.isNotEmpty) {
        throw Exception(
          "Cannot assign vehicle: Driver '$driverUserId' is already assigned to vehicle '$currentAssignedVehicleId'.",
        );
      }

      // Check Vehicle Status
      if (vehicle.status == 'underMaintenance') {
        throw Exception(
          "Cannot assign vehicle: Vehicle '$vehicleId' is currently under maintenance.",
        );
      }
      if (vehicle.status != 'idle') {
        throw Exception(
          "Cannot assign vehicle: Vehicle '$vehicleId' is not idle (Status: ${vehicle.status}).",
        );
      }

      // Check Vehicle Assignment (Enforce one driver per vehicle)
      if (vehicle.currentDriverId != null &&
          vehicle.currentDriverId!.isNotEmpty) {
        throw Exception(
          "Cannot assign vehicle: Vehicle '$vehicleId' is already assigned to driver '${vehicle.currentDriverId}'.",
        );
      }

      // 6. Prepare Updates
      final Timestamp now = Timestamp.now(); // Consider serverTimestamp

      // 7. Perform Updates within the transaction
      // a. Update the Vehicle document
      transaction.update(vehicleRef, {
        'currentDriverId': driverUserId,
        'status': 'active',
        'assignmentHistory': FieldValue.arrayUnion([driverUserId]),
        'lastUpdated': now, // Update lastUpdated timestamp
      });

      // b. Update the User document
      transaction.update(userRef, {
        'assignedVehicleId': vehicleId,
        'status': 'onRide',
        'assignmentHistory': FieldValue.arrayUnion([vehicleId]),
      });

      // c. Create a new record in driver_assignments collection
      DocumentReference newAssignmentRef = assignmentsRef.doc();
      Map<String, dynamic> newAssignmentData = {
        'id': newAssignmentRef.id,
        'driverId': driverUserId,
        'vehicleId': vehicleId,
        'assignedDate': now,
        'endDate': null,
        'isActive': true,
      };
      transaction.set(newAssignmentRef, newAssignmentData);

      log(
        "Successfully assigned driver '$driverUserId' to vehicle '$vehicleId' within transaction.",
      );
    });
  }

  // --- New Methods for Driver Actions (Subject to Security Rules) ---

  /// Ends the current ride/assignment for a driver.
  /// Updates vehicle, user, and driver_assignments documents atomically.
  /// Assumes the assignment is valid and active.
  Future<void> endRideAndAssignment({
    required String vehicleId,
    required String driverUserId,
  }) async {
    final FirebaseFirestore db = _firestore;

    return db.runTransaction((transaction) async {
      // 1. Get Document References
      DocumentReference vehicleRef = db.collection('vehicles').doc(vehicleId);
      DocumentReference userRef = db.collection('users').doc(driverUserId);
      // Need to find the active assignment record
      QuerySnapshot assignmentSnapshot = await db
          .collection('driver_assignments')
          .where('driverId', isEqualTo: driverUserId)
          .where('vehicleId', isEqualTo: vehicleId)
          .where('isActive', isEqualTo: true)
          .get();

      // 2. Validate Existence
      if (assignmentSnapshot.docs.isEmpty) {
        throw Exception(
          "Active assignment record not found for driver '$driverUserId' and vehicle '$vehicleId'.",
        );
      }
      if (assignmentSnapshot.docs.length > 1) {
        // Data inconsistency based on schema rules
        throw Exception(
          "Multiple active assignment records found for driver '$driverUserId' and vehicle '$vehicleId'. Data inconsistency.",
        );
      }
      DocumentReference assignmentRef = assignmentSnapshot.docs.first.reference;

      // 3. Perform Updates within the transaction
      final Timestamp now = Timestamp.now();

      // a. Update the Vehicle document
      transaction.update(vehicleRef, {
        'currentDriverId': FieldValue.delete(), // Remove driver ID
        'status': 'idle', // Set vehicle status back to idle
        'lastUpdated': now,
        // Optionally clear lastLocation or keep it
      });

      // b. Update the User document
      transaction.update(userRef, {
        'assignedVehicleId': FieldValue.delete(), // Remove vehicle ID
        'status': 'active', // Set user status back to active
      });

      // c. Update the driver_assignments record to end it
      transaction.update(assignmentRef, {'endDate': now, 'isActive': false});

      log(
        "Successfully ended ride/assignment for driver '$driverUserId' and vehicle '$vehicleId' within transaction.",
      );
    });
  }

  /// Creates a new vehicle_issues record.
  Future<String?> reportVehicleIssue({
    required String vehicleId,
    required String reportedByUserId, // Should be the driver's UID
    required String description,
  }) async {
    try {
      final CollectionReference issuesCollection = _firestore.collection(
        'vehicle_issues',
      );

      final Timestamp now = Timestamp.now();
      final issueData = {
        // 'id' will be generated by Firestore
        'vehicleId': vehicleId,
        'reportedBy': reportedByUserId,
        'description': description.trim(),
        'reportedDate': now,
        'status': 'reported', // Default status
        // 'resolvedDate': null, // Implicitly null
        // 'assignedTo': null, // Implicitly null
        // 'resolution': null, // Implicitly null
      };

      DocumentReference newIssueRef = await issuesCollection.add(issueData);
      log("Vehicle issue reported successfully with ID: ${newIssueRef.id}");
      // Consider updating vehicle's issueRecordIds array if strictly required by schema
      // For now, relying on queries by vehicleId is sufficient.
      return newIssueRef.id; // Return the ID of the created issue
    } on FirebaseException catch (e) {
      log("Firebase error reporting vehicle issue: ${e.message}");
      rethrow;
    } catch (e) {
      log("Error reporting vehicle issue: $e");
      return null;
    }
  }

  Future<bool> markVehicleUnderMaintenance(String vehicleId) async {
    try {
      // This update will be denied by current security rules if called by a driver
      await _vehiclesCollection.doc(vehicleId).update({
        'status': 'underMaintenance',
        'lastUpdated': FieldValue.serverTimestamp(),
        // Optionally, populate currentMaintenance map if structure is known
        // 'currentMaintenance': { ... }
      });
      log("Vehicle '$vehicleId' marked as underMaintenance.");
      return true;
    } on FirebaseException catch (e) {
      log(
        "Firebase error marking vehicle '$vehicleId' under maintenance: ${e.message}",
      );
      // This is where you'll see "The caller does not have permission..." if rules haven't changed
      if (e.code == 'permission-denied') {
        log(
          "Permission denied for marking vehicle '$vehicleId' under maintenance. Security rules likely need updating.",
        );
      }
      rethrow;
    } catch (e) {
      log("Error marking vehicle '$vehicleId' under maintenance: $e");
      return false;
    }
  }
}
