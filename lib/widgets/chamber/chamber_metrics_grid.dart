import 'package:flutter/material.dart';

import '../../models/appointment.dart';

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
    final totalBooked = appointments.length;
    final attendedCount = appointments.where((a) => a.status == AppointmentStatus.completed).length;
    final paidAppointments = appointments
        .where((a) => a.status == AppointmentStatus.completed && a.paymentType == PaymentType.paid)
        .toList();
    final freeAppointments = appointments
        .where((a) =>
            a.status == AppointmentStatus.completed &&
            (a.paymentType == PaymentType.freeReview || a.paymentType == PaymentType.freeFamily))
        .toList();
    final absentCount = appointments.where((a) => a.status == AppointmentStatus.absent).length;
    final waitingCount = appointments.where((a) => a.status == AppointmentStatus.pending).length;
    final totalDoctorFees = paidAppointments.fold(0, (sum, a) => sum + a.amountCollected);

    return ChamberMetricsGrid(
      key: key,
      totalBooked: totalBooked,
      attendedCount: attendedCount,
      paidCount: paidAppointments.length,
      freeCount: freeAppointments.length,
      absentCount: absentCount,
      waitingCount: waitingCount,
      totalFees: totalDoctorFees,
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

/// Standalone KPI metric tile displaying count, subtitle, and themed icon.
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              Icon(icon, size: 20, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
