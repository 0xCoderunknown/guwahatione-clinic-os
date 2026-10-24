import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/appointment.dart';
import '../models/patient.dart';
import 'firestore_paths.dart';

/// Service managing appointment bookings, atomic queue counters, and queue queries.
class BookingService {
  final FirebaseFirestore? _customFirestore;

  BookingService({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _appointmentsRef =>
      _firestore.collection(FirestorePaths.appointments);

  CollectionReference<Map<String, dynamic>> get _countersRef =>
      _firestore.collection(FirestorePaths.counters);

  CollectionReference<Map<String, dynamic>> get _patientsRef =>
      _firestore.collection(FirestorePaths.patients);

  /// Atomically allocates the next daily queue number, creates the appointment,
  /// upserts the patient demographic profile, and links carried-over prior appointments in a single transaction.
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
    String? carriedOverAppointmentId,
    int? carriedOverAmount,
    DateTime? carriedOverDate,
  }) async {
    final counterRef = _countersRef.doc(
      FirestorePaths.doctorQueueCounter(doctorId, scheduledDate),
    );
    final appointmentRef = _appointmentsRef.doc(appointmentId);
    final patientRef = _patientsRef.doc(patient.id);
    DocumentReference<Map<String, dynamic>>? priorApptRef;
    if (carriedOverAppointmentId != null &&
        carriedOverAppointmentId.trim().isNotEmpty) {
      priorApptRef = _appointmentsRef.doc(carriedOverAppointmentId.trim());
    }
    var queueNumber = 1;

    final effectiveCheckedInAt =
        checkedInAt ??
        (visitStatus == VisitStatus.waitingInLobby ? DateTime.now() : null);

    await _firestore.runTransaction((transaction) async {
      // 1. Read current daily queue number
      final snapshot = await transaction.get(counterRef);
      queueNumber =
          ((snapshot.data()?['currentNumber'] as num?)?.toInt() ?? 0) + 1;

      // 2. Read prior appointment if linking carry-over
      final targetPriorRef = priorApptRef;
      if (targetPriorRef != null) {
        final priorSnap = await transaction.get(targetPriorRef);
        if (priorSnap.exists) {
          transaction.update(targetPriorRef, {
            'refundStatus': 'carried_forward',
            'carriedForwardToAppointmentId': appointmentId,
            'carriedForwardDate': Timestamp.fromDate(scheduledDate),
          });
        }
      }

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
        carriedOverAppointmentId: carriedOverAppointmentId,
        carriedOverAmount: carriedOverAmount,
        carriedOverDate: carriedOverDate,
      );

      // 3. Commit atomic writes
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

  /// Updates appointment visitStatus to inConsultation when entering chamber and resets isPaused.
  Future<void> admitPatientToChamber(String appointmentId) async {
    final apptDoc = _appointmentsRef.doc(appointmentId);

    await apptDoc.update({
      'visitStatus': VisitStatus.inConsultation.name,
      'status': AppointmentStatus.pending.name,
      'isPaused': false,
    });
  }

  /// Pauses an active consultation encounter, setting visitStatus back to waitingInLobby
  /// and marking isPaused: true. Zero queue or document deletion.
  Future<void> pauseAppointment(String appointmentId) async {
    final apptDoc = _appointmentsRef.doc(appointmentId);
    await apptDoc.update({
      'visitStatus': VisitStatus.waitingInLobby.name,
      'isPaused': true,
    });
  }

  /// Resumes a paused appointment directly into active chamber.
  Future<void> resumeAppointment(String appointmentId) async {
    final apptDoc = _appointmentsRef.doc(appointmentId);
    await apptDoc.update({
      'visitStatus': VisitStatus.inConsultation.name,
      'isPaused': false,
    });
  }

  /// Returns an appointment back to waitingInLobby and clears isPaused (e.g. when an encounter is discarded).
  Future<void> returnAppointmentToLobby(String appointmentId) async {
    final apptDoc = _appointmentsRef.doc(appointmentId);
    await apptDoc.update({
      'visitStatus': VisitStatus.waitingInLobby.name,
      'isPaused': false,
    });
  }

  /// Updates status and optionally collected amount, payment type, or visitStatus.
  Future<void> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus status, {
    VisitStatus? visitStatus,
    int? collectedAmount,
    PaymentType? paymentType,
    String? refundStatus,
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
    if (refundStatus != null) {
      data['refundStatus'] = refundStatus;
    }

    final apptDoc = _appointmentsRef.doc(appointmentId);
    await apptDoc.update(data);
  }

  /// Updates patient name on an existing appointment (e.g. demographic corrections during consultation).
  Future<void> updateAppointmentPatientName({
    required String appointmentId,
    required String patientName,
  }) async {
    await _appointmentsRef.doc(appointmentId).update({
      'patientName': patientName.trim(),
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

  /// Streams upcoming advance appointments from tomorrow up to [daysAhead] days in the future.
  /// Strictly adheres to Indian date handling and excludes cancelled/absent appointments.
  Stream<List<Appointment>> getUpcomingAppointments({
    int daysAhead = 7,
    DateTime? fromDate,
  }) {
    final base = fromDate ?? DateTime.now();
    final tomorrow = DateTime(base.year, base.month, base.day).add(const Duration(days: 1));
    final futureEnd = tomorrow.add(Duration(days: daysAhead));

    return _appointmentsRef
        .where(
          'scheduledDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(tomorrow),
        )
        .where('scheduledDate', isLessThan: Timestamp.fromDate(futureEnd))
        .orderBy('scheduledDate')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => Appointment.fromJson(doc.data()))
              .toList();
          return list
              .where((a) => a.status != AppointmentStatus.absent)
              .toList();
        });
  }

  /// Retrieves appointments within an optional date range for export/auditing.
  Future<List<Appointment>> fetchAppointmentsForExport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query<Map<String, dynamic>> query = _appointmentsRef;
    if (startDate != null) {
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      query = query.where(
        'scheduledDate',
        isGreaterThanOrEqualTo: Timestamp.fromDate(start),
      );
    }
    if (endDate != null) {
      final end = DateTime(endDate.year, endDate.month, endDate.day).add(const Duration(days: 1));
      query = query.where('scheduledDate', isLessThan: Timestamp.fromDate(end));
    }
    final snapshot = await query.get();
    final list = snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] ??= doc.id;
      return Appointment.fromJson(data);
    }).toList();
    list.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
    return list;
  }

  /// Retrieves historical appointments for a given patient identity or phone number (AUDIT-28: capped at [limit]).
  Future<List<Appointment>> getAppointmentsForPatient(
    String patientId, {
    String? phone,
    int limit = 100,
  }) async {
    final cleanId = patientId.trim();
    if (cleanId.isEmpty) return [];

    // 1. Query by patientId (bounded)
    final snapshot = await _appointmentsRef
        .where('patientId', isEqualTo: cleanId)
        .limit(limit)
        .get();

    List<Appointment> list = snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] ??= doc.id;
      return Appointment.fromJson(data);
    }).toList();

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
      if (appt.status != AppointmentStatus.absent &&
          appt.status != AppointmentStatus.completed) {
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
  /// to AppointmentStatus.absent without destructively zeroing collected cash (tags refundStatus).
  /// Strict Audit Invariant: NEVER deletes documents or wipes cash drawer audit trails.
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

    final docsToUpdate = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

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
        docsToUpdate.add(doc);
      }
    }

    if (docsToUpdate.isEmpty) return 0;

    // Firestore batch hard-limit is 500 operations. Chunk in batches of 450.
    const chunkSize = 450;
    for (int i = 0; i < docsToUpdate.length; i += chunkSize) {
      final chunk = docsToUpdate.sublist(
        i,
        (i + chunkSize > docsToUpdate.length)
            ? docsToUpdate.length
            : i + chunkSize,
      );
      final batch = _firestore.batch();
      for (final doc in chunk) {
        final data = doc.data();
        final currentAmount = (data['amountCollected'] as num?)?.toInt() ?? 0;
        batch.update(doc.reference, {
          'visitStatus': VisitStatus.cancelled.name,
          'status': AppointmentStatus.absent.name,
          'refundStatus': currentAmount > 0 ? 'pending_refund' : 'none',
          'notes': reason,
        });
      }
      await batch.commit();
    }

    return docsToUpdate.length;
  }
}
