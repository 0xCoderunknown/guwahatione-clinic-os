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
        .where((a) =>
            a.status == AppointmentStatus.completed &&
            a.paymentType == PaymentType.paid)
        .fold(0, (sum, a) => sum + a.amountCollected);
  }

  /// Computes reception-level daily metrics in a single pass.
  static DailyRevenueMetrics calculateDailyMetrics(List<Appointment> appointments) {
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
  static ChamberKpiMetrics calculateChamberKpis(List<Appointment> appointments) {
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
      List<Appointment> appointments) {
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
}
