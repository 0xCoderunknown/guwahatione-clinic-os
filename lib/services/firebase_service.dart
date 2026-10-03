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
    // Build JSON but store scheduledDate as a Firestore Timestamp instead of
    // an ISO string. This enables proper server-side ordering and range
    // queries. fromJson handles both Timestamp and legacy ISO strings.
    final data = appointment.toJson();
    data['scheduledDate'] = Timestamp.fromDate(appointment.scheduledDate);

    await _appointmentsRef.doc(appointment.id).set(data);

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
  Future<bool> hasAppointmentForDate(String phone, DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final query = await _appointmentsRef
        .where('patientPhone', isEqualTo: phone)
        .where(
          'scheduledDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        )
        .where('scheduledDate', isLessThan: Timestamp.fromDate(end))
        .get();

    for (var doc in query.docs) {
      if (doc.data()['status'] != 'cancelled') {
        return true;
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

  /// Converts a Firestore document map to an [Appointment], handling both
  /// legacy ISO-string dates (old documents) and new Firestore Timestamps.
  Appointment _appointmentFromDoc(Map<String, dynamic> data) {
    // Normalize scheduledDate: Timestamp → ISO String so fromJson stays clean.
    final rawDate = data['scheduledDate'];
    if (rawDate is Timestamp) {
      data['scheduledDate'] = rawDate.toDate().toIso8601String();
    }
    return Appointment.fromJson(data);
  }
}
