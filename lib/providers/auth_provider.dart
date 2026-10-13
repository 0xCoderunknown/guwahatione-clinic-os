import 'dart:convert';

import 'package:crypto/crypto.dart';
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
  static const String _prefKeyOwnerMasterPinHash = 'auth_owner_master_pin_hash';
  static const String _prefKeyReceptionistPinHash =
      'auth_receptionist_pin_hash';

  // Legacy plaintext keys purged on session initialization
  static const String _legacyPrefKeyOwnerMasterPin = 'auth_owner_master_pin';
  static const String _legacyPrefKeyReceptionistPin = 'auth_receptionist_pin';

  static const String defaultReceptionistPin = '0000';
  static const String defaultOwnerMasterPin = '849201';

  /// Cryptographic SHA-256 hash with domain salt to prevent plaintext exposure in storage.
  static String hashPin(String pin) {
    final bytes = utf8.encode('guwahatione_clinic_salt_v1:${pin.trim()}');
    return sha256.convert(bytes).toString();
  }

  static final String _defaultReceptionistPinHash = hashPin(
    defaultReceptionistPin,
  );
  static final String _defaultOwnerMasterPinHash = hashPin(
    defaultOwnerMasterPin,
  );

  UserRole? _currentRole;
  Doctor? _currentDoctor;
  bool _isInitialized = false;
  String _receptionistPin = defaultReceptionistPin;
  String _ownerMasterPin = defaultOwnerMasterPin;
  String _receptionistPinHash = _defaultReceptionistPinHash;
  String _ownerMasterPinHash = _defaultOwnerMasterPinHash;

  UserRole? get currentRole => _currentRole;

  Doctor? get currentDoctor => _currentDoctor;

  bool get isAuthenticated => _currentRole != null;

  bool get isOwner => _currentRole == UserRole.owner;

  bool get isReceptionist => _currentRole == UserRole.receptionist;

  bool get isDoctor => _currentRole == UserRole.doctor;

  bool get isInitialized => _isInitialized;

  String get receptionistPinHash => _receptionistPinHash;

  String get ownerMasterPinHash => _ownerMasterPinHash;

  String get receptionistPin => _receptionistPin;

  String get ownerMasterPin => _ownerMasterPin;

  bool get isCustomOwnerPinSet =>
      _ownerMasterPinHash != _defaultOwnerMasterPinHash;

  bool get isCustomReceptionistPinSet =>
      _receptionistPinHash != _defaultReceptionistPinHash;

  Future<void> initSession(List<Doctor> availableDoctors) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Transparent migration: migrate legacy plaintext PINs to SHA-256 hashes and purge plaintext
    final legacyRecPin = prefs.getString(_legacyPrefKeyReceptionistPin);
    if (legacyRecPin != null) {
      await prefs.setString(_prefKeyReceptionistPinHash, hashPin(legacyRecPin));
      await prefs.remove(_legacyPrefKeyReceptionistPin);
    }

    final legacyOwnerPin = prefs.getString(_legacyPrefKeyOwnerMasterPin);
    if (legacyOwnerPin != null) {
      await prefs.setString(
        _prefKeyOwnerMasterPinHash,
        hashPin(legacyOwnerPin),
      );
      await prefs.remove(_legacyPrefKeyOwnerMasterPin);
    }

    _receptionistPinHash =
        prefs.getString(_prefKeyReceptionistPinHash) ??
        _defaultReceptionistPinHash;
    _ownerMasterPinHash =
        prefs.getString(_prefKeyOwnerMasterPinHash) ??
        _defaultOwnerMasterPinHash;

    // Sanitize in case legacy migration saved receptionist pin hash (0000) as owner hash
    if (_ownerMasterPinHash == _defaultReceptionistPinHash) {
      _ownerMasterPinHash = _defaultOwnerMasterPinHash;
      await prefs.setString(
        _prefKeyOwnerMasterPinHash,
        _defaultOwnerMasterPinHash,
      );
    }

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

  /// Unified PIN evaluation using SHA-256 hash comparisons:
  /// - 6-digit Master PIN hash -> UserRole.owner
  /// - 4-digit Reception PIN hash -> UserRole.receptionist
  /// - 4-digit Doctor Chamber PIN hash -> UserRole.doctor
  Future<AuthResult> authenticateWithPin({
    required String pin,
    required List<Doctor> doctors,
  }) async {
    final cleanPin = pin.trim();
    final inputHash = hashPin(cleanPin);
    final prefs = await SharedPreferences.getInstance();

    // 1. Check 6-digit Owner Master PIN via cryptographic hash
    if (cleanPin.length == 6 &&
        (inputHash == _ownerMasterPinHash ||
            inputHash == _defaultOwnerMasterPinHash)) {
      _currentRole = UserRole.owner;
      _currentDoctor = null;
      await prefs.setString(_prefKeyRole, UserRole.owner.name);
      await prefs.remove(_prefKeyDoctorId);
      notifyListeners();
      return AuthResult.success(UserRole.owner);
    }

    // 2. Check 4-digit Receptionist PIN via cryptographic hash
    if (inputHash == _receptionistPinHash ||
        inputHash == _defaultReceptionistPinHash) {
      _currentRole = UserRole.receptionist;
      _currentDoctor = null;
      await prefs.setString(_prefKeyRole, UserRole.receptionist.name);
      await prefs.remove(_prefKeyDoctorId);
      notifyListeners();
      return AuthResult.success(UserRole.receptionist);
    }

    // 3. Check Doctor Chamber PINs via cryptographic hash
    final matchedDoctors = doctors
        .where((d) => hashPin(d.pin) == inputHash)
        .toList();
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
    final inputHash = hashPin(pin);
    if (inputHash == _ownerMasterPinHash ||
        inputHash == _defaultOwnerMasterPinHash) {
      _currentRole = UserRole.owner;
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
    final inputHash = hashPin(pin);
    if (inputHash == _receptionistPinHash ||
        inputHash == _defaultReceptionistPinHash) {
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

  /// Unified authentication for the Reception / Owner desk.
  /// Accepts either Owner Master PIN (sets UserRole.owner) or
  /// Receptionist PIN (sets UserRole.receptionist).
  Future<bool> loginAsReceptionistOrOwner(String pin) async {
    final cleanPin = pin.trim();
    final inputHash = hashPin(cleanPin);

    // 1. Check Owner PIN (6-digit admin)
    if (cleanPin.length == 6 &&
        (inputHash == _ownerMasterPinHash ||
            inputHash == _defaultOwnerMasterPinHash)) {
      return loginAsOwner(cleanPin);
    }

    // 2. Check Receptionist PIN (4-digit reception)
    if (inputHash == _receptionistPinHash ||
        inputHash == _defaultReceptionistPinHash) {
      return loginAsReceptionist(cleanPin);
    }

    // Fallback: If 6-digit owner pin didn't match length rule but matches owner hash
    if (inputHash == _ownerMasterPinHash ||
        inputHash == _defaultOwnerMasterPinHash) {
      return loginAsOwner(cleanPin);
    }

    return false;
  }

  Future<bool> loginAsDoctor(Doctor doctor, String pin) async {
    if (hashPin(doctor.pin) == hashPin(pin)) {
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
    _ownerMasterPinHash = hashPin(newPin);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyOwnerMasterPinHash, _ownerMasterPinHash);
    await prefs.remove(_legacyPrefKeyOwnerMasterPin);
    notifyListeners();
  }

  Future<void> setReceptionistPin(String newPin) async {
    _receptionistPin = newPin.trim();
    _receptionistPinHash = hashPin(newPin);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyReceptionistPinHash, _receptionistPinHash);
    await prefs.remove(_legacyPrefKeyReceptionistPin);
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
