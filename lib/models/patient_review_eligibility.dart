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

  /// True if [daysSinceLastVisit] <= [allowedReviewDays] and [allowedReviewDays] > 0.
  final bool isWithinReviewPeriod;

  /// Backwards-compatible alias for [isWithinReviewPeriod].
  bool get isWithin14Days => isWithinReviewPeriod;

  /// Human-readable explanation of status.
  final String message;

  const PatientReviewEligibility({
    required this.hasVisitedDoctorEarlier,
    this.lastVisitDate,
    this.daysSinceLastVisit,
    this.allowedReviewDays = 14,
    required this.isWithinReviewPeriod,
    required this.message,
  });

  /// Evaluates review eligibility against historical appointments for a given doctor.
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

    final docLabel = doctorName != null ? 'Dr. $doctorName' : 'this doctor';

    if (pastVisitsWithDoctor.isEmpty) {
      return PatientReviewEligibility(
        hasVisitedDoctorEarlier: false,
        allowedReviewDays: allowedReviewDays,
        isWithinReviewPeriod: false,
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

    if (allowedReviewDays <= 0) {
      return PatientReviewEligibility(
        hasVisitedDoctorEarlier: true,
        lastVisitDate: latestVisit.scheduledDate,
        daysSinceLastVisit: daysSince,
        allowedReviewDays: 0,
        isWithinReviewPeriod: false,
        message: '$docLabel does not offer free reviews (0-day policy).',
      );
    }

    final withinWindow = daysSince <= allowedReviewDays;

    return PatientReviewEligibility(
      hasVisitedDoctorEarlier: true,
      lastVisitDate: latestVisit.scheduledDate,
      daysSinceLastVisit: daysSince,
      allowedReviewDays: allowedReviewDays,
      isWithinReviewPeriod: withinWindow,
      message: withinWindow
          ? 'Eligible for $allowedReviewDays-day Free Review ($daysSince day${daysSince == 1 ? '' : 's'} ago)'
          : '$allowedReviewDays days have passed ($daysSince day${daysSince == 1 ? '' : 's'} ago)',
    );
  }
}
