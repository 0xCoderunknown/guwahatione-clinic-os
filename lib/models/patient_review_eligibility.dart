import '../utils/formatters.dart';
import 'appointment.dart';

/// Encapsulates the eligibility evaluation for a patient requesting a Free Review.
///
/// Business Rules:
/// 1. Only a patient who visited earlier can get a free review, and that too if
///    they book with the SAME doctor.
/// 2. If the doctor's policy is 0 days, free reviews are disabled/not offered.
/// 3. If booked within the doctor's configured [allowedReviewDays] (0 to 30 days),
///    the review is fully eligible.
/// 4. If more than [allowedReviewDays] have passed, an advisory warning is triggered.
/// 5. If the patient has never visited this doctor earlier, free review is disallowed.
class PatientReviewEligibility {
  /// Whether the patient has any completed/attended prior visit with this doctor.
  final bool hasVisitedDoctorEarlier;

  /// The scheduled date of the most recent past visit with this doctor.
  final DateTime? lastVisitDate;

  /// Calendar days elapsed between the prior visit and the target appointment date.
  final int? daysSinceLastVisit;

  /// The doctor's configured free review grace period (0 to 30 days).
  final int allowedReviewDays;

  /// True if [daysSinceLastVisit] <= [allowedReviewDays] and [allowedReviewDays] > 0
  /// and the single free review entitlement has not already been used.
  final bool isWithinReviewPeriod;

  /// True if a free review was already used for the most recent paid consultation cycle.
  final bool isReviewAlreadyConsumed;

  /// Human-readable explanation of status.
  final String message;

  const PatientReviewEligibility({
    required this.hasVisitedDoctorEarlier,
    this.lastVisitDate,
    this.daysSinceLastVisit,
    this.allowedReviewDays = 14,
    required this.isWithinReviewPeriod,
    this.isReviewAlreadyConsumed = false,
    required this.message,
  });

  /// Evaluates review eligibility against historical appointments for a given doctor.
  ///
  /// Strict 1:1 Paid-to-Review Cycle:
  /// 1. Finds the most recent PAID visit with this doctor. Non-paid visits (unpaid,
  ///    courtesy, absent, or prior reviews) cannot originate a free review.
  /// 2. If doctor policy is 0 days, free reviews are disabled.
  /// 3. If a free review has ALREADY been taken since the originating paid visit,
  ///    the entitlement is consumed and further free reviews are disallowed.
  /// 4. If within [allowedReviewDays] of the paid visit and not yet consumed, eligible.
  /// 5. If more than [allowedReviewDays] have passed, an advisory warning is triggered.
  factory PatientReviewEligibility.calculate({
    required List<Appointment> appointments,
    required String? doctorId,
    required DateTime targetDate,
    String? doctorName,
    int allowedReviewDays = 14,
  }) {
    if (doctorId == null || doctorId.isEmpty) {
      return PatientReviewEligibility(
        hasVisitedDoctorEarlier: false,
        allowedReviewDays: allowedReviewDays,
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
    final pastVisitsWithDoctor = appointments.where((a) {
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
        allowedReviewDays: allowedReviewDays,
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
        allowedReviewDays: allowedReviewDays,
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
    if (allowedReviewDays <= 0) {
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
        allowedReviewDays: allowedReviewDays,
        isWithinReviewPeriod: false,
        isReviewAlreadyConsumed: true,
        message:
            'Free review already used for visit on ${latestPaidVisit.scheduledDate.day.toString().padLeft(2, '0')}-${latestPaidVisit.scheduledDate.month.toString().padLeft(2, '0')}-${latestPaidVisit.scheduledDate.year} (1 review allowed per paid visit).',
      );
    }

    final withinWindow = daysSincePaid <= allowedReviewDays;

    return PatientReviewEligibility(
      hasVisitedDoctorEarlier: true,
      lastVisitDate: latestPaidVisit.scheduledDate,
      daysSinceLastVisit: daysSincePaid,
      allowedReviewDays: allowedReviewDays,
      isWithinReviewPeriod: withinWindow,
      isReviewAlreadyConsumed: false,
      message: withinWindow
          ? 'Eligible for $allowedReviewDays-day Free Review ($daysSincePaid day${daysSincePaid == 1 ? '' : 's'} ago)'
          : '$allowedReviewDays days have passed since paid visit ($daysSincePaid day${daysSincePaid == 1 ? '' : 's'} ago)',
    );
  }
}
