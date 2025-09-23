import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_tracker_app/data/models/issue_model.dart';

class IssueRepository {
  final CollectionReference _issues = FirebaseFirestore.instance.collection(
    'vehicle_issues',
  );

  /// Stream of all issues (admin/manager view).
  Stream<List<Issue>> getIssuesStream() {
    return _issues
        .orderBy('reportedDate', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) =>
                    Issue.fromJson(doc.data() as Map<String, dynamic>, doc.id),
              )
              .toList(),
        );
  }

  /// Update status (admin action).
  Future<bool> updateStatus(String issueId, String newStatus) async {
    try {
      await _issues.doc(issueId).update({
        'status': newStatus,
        if (newStatus == 'fixed') 'resolvedDate': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      log('updateStatus error: $e');
      return false;
    }
  }

  /// Delete issue (admin action).
  Future<bool> deleteIssue(String issueId) async {
    try {
      await _issues.doc(issueId).delete();
      return true;
    } catch (e) {
      log('deleteIssue error: $e');
      return false;
    }
  }
}
