import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  final String id;
  final String vehicleId;
  final String driverId;
  final String date; // yyyy-MM-dd  (fast filter)
  final Timestamp startTime;
  final Timestamp? endTime;
  final String status; // on-going | finished | cancelled
  final int? startOdo;
  final int? endOdo;
  final Timestamp createdAt;

  Trip({
    this.id = '',
    required this.vehicleId,
    required this.driverId,
    required this.date,
    required this.startTime,
    this.endTime,
    this.status = 'on-going',
    this.startOdo,
    this.endOdo,
    required this.createdAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json, String id) {
    return Trip(
      id: id,
      vehicleId: json['vehicleId'] ?? '',
      driverId: json['driverId'] ?? '',
      date: json['date'] ?? '',
      startTime: json['startTime'] ?? Timestamp.now(),
      endTime: json['endTime'],
      status: json['status'] ?? 'on-going',
      startOdo: json['startOdo'],
      endOdo: json['endOdo'],
      createdAt: json['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleId': vehicleId,
      'driverId': driverId,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
      'startOdo': startOdo,
      'endOdo': endOdo,
      'createdAt': createdAt,
    };
  }

  /* helpers */
  Duration? get duration => endTime?.toDate().difference(startTime.toDate());

  bool get isOnGoing => status == 'on-going';
  bool get isFinished => status == 'finished';
}
