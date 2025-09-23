import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:driver_tracker_app/data/models/models.dart';
import 'package:driver_tracker_app/features/auth/controllers/auth_controller.dart';

class IssuesScreen extends StatelessWidget {
  IssuesScreen({super.key});

  final IssueRepository _repo = IssueRepository();
  final AuthController authCtrl = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reported Issues'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authCtrl.logout(),
          ),
        ],
      ),
      body: StreamBuilder<List<Issue>>(
        stream: _repo.getIssuesStream(),
        builder: (_, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final issues = snap.data!;
          if (issues.isEmpty)
            return const Center(child: Text('No issues reported'));
          return ListView.builder(
            itemCount: issues.length,
            itemBuilder: (_, i) {
              final iss = issues[i];
              final isAdmin = authCtrl.userRole.value == 'admin';
              final canAct = isAdmin || authCtrl.userRole.value == 'manager';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: iss.isOpen ? Colors.orange : Colors.green,
                    child: Icon(
                      iss.isOpen ? Icons.report_problem : Icons.check_circle,
                      color: Colors.white,
                    ),
                  ),
                  title: Text('${iss.vehicleId} • ${iss.description}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${iss.status}'),
                      Text(
                        'Reported: ${DateFormat('d MMM yyyy – HH:mm').format(iss.reportedDate.toDate())}',
                      ),
                      if (iss.resolvedDate != null)
                        Text(
                          'Resolved: ${DateFormat('d MMM yyyy – HH:mm').format(iss.resolvedDate!.toDate())}',
                        ),
                    ],
                  ),
                  trailing: canAct && iss.isOpen
                      ? PopupMenuButton<String>(
                          onSelected: (val) async {
                            if (val == 'fixed') {
                              await _repo.updateStatus(iss.id, 'fixed');
                            } else if (val == 'dismissed') {
                              await _repo.updateStatus(iss.id, 'dismissed');
                            } else if (val == 'delete') {
                              final yes = await Get.defaultDialog<bool>(
                                title: 'Delete Issue',
                                middleText: 'Delete this issue permanently?',
                                textConfirm: 'Delete',
                                textCancel: 'Cancel',
                                onConfirm: () => Get.back(result: true),
                              );
                              if (yes == true) await _repo.deleteIssue(iss.id);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'fixed',
                              child: Text('Mark Fixed'),
                            ),
                            PopupMenuItem(
                              value: 'dismissed',
                              child: Text('Dismiss'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Refresh',
        onPressed: () {}, // stream auto-refreshes
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
