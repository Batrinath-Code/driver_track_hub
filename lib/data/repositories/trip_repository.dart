import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_tracker_app/data/models/trip_model.dart';

class TripRepository {
  final CollectionReference _trips = FirebaseFirestore.instance.collection(
    'trips',
  );

  /* ----------  READ  ---------- */
  /// Stream of trips for a single calendar day (yyyy-MM-dd UTC).
  /// If [day] is null → today UTC.
  Stream<List<Trip>> getTripsStream({DateTime? day}) {
    final dateStr = (day ?? DateTime.now().toUtc())
        .toIso8601String()
        .split('T')
        .first; // yyyy-MM-dd UTC

    return _trips
        .where('date', isEqualTo: dateStr)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) =>
                    Trip.fromJson(doc.data() as Map<String, dynamic>, doc.id),
              )
              .toList(),
        );
  }

  /// Single trip by id.
  Future<Trip?> getTrip(String tripId) async {
    final doc = await _trips.doc(tripId).get();
    if (!doc.exists) return null;
    return Trip.fromJson(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// Any on-going trip for this driver (max 1).
  Future<Trip?> getOnGoingTrip(String driverId) async {
    final snap = await _trips
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'on-going')
        .limit(1)
        .get();
    return snap.docs.isEmpty
        ? null
        : Trip.fromJson(
            snap.docs.first.data() as Map<String, dynamic>,
            snap.docs.first.id,
          );
  }

  /* ----------  WRITE  ---------- */
  /// Creates a new trip and returns its Firestore id.
  Future<String> startTrip({
    required String vehicleId,
    required String driverId,
    int? startOdo,
  }) async {
    final now = Timestamp.now();
    final dateStr = DateTime.now().toUtc().toIso8601String().split('T').first;

    final doc = await _trips.add({
      'vehicleId': vehicleId,
      'driverId': driverId,
      'date': dateStr,
      'startTime': now,
      'status': 'on-going',
      'startOdo': startOdo,
      'createdAt': now,
    });
    log('Trip started  ${doc.id}');
    return doc.id;
  }

  /// Finishes a trip and optionally stores ending odometer.
  Future<void> endTrip(String tripId, {int? endOdo}) async {
    await _trips.doc(tripId).update({
      'status': 'finished',
      'endTime': FieldValue.serverTimestamp(),
      if (endOdo != null) 'endOdo': endOdo,
    });
    log('Trip finished $tripId');
  }

  /// Finish trip + assign driver + create trip in ONE transaction.
  Future<String> createTripAndAssign({
    required String vehicleId,
    required String driverId,
    int? startOdo,
  }) async {
    final fire = FirebaseFirestore.instance;
    return fire.runTransaction((tx) async {
      final vehicleRef = fire.collection('vehicles').doc(vehicleId);
      final userRef = fire.collection('users').doc(driverId);

      final vSnap = await tx.get(vehicleRef);
      final uSnap = await tx.get(userRef);
      if (!vSnap.exists || !uSnap.exists) {
        throw Exception('Vehicle or driver not found');
      }
      if (vSnap.data()?['status'] != 'idle') {
        throw Exception('Vehicle is not idle');
      }

      tx.update(vehicleRef, {
        'currentDriverId': driverId,
        'status': 'active',
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      tx.update(userRef, {'assignedVehicleId': vehicleId, 'status': 'onRide'});

      final now = Timestamp.now();
      final dateStr =
          '${now.toDate().year}-${now.toDate().month.toString().padLeft(2, '0')}-${now.toDate().day.toString().padLeft(2, '0')}';

      final tripRef = fire.collection('trips').doc();
      tx.set(tripRef, {
        'vehicleId': vehicleId,
        'driverId': driverId,
        'date': dateStr,
        'startTime': now,
        'status': 'on-going',
        'startOdo': startOdo,
        'createdAt': now,
      });

      return tripRef.id;
    });
  }

  /// Creates a vehicle_issues record.
  Future<String?> reportVehicleIssue({
    required String vehicleId,
    required String reportedByUserId,
    required String description,
  }) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('vehicle_issues')
          .add({
            'vehicleId': vehicleId,
            'reportedBy': reportedByUserId,
            'description': description.trim(),
            'reportedDate': FieldValue.serverTimestamp(),
            'status': 'reported',
          });
      return doc.id;
    } catch (e) {
      log('reportVehicleIssue error: $e');
      return null;
    }
  }

  /// Finish trip + maintenance + free driver atomically.
  Future<void> finishTripAndMaintenance({
    required String tripId,
    required String vehicleId,
    required String driverId,
    int? endOdo,
    String issueDesc = '',
  }) async {
    final fire = FirebaseFirestore.instance;
    return fire.runTransaction((tx) async {
      final now = Timestamp.now();

      /* 1.  finish the trip  */
      tx.update(fire.collection('trips').doc(tripId), {
        'status': 'finished',
        'endTime': now,
        if (endOdo != null) 'endOdo': endOdo,
      });

      /* 2.  vehicle → maintenance  */
      tx.update(fire.collection('vehicles').doc(vehicleId), {
        'status': 'underMaintenance',
        'currentDriverId': FieldValue.delete(),
        'lastUpdated': now,
      });

      /* 3.  free the driver  */
      tx.update(fire.collection('users').doc(driverId), {
        'assignedVehicleId': FieldValue.delete(),
        'status': 'active',
      });
    });
  }
}
