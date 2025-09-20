import 'package:cloud_firestore/cloud_firestore.dart';

class Ride {
  final String id;
  final String driverId;
  final String vehicleId;
  final DateTime startTime;
  final DateTime? endTime;
  final GeoPoint startLocation;
  final GeoPoint? endLocation;

  final String status; // active, completed, cancelled
  final List<Map<String, dynamic>>? locations; // optional GPS logs

  Ride({
    required this.id,
    required this.driverId,
    required this.vehicleId,
    required this.startTime,
    this.endTime,
    required this.status,
    this.locations,
    required this.startLocation,
    this.endLocation,
  });

  factory Ride.fromJson(Map<String, dynamic> json, [String? id]) {
    return Ride(
      id: id ?? '',
      driverId: json['driverId'],
      vehicleId: json['vehicleId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      status: json['status'],
      locations: json['locations'] != null
          ? List<Map<String, dynamic>>.from(json['locations'])
          : null,

      startLocation: GeoPoint(
        json['startLocation']['latitude'],
        json['startLocation']['longitude'],
      ),

      endLocation: json['endLocation'] != null
          ? GeoPoint(
              json['endLocation']['latitude'],
              json['endLocation']['longitude'],
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'vehicleId': vehicleId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'status': status,
      'locations': locations,
      'startLocation': {
        'latitude': startLocation.latitude,
        'longitude': startLocation.longitude,
      },
      'endLocation': endLocation != null
          ? {
              'latitude': endLocation!.latitude,
              'longitude': endLocation!.longitude,
            }
          : null,
    };
  }
}
