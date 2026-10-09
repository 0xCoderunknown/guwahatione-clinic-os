import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/patient.dart';
import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/consultation.dart';
import '../models/medicine.dart';
import '../models/prescription_item.dart';
import '../utils/default_medicines.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection References
  CollectionReference<Map<String, dynamic>> get _patientsRef =>
      _firestore.collection('patients');

  CollectionReference<Map<String, dynamic>> get _appointmentsRef =>
      _firestore.collection('appointments');

  CollectionReference<Map<String, dynamic>> get _countersRef =>
      _firestore.collection('counters');

  CollectionReference<Map<String, dynamic>> get _consultationsRef =>
      _firestore.collection('consultations');

  CollectionReference<Map<String, dynamic>> get _medicinesRef =>
      _firestore.collection('medicines');

  // ---------------------------------------------------------------------------
  // Patients
  // ---------------------------------------------------------------------------

  Future<Patient?> getPatient(String phoneNumber) async {
    final doc = await _patientsRef.doc(phoneNumber).get();
    if (doc.exists) {
      return Patient.fromJson(doc.data()!);
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Appointments
  // ---------------------------------------------------------------------------

  Future<int> bookAppointment({
    required String appointmentId,
    required Patient patient,
    required PaymentType paymentType,
    required int amountCollected,
    required DateTime scheduledDate,
    required String doctorId,
    required String doctorName,
  }) async {
    final dateKey =
        '${scheduledDate.year}-${scheduledDate.month.toString().padLeft(2, '0')}-${scheduledDate.day.toString().padLeft(2, '0')}';
    final counterRef = _countersRef.doc('queue_${doctorId}_$dateKey');
    final appointmentRef = _appointmentsRef.doc(appointmentId);
    final patientRef = _patientsRef.doc(patient.phoneNumber);
    var queueNumber = 1;

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);
      queueNumber =
          ((snapshot.data()?['currentNumber'] as num?)?.toInt() ?? 0) + 1;

      final appointment = Appointment(
        id: appointmentId,
        patientPhone: patient.phoneNumber,
        patientName: patient.name,
        status: AppointmentStatus.pending,
        paymentType: paymentType,
        amountCollected: amountCollected,
        queueNumber: queueNumber,
        scheduledDate: scheduledDate,
        doctorId: doctorId,
        doctorName: doctorName,
      );

      transaction.set(counterRef, {'currentNumber': queueNumber});
      transaction.set(appointmentRef, appointment.toJson());
      transaction.set(patientRef, {
        'id': patient.id,
        'name': patient.name,
        'age': patient.age,
        'gender': patient.gender,
        'phoneNumber': patient.phoneNumber,
      }, SetOptions(merge: true));
    });

    return queueNumber;
  }

  Future<void> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus status, {
    int? collectedAmount,
    PaymentType? paymentType,
  }) async {
    final Map<String, dynamic> data = {'status': status.name};
    if (collectedAmount != null) {
      data['amountCollected'] = collectedAmount;
    }
    if (paymentType != null) {
      data['paymentType'] = paymentType.name;
    }
    await _appointmentsRef.doc(appointmentId).update(data);
  }

  Stream<List<Appointment>> getAppointmentsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    return _appointmentsRef
        .where(
          'scheduledDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        )
        .where('scheduledDate', isLessThan: Timestamp.fromDate(end))
        .orderBy('scheduledDate')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return _appointmentFromDoc(doc.data());
          }).toList();
        });
  }

  Stream<List<Appointment>> getAppointmentsForDoctorAndDate(
    String doctorId,
    DateTime date,
  ) {
    // Reuses getAppointmentsForDate to eliminate the need for a composite
    // Firestore index (doctorId + scheduledDate). In-memory filtering is
    // instantaneous and error-free for daily clinic appointment volumes.
    return getAppointmentsForDate(date).map((appointments) {
      return appointments.where((a) => a.doctorId == doctorId).toList();
    });
  }

  /// Retrieves all historical appointments for a given patient phone number.
  /// Uses a single-field equality filter on patientPhone so no composite index is needed.
  Future<List<Appointment>> getAppointmentsForPatient(String phone) async {
    final snapshot = await _appointmentsRef
        .where('patientPhone', isEqualTo: phone)
        .get();

    return snapshot.docs.map((doc) {
      return _appointmentFromDoc(doc.data());
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Queue Numbers
  //
  // Uses an atomic transaction for each doctor's daily queue sequence.
  // Counter documents live at: counters/queue_{doctorId}_{yyyy-MM-dd}
  // ---------------------------------------------------------------------------

  // Check if a patient already has a non-cancelled appointment on this date.
  // Filters by phone in Firestore (single-field query) and evaluates date range
  // in memory to avoid requiring a composite index.
  Future<bool> hasAppointmentForDate(String phone, DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final query = await _appointmentsRef
        .where('patientPhone', isEqualTo: phone)
        .get();

    for (var doc in query.docs) {
      final appt = _appointmentFromDoc(doc.data());
      if (appt.status != AppointmentStatus.absent) {
        if (!appt.scheduledDate.isBefore(start) &&
            appt.scheduledDate.isBefore(end)) {
          return true;
        }
      }
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Chamber Real-Time Session (Zero-Touch Sync)
  // ---------------------------------------------------------------------------

  Future<void> callTokenIntoChamber({
    required String doctorId,
    required DateTime date,
    required Appointment appointment,
  }) async {
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final chamberDocId = 'chamber_${doctorId}_$dateKey';
    await _countersRef.doc(chamberDocId).set({
      'doctorId': doctorId,
      'date': dateKey,
      'activeAppointmentId': appointment.id,
      'activeQueueNumber': appointment.queueNumber,
      'patientName': appointment.patientName,
      'patientPhone': appointment.patientPhone,
      'calledAt': FieldValue.serverTimestamp(),
      'status': 'calling',
    }, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamChamberSession(
    String doctorId,
    DateTime date,
  ) {
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final chamberDocId = 'chamber_${doctorId}_$dateKey';
    return _countersRef.doc(chamberDocId).snapshots();
  }

  Future<void> clearChamberSession(String doctorId, DateTime date) async {
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final chamberDocId = 'chamber_${doctorId}_$dateKey';
    await _countersRef.doc(chamberDocId).set({
      'activeAppointmentId': null,
      'activeQueueNumber': null,
      'status': 'idle',
      'clearedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // Doctors
  // ---------------------------------------------------------------------------

  Future<void> addDoctor(Doctor doctor) async {
    await _firestore.collection('doctors').doc(doctor.id).set(doctor.toJson());
  }

  Future<void> updateDoctorSearchPreference(
    String doctorId,
    String searchPreference,
  ) async {
    await _firestore.collection('doctors').doc(doctorId).update({
      'searchPreference': searchPreference,
    });
  }

  Stream<List<Doctor>> getDoctors() {
    return _firestore.collection('doctors').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Doctor.fromJson(doc.data());
      }).toList();
    });
  }

  Future<void> deleteDoctor(String doctorId) async {
    await _firestore.collection('doctors').doc(doctorId).delete();
  }

  // ---------------------------------------------------------------------------
  // Longitudinal Consultations (Append-Only)
  // ---------------------------------------------------------------------------

  /// Records an immutable clinical consultation encounter.
  /// Follows the strict append-only policy: each consultation is a new document.
  /// Also updates appointment status to 'completed' and syncs patient last visit date.
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

    // 3. Keep patient record synced
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
  /// Queries by patientPhone and sorts in memory to avoid requiring a remote composite index.
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

  // ---------------------------------------------------------------------------
  // Master Medicine Catalogue
  // ---------------------------------------------------------------------------

  Future<void> addMedicine(Medicine medicine) async {
    await _medicinesRef.doc(medicine.id).set(medicine.toJson());
  }

  Future<void> deleteMedicine(String medicineId) async {
    await _medicinesRef.doc(medicineId).delete();
  }

  Stream<List<Medicine>> getMedicines() {
    return _medicinesRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Medicine.fromJson(doc.data())).toList();
    });
  }

  /// Ensures standard, essential OPD medicines exist in Firestore by default.
  /// Uses deterministic document IDs so execution is strictly idempotent.
  Future<void> ensureDefaultMedicinesExist() async {
    final snapshot = await _medicinesRef.limit(1).get();
    if (snapshot.docs.isEmpty) {
      final batch = _firestore.batch();
      for (final med in defaultEssentialMedicines) {
        batch.set(_medicinesRef.doc(med.id), med.toJson());
      }
      await batch.commit();
    }
  }

  /// Scans the medicines collection, identifies duplicate entries (same product name,
  /// composition, and strength), preserves one canonical record, and batch deletes the rest.
  /// Returns the number of purged duplicate documents.
  Future<int> deduplicateMedicines() async {
    final snapshot = await _medicinesRef.get();
    if (snapshot.docs.isEmpty) return 0;

    final seenKeys = <String, String>{}; // key -> preserved docId
    final toDeleteDocIds = <String>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final productName = (data['productName'] as String? ?? '')
          .trim()
          .toLowerCase();
      final composition = (data['composition'] as String? ?? '')
          .trim()
          .toLowerCase();
      final strength = (data['strength'] as String? ?? '').trim().toLowerCase();

      final key = '$productName|$composition|$strength';

      if (seenKeys.containsKey(key)) {
        // If this document is a duplicate, delete it
        toDeleteDocIds.add(doc.id);
      } else {
        seenKeys[key] = doc.id;
      }
    }

    if (toDeleteDocIds.isNotEmpty) {
      // Chunk deletions in batches of 450 (Firestore limit is 500)
      for (var i = 0; i < toDeleteDocIds.length; i += 450) {
        final batch = _firestore.batch();
        final chunk = toDeleteDocIds.skip(i).take(450);
        for (final id in chunk) {
          batch.delete(_medicinesRef.doc(id));
        }
        await batch.commit();
      }
    }

    return toDeleteDocIds.length;
  }

  /// Searches the medicine catalogue across both composition and trade name.
  Future<List<Medicine>> searchMedicines(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    final snapshot = await _medicinesRef.get();
    return snapshot.docs.map((doc) => Medicine.fromJson(doc.data())).where((
      med,
    ) {
      final tradeNameMatch = med.productName.toLowerCase().contains(cleanQuery);
      final compositionMatch = med.composition.toLowerCase().contains(
        cleanQuery,
      );
      return tradeNameMatch || compositionMatch;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Appointment _appointmentFromDoc(Map<String, dynamic> data) {
    return Appointment.fromJson(data);
  }
}
