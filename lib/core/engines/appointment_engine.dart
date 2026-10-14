import '../../models/models.dart';
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
  /// Evaluates review eligibility against historical appointments for a given doctor.
  /// 1. Only a patient who visited earlier can get a free review with the SAME doctor.
  /// 2. If doctor policy has 0 free review days, free reviews are disabled/not offered.
  /// 3. If within doctor's configured [freeReviewDays] (0 to 30), free review is fully eligible.
  /// 4. If more than [freeReviewDays] have passed, free review is flagged with an advisory warning.
  /// 5. Absent visits never qualify as prior encounters.
  static PatientReviewEligibility evaluateReviewEligibility({
    required List<Appointment> patientHistory,
    required String? doctorId,
    required DateTime targetDate,
    String? doctorName,
    int freeReviewDays = 14,
  }) {
    return PatientReviewEligibility.calculate(
      appointments: patientHistory,
      doctorId: doctorId,
      targetDate: targetDate,
      doctorName: doctorName,
      allowedReviewDays: freeReviewDays,
    );
  }

  /// Automatically determines suggested payment type based on patient visit history.
  static PaymentType suggestPaymentType({
    required List<Appointment> patientHistory,
    required String? doctorId,
    required DateTime targetDate,
    int freeReviewDays = 14,
  }) {
    final eligibility = evaluateReviewEligibility(
      patientHistory: patientHistory,
      doctorId: doctorId,
      targetDate: targetDate,
      freeReviewDays: freeReviewDays,
    );
    if (eligibility.hasVisitedDoctorEarlier &&
        eligibility.isWithinReviewPeriod) {
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
    Set<String>? activeAppointmentIds,
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
        final matchesActive =
            (activeAppointmentId != null && a.id == activeAppointmentId) ||
            (activeAppointmentId == null &&
                activeQueueNumber != null &&
                a.queueNumber == activeQueueNumber) ||
            (activeAppointmentIds != null &&
                activeAppointmentIds.contains(a.id));

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

  /// Calculates total booked tokens count for a doctor on a target date.
  ///
  /// Reflects the highest issued queue token ($1 \dots N$) to maintain audit-proof
  /// capacity tracking according to sequential queue invariants.
  static int calculateBookedTokensCount({
    required List<Appointment> appointments,
    required String doctorId,
    required DateTime targetDate,
  }) {
    final nextToken = calculateProvisionalNextToken(
      appointments: appointments,
      doctorId: doctorId,
      targetDate: targetDate,
    );
    return nextToken > 1 ? nextToken - 1 : 0;
  }

  /// Evaluates the token cap alert status based on [bookedCount] and [limit].
  ///
  /// - [TokenCapStatus.overCap]: bookedCount > limit (e.g. 19/18)
  /// - [TokenCapStatus.atLimit]: bookedCount == limit (e.g. 18/18)
  /// - [TokenCapStatus.runwayAlert]: bookedCount >= limit - 2 (e.g. 16/18 or 17/18)
  /// - [TokenCapStatus.normal]: bookedCount < limit - 2 (e.g. 12/18)
  static TokenCapStatus evaluateTokenCapStatus({
    required int bookedCount,
    required int limit,
  }) {
    if (bookedCount > limit) return TokenCapStatus.overCap;
    if (bookedCount == limit) return TokenCapStatus.atLimit;
    if (bookedCount >= limit - 2) return TokenCapStatus.runwayAlert;
    return TokenCapStatus.normal;
  }

  /// Checks if the given date matches the doctor's configured available days.
  /// Returns true if doctor has no day restrictions (all days configured or empty),
  /// or if the target date's weekday matches one of the doctor's available days.
  static bool isDoctorAvailableOnDate({
    required Doctor? doctor,
    required DateTime date,
  }) {
    if (doctor == null || doctor.availableDays.isEmpty) return true;
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final currentDay = dayNames[date.weekday - 1];
    return doctor.availableDays.contains(currentDay);
  }
}

/// Operational token allocation alert statuses for doctor OPD capacity.
enum TokenCapStatus {
  /// Regular volume comfortably under limit (< limit - 2).
  normal,

  /// Runway warning threshold reached (limit - 2 <= booked < limit).
  runwayAlert,

  /// Capacity cap fully filled (booked == limit).
  atLimit,

  /// Over-cap booking allowed for emergency front-desk admissions (booked > limit).
  overCap,
}
