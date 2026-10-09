import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor.dart';
import 'firestore_paths.dart';

/// Service managing doctor profiles, search preferences, and chamber directories.
class DoctorService {
  final FirebaseFirestore _firestore;

  DoctorService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _doctorsRef =>
      _firestore.collection(FirestorePaths.doctors);

  Future<void> addDoctor(Doctor doctor) async {
    await _doctorsRef.doc(doctor.id).set(doctor.toJson());
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

  Future<void> deleteDoctor(String doctorId) async {
    await _doctorsRef.doc(doctorId).delete();
  }
}
