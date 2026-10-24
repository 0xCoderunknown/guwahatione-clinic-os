import 'package:flutter/material.dart';

import '../../core/engines/engines.dart';
import '../../models/appointment.dart';
import '../common/metric_kpi_card.dart';

/// Live KPI metrics grid for Doctor Chamber (Consulted, Waiting, Pending, Doctor Fees).
class ChamberMetricsGrid extends StatelessWidget {
  final int totalBooked;
  final int attendedCount;
  final int paidCount;
  final int freeCount;
  final int absentCount;
  final int waitingCount;
  final int pendingArrivalCount;
  final int totalFees;
  final bool isDesktop;
  final bool isPastDate;

  const ChamberMetricsGrid({
    super.key,
    required this.totalBooked,
    required this.attendedCount,
    required this.paidCount,
    required this.freeCount,
    required this.absentCount,
    required this.waitingCount,
    this.pendingArrivalCount = 0,
    required this.totalFees,
    required this.isDesktop,
    this.isPastDate = false,
  });

  factory ChamberMetricsGrid.fromAppointments({
    Key? key,
    required List<Appointment> appointments,
    required bool isDesktop,
    bool isPastDate = false,
  }) {
    final kpis = RevenueEngine.calculateChamberKpis(appointments);

    final absentCount = appointments
        .where(
          (a) =>
              a.status == AppointmentStatus.absent ||
              a.visitStatus == VisitStatus.cancelled ||
              (isPastDate && a.visitStatus != VisitStatus.completed),
        )
        .length;

    final waitingCount = isPastDate
        ? 0
        : appointments
            .where(
              (a) =>
                  a.status == AppointmentStatus.pending &&
                  (a.visitStatus == VisitStatus.waitingInLobby ||
                      a.visitStatus == VisitStatus.inConsultation),
            )
            .length;

    final pendingArrivalCount = isPastDate
        ? 0
        : appointments
            .where(
              (a) =>
                  a.status == AppointmentStatus.pending &&
                  a.visitStatus == VisitStatus.booked,
            )
            .length;

    return ChamberMetricsGrid(
      key: key,
      totalBooked: kpis.totalBooked,
      attendedCount: kpis.attendedCount,
      paidCount: kpis.paidCount,
      freeCount: kpis.freeCount,
      absentCount: absentCount,
      waitingCount: waitingCount,
      pendingArrivalCount: pendingArrivalCount,
      totalFees: kpis.totalDoctorFees,
      isDesktop: isDesktop,
      isPastDate: isPastDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      ChamberMetricTile(
        title: "Consulted",
        value: "$attendedCount",
        subtitle: "$paidCount paid • $freeCount free",
        icon: Icons.done_all_rounded,
        color: Colors.teal,
      ),
      ChamberMetricTile(
        title: "Waiting",
        value: "$waitingCount",
        subtitle: isPastDate ? "Shift closed" : "$waitingCount in lobby",
        icon: Icons.meeting_room_outlined,
        color: Colors.blue,
      ),
      ChamberMetricTile(
        title: isPastDate ? "Absent / No-Show" : "Pending",
        value: "${isPastDate ? absentCount : pendingArrivalCount}",
        subtitle: isPastDate
            ? "Unattended"
            : (absentCount > 0
                ? "$pendingArrivalCount pending • $absentCount absent"
                : "Not arrived yet"),
        icon: isPastDate
            ? Icons.person_off_outlined
            : Icons.pending_actions_rounded,
        color: const Color(0xFF64748B),
      ),
      ChamberMetricTile(
        title: "Doctor's Fees",
        value: "₹$totalFees",
        subtitle: "$paidCount paid visits",
        icon: Icons.currency_rupee_rounded,
        color: const Color(0xFF059669),
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map(
              (card) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: card,
                ),
              ),
            )
            .toList(),
      );
    } else {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.45,
        children: cards,
      );
    }
  }
}

/// Standalone KPI metric tile delegating to the unified [MetricKpiCard].
class ChamberMetricTile extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const ChamberMetricTile({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return MetricKpiCard(
      title: title,
      value: value,
      subtitle: subtitle,
      icon: icon,
      color: color,
      layout: MetricCardLayout.vertical,
    );
  }
}
