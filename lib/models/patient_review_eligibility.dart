import 'appointment.dart';

/// Encapsulates the eligibility evaluation for a patient requesting a Free Review.
///
/// Business Rules:
/// 1. Only a patient who visited earlier can get a free review, and that too if
///    they book with the SAME doctor.
/// 2. If booked within 14 days of the previous visit, free review is fully eligible.
/// 3. If more than 14 days have passed, the free review option must NOT be disabled,
///    but choosing it must immediately warn that 14 days have passed.
/// 4. If the patient has never visited this doctor earlier, free review is disabled/disallowed.
class PatientReviewEligibility {
  /// Whether the patient has any completed/attended prior visit with this doctor.
  final bool hasVisitedDoctorEarlier;

  /// The scheduled date of the most recent past visit with this doctor.
  final DateTime? lastVisitDate;

  /// Calendar days elapsed between the prior visit and the target appointment date.
  final int? daysSinceLastVisit;

  /// True if [daysSinceLastVisit] <= 14.
  final bool isWithin14Days;

  /// Human-readable explanation of status.
  final String message;

  const PatientReviewEligibility({
    required this.hasVisitedDoctorEarlier,
    this.lastVisitDate,
    this.daysSinceLastVisit,
    required this.isWithin14Days,
    required this.message,
  });

  /// Evaluates review eligibility against historical appointments for a given doctor.
  factory PatientReviewEligibility.calculate({
    required List<Appointment> appointments,
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

    if (pastVisitsWithDoctor.isEmpty) {
      final docLabel = doctorName != null ? 'Dr. $doctorName' : 'this doctor';
      return PatientReviewEligibility(
        hasVisitedDoctorEarlier: false,
        isWithin14Days: false,
        message: 'No earlier visit with $docLabel.',
      );
    }

    // Sort descending by scheduledDate to pick the most recent visit
    pastVisitsWithDoctor.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
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
}
