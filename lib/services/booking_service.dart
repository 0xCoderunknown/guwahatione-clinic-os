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
    final patientRef = _patientsRef.doc(patient.id);
    var queueNumber = 1;

    final effectiveCheckedInAt =
        checkedInAt ??
        (visitStatus == VisitStatus.waitingInLobby ? DateTime.now() : null);

    await _firestore.runTransaction((transaction) async {
      // 1. Read current daily queue number
      final snapshot = await transaction.get(counterRef);
      queueNumber =
          ((snapshot.data()?['currentNumber'] as num?)?.toInt() ?? 0) + 1;

      final appointment = Appointment(
        id: appointmentId,
        patientId: patient.id,
        patientPhone: patient.phoneNumber,
        patientName: patient.name,
        patientAgeDisplay: patient.formattedAge,
        guardianName: patient.guardianName,
        guardianRelation: patient.guardianRelation,
        visitStatus: visitStatus,
        paymentType: paymentType,
        amountCollected: amountCollected,
        queueNumber: queueNumber,
        scheduledDate: scheduledDate,
        doctorId: doctorId,
        doctorName: doctorName,
        checkedInAt: effectiveCheckedInAt,
      );

      // 2. Commit atomic writes
      transaction.set(counterRef, {'currentNumber': queueNumber});
      transaction.set(appointmentRef, appointment.toJson());
      transaction.set(patientRef, patient.toJson(), SetOptions(merge: true));
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
    final apptDoc = _appointmentsRef.doc(appointmentId);

    final checkInTime = checkedInAt ?? DateTime.now();
    final Map<String, dynamic> data = {
      'visitStatus': VisitStatus.waitingInLobby.name,
      'status': AppointmentStatus.pending.name,
      'paymentType': paymentType.name,
      'amountCollected': amountCollected,
      'checkedInAt': Timestamp.fromDate(checkInTime),
    };
    await apptDoc.update(data);
  }

  /// Updates appointment visitStatus to inConsultation when entering chamber.
  Future<void> admitPatientToChamber(String appointmentId) async {
    final apptDoc = _appointmentsRef.doc(appointmentId);

    await apptDoc.update({
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
    final effectiveVisitStatus =
        visitStatus ??
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

    final apptDoc = _appointmentsRef.doc(appointmentId);
    await apptDoc.update(data);
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

  /// Retrieves historical appointments for a given patient identity or phone number.
  Future<List<Appointment>> getAppointmentsForPatient(
    String patientId, {
    String? phone,
  }) async {
    final cleanId = patientId.trim();
    if (cleanId.isEmpty) return [];

    // 1. Query by patientId
    final snapshot = await _appointmentsRef
        .where('patientId', isEqualTo: cleanId)
        .get();

    List<Appointment> list = snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] ??= doc.id;
      return Appointment.fromJson(data);
    }).toList();

    // 2. Backward compatibility fallback for legacy records
    if (list.isEmpty) {
      final fallbackPhone = phone?.trim() ?? cleanId;
      final phoneSnap = await _appointmentsRef
          .where('patientPhone', isEqualTo: fallbackPhone)
          .get();
      list = phoneSnap.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] ??= doc.id;
        return Appointment.fromJson(data);
      }).toList();
    }

    list.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
    return list;
  }

  /// Checks if a patient already has a non-absent appointment on this date with a specific doctor and name.
  Future<bool> hasAppointmentForDate({
    required String phone,
    required DateTime date,
    String? patientName,
    String? doctorId,
    String? patientId,
  }) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    var queryRef = _appointmentsRef.where(
      'patientPhone',
      isEqualTo: phone.trim(),
    );
    if (doctorId != null && doctorId.isNotEmpty) {
      queryRef = queryRef.where('doctorId', isEqualTo: doctorId);
    }
    final query = await queryRef.get();

    final cleanName = patientName?.trim().toLowerCase();
    final cleanPatId = patientId?.trim();
    for (var doc in query.docs) {
      final appt = Appointment.fromJson(doc.data());
      if (appt.status != AppointmentStatus.absent) {
        if (!appt.scheduledDate.isBefore(start) &&
            appt.scheduledDate.isBefore(end)) {
          if (cleanPatId != null &&
              cleanPatId.isNotEmpty &&
              appt.patientId.isNotEmpty &&
              appt.patientId == cleanPatId) {
            return true;
          }
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

  /// Closes today's session for a specific doctor when the doctor is absent or unavailable.
  /// Atomically updates all un-consulted appointments (pending / booked / waitingInLobby)
  /// to AppointmentStatus.absent with amountCollected = 0.
  /// Strict Audit Invariant: NEVER deletes documents.
  Future<int> closeDoctorSessionForDate({
    required String doctorId,
    required DateTime date,
    String reason = 'Doctor absent / session closed',
  }) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final snapshot = await _appointmentsRef
        .where('doctorId', isEqualTo: doctorId)
        .where(
          'scheduledDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        )
        .where('scheduledDate', isLessThan: Timestamp.fromDate(end))
        .get();

    final batch = _firestore.batch();
    int markedCount = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final visitStatus = data['visitStatus'] as String?;
      final status = data['status'] as String?;
      final isCompleted =
          visitStatus == VisitStatus.completed.name ||
          status == AppointmentStatus.completed.name;
      final isAlreadyAbsent =
          visitStatus == VisitStatus.cancelled.name ||
          status == AppointmentStatus.absent.name;

      if (!isCompleted && !isAlreadyAbsent) {
        batch.update(doc.reference, {
          'visitStatus': VisitStatus.cancelled.name,
          'status': AppointmentStatus.absent.name,
          'amountCollected': 0,
          'notes': reason,
        });
        markedCount++;
      }
    }

    if (markedCount > 0) {
      await batch.commit();
    }
    return markedCount;
  }
}
