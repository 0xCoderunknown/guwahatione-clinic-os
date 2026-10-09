import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient.dart';
import 'firestore_paths.dart';

/// Service managing patient demographics lookup and retrieval.
class PatientService {
  final FirebaseFirestore _firestore;

  PatientService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _patientsRef =>
      _firestore.collection(FirestorePaths.patients);

  /// Retrieves a patient demographic profile by primary key (phone number).
  Future<Patient?> getPatient(String phoneNumber) async {
    final doc = await _patientsRef.doc(phoneNumber).get();
    if (doc.exists && doc.data() != null) {
      return Patient.fromJson(doc.data()!);
    }
    return null;
  }
}
