import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment.dart';
import '../models/consultation.dart';
import '../models/prescription_item.dart';
import 'firestore_paths.dart';

/// Service managing append-only clinical consultations and longitudinal medical timelines.
class ConsultationService {
  final FirebaseFirestore _firestore;

  ConsultationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _consultationsRef =>
      _firestore.collection(FirestorePaths.consultations);

  CollectionReference<Map<String, dynamic>> get _appointmentsRef =>
      _firestore.collection(FirestorePaths.appointments);

  CollectionReference<Map<String, dynamic>> get _patientsRef =>
      _firestore.collection(FirestorePaths.patients);

  /// Records an immutable clinical consultation encounter.
  /// Follows the strict append-only policy: each consultation is a new document.
  /// Also atomically marks appointment status as 'completed' and syncs patient lastVisitDate.
  Future<void> saveConsultation(Consultation consultation) async {
    final batch = _firestore.batch();

    // 1. Append consultation document (immutable)
    final consultDoc = _consultationsRef.doc(consultation.id);
    batch.set(consultDoc, consultation.toJson());

    // 2. Mark appointment as completed
    if (consultation.appointmentId.isNotEmpty) {
      final apptDoc = _appointmentsRef.doc(consultation.appointmentId);
      batch.update(apptDoc, {'status': AppointmentStatus.completed.name});
    }

    // 3. Keep patient record synced (lastVisitDate stamped on consultation completion)
    final patientDoc = _patientsRef.doc(consultation.patientPhone);
    batch.set(patientDoc, {
      'lastVisitDate': consultation.createdAt.toIso8601String(),
      'name': consultation.patientName,
      'age': consultation.patientAge,
      'gender': consultation.patientGender,
      'phoneNumber': consultation.patientPhone,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// Retrieves the longitudinal consultation timeline for a patient, ordered by date desc.
  Future<List<Consultation>> getConsultationsForPatient(String phone) async {
    final snapshot = await _consultationsRef
        .where('patientPhone', isEqualTo: phone)
        .get();

    final consultations = snapshot.docs
        .map((doc) => Consultation.fromJson(doc.data()))
        .toList();

    consultations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return consultations;
  }

  /// Retrieves the latest consultation for a patient, or null if none exists.
  Future<Consultation?> getLatestConsultationForPatient(String phone) async {
    final list = await getConsultationsForPatient(phone);
    if (list.isEmpty) return null;
    return list.first;
  }

  /// Fetches the active medications from the patient's most recent consultation
  /// to populate the medication reconciliation interface for follow-up visits.
  Future<List<PrescriptionItem>> getLatestActiveMedications(
    String phone,
  ) async {
    final latest = await getLatestConsultationForPatient(phone);
    if (latest == null) return [];
    return latest.activePrescriptions;
  }
}
