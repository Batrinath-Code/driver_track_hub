import 'package:cloud_firestore/cloud_firestore.dart';

class Issue {
  final String id;
  final String vehicleId;
  final String reportedBy;
  final String description;
  final Timestamp reportedDate;
  final Timestamp? resolvedDate;
  final String status; // reported | underInvestigation | fixed | dismissed
  final String? assignedTo; // admin/manager id

  Issue({
    this.id = '',
    required this.vehicleId,
    required this.reportedBy,
    required this.description,
    required this.reportedDate,
    this.resolvedDate,
    this.status = 'reported',
    this.assignedTo,
  });

  factory Issue.fromJson(Map<String, dynamic> json, String id) {
    return Issue(
      id: id,
      vehicleId: json['vehicleId'] ?? '',
      reportedBy: json['reportedBy'] ?? '',
      description: json['description'] ?? '',
      reportedDate: json['reportedDate'] ?? Timestamp.now(),
      resolvedDate: json['resolvedDate'],
      status: json['status'] ?? 'reported',
      assignedTo: json['assignedTo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleId': vehicleId,
      'reportedBy': reportedBy,
      'description': description,
      'reportedDate': reportedDate,
      'resolvedDate': resolvedDate,
      'status': status,
      'assignedTo': assignedTo,
    };
  }

  bool get isOpen => status != 'fixed' && status != 'dismissed';
}
