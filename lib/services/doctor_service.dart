import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/doctor.dart';
import 'firestore_paths.dart';

/// Service managing doctor profiles, search preferences, and chamber directories.
class DoctorService {
  final FirebaseFirestore? _customFirestore;

  DoctorService({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _doctorsRef =>
      _firestore.collection(FirestorePaths.doctors);

  Future<void> addDoctor(Doctor doctor) async {
    await _doctorsRef.doc(doctor.id).set(doctor.toJson());
  }

  Future<void> updateDoctor(Doctor doctor) async {
    await _doctorsRef.doc(doctor.id).update(doctor.toJson());
  }

  /// Updates planned leave dates (blockedDates) for a physician.
  Future<void> updateDoctorLeave(
    String doctorId,
    List<DateTime> blockedDates,
  ) async {
    await _doctorsRef.doc(doctorId).update({
      'blockedDates': blockedDates.map((d) => d.toIso8601String()).toList(),
    });
  }

  Future<void> updateDoctorSearchPreference(
    String doctorId,
    String searchPreference,
  ) async {
    await _doctorsRef.doc(doctorId).update({
      'searchPreference': searchPreference,
    });
  }

  Stream<List<Doctor>> getDoctors() {
    return _doctorsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Doctor.fromJson(doc.data());
      }).toList();
    });
  }

  /// Toggles doctor active operational status.
  /// When deactivated (isActive: false), doctor is hidden from reception desk,
  /// walk-in booking, live queues, and chamber logins, while preserving all
  /// longitudinal prescriptions, past appointments, and financial records.
  Future<void> setDoctorActiveStatus(String doctorId, bool isActive) async {
    await _doctorsRef.doc(doctorId).update({'isActive': isActive});
  }
}
