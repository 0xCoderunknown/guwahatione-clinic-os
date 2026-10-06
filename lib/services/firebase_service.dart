import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient.dart';
import '../models/appointment.dart';
import '../models/doctor.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection References
  CollectionReference<Map<String, dynamic>> get _patientsRef =>
      _firestore.collection('patients');

  CollectionReference<Map<String, dynamic>> get _appointmentsRef =>
      _firestore.collection('appointments');

  CollectionReference<Map<String, dynamic>> get _countersRef =>
      _firestore.collection('counters');

  // ---------------------------------------------------------------------------
  // Patients
  // ---------------------------------------------------------------------------

  Future<void> addPatient(Patient patient) async {
    // Phone number is the document key — upserts cleanly.
    await _patientsRef.doc(patient.phoneNumber).set(patient.toJson());
  }

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

  Future<void> createAppointment(Appointment appointment) async {
    await _appointmentsRef.doc(appointment.id).set(appointment.toJson());

    // Keep the patient's lastVisitDate in sync.
    await _patientsRef.doc(appointment.patientPhone).update({
      'lastVisitDate': appointment.scheduledDate.toIso8601String(),
    });
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
  // Uses an atomic Firestore transaction on a per-day counter document to
  // prevent duplicate queue numbers when two bookings happen simultaneously.
  // Counter documents live at: counters/{YYYY-MM-DD}
  // ---------------------------------------------------------------------------

  Future<int> getNextQueueNumber(DateTime date) async {
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final counterRef = _countersRef.doc(dateKey);

    int queueNumber = 1;

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);
      if (snapshot.exists) {
        queueNumber = ((snapshot.data()!['count'] as num?)?.toInt() ?? 0) + 1;
      } else {
        queueNumber = 1;
      }
      transaction.set(counterRef, {'count': queueNumber, 'date': dateKey});
    });

    return queueNumber;
  }

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
  // Doctors
  // ---------------------------------------------------------------------------

  Future<void> addDoctor(Doctor doctor) async {
    await _firestore
        .collection('doctors')
        .doc(doctor.id)
        .set(doctor.toJson());
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
  // Helpers
  // ---------------------------------------------------------------------------

  Appointment _appointmentFromDoc(Map<String, dynamic> data) {
    return Appointment.fromJson(data);
  }
}
