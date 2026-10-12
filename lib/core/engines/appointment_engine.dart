import '../../models/appointment.dart';
import '../../models/doctor.dart';
import '../../models/patient_review_eligibility.dart';
import '../../utils/app_constants.dart';

/// Partitioned appointment queue segments.
class QueuePartition {
  final List<Appointment> pending;
  final List<Appointment> completed;
  final List<Appointment> absent;

  const QueuePartition({
    required this.pending,
    required this.completed,
    required this.absent,
  });

  int get total => pending.length + completed.length + absent.length;
}

/// Reception desk queue partitioning model reflecting in-chamber status,
/// top-level completed history, and waiting/bypassed tokens.
class ReceptionQueueView {
  final List<Appointment> completed;
  final Appointment? inChamber;
  final List<Appointment> waiting;
  final List<Appointment> booked;
  final List<Appointment> absent;
  final Set<String> bypassedAppointmentIds;

  const ReceptionQueueView({
    required this.completed,
    this.inChamber,
    required this.waiting,
    this.booked = const [],
    required this.absent,
    required this.bypassedAppointmentIds,
  });

  bool isBypassed(String appointmentId) =>
      bypassedAppointmentIds.contains(appointmentId);
}

/// Estimated arrival and consultation window calculated for a queued token.
class EstimatedConsultationWindow {
  final DateTime estimatedStart;
  final DateTime estimatedEnd;
  final int patientsAhead;
  final String formattedRange;
  final String relativeSummary;

  const EstimatedConsultationWindow({
    required this.estimatedStart,
    required this.estimatedEnd,
    required this.patientsAhead,
    required this.formattedRange,
    required this.relativeSummary,
  });
}

/// Pure Dart appointment, booking policy, and queue rules engine.
///
/// Single source of truth for 14-day free review calculations, fee determinations,
/// queue partitioning, and dynamic consultation arrival estimation. Zero Flutter UI dependencies.
abstract class AppointmentEngine {
  /// Evaluates whether a patient is eligible for a Free Review with a specific doctor.
  ///
  /// Business Rules (Invariants):
  /// 1. Only a patient who visited earlier can get a free review, and that too if
  ///    they book with the SAME doctor.
  /// 2. If booked within 14 days of the previous visit, free review is fully eligible.
  /// 3. If more than 14 days have passed, free review is flagged with an advisory warning.
  /// 4. Absent visits never qualify as prior encounters.
  static PatientReviewEligibility evaluateReviewEligibility({
    required List<Appointment> patientHistory,
    required String? doctorId,
    required DateTime targetDate,
    String? doctorName,
  }) {
    if (doctorId == null || doctorId.isEmpty) {
      return const PatientReviewEligibility(
        hasVisitedDoctorEarlier: false,
        isWithin14Days: false,
        message: 'No doctor selected.',
      );
    }

    final targetDay = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );

    // Find all past visits with THIS doctor strictly before targetDay,
    // excluding absent visits.
    final pastVisitsWithDoctor = patientHistory.where((a) {
      if (a.doctorId != doctorId) return false;
      if (a.status == AppointmentStatus.absent) return false;
      final aDay = DateTime(
        a.scheduledDate.year,
        a.scheduledDate.month,
        a.scheduledDate.day,
      );
      return aDay.isBefore(targetDay);
    }).toList();

    if (pastVisitsWithDoctor.isEmpty) {
      final docLabel = doctorName != null ? 'Dr. $doctorName' : 'this doctor';
      return PatientReviewEligibility(
        hasVisitedDoctorEarlier: false,
        isWithin14Days: false,
        message: 'No earlier visit with $docLabel.',
      );
    }

    // Sort descending by scheduledDate to pick the most recent visit
    pastVisitsWithDoctor.sort(
      (a, b) => b.scheduledDate.compareTo(a.scheduledDate),
    );
    final latestVisit = pastVisitsWithDoctor.first;
    final latestVisitDay = DateTime(
      latestVisit.scheduledDate.year,
      latestVisit.scheduledDate.month,
      latestVisit.scheduledDate.day,
    );

    final daysSince = targetDay.difference(latestVisitDay).inDays;
    final within14 = daysSince <= 14;

    return PatientReviewEligibility(
      hasVisitedDoctorEarlier: true,
      lastVisitDate: latestVisit.scheduledDate,
      daysSinceLastVisit: daysSince,
      isWithin14Days: within14,
      message: within14
          ? 'Eligible for 14-day Free Review ($daysSince day${daysSince == 1 ? '' : 's'} ago)'
          : '14 days have passed ($daysSince day${daysSince == 1 ? '' : 's'} ago)',
    );
  }

  /// Automatically determines suggested payment type based on patient visit history.
  static PaymentType suggestPaymentType({
    required List<Appointment> patientHistory,
    required String? doctorId,
    required DateTime targetDate,
  }) {
    final eligibility = evaluateReviewEligibility(
      patientHistory: patientHistory,
      doctorId: doctorId,
      targetDate: targetDate,
    );
    if (eligibility.hasVisitedDoctorEarlier && eligibility.isWithin14Days) {
      return PaymentType.freeReview;
    }
    return PaymentType.paidCash;
  }

  /// Resolves the exact amount to collect from the patient based on doctor configuration
  /// and selected payment policy.
  static int resolveConsultationFee({
    required Doctor? doctor,
    required PaymentType paymentType,
  }) {
    switch (paymentType) {
      case PaymentType.freeReview:
      case PaymentType.freeFamily:
      case PaymentType.unpaid:
        return 0;
      case PaymentType.postPay:
      case PaymentType.paidCash:
      case PaymentType.paidUpi:
        return doctor?.consultationFee ?? AppConstants.defaultConsultationFee;
    }
  }

  /// Partitions an appointment list into Pending, Completed, and Absent segments.
  static QueuePartition partitionQueue(List<Appointment> appointments) {
    final List<Appointment> pending = [];
    final List<Appointment> completed = [];
    final List<Appointment> absent = [];

    for (final a in appointments) {
      switch (a.status) {
        case AppointmentStatus.pending:
          pending.add(a);
          break;
        case AppointmentStatus.completed:
          completed.add(a);
          break;
        case AppointmentStatus.absent:
          absent.add(a);
          break;
      }
    }

    return QueuePartition(
      pending: pending,
      completed: completed,
      absent: absent,
    );
  }

  /// Partitions appointments for the Reception desk live queue view.
  ///
  /// Separates completed patients (for top collapsible accordion), isolates the active
  /// in-chamber patient if matched, sorts waiting appointments by token, and marks
  /// uncalled waiting tokens lower than the active chamber token as bypassed.
  static ReceptionQueueView partitionQueueForReception({
    required List<Appointment> appointments,
    String? activeAppointmentId,
    int? activeQueueNumber,
  }) {
    final List<Appointment> completed = [];
    final List<Appointment> waiting = [];
    final List<Appointment> booked = [];
    final List<Appointment> absent = [];
    Appointment? inChamber;

    for (final a in appointments) {
      if (a.visitStatus == VisitStatus.completed) {
        completed.add(a);
      } else if (a.visitStatus == VisitStatus.cancelled) {
        absent.add(a);
      } else if (a.visitStatus == VisitStatus.booked) {
        booked.add(a);
      } else {
        final matchesActive = (activeAppointmentId != null &&
                a.id == activeAppointmentId) ||
            (activeAppointmentId == null &&
                activeQueueNumber != null &&
                a.queueNumber == activeQueueNumber);

        if (matchesActive && inChamber == null) {
          inChamber = a;
        } else {
          waiting.add(a);
        }
      }
    }

    // Sort completed descending by token so most recently completed are on top
    completed.sort((a, b) => b.queueNumber.compareTo(a.queueNumber));

    // Sort waiting ascending by token
    waiting.sort((a, b) => a.queueNumber.compareTo(b.queueNumber));

    // Sort booked ascending by token
    booked.sort((a, b) => a.queueNumber.compareTo(b.queueNumber));

    final Set<String> bypassed = {};
    if (inChamber != null) {
      for (final a in waiting) {
        if (a.queueNumber < inChamber.queueNumber) {
          bypassed.add(a.id);
        }
      }
    }

    return ReceptionQueueView(
      completed: completed,
      inChamber: inChamber,
      waiting: waiting,
      booked: booked,
      absent: absent,
      bypassedAppointmentIds: bypassed,
    );
  }

  /// Checks if a date falls on a clinic holiday or blocked operational date.
  static bool isDateBlocked(DateTime date) {
    return AppConstants.isDateBlocked(date);
  }

  /// Checks if an active (non-absent) booking already exists for the exact same patient
  /// with the same doctor on the given target date.
  ///
  /// Composite key: (targetDate + doctorId + normalized patientName + patientPhone)
  static Appointment? findDuplicateBooking({
    required List<Appointment> appointments,
    required String? doctorId,
    required String patientName,
    required String patientPhone,
    required DateTime targetDate,
  }) {
    if (doctorId == null || doctorId.isEmpty) return null;
    final cleanPhone = patientPhone.trim();
    final cleanName = patientName.trim().toLowerCase();
    if (cleanPhone.isEmpty || cleanName.isEmpty) return null;

    final start = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final end = start.add(const Duration(days: 1));

    for (final a in appointments) {
      if (a.doctorId != doctorId) continue;
      if (a.status == AppointmentStatus.absent) continue;
      if (a.scheduledDate.isBefore(start) || !a.scheduledDate.isBefore(end)) {
        continue;
      }

      if (a.patientPhone.trim() == cleanPhone &&
          a.patientName.trim().toLowerCase() == cleanName) {
        return a;
      }
    }
    return null;
  }

  /// Validates whether a patient already has an active (non-absent) booking on the target date.
  static bool hasDuplicateBookingOnDate({
    required List<Appointment> appointments,
    required String phoneNumber,
    required DateTime targetDate,
    String? patientName,
    String? doctorId,
  }) {
    if (patientName != null && doctorId != null) {
      return findDuplicateBooking(
            appointments: appointments,
            doctorId: doctorId,
            patientName: patientName,
            patientPhone: phoneNumber,
            targetDate: targetDate,
          ) !=
          null;
    }

    final start = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final end = start.add(const Duration(days: 1));

    return appointments.any((a) {
      if (a.patientPhone != phoneNumber) return false;
      if (a.status == AppointmentStatus.absent) return false;
      return !a.scheduledDate.isBefore(start) && a.scheduledDate.isBefore(end);
    });
  }

  /// Calculates dynamic estimated consultation time window for a token in a doctor's queue.
  ///
  /// Considers pending appointments ahead of this token, chamber start time, and clinical
  /// average consultation duration (default: 8 minutes per patient).
  static EstimatedConsultationWindow calculateEstimatedWindow({
    required List<Appointment> doctorAppointments,
    required int targetQueueNumber,
    DateTime? chamberStartTime,
    DateTime? currentTime,
    int averageMinutesPerPatient = 8,
  }) {
    final now = currentTime ?? DateTime.now();

    // Count pending patients ahead of this target token
    final patientsAhead = doctorAppointments.where((a) {
      return a.queueNumber < targetQueueNumber &&
          a.status == AppointmentStatus.pending;
    }).length;

    if (patientsAhead <= 0) {
      final start = now;
      final end = start.add(Duration(minutes: averageMinutesPerPatient));
      return EstimatedConsultationWindow(
        estimatedStart: start,
        estimatedEnd: end,
        patientsAhead: 0,
        formattedRange: 'Now / Next Up',
        relativeSummary: 'Next in line',
      );
    }

    // Determine baseline time
    final baseTime = (chamberStartTime != null && chamberStartTime.isAfter(now))
        ? chamberStartTime
        : now;

    final startMinutes = patientsAhead * averageMinutesPerPatient;
    final estimatedStart = baseTime.add(Duration(minutes: startMinutes));
    final estimatedEnd = estimatedStart.add(
      Duration(minutes: averageMinutesPerPatient + 7),
    );

    String formatTime(DateTime dt) {
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    }

    final formattedRange =
        '${formatTime(estimatedStart)} – ${formatTime(estimatedEnd)}';
    final waitMinutes = startMinutes;
    final relativeSummary = '~$waitMinutes min wait ($patientsAhead ahead)';

    return EstimatedConsultationWindow(
      estimatedStart: estimatedStart,
      estimatedEnd: estimatedEnd,
      patientsAhead: patientsAhead,
      formattedRange: formattedRange,
      relativeSummary: relativeSummary,
    );
  }

  /// Calculates the provisional next queue token number for a doctor on a target date.
  ///
  /// Invariant: Queue numbers are consecutive starting from 1 for the day.
  /// Scans existing appointments for the doctor on [targetDate] and returns max(queueNumber) + 1.
  static int calculateProvisionalNextToken({
    required List<Appointment> appointments,
    required String doctorId,
    required DateTime targetDate,
  }) {
    final start = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final end = start.add(const Duration(days: 1));

    int maxQueue = 0;
    for (final a in appointments) {
      if (a.doctorId == doctorId &&
          !a.scheduledDate.isBefore(start) &&
          a.scheduledDate.isBefore(end)) {
        if (a.queueNumber > maxQueue) {
          maxQueue = a.queueNumber;
        }
      }
    }
    return maxQueue + 1;
  }

  /// Calculates provisional estimated consultation window for the next token in queue.
  static EstimatedConsultationWindow calculateProvisionalEstimatedWindow({
    required List<Appointment> appointments,
    required String doctorId,
    required DateTime targetDate,
    DateTime? currentTime,
    int averageMinutesPerPatient = 8,
  }) {
    final nextToken = calculateProvisionalNextToken(
      appointments: appointments,
      doctorId: doctorId,
      targetDate: targetDate,
    );
    final doctorAppointments = appointments
        .where((a) => a.doctorId == doctorId)
        .toList();

    return calculateEstimatedWindow(
      doctorAppointments: doctorAppointments,
      targetQueueNumber: nextToken,
      currentTime: currentTime,
      averageMinutesPerPatient: averageMinutesPerPatient,
    );
  }

  /// Counts appointments booked for a specific doctor.
  static int countDoctorAppointments({
    required List<Appointment> appointments,
    required String doctorId,
  }) {
    return appointments.where((a) => a.doctorId == doctorId).length;
  }
}
