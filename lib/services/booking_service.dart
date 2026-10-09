import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment.dart';
import '../models/patient.dart';
import 'firestore_paths.dart';

/// Service managing appointment bookings, atomic queue counters, and queue queries.
class BookingService {
  final FirebaseFirestore _firestore;

  BookingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _appointmentsRef =>
      _firestore.collection(FirestorePaths.appointments);

  CollectionReference<Map<String, dynamic>> get _countersRef =>
      _firestore.collection(FirestorePaths.counters);

  CollectionReference<Map<String, dynamic>> get _patientsRef =>
      _firestore.collection(FirestorePaths.patients);

  /// Atomically allocates the next daily queue number, creates the appointment,
  /// and upserts the patient demographic profile in a single transaction.
  Future<int> bookAppointment({
    required String appointmentId,
    required Patient patient,
    required PaymentType paymentType,
    required int amountCollected,
    required DateTime scheduledDate,
    required String doctorId,
    required String doctorName,
  }) async {
    final counterRef = _countersRef.doc(
      FirestorePaths.doctorQueueCounter(doctorId, scheduledDate),
    );
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

  /// Updates status and optionally collected amount or payment type.
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

  /// Streams appointments for a given calendar date.
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
            return Appointment.fromJson(doc.data());
          }).toList();
        });
  }

  /// Streams appointments for a specific doctor on a given date.
  /// Reuses getAppointmentsForDate to eliminate composite index requirements.
  Stream<List<Appointment>> getAppointmentsForDoctorAndDate(
    String doctorId,
    DateTime date,
  ) {
    return getAppointmentsForDate(date).map((appointments) {
      return appointments.where((a) => a.doctorId == doctorId).toList();
    });
  }

  /// Retrieves all historical appointments for a given patient phone number.
  Future<List<Appointment>> getAppointmentsForPatient(String phone) async {
    final snapshot = await _appointmentsRef
        .where('patientPhone', isEqualTo: phone)
        .get();

    return snapshot.docs.map((doc) {
      return Appointment.fromJson(doc.data());
    }).toList();
  }

  /// Checks if a patient already has a non-absent appointment on this date.
  Future<bool> hasAppointmentForDate(String phone, DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final query = await _appointmentsRef
        .where('patientPhone', isEqualTo: phone)
        .get();

    for (var doc in query.docs) {
      final appt = Appointment.fromJson(doc.data());
      if (appt.status != AppointmentStatus.absent) {
        if (!appt.scheduledDate.isBefore(start) &&
            appt.scheduledDate.isBefore(end)) {
          return true;
        }
      }
    }
    return false;
  }
}
