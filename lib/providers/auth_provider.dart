import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/doctor.dart';
import '../models/user_role.dart';

class AuthResult {
  final bool isSuccess;
  final UserRole? role;
  final Doctor? doctor;
  final List<Doctor> matchingDoctors;
  final String? errorMessage;

  const AuthResult._({
    required this.isSuccess,
    this.role,
    this.doctor,
    this.matchingDoctors = const [],
    this.errorMessage,
  });

  factory AuthResult.success(UserRole role, {Doctor? doctor}) =>
      AuthResult._(isSuccess: true, role: role, doctor: doctor);

  factory AuthResult.multipleDoctors(List<Doctor> doctors) =>
      AuthResult._(isSuccess: false, matchingDoctors: doctors);

  factory AuthResult.failed(String message) =>
      AuthResult._(isSuccess: false, errorMessage: message);
}

class AuthProvider with ChangeNotifier {
  static const String _prefKeyRole = 'auth_role';
  static const String _prefKeyDoctorId = 'auth_doctor_id';
  static const String _prefKeyOwnerMasterPin = 'auth_owner_master_pin';
  static const String _prefKeyReceptionistPin = 'auth_receptionist_pin';

  static const String defaultReceptionistPin = '0000';
  static const String defaultOwnerMasterPin = '849201';

  UserRole? _currentRole;
  Doctor? _currentDoctor;
  bool _isInitialized = false;
  String _receptionistPin = defaultReceptionistPin;
  String _ownerMasterPin = defaultOwnerMasterPin;

  UserRole? get currentRole => _currentRole;

  Doctor? get currentDoctor => _currentDoctor;

  bool get isAuthenticated => _currentRole != null;

  bool get isOwner => _currentRole == UserRole.owner;

  bool get isReceptionist => _currentRole == UserRole.receptionist;

  bool get isDoctor => _currentRole == UserRole.doctor;

  bool get isInitialized => _isInitialized;

  String get receptionistPin => _receptionistPin;

  String get ownerMasterPin => _ownerMasterPin;


  Future<void> initSession(List<Doctor> availableDoctors) async {
    final prefs = await SharedPreferences.getInstance();
    _receptionistPin =
        prefs.getString(_prefKeyReceptionistPin) ?? defaultReceptionistPin;
    _ownerMasterPin =
        prefs.getString(_prefKeyOwnerMasterPin) ?? defaultOwnerMasterPin;
    final savedRole = prefs.getString(_prefKeyRole);
    final savedDoctorId = prefs.getString(_prefKeyDoctorId);

    if (savedRole == UserRole.owner.name) {
      _currentRole = UserRole.owner;
      _currentDoctor = null;
    } else if (savedRole == UserRole.receptionist.name) {
      _currentRole = UserRole.receptionist;
      _currentDoctor = null;
    } else if (savedRole == UserRole.doctor.name && savedDoctorId != null) {
      try {
        _currentDoctor = availableDoctors.firstWhere(
          (d) => d.id == savedDoctorId,
        );
        _currentRole = UserRole.doctor;
      } catch (_) {
        // Doctor not found or removed
        _currentRole = null;
        _currentDoctor = null;
        await prefs.remove(_prefKeyRole);
        await prefs.remove(_prefKeyDoctorId);
      }
    }
    _isInitialized = true;
    notifyListeners();
  }

  /// Unified PIN evaluation without manual role selectors:
  /// - 6-digit Master PIN -> UserRole.owner
  /// - 4-digit Reception PIN ('0000') -> UserRole.receptionist
  /// - 4-digit Doctor Chamber PIN -> UserRole.doctor
  Future<AuthResult> authenticateWithPin({
    required String pin,
    required List<Doctor> doctors,
  }) async {
    final cleanPin = pin.trim();
    final prefs = await SharedPreferences.getInstance();

    // 1. Check 6-digit Owner Master PIN
    if (cleanPin.length == 6 && cleanPin == _ownerMasterPin) {
      _currentRole = UserRole.owner;
      _currentDoctor = null;
      await prefs.setString(_prefKeyRole, UserRole.owner.name);
      await prefs.remove(_prefKeyDoctorId);
      notifyListeners();
      return AuthResult.success(UserRole.owner);
    }

    // 2. Check 4-digit Receptionist PIN
    if (cleanPin == _receptionistPin || cleanPin == '0000') {
      _currentRole = UserRole.receptionist;
      _currentDoctor = null;
      await prefs.setString(_prefKeyRole, UserRole.receptionist.name);
      await prefs.remove(_prefKeyDoctorId);
      notifyListeners();
      return AuthResult.success(UserRole.receptionist);
    }

    // 3. Check Doctor Chamber PINs
    final matchedDoctors =
        doctors.where((d) => d.pin.trim() == cleanPin).toList();
    if (matchedDoctors.length == 1) {
      final doc = matchedDoctors.first;
      _currentRole = UserRole.doctor;
      _currentDoctor = doc;
      await prefs.setString(_prefKeyRole, UserRole.doctor.name);
      await prefs.setString(_prefKeyDoctorId, doc.id);
      notifyListeners();
      return AuthResult.success(UserRole.doctor, doctor: doc);
    } else if (matchedDoctors.length > 1) {
      return AuthResult.multipleDoctors(matchedDoctors);
    }

    return AuthResult.failed('Invalid Access PIN. Please try again.');
  }

  /// Elevated Owner auto step-down to Receptionist.
  Future<void> stepDownToReception() async {
    if (_currentRole == UserRole.owner) {
      _currentRole = UserRole.receptionist;
      _currentDoctor = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyRole, UserRole.receptionist.name);
      await prefs.remove(_prefKeyDoctorId);
      notifyListeners();
    }
  }

  Future<bool> loginAsOwner(String pin) async {
    final cleanPin = pin.trim();
    if (cleanPin == _ownerMasterPin ||
        cleanPin == _receptionistPin ||
        cleanPin == '0000') {
      _currentRole = cleanPin == _ownerMasterPin
          ? UserRole.owner
          : UserRole.receptionist;
      _currentDoctor = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyRole, _currentRole!.name);
      await prefs.remove(_prefKeyDoctorId);

      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> loginAsReceptionist(String pin) async {
    if (pin.trim() == _receptionistPin || pin.trim() == '0000') {
      _currentRole = UserRole.receptionist;
      _currentDoctor = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyRole, UserRole.receptionist.name);
      await prefs.remove(_prefKeyDoctorId);

      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> loginAsDoctor(Doctor doctor, String pin) async {
    if (doctor.pin.trim() == pin.trim()) {
      _currentRole = UserRole.doctor;
      _currentDoctor = doctor;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyRole, UserRole.doctor.name);
      await prefs.setString(_prefKeyDoctorId, doctor.id);

      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> setOwnerMasterPin(String newPin) async {
    _ownerMasterPin = newPin.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyOwnerMasterPin, _ownerMasterPin);
    notifyListeners();
  }

  Future<void> setReceptionistPin(String newPin) async {
    _receptionistPin = newPin.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyReceptionistPin, _receptionistPin);
    notifyListeners();
  }


  Future<void> logout() async {
    _currentRole = null;
    _currentDoctor = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyRole);
    await prefs.remove(_prefKeyDoctorId);

    notifyListeners();
  }
}
