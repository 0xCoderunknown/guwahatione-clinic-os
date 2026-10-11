import '../../models/appointment.dart';

/// Aggregated KPI metrics for a doctor's chamber session.
class ChamberKpiMetrics {
  final int totalBooked;
  final int attendedCount;
  final int paidCount;
  final int freeCount;
  final int absentCount;
  final int waitingCount;
  final int totalDoctorFees;

  const ChamberKpiMetrics({
    required this.totalBooked,
    required this.attendedCount,
    required this.paidCount,
    required this.freeCount,
    required this.absentCount,
    required this.waitingCount,
    required this.totalDoctorFees,
  });

  factory ChamberKpiMetrics.empty() {
    return const ChamberKpiMetrics(
      totalBooked: 0,
      attendedCount: 0,
      paidCount: 0,
      freeCount: 0,
      absentCount: 0,
      waitingCount: 0,
      totalDoctorFees: 0,
    );
  }
}

/// Aggregated doctor statistics summary for owner dashboard & reports.
class DoctorAnalyticsSummary {
  final String doctorId;
  final String doctorName;
  final int totalPatients;
  final int completed;
  final int pending;
  final int absent;
  final int free;
  final int realizedRevenue;

  const DoctorAnalyticsSummary({
    required this.doctorId,
    required this.doctorName,
    required this.totalPatients,
    required this.completed,
    required this.pending,
    required this.absent,
    required this.free,
    required this.realizedRevenue,
  });
}

/// Overall daily reception metrics.
class DailyRevenueMetrics {
  final int totalAppointments;
  final int completedCount;
  final int pendingCount;
  final int absentCount;
  final int realizedRevenue;

  const DailyRevenueMetrics({
    required this.totalAppointments,
    required this.completedCount,
    required this.pendingCount,
    required this.absentCount,
    required this.realizedRevenue,
  });
}

/// Pure Dart financial calculation & metrics engine.
///
/// Single source of truth for clinic revenue, realized fees, and chamber KPIs.
/// Zero Flutter UI dependencies.
abstract class RevenueEngine {
  /// Calculates realized revenue for a collection of appointments.
  ///
  /// Revenue Rule: Only completed consultations generate realized revenue.
  /// Pending or absent appointments never contribute to realized revenue.
  static int calculateRealizedRevenue(List<Appointment> appointments) {
    return appointments
        .where((a) => a.status == AppointmentStatus.completed)
        .fold(0, (sum, a) => sum + a.amountCollected);
  }

  /// Calculates total fees collected specifically for a doctor across their completed appointments.
  static int calculateDoctorTotalFees(List<Appointment> appointments) {
    return appointments
        .where(
          (a) =>
              a.status == AppointmentStatus.completed &&
              a.paymentType == PaymentType.paid,
        )
        .fold(0, (sum, a) => sum + a.amountCollected);
  }

  /// Computes reception-level daily metrics in a single pass.
  static DailyRevenueMetrics calculateDailyMetrics(
    List<Appointment> appointments,
  ) {
    int completed = 0;
    int pending = 0;
    int absent = 0;
    int realizedRevenue = 0;

    for (final a in appointments) {
      switch (a.status) {
        case AppointmentStatus.completed:
          completed++;
          realizedRevenue += a.amountCollected;
          break;
        case AppointmentStatus.pending:
          pending++;
          break;
        case AppointmentStatus.absent:
          absent++;
          break;
      }
    }

    return DailyRevenueMetrics(
      totalAppointments: appointments.length,
      completedCount: completed,
      pendingCount: pending,
      absentCount: absent,
      realizedRevenue: realizedRevenue,
    );
  }

  /// Computes all KPI metrics required for the Doctor Chamber in a single pass.
  static ChamberKpiMetrics calculateChamberKpis(
    List<Appointment> appointments,
  ) {
    int attended = 0;
    int paid = 0;
    int free = 0;
    int absent = 0;
    int waiting = 0;
    int totalDoctorFees = 0;

    for (final a in appointments) {
      switch (a.status) {
        case AppointmentStatus.completed:
          attended++;
          if (a.paymentType == PaymentType.paid) {
            paid++;
            totalDoctorFees += a.amountCollected;
          } else {
            free++;
          }
          break;
        case AppointmentStatus.pending:
          waiting++;
          break;
        case AppointmentStatus.absent:
          absent++;
          break;
      }
    }

    return ChamberKpiMetrics(
      totalBooked: appointments.length,
      attendedCount: attended,
      paidCount: paid,
      freeCount: free,
      absentCount: absent,
      waitingCount: waiting,
      totalDoctorFees: totalDoctorFees,
    );
  }

  /// Groups appointments by doctor and computes performance analytics.
  static List<DoctorAnalyticsSummary> calculateDoctorAnalytics(
    List<Appointment> appointments,
  ) {
    if (appointments.isEmpty) return const [];

    final Map<String, List<Appointment>> grouped = {};
    for (final a in appointments) {
      grouped.putIfAbsent(a.doctorId, () => []).add(a);
    }

    final List<DoctorAnalyticsSummary> summaries = [];

    for (final entry in grouped.entries) {
      final docAppts = entry.value;
      final docName = docAppts.first.doctorName;
      final docId = entry.key;

      int completed = 0;
      int pending = 0;
      int absent = 0;
      int free = 0;
      int revenue = 0;

      for (final a in docAppts) {
        if (a.paymentType != PaymentType.paid) {
          free++;
        }
        switch (a.status) {
          case AppointmentStatus.completed:
            completed++;
            revenue += a.amountCollected;
            break;
          case AppointmentStatus.pending:
            pending++;
            break;
          case AppointmentStatus.absent:
            absent++;
            break;
        }
      }

      summaries.add(
        DoctorAnalyticsSummary(
          doctorId: docId,
          doctorName: docName,
          totalPatients: docAppts.length,
          completed: completed,
          pending: pending,
          absent: absent,
          free: free,
          realizedRevenue: revenue,
        ),
      );
    }

    return summaries;
  }

  /// Generates the daily end-of-day financial handover summary for cash drawer balancing.
  static CashHandoverSummary calculateCashHandover({
    required List<Appointment> appointments,
    required DateTime date,
  }) {
    int totalCompleted = 0;
    int totalPaid = 0;
    int totalFreeReview = 0;
    int totalFreeFamily = 0;
    int totalCash = 0;

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

      for (final a in docAppts) {
        if (a.status == AppointmentStatus.completed) {
          docCompleted++;
          totalCompleted++;

          switch (a.paymentType) {
            case PaymentType.paid:
              docPaid++;
              totalPaid++;
              docCash += a.amountCollected;
              totalCash += a.amountCollected;
              break;
            case PaymentType.freeReview:
              docFreeReview++;
              totalFreeReview++;
              break;
            case PaymentType.freeFamily:
              docFreeFamily++;
              totalFreeFamily++;
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
      totalRealizedCash: totalCash,
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

/// Doctor breakdown row for end-of-day cash handover.
class CashHandoverDoctorRow {
  final String doctorId;
  final String doctorName;
  final int totalPatients;
  final int completedCount;
  final int paidCount;
  final int freeReviewCount;
  final int freeFamilyCount;
  final int cashCollected;

  const CashHandoverDoctorRow({
    required this.doctorId,
    required this.doctorName,
    required this.totalPatients,
    required this.completedCount,
    required this.paidCount,
    required this.freeReviewCount,
    required this.freeFamilyCount,
    required this.cashCollected,
  });
}

/// Aggregated end-of-day financial handover summary.
class CashHandoverSummary {
  final DateTime date;
  final int totalAppointments;
  final int totalCompleted;
  final int totalPaidCount;
  final int totalFreeReviewCount;
  final int totalFreeFamilyCount;
  final int totalRealizedCash;
  final List<CashHandoverDoctorRow> doctorBreakdown;

  const CashHandoverSummary({
    required this.date,
    required this.totalAppointments,
    required this.totalCompleted,
    required this.totalPaidCount,
    required this.totalFreeReviewCount,
    required this.totalFreeFamilyCount,
    required this.totalRealizedCash,
    required this.doctorBreakdown,
  });
}
