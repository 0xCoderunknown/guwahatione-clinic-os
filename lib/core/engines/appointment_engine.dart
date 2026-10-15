import '../../models/models.dart';
import '../../utils/app_constants.dart';
import '../../utils/formatters.dart';

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
  /// 1. Finds the most recent PAID visit with this doctor. Non-paid visits (unpaid,
  ///    courtesy, absent, or prior reviews) cannot originate a free review.
  /// 2. If doctor policy is 0 days, free reviews are disabled.
  /// 3. If a free review has ALREADY been taken since the originating paid visit,
  ///    the entitlement is consumed and further free reviews are disallowed.
  /// 4. If within [freeReviewDays] of the paid visit and not yet consumed, eligible.
  /// 5. If more than [freeReviewDays] have passed, an advisory warning is triggered.
  /// 6. Absent visits never qualify as prior encounters.
  static PatientReviewEligibility evaluateReviewEligibility({
    required List<Appointment> patientHistory,
    required String? doctorId,
    required DateTime targetDate,
    String? doctorName,
    int freeReviewDays = 14,
  }) {
    if (doctorId == null || doctorId.isEmpty) {
      return PatientReviewEligibility(
        hasVisitedDoctorEarlier: false,
        allowedReviewDays: freeReviewDays,
        isWithinReviewPeriod: false,
        isReviewAlreadyConsumed: false,
        message: 'No doctor selected.',
      );
    }

    final targetDay = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );

    // Filter appointments for THIS doctor scheduled strictly before targetDay,
    // excluding absent/unattended records.
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

    final docLabel = doctorName != null
        ? AppFormatters.doctorTitle(doctorName)
        : 'this doctor';

    if (pastVisitsWithDoctor.isEmpty) {
      return PatientReviewEligibility(
        hasVisitedDoctorEarlier: false,
        allowedReviewDays: freeReviewDays,
        isWithinReviewPeriod: false,
        isReviewAlreadyConsumed: false,
        message: 'No earlier visit with $docLabel.',
      );
    }

    // Sort descending by scheduledDate to inspect the timeline
    pastVisitsWithDoctor.sort(
      (a, b) => b.scheduledDate.compareTo(a.scheduledDate),
    );

    // Find the most recent PAID consultation that originates a review cycle.
    // (Excludes freeReview, freeFamily, unpaid, or zero-fee non-paid visits).
    Appointment? latestPaidVisit;
    for (final a in pastVisitsWithDoctor) {
      if (a.paymentType.isPaid ||
          (a.paymentType == PaymentType.postPay && a.amountCollected > 0)) {
        latestPaidVisit = a;
        break;
      }
    }

    // If the patient never had a paid consultation with this doctor, no free review is unlocked.
    if (latestPaidVisit == null) {
      return PatientReviewEligibility(
        hasVisitedDoctorEarlier: false,
        allowedReviewDays: freeReviewDays,
        isWithinReviewPeriod: false,
        isReviewAlreadyConsumed: false,
        message: 'No prior paid consultation with $docLabel.',
      );
    }

    final latestPaidDay = DateTime(
      latestPaidVisit.scheduledDate.year,
      latestPaidVisit.scheduledDate.month,
      latestPaidVisit.scheduledDate.day,
    );

    final daysSincePaid = targetDay.difference(latestPaidDay).inDays;

    // Doctor policy check: 0 days disables free reviews completely.
    if (freeReviewDays <= 0) {
      return PatientReviewEligibility(
        hasVisitedDoctorEarlier: true,
        lastVisitDate: latestPaidVisit.scheduledDate,
        daysSinceLastVisit: daysSincePaid,
        allowedReviewDays: 0,
        isWithinReviewPeriod: false,
        isReviewAlreadyConsumed: false,
        message: '$docLabel does not offer free reviews (0-day policy).',
      );
    }

    // Check if the single free review entitlement has ALREADY been used
    // for this paid consultation cycle (i.e. any visit between latestPaidDay and targetDay
    // with paymentType == freeReview).
    final hasAlreadyConsumedReview = pastVisitsWithDoctor.any((a) {
      if (a.paymentType != PaymentType.freeReview) return false;
      final aDay = DateTime(
        a.scheduledDate.year,
        a.scheduledDate.month,
        a.scheduledDate.day,
      );
      return !aDay.isBefore(latestPaidDay);
    });

    if (hasAlreadyConsumedReview) {
      return PatientReviewEligibility(
        hasVisitedDoctorEarlier: true,
        lastVisitDate: latestPaidVisit.scheduledDate,
        daysSinceLastVisit: daysSincePaid,
        allowedReviewDays: freeReviewDays,
        isWithinReviewPeriod: false,
        isReviewAlreadyConsumed: true,
        message:
            'Free review already used for visit on ${AppFormatters.date(latestPaidVisit.scheduledDate)} (1 review allowed per paid visit).',
      );
    }

    final withinWindow = daysSincePaid <= freeReviewDays;

    return PatientReviewEligibility(
      hasVisitedDoctorEarlier: true,
      lastVisitDate: latestPaidVisit.scheduledDate,
      daysSinceLastVisit: daysSincePaid,
      allowedReviewDays: freeReviewDays,
      isWithinReviewPeriod: withinWindow,
      isReviewAlreadyConsumed: false,
      message: withinWindow
          ? 'Eligible for $freeReviewDays-day Free Review ($daysSincePaid day${daysSincePaid == 1 ? '' : 's'} ago)'
          : '$freeReviewDays days have passed since paid visit ($daysSincePaid day${daysSincePaid == 1 ? '' : 's'} ago)',
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
  /// Composite key: (targetDate + doctorId + (patientId match OR (normalized patientName + patientPhone)))
  static Appointment? findDuplicateBooking({
    required List<Appointment> appointments,
    required String? doctorId,
    required String patientName,
    required String patientPhone,
    String? patientId,
    required DateTime targetDate,
  }) {
    if (doctorId == null || doctorId.isEmpty) return null;
    final cleanPhone = patientPhone.trim();
    final cleanName = patientName.trim().toLowerCase();
    final cleanPatId = patientId?.trim();
    if (cleanPhone.isEmpty || cleanName.isEmpty) return null;

    final start = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final end = start.add(const Duration(days: 1));

    for (final a in appointments) {
      if (a.doctorId != doctorId) continue;
      if (a.status == AppointmentStatus.absent) continue;
      if (a.scheduledDate.isBefore(start) || !a.scheduledDate.isBefore(end)) {
        continue;
      }

      if (cleanPatId != null &&
          cleanPatId.isNotEmpty &&
          a.patientId.isNotEmpty &&
          a.patientId == cleanPatId) {
        return a;
      }

      if (a.patientPhone.trim() == cleanPhone &&
          a.patientName.trim().toLowerCase() == cleanName) {
        return a;
      }
    }
    return null;
  }

  /// Evaluates whether an appointment already exists for the given patient identity
  /// (matching patientId, or normalized name + phone) with this doctor on the target date.
  static bool hasDuplicateAppointment({
    required List<Appointment> existingAppointments,
    required String patientPhone,
    required String patientName,
    String? patientId,
    required String doctorId,
    required DateTime targetDate,
  }) {
    return findDuplicateBooking(
          appointments: existingAppointments,
          doctorId: doctorId,
          patientName: patientName,
          patientPhone: patientPhone,
          patientId: patientId,
          targetDate: targetDate,
        ) !=
        null;
  }

  /// Validates whether a patient already has an active (non-absent) booking on the target date.
  static bool hasDuplicateBookingOnDate({
    required List<Appointment> appointments,
    required String phoneNumber,
    required DateTime targetDate,
    String? patientName,
    String? doctorId,
    String? patientId,
  }) {
    if (patientName != null && doctorId != null) {
      return findDuplicateBooking(
            appointments: appointments,
            doctorId: doctorId,
            patientName: patientName,
            patientPhone: phoneNumber,
            patientId: patientId,
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

    final formattedRange =
        '${AppFormatters.time(estimatedStart)} – ${AppFormatters.time(estimatedEnd)}';
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

  /// Evaluates whether a doctor is on planned leave on the given target date.
  /// Matches year, month, and day against the doctor's configured blockedDates.
  static bool isDoctorOnLeave({
    required Doctor? doctor,
    required DateTime date,
  }) {
    if (doctor == null || doctor.blockedDates.isEmpty) return false;
    final targetY = date.year;
    final targetM = date.month;
    final targetD = date.day;
    return doctor.blockedDates.any(
      (b) => b.year == targetY && b.month == targetM && b.day == targetD,
    );
  }

  /// Returns the contiguous sorted sequence of leave dates containing [date],
  /// or an empty list if [date] is not within the doctor's blocked dates.
  static List<DateTime> getContiguousDoctorLeaveBlock({
    required Doctor? doctor,
    required DateTime date,
  }) {
    if (!isDoctorOnLeave(doctor: doctor, date: date)) return const [];
    final target = DateTime(date.year, date.month, date.day);

    // Normalize, deduplicate, and sort all blocked dates
    final normalized = doctor!.blockedDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => a.compareTo(b));

    // Group into contiguous clusters where adjacent elements are exactly 1 day apart
    final clusters = <List<DateTime>>[];
    List<DateTime> currentCluster = [];

    for (int i = 0; i < normalized.length; i++) {
      if (currentCluster.isEmpty) {
        currentCluster.add(normalized[i]);
      } else {
        final prev = currentCluster.last;
        final curr = normalized[i];
        final nextDay = DateTime(prev.year, prev.month, prev.day + 1);
        if (curr.year == nextDay.year &&
            curr.month == nextDay.month &&
            curr.day == nextDay.day) {
          currentCluster.add(curr);
        } else {
          clusters.add(currentCluster);
          currentCluster = [curr];
        }
      }
    }
    if (currentCluster.isNotEmpty) {
      clusters.add(currentCluster);
    }

    for (final cluster in clusters) {
      if (cluster.contains(target)) {
        return cluster;
      }
    }

    return [target];
  }

  /// Formats human-facing leave explanation strictly adhering to Indian DD-MM-YYYY dates.
  /// - 1 day: 'Doctor is on leave on 18-10-2026'
  /// - 2 days: 'Doctor is on leave on 18-10-2026 and 19-10-2026'
  /// - 3+ days (extended / week leave): 'Doctor is on leave from 18-10-2026 to 24-10-2026'
  /// Returns null if doctor is not on leave on [date].
  static String? formatDoctorLeaveSummary({
    required Doctor? doctor,
    required DateTime date,
  }) {
    if (!isDoctorOnLeave(doctor: doctor, date: date)) return null;
    final block = getContiguousDoctorLeaveBlock(doctor: doctor, date: date);
    if (block.isEmpty) return 'Doctor is on leave';
    if (block.length == 1) {
      return 'Doctor is on leave on ${AppFormatters.date(block.first)}';
    }
    if (block.length == 2) {
      return 'Doctor is on leave on ${AppFormatters.date(block[0])} and ${AppFormatters.date(block[1])}';
    }
    return 'Doctor is on leave from ${AppFormatters.date(block.first)} to ${AppFormatters.date(block.last)}';
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
