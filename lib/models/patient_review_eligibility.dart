import '../core/engines/appointment_engine.dart';
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
  /// Delegates directly to pure domain [AppointmentEngine.evaluateReviewEligibility].
  factory PatientReviewEligibility.calculate({
    required List<Appointment> appointments,
    required String? doctorId,
    required DateTime targetDate,
    String? doctorName,
    int allowedReviewDays = 14,
  }) {
    return AppointmentEngine.evaluateReviewEligibility(
      patientHistory: appointments,
      doctorId: doctorId,
      targetDate: targetDate,
      doctorName: doctorName,
      freeReviewDays: allowedReviewDays,
    );
  }
}

