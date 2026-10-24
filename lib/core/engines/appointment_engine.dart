import '../../config/clinic_config.dart';
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
/// top-level completed history, and waiting tokens.
class ReceptionQueueView {
  final List<Appointment> completed;
  final List<Appointment> inChamberPatients;
  Appointment? get inChamber => inChamberPatients.firstOrNull;
  final List<Appointment> waiting;
  final List<Appointment> booked;
  final List<Appointment> absent;

  const ReceptionQueueView({
    required this.completed,
    this.inChamberPatients = const [],
    required this.waiting,
    this.booked = const [],
    required this.absent,
  });
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

    // Filter appointments for THIS doctor scheduled before targetDay,
    // or completed on the exact same date (same-day return / lab review),
    // excluding absent/unattended records.
    final pastVisitsWithDoctor = patientHistory.where((a) {
      if (a.doctorId != doctorId) return false;
      if (a.status == AppointmentStatus.absent) return false;
      final aDay = DateTime(
        a.scheduledDate.year,
        a.scheduledDate.month,
        a.scheduledDate.day,
      );
      if (aDay.isBefore(targetDay)) return true;
      if (aDay.isAtSameMomentAs(targetDay) &&
          a.status == AppointmentStatus.completed) {
        return true;
      }
      return false;
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

    final String timeAgoLabel = daysSincePaid == 0
        ? 'Same-day return / lab review'
        : '$daysSincePaid day${daysSincePaid == 1 ? '' : 's'} ago';

    return PatientReviewEligibility(
      hasVisitedDoctorEarlier: true,
      lastVisitDate: latestPaidVisit.scheduledDate,
      daysSinceLastVisit: daysSincePaid,
      allowedReviewDays: freeReviewDays,
      isWithinReviewPeriod: withinWindow,
      isReviewAlreadyConsumed: false,
      message: withinWindow
          ? 'Eligible for $freeReviewDays-day Free Review ($timeAgoLabel)'
          : '$freeReviewDays days have passed since paid visit ($timeAgoLabel)',
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
      case PaymentType.paidCarryOver:
      case PaymentType.freeReview:
      case PaymentType.freeFamily:
      case PaymentType.unpaid:
        return 0;
      case PaymentType.postPay:
      case PaymentType.paidCash:
      case PaymentType.paidUpi:
        return doctor?.consultationFee ??
            ClinicConfig.current.defaultConsultationFee;
    }
  }

  /// Identifies if a patient has an eligible prepaid, un-consulted appointment from a prior date (QOL-03).
  ///
  /// Eligibility criteria:
  /// 1. Belongs to the same doctor (doctorId matches).
  /// 2. Scheduled on a prior date strictly before [targetDate].
  /// 3. Was paid (paidCash, paidUpi, or amountCollected > 0).
  /// 4. Patient was not consulted (status is absent, or cancelled/unattended).
  /// 5. Has not been refunded and has not already been carried forward (refundStatus != 'refunded' && refundStatus != 'carried_forward').
  /// 6. Within the validity window (default [validityDays] = 30 days).
  static Appointment? findEligibleCarryOverAppointment({
    required List<Appointment> patientHistory,
    required String? doctorId,
    required DateTime targetDate,
    String? patientId,
    String? patientName,
    int validityDays = 30,
  }) {
    if (doctorId == null || doctorId.isEmpty) return null;

    final targetDay = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );
    final earliestAllowed = targetDay.subtract(Duration(days: validityDays));

    final cleanPatId = patientId?.trim();
    final cleanName = patientName?.trim().toLowerCase();

    // Sort descending to find the most recent eligible appointment first
    final sorted = List<Appointment>.from(patientHistory)
      ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));

    for (final a in sorted) {
      if (a.doctorId != doctorId) continue;

      final apptDay = DateTime(
        a.scheduledDate.year,
        a.scheduledDate.month,
        a.scheduledDate.day,
      );

      // Must be strictly from a prior calendar date
      if (!apptDay.isBefore(targetDay)) continue;

      // Must be within validity window
      if (apptDay.isBefore(earliestAllowed)) continue;

      // Match patient identity if provided
      if (cleanPatId != null && cleanPatId.isNotEmpty) {
        if (a.patientId.isNotEmpty && a.patientId != cleanPatId) continue;
      } else if (cleanName != null && cleanName.isNotEmpty) {
        if (a.patientName.trim().toLowerCase() != cleanName) continue;
      }

      // Must have been a paid visit
      final wasPaid = (a.paymentType == PaymentType.paidCash ||
          a.paymentType == PaymentType.paidUpi ||
          a.amountCollected > 0);
      if (!wasPaid) continue;

      // Must NOT have completed consultation
      if (a.status == AppointmentStatus.completed) continue;

      // Must NOT be already refunded or already carried forward
      if (a.refundStatus == 'refunded' || a.refundStatus == 'carried_forward') {
        continue;
      }

      return a;
    }

    return null;
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
  /// Separates completed patients (for top collapsible accordion), isolates active
  /// in-chamber patient(s), and sorts waiting appointments by token in FIFO order.
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
    final List<Appointment> inChamberPatients = [];

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

        if (matchesActive) {
          inChamberPatients.add(a);
        } else {
          waiting.add(a);
        }
      }
    }

    // Sort completed descending by token so most recently completed are on top
    completed.sort((a, b) => b.queueNumber.compareTo(a.queueNumber));

    // Sort inChamberPatients ascending by token
    inChamberPatients.sort((a, b) => a.queueNumber.compareTo(b.queueNumber));

    // Sort waiting ascending by token
    waiting.sort((a, b) => a.queueNumber.compareTo(b.queueNumber));

    // Sort booked ascending by token
    booked.sort((a, b) => a.queueNumber.compareTo(b.queueNumber));

    return ReceptionQueueView(
      completed: completed,
      inChamberPatients: inChamberPatients,
      waiting: waiting,
      booked: booked,
      absent: absent,
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

    // Count pending patients ahead of this target token who are waiting in lobby
    final patientsAhead = doctorAppointments.where((a) {
      return a.queueNumber < targetQueueNumber &&
          a.status == AppointmentStatus.pending &&
          a.visitStatus != VisitStatus.inConsultation;
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
    const shortDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const fullDays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final shortDay = shortDays[date.weekday - 1];
    final fullDay = fullDays[date.weekday - 1];
    return doctor.availableDays.any((d) {
      final normalized = d.trim().toLowerCase();
      return normalized == shortDay.toLowerCase() ||
          normalized == fullDay.toLowerCase() ||
          normalized.startsWith(shortDay.toLowerCase());
    });
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
    final normalized =
        doctor!.blockedDates
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

  /// Generates a valid 10-digit dummy contact phone number for illiterate, elderly,
  /// or emergency trauma walk-ins who arrive without a mobile phone.
  ///
  /// Conforms to the 10-digit national schema using the reserved non-mobile prefix '00'
  /// plus the last 8 digits of the current millisecond timestamp for guaranteed uniqueness.
  /// Indian telecom regulations (TRAI) prohibit real mobile numbers starting with '0',
  /// guaranteeing zero possibility of collision with a real patient's mobile number.
  /// Example: '00' + '12345678' -> '0012345678'.
  static String generateEmergencyDummyPhone({DateTime? timestamp}) {
    final now = timestamp ?? DateTime.now();
    final msStr = now.millisecondsSinceEpoch.toString();
    final suffix = msStr.length >= 8
        ? msStr.substring(msStr.length - 8)
        : msStr.padLeft(8, '0');
    return '00$suffix';
  }

  /// Whether a phone number is an internal dummy phone generated for emergency/no-phone walk-ins.
  static bool isEmergencyDummyPhone(String phone) {
    final clean = phone.trim();
    return clean.length == 10 && clean.startsWith('00');
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
