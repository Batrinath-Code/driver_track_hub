import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:driver_tracker_app/features/auth/controllers/auth_controller.dart';
import 'package:driver_tracker_app/features/trips/controllers/trip_controller.dart';
import 'package:driver_tracker_app/data/models/models.dart';
import 'package:driver_tracker_app/features/vehicles/screens/add_edit_vehicle_screen.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  final TripController tripCtrl = Get.put(TripController());
  final AuthController authCtrl = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => tripCtrl.pickDate(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authCtrl.logout(),
          ),
        ],
      ),
      body: Obx(() {
        if (tripCtrl.isLoading.value)
          return const Center(child: CircularProgressIndicator());

        final isToday = tripCtrl.isTodaySelected;

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              /*  DATE CHIP  */
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    DateFormat(
                      'EEEE, d MMM',
                    ).format(tripCtrl.selectedDay.value),
                  ),
                  trailing: Chip(
                    label: Text('${tripCtrl.vehiclesCount} vehicles'),
                  ),
                  onTap: () => tripCtrl.pickDate(context),
                ),
              ),
              const SizedBox(height: 12),

              /*  DRIVER CARD – only TODAY  */
              if (authCtrl.userRole.value == 'driver' && isToday)
                _driverCard(context),

              const SizedBox(height: 12),

              /*  TRIP LIST – no per-tile FutureBuilder  */
              Expanded(
                child: tripCtrl.tripsToday.isEmpty
                    ? const Center(child: Text('No trips for this day'))
                    : ListView.builder(
                        itemCount: tripCtrl.tripsToday.length,
                        itemBuilder: (_, i) {
                          final trip = tripCtrl.tripsToday[i];
                          final driver =
                              tripCtrl.driverNames[trip.driverId] ?? '...';
                          final reg =
                              tripCtrl.vehicleRegs[trip.vehicleId] ?? '...';

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: trip.isOnGoing
                                    ? Colors.green
                                    : Colors.grey,
                                child: Icon(
                                  trip.isOnGoing
                                      ? Icons.directions_car
                                      : Icons.check,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text('$driver  •  $reg'),
                              subtitle: Text(
                                '${DateFormat('HH:mm').format(trip.startTime.toDate())} '
                                '${trip.endTime != null ? '– ${DateFormat('HH:mm').format(trip.endTime!.toDate())}' : ''}',
                              ),
                              trailing: Chip(
                                label: Text(trip.status),
                                backgroundColor: trip.isOnGoing
                                    ? Colors.green.shade100
                                    : Colors.grey.shade100,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (authCtrl.userRole.value == 'admin' ||
              authCtrl.userRole.value == 'manager')
            FloatingActionButton(
              heroTag: 'issues',
              tooltip: 'Reported Issues',
              onPressed: () => Get.toNamed('/issues'),
              child: const Icon(Icons.report),
            ),
          const SizedBox(height: 10),
          if (authCtrl.userRole.value == 'admin')
            FloatingActionButton(
              heroTag: 'users',
              tooltip: 'Manage Users',
              onPressed: () => Get.toNamed('/users'),
              child: const Icon(Icons.people),
            ),
          const SizedBox(height: 10),
          if (authCtrl.userRole.value == 'admin' ||
              authCtrl.userRole.value == 'manager')
            FloatingActionButton(
              heroTag: 'vehicles',
              tooltip: 'Manage Vehicles',
              onPressed: () {
                Get.put(VehicleRepository());
                Get.toNamed('/vehicles');
              },
              child: const Icon(Icons.directions_car),
            ),
          const SizedBox(height: 10),
          if (authCtrl.userRole.value == 'admin' ||
              authCtrl.userRole.value == 'manager')
            FloatingActionButton(
              heroTag: 'addVehicle',
              tooltip: 'Add Vehicle',
              onPressed: () => Get.toNamed('/add-edit-vehicle'),
              child: const Icon(Icons.add),
            ),
        ],
      ),
    );
  }

  /*  DRIVER CARD – morphs after start  */
  Widget _driverCard(BuildContext context) {
    return Obx(() {
      final onGoing = tripCtrl.onGoingTrip.value;
      final ready = onGoing == null;

      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /*  status row  */
              Row(
                children: [
                  Icon(
                    ready ? Icons.directions_car : Icons.drive_eta,
                    color: ready
                        ? Theme.of(context).colorScheme.primary
                        : Colors.orange,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ready ? 'Ready to drive' : 'Trip in progress',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        ready
                            ? 'Tap Start to begin your trip'
                            : 'End trip or report an issue',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Chip(
                    label: Text(ready ? 'Idle' : 'On trip'),
                    backgroundColor: ready
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.orange.shade100,
                    labelStyle: TextStyle(
                      color: ready
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Colors.orange.shade900,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              /*  SINGLE BIG ACTION BEFORE START  */
              if (ready)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _showStartDialog(context),
                    icon: const Icon(Icons.play_arrow, size: 24),
                    label: const Text('Start Trip'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),

              /*  TWO EQUAL BUTTONS AFTER START  */
              if (!ready)
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => _showEndDialog(context),
                        icon: const Icon(Icons.stop, size: 24),
                        label: const Text('End Trip'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showReportDialog(context),
                        icon: const Icon(Icons.report, size: 24),
                        label: const Text('Report Issue'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: BorderSide(color: Colors.orange),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    });
  }

  /*  BOTTOM-SHEET DIALOGS  */
  void _showStartDialog(BuildContext context) async {
    final odoCtrl = TextEditingController();
    final selectedVehicleId = ''.obs;

    await Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        height: Get.height * 0.6,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Text(
              'Select an idle vehicle',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<Vehicle>>(
                stream: Get.find<VehicleRepository>().getIdleVehiclesStream(),
                builder: (_, snap) {
                  if (!snap.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final vehicles = snap.data!;
                  if (vehicles.isEmpty)
                    return const Center(child: Text('No idle vehicles'));
                  return ListView.builder(
                    itemCount: vehicles.length,
                    itemBuilder: (_, i) {
                      final v = vehicles[i];
                      return Obx(
                        () => ListTile(
                          leading: const Icon(Icons.directions_car),
                          title: Text(v.name),
                          subtitle: Text('Reg: ${v.regNumber}'),
                          trailing: selectedVehicleId.value == v.id
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : null,
                          onTap: () => selectedVehicleId.value = v.id,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            TextField(
              controller: odoCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Starting odometer (km)',
              ),
            ),
            const SizedBox(height: 12),
            Obx(
              () => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedVehicleId.value.isEmpty
                      ? null
                      : () async {
                          Get.back();
                          await tripCtrl.createTripAndAssign(
                            vehicleId: selectedVehicleId.value,
                            driverId: authCtrl.firebaseUser.value!.uid,
                            startOdo: int.tryParse(odoCtrl.text),
                          );
                          Get.snackbar('Success', 'Trip started');
                          odoCtrl.dispose();
                        },
                  child: const Text('CREATE TRIP'),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showEndDialog(BuildContext context) async {
    final odoCtrl = TextEditingController();
    final onGoing = tripCtrl.onGoingTrip.value;
    if (onGoing == null) return;

    final ok = await Get.defaultDialog<bool>(
      title: 'End Trip',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter ending odometer (optional)'),
          TextField(
            controller: odoCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'km'),
          ),
        ],
      ),
      textConfirm: 'END',
      textCancel: 'CANCEL',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () => Get.back(result: true),
    );

    if (ok == true) {
      /* 1.  finish trip only  */
      await tripCtrl.endTrip(onGoing.id, endOdo: int.tryParse(odoCtrl.text));
      /* 2.  free vehicle & driver  */
      await tripCtrl.freeVehicleAndDriver(
        vehicleId: onGoing.vehicleId,
        driverId: authCtrl.firebaseUser.value!.uid,
      );
      /* 3.  refresh UI  */
      await tripCtrl.loadOnGoingTrip(authCtrl.firebaseUser.value!.uid);
      Get.snackbar('Success', 'Trip ended. Vehicle is idle.');
      odoCtrl.dispose();
    }
  }

  void _showReportDialog(BuildContext context) async {
    final odoCtrl = TextEditingController();
    final issueCtrl = TextEditingController();

    await Get.defaultDialog(
      title: 'Report Issue',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Describe the problem'),
          TextField(
            controller: issueCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Breakdown, puncher, no oil...',
            ),
          ),
          const SizedBox(height: 8),
          const Text('Current odometer (optional)'),
          TextField(
            controller: odoCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'km'),
          ),
        ],
      ),
      textConfirm: 'SUBMIT',
      textCancel: 'CANCEL',
      onConfirm: () async {
        if (issueCtrl.text.trim().isEmpty) {
          Get.snackbar('Required', 'Please describe the issue');
          return;
        }
        Get.back(); // close dialog

        final onGoing = tripCtrl.onGoingTrip.value;
        if (onGoing != null) {
          // 1.  finish trip + maintenance + free driver
          await tripCtrl.finishTripAndMaintenance(
            tripId: onGoing.id,
            vehicleId: onGoing.vehicleId,
            driverId: authCtrl.firebaseUser.value!.uid,
            endOdo: int.tryParse(odoCtrl.text),
            issueDesc: issueCtrl.text.trim(),
          );
          // 2.  write issue doc (extra detail)
          await tripCtrl.reportIssue(issueCtrl.text.trim());
          await tripCtrl.loadOnGoingTrip(authCtrl.firebaseUser.value!.uid);
          Get.snackbar(
            'Done',
            'Issue reported & trip finished. Vehicle under maintenance.',
          );
        } else {
          // driver not on trip – simple report only
          await tripCtrl.reportIssue(issueCtrl.text.trim());

          Get.snackbar('Done', 'Issue reported.');
        }
        odoCtrl.dispose();
        issueCtrl.dispose();
      },
    );
  }
}
