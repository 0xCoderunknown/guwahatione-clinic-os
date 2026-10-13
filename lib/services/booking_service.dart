import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/appointment.dart';
import '../models/appointment_event.dart';
import '../models/patient.dart';
import 'firestore_paths.dart';

/// Exception thrown when an atomic duplicate booking is detected at the transaction boundary.
class DuplicateBookingException implements Exception {
  final String message;
  const DuplicateBookingException(this.message);

  @override
  String toString() => message;
}

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

  CollectionReference<Map<String, dynamic>> get _eventsRef =>
      _firestore.collection(FirestorePaths.appointmentEvents);

  /// Atomically verifies booking lock, allocates the next daily queue number,
  /// creates the appointment, upserts the patient demographic profile, and
  /// records the initial forensic audit event in a single transaction.
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
    final lockRef = _countersRef.doc(
      FirestorePaths.bookingLock(
        doctorId,
        scheduledDate,
        patient.phoneNumber,
        patient.name,
      ),
    );
    final appointmentRef = _appointmentsRef.doc(appointmentId);
    final patientRef = _patientsRef.doc(patient.phoneNumber);
    final eventRef = _eventsRef.doc();
    var queueNumber = 1;

    final effectiveCheckedInAt = checkedInAt ??
        (visitStatus == VisitStatus.waitingInLobby ? DateTime.now() : null);

    await _firestore.runTransaction((transaction) async {
      // 1. Concurrency Boundary: Verify atomic duplicate lock
      final lockSnapshot = await transaction.get(lockRef);
      if (lockSnapshot.exists) {
        throw DuplicateBookingException(
          'Patient ${patient.name} already has an active booking with this doctor today.',
        );
      }

      // 2. Read current daily queue number
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

      final event = AppointmentEvent(
        id: eventRef.id,
        appointmentId: appointmentId,
        eventType: AppointmentEventType.created,
        visitStatus: visitStatus,
        amountCollected: amountCollected,
        paymentType: paymentType,
        actorRole: 'receptionist',
        timestamp: DateTime.now(),
        note: 'Appointment booked (Token #$queueNumber)',
      );

      // 3. Commit atomic writes
      transaction.set(lockRef, {
        'appointmentId': appointmentId,
        'createdAt': FieldValue.serverTimestamp(),
        'doctorId': doctorId,
        'patientPhone': patient.phoneNumber,
        'patientName': patient.name,
      });
      transaction.set(counterRef, {'currentNumber': queueNumber});
      transaction.set(appointmentRef, appointment.toJson());
      transaction.set(patientRef, {
        'id': patient.id,
        'name': patient.name,
        'age': patient.age,
        'gender': patient.gender,
        'phoneNumber': patient.phoneNumber,
      }, SetOptions(merge: true));
      transaction.set(eventRef, event.toJson());
    });

    return queueNumber;
  }

  /// 1-tap reception check-in workflow for advance/phone bookings.
  /// Updates visitStatus to waitingInLobby, updates payment details, timestamps checkedInAt,
  /// and appends an immutable audit event.
  Future<void> checkInPatient({
    required String appointmentId,
    required PaymentType paymentType,
    required int amountCollected,
    DateTime? checkedInAt,
  }) async {
    final batch = _firestore.batch();
    final apptDoc = _appointmentsRef.doc(appointmentId);
    final eventDoc = _eventsRef.doc();

    final checkInTime = checkedInAt ?? DateTime.now();
    final Map<String, dynamic> data = {
      'visitStatus': VisitStatus.waitingInLobby.name,
      'status': AppointmentStatus.pending.name,
      'paymentType': paymentType.name,
      'amountCollected': amountCollected,
      'checkedInAt': Timestamp.fromDate(checkInTime),
    };
    batch.update(apptDoc, data);

    final event = AppointmentEvent(
      id: eventDoc.id,
      appointmentId: appointmentId,
      eventType: AppointmentEventType.checkedIn,
      visitStatus: VisitStatus.waitingInLobby,
      amountCollected: amountCollected,
      paymentType: paymentType,
      actorRole: 'receptionist',
      timestamp: checkInTime,
      note: 'Patient checked into lobby desk',
    );
    batch.set(eventDoc, event.toJson());

    await batch.commit();
  }

  /// Updates appointment visitStatus to inConsultation when entering chamber and appends audit event.
  Future<void> admitPatientToChamber(String appointmentId) async {
    final batch = _firestore.batch();
    final apptDoc = _appointmentsRef.doc(appointmentId);
    final eventDoc = _eventsRef.doc();

    batch.update(apptDoc, {
      'visitStatus': VisitStatus.inConsultation.name,
      'status': AppointmentStatus.pending.name,
    });

    final event = AppointmentEvent(
      id: eventDoc.id,
      appointmentId: appointmentId,
      eventType: AppointmentEventType.admitted,
      visitStatus: VisitStatus.inConsultation,
      actorRole: 'receptionist',
      timestamp: DateTime.now(),
      note: 'Patient admitted into doctor chamber',
    );
    batch.set(eventDoc, event.toJson());

    await batch.commit();
  }

  /// Updates status and optionally collected amount, payment type, or visitStatus,
  /// and appends an immutable audit event.
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

    final batch = _firestore.batch();
    final apptDoc = _appointmentsRef.doc(appointmentId);
    final eventDoc = _eventsRef.doc();

    batch.update(apptDoc, data);

    final eventType = status == AppointmentStatus.absent
        ? AppointmentEventType.markedAbsent
        : (status == AppointmentStatus.completed
            ? AppointmentEventType.completed
            : AppointmentEventType.statusUpdated);

    final event = AppointmentEvent(
      id: eventDoc.id,
      appointmentId: appointmentId,
      eventType: eventType,
      visitStatus: effectiveVisitStatus,
      amountCollected: collectedAmount,
      paymentType: paymentType,
      actorRole: 'receptionist',
      timestamp: DateTime.now(),
      note: 'Status updated to ${status.name} / ${effectiveVisitStatus.name}',
    );
    batch.set(eventDoc, event.toJson());

    await batch.commit();
  }

  /// Streams audit trail events for a specific appointment, ordered by timestamp.
  Stream<List<AppointmentEvent>> getAppointmentEvents(String appointmentId) {
    return _eventsRef
        .where('appointmentId', isEqualTo: appointmentId)
        .snapshots()
        .map((snapshot) {
          final events = snapshot.docs
              .map((doc) => AppointmentEvent.fromJson(doc.data()))
              .toList();
          events.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return events;
        });
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
