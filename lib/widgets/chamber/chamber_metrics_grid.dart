import 'package:flutter/material.dart';
import '../../core/engines/engines.dart';
import '../../models/appointment.dart';
import '../common/metric_kpi_card.dart';

/// Live KPI metrics grid for Doctor Chamber (Total, Consulted, Absent, Doctor Share).
class ChamberMetricsGrid extends StatelessWidget {
  final int totalBooked;
  final int attendedCount;
  final int paidCount;
  final int freeCount;
  final int absentCount;
  final int waitingCount;
  final int totalFees;
  final bool isDesktop;

  const ChamberMetricsGrid({
    super.key,
    required this.totalBooked,
    required this.attendedCount,
    required this.paidCount,
    required this.freeCount,
    required this.absentCount,
    required this.waitingCount,
    required this.totalFees,
    required this.isDesktop,
  });

  factory ChamberMetricsGrid.fromAppointments({
    Key? key,
    required List<Appointment> appointments,
    required bool isDesktop,
  }) {
    final kpis = RevenueEngine.calculateChamberKpis(appointments);

    return ChamberMetricsGrid(
      key: key,
      totalBooked: kpis.totalBooked,
      attendedCount: kpis.attendedCount,
      paidCount: kpis.paidCount,
      freeCount: kpis.freeCount,
      absentCount: kpis.absentCount,
      waitingCount: kpis.waitingCount,
      totalFees: kpis.totalDoctorFees,
      isDesktop: isDesktop,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      ChamberMetricTile(
        title: "Total Tokens",
        value: "$totalBooked",
        subtitle: "$waitingCount still in queue",
        icon: Icons.confirmation_number_outlined,
        color: Colors.blue,
      ),
      ChamberMetricTile(
        title: "Consulted",
        value: "$attendedCount",
        subtitle: "$paidCount paid • $freeCount free",
        icon: Icons.done_all_rounded,
        color: Colors.teal,
      ),
      ChamberMetricTile(
        title: "Absent / No-Show",
        value: "$absentCount",
        subtitle: "Slots preserved",
        icon: Icons.person_off_outlined,
        color: const Color(0xFF64748B),
      ),
      ChamberMetricTile(
        title: "Doctor Share",
        value: "₹$totalFees",
        subtitle: "From $paidCount paid visits",
        icon: Icons.currency_rupee_rounded,
        color: const Color(0xFF059669),
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map((card) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: card,
                  ),
                ))
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
