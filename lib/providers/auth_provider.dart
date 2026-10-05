import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/doctor.dart';
import '../models/user_role.dart';

class AuthProvider with ChangeNotifier {
  static const String _prefKeyRole = 'auth_role';
  static const String _prefKeyDoctorId = 'auth_doctor_id';
  static const String _prefKeyOwnerPin = 'auth_owner_pin';
  static const String defaultOwnerPin = '0000';

  UserRole? _currentRole;
  Doctor? _currentDoctor;
  bool _isInitialized = false;
  String _ownerPin = defaultOwnerPin;

  UserRole? get currentRole => _currentRole;
  Doctor? get currentDoctor => _currentDoctor;
  bool get isAuthenticated => _currentRole != null;
  bool get isOwner => _currentRole == UserRole.owner;
  bool get isDoctor => _currentRole == UserRole.doctor;
  bool get isInitialized => _isInitialized;
  String get ownerPin => _ownerPin;

  Future<void> initSession(List<Doctor> availableDoctors) async {
    final prefs = await SharedPreferences.getInstance();
    _ownerPin = prefs.getString(_prefKeyOwnerPin) ?? defaultOwnerPin;
    final savedRole = prefs.getString(_prefKeyRole);
    final savedDoctorId = prefs.getString(_prefKeyDoctorId);

    if (savedRole == UserRole.owner.name) {
      _currentRole = UserRole.owner;
      _currentDoctor = null;
    } else if (savedRole == UserRole.doctor.name && savedDoctorId != null) {
      try {
        _currentDoctor = availableDoctors.firstWhere((d) => d.id == savedDoctorId);
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

  Future<bool> loginAsOwner(String pin) async {
    if (pin.trim() == _ownerPin) {
      _currentRole = UserRole.owner;
      _currentDoctor = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyRole, UserRole.owner.name);
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

  Future<void> setOwnerPin(String newPin) async {
    _ownerPin = newPin.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyOwnerPin, _ownerPin);
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
