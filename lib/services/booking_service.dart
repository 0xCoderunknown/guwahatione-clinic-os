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
    VisitStatus visitStatus = VisitStatus.waitingInLobby,
    required PaymentType paymentType,
    required int amountCollected,
    required DateTime scheduledDate,
    required String doctorId,
    required String doctorName,
    DateTime? checkedInAt,
  }) async {
    final counterRef = _countersRef.doc(
      FirestorePaths.doctorQueueCounter(doctorId, scheduledDate),
    );
    final appointmentRef = _appointmentsRef.doc(appointmentId);
    final patientRef = _patientsRef.doc(patient.phoneNumber);
    var queueNumber = 1;

    final effectiveCheckedInAt = checkedInAt ??
        (visitStatus == VisitStatus.waitingInLobby ? DateTime.now() : null);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);
      queueNumber =
          ((snapshot.data()?['currentNumber'] as num?)?.toInt() ?? 0) + 1;

      final appointment = Appointment(
        id: appointmentId,
        patientPhone: patient.phoneNumber,
        patientName: patient.name,
        visitStatus: visitStatus,
        paymentType: paymentType,
        amountCollected: amountCollected,
        queueNumber: queueNumber,
        scheduledDate: scheduledDate,
        doctorId: doctorId,
        doctorName: doctorName,
        checkedInAt: effectiveCheckedInAt,
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

  /// 1-tap reception check-in workflow for advance/phone bookings.
  /// Updates visitStatus to waitingInLobby, updates payment details, and timestamps checkedInAt.
  Future<void> checkInPatient({
    required String appointmentId,
    required PaymentType paymentType,
    required int amountCollected,
    DateTime? checkedInAt,
  }) async {
    final Map<String, dynamic> data = {
      'visitStatus': VisitStatus.waitingInLobby.name,
      'status': AppointmentStatus.pending.name,
      'paymentType': paymentType.name,
      'amountCollected': amountCollected,
      'checkedInAt': Timestamp.fromDate(checkedInAt ?? DateTime.now()),
    };
    await _appointmentsRef.doc(appointmentId).update(data);
  }

  /// Updates appointment visitStatus to inConsultation when entering chamber.
  Future<void> admitPatientToChamber(String appointmentId) async {
    await _appointmentsRef.doc(appointmentId).update({
      'visitStatus': VisitStatus.inConsultation.name,
      'status': AppointmentStatus.pending.name,
    });
  }

  /// Updates status and optionally collected amount, payment type, or visitStatus.
  Future<void> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus status, {
    VisitStatus? visitStatus,
    int? collectedAmount,
    PaymentType? paymentType,
  }) async {
    final effectiveVisitStatus = visitStatus ??
        (status == AppointmentStatus.completed
            ? VisitStatus.completed
            : (status == AppointmentStatus.absent
                ? VisitStatus.cancelled
                : VisitStatus.waitingInLobby));

    final Map<String, dynamic> data = {
      'status': status.name,
      'visitStatus': effectiveVisitStatus.name,
    };
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
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] ??= doc.id;
      return Appointment.fromJson(data);
    }).toList();
  }

  /// Checks if a patient already has a non-absent appointment on this date with a specific doctor and name.
  Future<bool> hasAppointmentForDate({
    required String phone,
    required DateTime date,
    String? patientName,
    String? doctorId,
  }) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    var queryRef =
        _appointmentsRef.where('patientPhone', isEqualTo: phone.trim());
    if (doctorId != null && doctorId.isNotEmpty) {
      queryRef = queryRef.where('doctorId', isEqualTo: doctorId);
    }
    final query = await queryRef.get();

    final cleanName = patientName?.trim().toLowerCase();
    for (var doc in query.docs) {
      final appt = Appointment.fromJson(doc.data());
      if (appt.status != AppointmentStatus.absent) {
        if (!appt.scheduledDate.isBefore(start) &&
            appt.scheduledDate.isBefore(end)) {
          if (cleanName != null && cleanName.isNotEmpty) {
            if (appt.patientName.trim().toLowerCase() == cleanName) {
              return true;
            }
          } else {
            return true;
          }
        }
      }
    }
    return false;
  }
}
