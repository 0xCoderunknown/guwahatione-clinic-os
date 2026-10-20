import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../models/doctor.dart';
import '../../models/user_role.dart';
import '../../services/doctor_service.dart';

/// Delegate controller responsible for doctor master roster streams,
/// physician leave configuration, search preferences, and CRUD operations.
class DoctorStateDelegate {
  final DoctorService _doctorService;
  final Uuid _uuid;
  final VoidCallback _notifyListeners;

  StreamSubscription? _doctorSub;
  List<Doctor> _doctors = [];
  bool _hasLoadedDoctors = false;

  DoctorStateDelegate({
    DoctorService? doctorService,
    Uuid? uuid,
    required this._notifyListeners,
  }) : _doctorService = doctorService ?? DoctorService(),
       _uuid = uuid ?? const Uuid() {
    subscribeToDoctors();
  }

  /// Active doctors eligible for OPD scheduling, walk-in booking, live queue, and chamber login.
  List<Doctor> get doctors => _doctors.where((d) => d.isActive).toList();

  /// Full doctor roster including active and retired/inactive physicians (for Owner settings).
  List<Doctor> get allDoctors => _doctors;

  /// Deactivated / retired doctors.
  List<Doctor> get inactiveDoctors =>
      _doctors.where((d) => !d.isActive).toList();

  Doctor? getDoctorById(String doctorId) =>
      _doctors.where((d) => d.id == doctorId).firstOrNull;

  bool get hasLoadedDoctors => _hasLoadedDoctors;

  void subscribeToDoctors() {
    _doctorSub?.cancel();
    _doctorSub = _doctorService.getDoctors().listen((doctors) {
      _doctors = doctors;
      _hasLoadedDoctors = true;
      _notifyListeners();
    });
  }

  Future<void> addDoctor(
    String name,
    String specialty,
    String phone,
    List<String> days, {
    List<DateTime> blockedDates = const [],
    String pin = '1234',
    int consultationFee = 500,
    int freeReviewDays = 14,
    String? medicalRegNumber,
    String shiftTiming = '6:00 PM – 8:30 PM',
    int dailyTokenLimit = 18,
    int doctorSharePercentage = 100,
    UserRole? requestingRole,
  }) async {
    if (requestingRole != null && !requestingRole.isOwner) {
      throw Exception(
        'Permission Denied: Only clinic administrators (owner) can register new doctors.',
      );
    }
    try {
      final newDoctor = Doctor(
        id: _uuid.v4(),
        name: name,
        specialty: specialty,
        phone: phone,
        availableDays: days,
        blockedDates: blockedDates,
        pin: pin,
        consultationFee: consultationFee,
        freeReviewDays: freeReviewDays,
        medicalRegNumber: medicalRegNumber,
        shiftTiming: shiftTiming,
        dailyTokenLimit: dailyTokenLimit,
        doctorSharePercentage: doctorSharePercentage,
      );
      await _doctorService.addDoctor(newDoctor);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateDoctor(Doctor doctor, {UserRole? requestingRole}) async {
    if (requestingRole != null && !requestingRole.isOwner) {
      throw Exception(
        'Permission Denied: Only clinic administrators (owner) can modify doctor profiles.',
      );
    }
    try {
      await _doctorService.updateDoctor(doctor);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateDoctorLeave(
    String doctorId,
    List<DateTime> blockedDates, {
    UserRole? requestingRole,
  }) async {
    if (requestingRole != null && !requestingRole.isOwner) {
      throw Exception(
        'Permission Denied: Only clinic administrators (owner) can modify doctor leave.',
      );
    }
    try {
      await _doctorService.updateDoctorLeave(doctorId, blockedDates);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setDoctorActiveStatus(
    String doctorId,
    bool isActive, {
    UserRole? requestingRole,
  }) async {
    if (requestingRole != null && !requestingRole.isOwner) {
      throw Exception(
        'Permission Denied: Only clinic administrators (owner) can change doctor active status.',
      );
    }
    try {
      await _doctorService.setDoctorActiveStatus(doctorId, isActive);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateDoctorSearchPreference(
    String doctorId,
    String searchPreference,
  ) async {
    try {
      await _doctorService.updateDoctorSearchPreference(
        doctorId,
        searchPreference,
      );
    } catch (e) {
      debugPrint('Error updating doctor search preference: $e');
      rethrow;
    }
  }

  void dispose() {
    _doctorSub?.cancel();
  }
}
