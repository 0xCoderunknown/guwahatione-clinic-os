import '../../models/models.dart';

/// Doctor breakdown row for end-of-day cash handover.
class CashHandoverDoctorRow {
  final String doctorId;
  final String doctorName;
  final int totalPatients;
  final int completedCount;
  final int paidCount;
  final int freeReviewCount;
  final int freeFamilyCount;
  final int cashCollected; // Physical cash in drawer (paidCash + postPay)
  final int upiCollected; // Digital UPI in bank account (paidUpi)
  final int totalRevenue; // cashCollected + upiCollected

  const CashHandoverDoctorRow({
    required this.doctorId,
    required this.doctorName,
    required this.totalPatients,
    required this.completedCount,
    required this.paidCount,
    required this.freeReviewCount,
    required this.freeFamilyCount,
    required this.cashCollected,
    this.upiCollected = 0,
    int? totalRevenue,
  }) : totalRevenue = totalRevenue ?? (cashCollected + upiCollected);
}

/// Aggregated end-of-day financial handover summary.
class CashHandoverSummary {
  final DateTime date;
  final int totalAppointments;
  final int totalCompleted;
  final int totalPaidCount;
  final int totalFreeReviewCount;
  final int totalFreeFamilyCount;
  final int totalPhysicalCash; // Physical cash in counter drawer
  final int totalUpiRevenue; // Bank account UPI collections
  final int totalRevenue; // totalPhysicalCash + totalUpiRevenue
  final List<CashHandoverDoctorRow> doctorBreakdown;

  /// Expected physical cash in drawer for cash reconciliation
  int get totalRealizedCash => totalPhysicalCash;

  const CashHandoverSummary({
    required this.date,
    required this.totalAppointments,
    required this.totalCompleted,
    required this.totalPaidCount,
    required this.totalFreeReviewCount,
    required this.totalFreeFamilyCount,
    required this.totalPhysicalCash,
    this.totalUpiRevenue = 0,
    int? totalRevenue,
    required this.doctorBreakdown,
  }) : totalRevenue = totalRevenue ?? (totalPhysicalCash + totalUpiRevenue);
}

/// Pure Dart daily end-of-day financial handover & cash drawer reconciliation engine.
///
/// Handles doctor breakdown aggregation, denomination calculations, and audit discrepancy evaluation.
/// Zero Flutter UI or Firebase SDK dependencies.
abstract class CashHandoverEngine {
  /// Generates the daily end-of-day financial handover summary for cash drawer balancing.
  static CashHandoverSummary calculateCashHandover({
    required List<Appointment> appointments,
    required DateTime date,
  }) {
    int totalCompleted = 0;
    int totalPaid = 0;
    int totalFreeReview = 0;
    int totalFreeFamily = 0;
    int totalPhysicalCash = 0;
    int totalUpiRevenue = 0;

    final Map<String, List<Appointment>> byDoctor = {};
    for (final a in appointments) {
      byDoctor.putIfAbsent(a.doctorId, () => []).add(a);
    }

    final List<CashHandoverDoctorRow> doctorRows = [];

    for (final entry in byDoctor.entries) {
      final docAppts = entry.value;
      final docName = docAppts.first.doctorName;
      final docId = entry.key;

      int docCompleted = 0;
      int docPaid = 0;
      int docFreeReview = 0;
      int docFreeFamily = 0;
      int docCash = 0;
      int docUpi = 0;

      for (final a in docAppts) {
        if (a.status == AppointmentStatus.completed) {
          docCompleted++;
          totalCompleted++;

          switch (a.paymentType) {
            case PaymentType.paidCash:
            case PaymentType.postPay:
              if (a.amountCollected > 0) {
                docPaid++;
                totalPaid++;
                docCash += a.amountCollected;
                totalPhysicalCash += a.amountCollected;
              }
              break;
            case PaymentType.paidUpi:
              if (a.amountCollected > 0) {
                docPaid++;
                totalPaid++;
                docUpi += a.amountCollected;
                totalUpiRevenue += a.amountCollected;
              }
              break;
            case PaymentType.freeReview:
              docFreeReview++;
              totalFreeReview++;
              break;
            case PaymentType.freeFamily:
              docFreeFamily++;
              totalFreeFamily++;
              break;
            case PaymentType.unpaid:
              break;
          }
        }
      }

      doctorRows.add(
        CashHandoverDoctorRow(
          doctorId: docId,
          doctorName: docName,
          totalPatients: docAppts.length,
          completedCount: docCompleted,
          paidCount: docPaid,
          freeReviewCount: docFreeReview,
          freeFamilyCount: docFreeFamily,
          cashCollected: docCash,
          upiCollected: docUpi,
          totalRevenue: docCash + docUpi,
        ),
      );
    }

    return CashHandoverSummary(
      date: date,
      totalAppointments: appointments.length,
      totalCompleted: totalCompleted,
      totalPaidCount: totalPaid,
      totalFreeReviewCount: totalFreeReview,
      totalFreeFamilyCount: totalFreeFamily,
      totalPhysicalCash: totalPhysicalCash,
      totalUpiRevenue: totalUpiRevenue,
      totalRevenue: totalPhysicalCash + totalUpiRevenue,
      doctorBreakdown: doctorRows,
    );
  }

  /// Calculates total physical cash counted from denomination counts.
  /// Map keys are denominations (e.g. 500, 200, 100, 50, 20, 10), values are note counts.
  static int calculateDenominationTotal(Map<int, int> denominationCounts) {
    int total = 0;
    for (final entry in denominationCounts.entries) {
      if (entry.value > 0) {
        total += entry.key * entry.value;
      }
    }
    return total;
  }

  /// Computes difference between counted physical cash and expected realized system cash.
  /// Positive = surplus, Negative = shortage, 0 = balanced.
  static int calculateDiscrepancy({
    required int physicalCounted,
    required int expectedCash,
  }) {
    return physicalCounted - expectedCash;
  }
}
