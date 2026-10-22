import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/clinic_config.dart';
import '../models/doctor.dart';
import '../models/user_role.dart';
import '../services/services.dart';

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
  final SecurityService _securityService;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _securitySubscription;

  AuthProvider({SecurityService? securityService})
      : _securityService = securityService ?? SecurityService();
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

  bool get isCustomOwnerPinSet =>
      _ownerMasterPinHash != _defaultOwnerMasterPinHash;

  bool get isCustomReceptionistPinSet =>
      _receptionistPinHash != _defaultReceptionistPinHash;

  /// Whether universal 0000 testing authentication mode is active.
  bool get isTestingMode => ClinicConfig.current.features.isTestingModeActive;

  /// Verifies if a given PIN matches the clinic Reception PIN or Owner Master PIN.
  /// When [isTestingMode] is active, '0000' is unconditionally accepted.
  bool verifyReceptionOrOwnerPin(String pin) {
    final cleanPin = pin.trim();
    if (cleanPin.isEmpty) return false;
    if (isTestingMode && cleanPin == '0000') return true;
    final inputHash = hashPin(cleanPin);
    return inputHash == _receptionistPinHash ||
        inputHash == _ownerMasterPinHash;
  }

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

    // 2. Subscribe to remote security pin synchronization
    await _securitySubscription?.cancel();
    try {
      _securitySubscription = _securityService.securityStream().listen(
        (snapshot) async {
          if (!snapshot.exists || snapshot.data() == null) return;
          final data = snapshot.data()!;
          bool changed = false;

          final remoteOwnerHash = data['ownerMasterPinHash'] as String?;
          if (remoteOwnerHash != null &&
              remoteOwnerHash.isNotEmpty &&
              remoteOwnerHash != _ownerMasterPinHash) {
            _ownerMasterPinHash = remoteOwnerHash;
            final p = await SharedPreferences.getInstance();
            await p.setString(_prefKeyOwnerMasterPinHash, remoteOwnerHash);
            changed = true;
          }

          final remoteRecHash = data['receptionistPinHash'] as String?;
          if (remoteRecHash != null &&
              remoteRecHash.isNotEmpty &&
              remoteRecHash != _receptionistPinHash) {
            _receptionistPinHash = remoteRecHash;
            final p = await SharedPreferences.getInstance();
            await p.setString(_prefKeyReceptionistPinHash, remoteRecHash);
            changed = true;
          }

          if (changed) {
            notifyListeners();
          }
        },
        onError: (_) {
          // Gracefully handle network drops
        },
      );
    } catch (_) {
      // Offline or unit testing without Firebase
    }
  }

  /// Unified PIN evaluation using SHA-256 hash comparisons:
  /// - 6-digit Master PIN hash -> UserRole.owner
  /// - 4-digit Reception PIN hash -> UserRole.receptionist
  /// - 4-digit Doctor Chamber PIN hash -> UserRole.doctor
  Future<AuthResult> authenticateWithPin({
    required String pin,
    required List<Doctor> doctors,
    UserRole? targetRole,
  }) async {
    final cleanPin = pin.trim();
    final inputHash = hashPin(cleanPin);
    final prefs = await SharedPreferences.getInstance();

    // Universal testing mode bypass: 0000 unlocks any role
    if (isTestingMode && cleanPin == '0000') {
      if (targetRole == UserRole.owner) {
        _currentRole = UserRole.owner;
        _currentDoctor = null;
        await prefs.setString(_prefKeyRole, UserRole.owner.name);
        await prefs.remove(_prefKeyDoctorId);
        notifyListeners();
        return AuthResult.success(UserRole.owner);
      }
      if (targetRole == UserRole.receptionist) {
        _currentRole = UserRole.receptionist;
        _currentDoctor = null;
        await prefs.setString(_prefKeyRole, UserRole.receptionist.name);
        await prefs.remove(_prefKeyDoctorId);
        notifyListeners();
        return AuthResult.success(UserRole.receptionist);
      }
    }

    // 1. Check 6-digit Owner Master PIN via cryptographic hash
    if (cleanPin.length == 6 && inputHash == _ownerMasterPinHash) {
      _currentRole = UserRole.owner;
      _currentDoctor = null;
      await prefs.setString(_prefKeyRole, UserRole.owner.name);
      await prefs.remove(_prefKeyDoctorId);
      notifyListeners();
      return AuthResult.success(UserRole.owner);
    }

    // 2. Check 4-digit Receptionist PIN via cryptographic hash (or testing mode 0000)
    if (inputHash == _receptionistPinHash ||
        (isTestingMode && cleanPin == '0000')) {
      _currentRole = UserRole.receptionist;
      _currentDoctor = null;
      await prefs.setString(_prefKeyRole, UserRole.receptionist.name);
      await prefs.remove(_prefKeyDoctorId);
      notifyListeners();
      return AuthResult.success(UserRole.receptionist);
    }

    // 3. Check Doctor Chamber PINs via cryptographic hash (only active doctors)
    final matchedDoctors = doctors
        .where((d) => d.isActive && (hashPin(d.pin) == inputHash || (isTestingMode && cleanPin == '0000')))
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
    final cleanPin = pin.trim();
    final inputHash = hashPin(cleanPin);
    if ((isTestingMode && cleanPin == '0000') ||
        inputHash == _ownerMasterPinHash) {
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
    final cleanPin = pin.trim();
    final inputHash = hashPin(cleanPin);
    if ((isTestingMode && cleanPin == '0000') ||
        inputHash == _receptionistPinHash) {
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
  /// In testing mode, allows explicit [targetRole] selection with PIN '0000'.
  Future<bool> loginAsReceptionistOrOwner(
    String pin, {
    UserRole? targetRole,
  }) async {
    final cleanPin = pin.trim();
    final inputHash = hashPin(cleanPin);

    // Testing Mode: PIN '0000' authenticates target role or receptionist by default
    if (isTestingMode && cleanPin == '0000') {
      if (targetRole == UserRole.owner) {
        return loginAsOwner(cleanPin);
      }
      return loginAsReceptionist(cleanPin);
    }

    // 1. Check Owner PIN (6-digit admin)
    if (cleanPin.length == 6 && inputHash == _ownerMasterPinHash) {
      return loginAsOwner(cleanPin);
    }

    // 2. Check Receptionist PIN (4-digit reception)
    if (inputHash == _receptionistPinHash) {
      return loginAsReceptionist(cleanPin);
    }

    // Fallback: If 6-digit owner pin didn't match length rule but matches owner hash
    if (inputHash == _ownerMasterPinHash) {
      return loginAsOwner(cleanPin);
    }

    return false;
  }

  Future<bool> loginAsDoctor(Doctor doctor, String pin) async {
    if (!doctor.isActive) return false;
    final cleanPin = pin.trim();
    if ((isTestingMode && cleanPin == '0000') ||
        hashPin(doctor.pin) == hashPin(cleanPin)) {
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

  /// Verifies an entered PIN against the Owner Master Passkey hash.
  /// Used for authorizing sensitive administrative actions like doctor deactivation/reactivation.
  /// When [isTestingMode] is active, '0000' is unconditionally accepted.
  bool verifyOwnerMasterPin(String pin) {
    final cleanPin = pin.trim();
    if (cleanPin.isEmpty) return false;
    if (isTestingMode && cleanPin == '0000') return true;
    final inputHash = hashPin(cleanPin);
    return inputHash == _ownerMasterPinHash;
  }

  /// Updates Owner Master PIN and/or Receptionist PIN locally and synchronizes to Firestore.
  Future<void> updateSecurityPins({
    String? newOwnerPin,
    String? newReceptionistPin,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String? newOwnerHash;
    String? newRecHash;

    if (newOwnerPin != null && newOwnerPin.trim().isNotEmpty) {
      newOwnerHash = hashPin(newOwnerPin.trim());
      _ownerMasterPinHash = newOwnerHash;
      await prefs.setString(_prefKeyOwnerMasterPinHash, newOwnerHash);
      await prefs.remove(_legacyPrefKeyOwnerMasterPin);
    }

    if (newReceptionistPin != null && newReceptionistPin.trim().isNotEmpty) {
      newRecHash = hashPin(newReceptionistPin.trim());
      _receptionistPinHash = newRecHash;
      await prefs.setString(_prefKeyReceptionistPinHash, newRecHash);
      await prefs.remove(_legacyPrefKeyReceptionistPin);
    }

    notifyListeners();

    try {
      await _securityService.updateSecurityPins(
        ownerMasterPinHash: newOwnerHash,
        receptionistPinHash: newRecHash,
      );
    } catch (_) {
      // Local changes persist via SharedPreferences even when offline
    }
  }

  Future<void> setOwnerMasterPin(String newPin) async {
    await updateSecurityPins(newOwnerPin: newPin);
  }

  Future<void> setReceptionistPin(String newPin) async {
    await updateSecurityPins(newReceptionistPin: newPin);
  }

  Future<void> logout() async {
    _currentRole = null;
    _currentDoctor = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyRole);
    await prefs.remove(_prefKeyDoctorId);

    notifyListeners();
  }

  @override
  void dispose() {
    _securitySubscription?.cancel();
    super.dispose();
  }
}
