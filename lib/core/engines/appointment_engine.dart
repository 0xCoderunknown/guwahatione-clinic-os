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

/// Pure Dart appointment, booking policy, and queue rules engine.
///
/// Single source of truth for 14-day free review calculations, fee determinations,
/// and queue partitioning. Zero Flutter UI dependencies.
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
    return PaymentType.paid;
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
        return 0;
      case PaymentType.paid:
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

  /// Checks if a date falls on a clinic holiday or blocked operational date.
  static bool isDateBlocked(DateTime date) {
    return AppConstants.isDateBlocked(date);
  }

  /// Validates whether a patient already has an active (non-absent) booking on the target date.
  static bool hasDuplicateBookingOnDate({
    required List<Appointment> appointments,
    required String phoneNumber,
    required DateTime targetDate,
  }) {
    final start = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final end = start.add(const Duration(days: 1));

    return appointments.any((a) {
      if (a.patientPhone != phoneNumber) return false;
      if (a.status == AppointmentStatus.absent) return false;
      return !a.scheduledDate.isBefore(start) && a.scheduledDate.isBefore(end);
    });
  }
}
