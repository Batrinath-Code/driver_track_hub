import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:driver_tracker_app/data/models/trip_model.dart';
import 'package:driver_tracker_app/data/repositories/trip_repository.dart';
import 'package:driver_tracker_app/data/repositories/user_repository.dart';
import 'package:driver_tracker_app/data/repositories/vehicle_repository.dart';
import 'package:driver_tracker_app/features/auth/controllers/auth_controller.dart';

class TripController extends GetxController {
  /* ----------  repos  ---------- */
  final TripRepository _tripRepo = TripRepository();
  final UserRepository _userRepo = UserRepository();
  final VehicleRepository _vehicleRepo = VehicleRepository();
  final AuthController authCtrl = Get.find();

  /* ----------  obs  ---------- */
  final selectedDay = DateTime.now().obs;
  final tripsToday = <Trip>[].obs;
  final vehiclesCount = 0.obs;
  final isLoading = true.obs;

  /* ----------  cached names / regs  ---------- */
  final driverNames = <String, String>{}.obs; // uid → name
  final vehicleRegs = <String, String>{}.obs; // vehicleId → reg

  /* ----------  on-going trip  ---------- */
  final onGoingTrip = Rxn<Trip>();

  /* ----------  stream sub  ---------- */
  StreamSubscription<List<Trip>>? _tripSub;

  @override
  void onInit() {
    super.onInit();
    _loadDay(DateTime.now());
    ever(selectedDay, (_) => _loadDay(selectedDay.value));
  }

  @override
  void onClose() {
    _tripSub?.cancel();
    super.onClose();
  }

  /* ----------  helpers  ---------- */
  bool get isTodaySelected {
    final now = DateTime.now().toUtc();
    return selectedDay.value.year == now.year &&
        selectedDay.value.month == now.month &&
        selectedDay.value.day == now.day;
  }

  /* ----------  load / reload day  ---------- */
  void _loadDay(DateTime day) async {
    selectedDay.value = day;
    isLoading(true);

    /* 1.  hide old data instantly  */
    tripsToday.clear();
    vehiclesCount.value = 0;
    onGoingTrip.value = null;
    driverNames.clear();
    vehicleRegs.clear();

    /* 2.  tiny delay so UI shows loader immediately  */
    await Future.delayed(const Duration(milliseconds: 50));

    /* 3.  start new stream  */
    _tripSub?.cancel();
    _tripSub = _tripRepo.getTripsStream(day: day).listen((list) async {
      /* 1.  cache names/regs FIRST  */
      await _cacheNamesAndRegs(list);

      /* 2.  then publish to UI  */
      tripsToday.assignAll(list);
      vehiclesCount.value = list.map((t) => t.vehicleId).toSet().length;
      await _loadOnGoingTrip();
      isLoading(false);
    }, onError: (_) => isLoading(false));
  }

  Future<void> _cacheNamesAndRegs(List<Trip> trips) async {
    final uIds = trips.map((t) => t.driverId).toSet();
    final vIds = trips.map((t) => t.vehicleId).toSet();

    final users = await Future.wait(
      uIds.map((id) => _userRepo.getUserById(id)),
    );
    final vehicles = await Future.wait(
      vIds.map((id) => _vehicleRepo.getVehicleById(id)),
    );

    driverNames.assignAll(
      Map.fromEntries(users.map((u) => MapEntry(u!.uid, u.name))),
    );
    vehicleRegs.assignAll(
      Map.fromEntries(vehicles.map((v) => MapEntry(v!.id, v.regNumber))),
    );
  }

  Future<void> _loadOnGoingTrip() async {
    final user = authCtrl.firebaseUser.value;
    if (user == null) return;
    onGoingTrip.value = await _tripRepo.getOnGoingTrip(user.uid);
  }

  /* ----------  public helpers  ---------- */
  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDay.value,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDay.value) _loadDay(picked);
  }

  /* ----------  driver actions  ---------- */
  Future<String> createTripAndAssign({
    required String vehicleId,
    required String driverId,
    int? startOdo,
  }) async {
    final id = await _tripRepo.createTripAndAssign(
      vehicleId: vehicleId,
      driverId: driverId,
      startOdo: startOdo,
    );
    await _loadOnGoingTrip();
    return id;
  }

  Future<void> endTrip(String tripId, {int? endOdo}) async {
    await _tripRepo.endTrip(tripId, endOdo: endOdo);
    await _loadOnGoingTrip();
  }

  Future<void> finishTripAndMaintenance({
    required String tripId,
    required String vehicleId,
    required String driverId,
    int? endOdo,
    String issueDesc = '',
  }) async {
    await _tripRepo.finishTripAndMaintenance(
      tripId: tripId,
      vehicleId: vehicleId,
      driverId: driverId,
      endOdo: endOdo,
      issueDesc: issueDesc,
    );
    await _loadOnGoingTrip();
  }

  Future<void> reportIssue(String description) async =>
      await _tripRepo.reportVehicleIssue(
        vehicleId: onGoingTrip.value?.vehicleId ?? '',
        reportedByUserId: authCtrl.firebaseUser.value!.uid,
        description: description.trim(),
      );
}
