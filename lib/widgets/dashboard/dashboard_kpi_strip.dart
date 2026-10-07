import 'package:flutter/material.dart';

import '../../core/engines/engines.dart';
import '../common/metric_kpi_card.dart';
import '../../providers/clinic_provider.dart';
import '../../screens/appointment_list_screen.dart';
import '../../screens/doctor_list_screen.dart';
import '../../screens/statistics_screen.dart';

/// Responsive KPI Metrics Strip for Reception Dashboard.
class DashboardKpiStrip extends StatelessWidget {
  final ClinicProvider provider;
  final double screenWidth;

  const DashboardKpiStrip({
    super.key,
    required this.provider,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = RevenueEngine.calculateDailyMetrics(provider.todayAppointments);

    final cards = [
      DashboardKpiData(
        title: 'Today Appointments',
        value: '${metrics.totalAppointments}',
        subtitle: '${metrics.completedCount} completed',
        icon: Icons.calendar_today_rounded,
        color: const Color(0xFF2563EB), // Blue
        bgColor: const Color(0xFFEFF6FF),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AppointmentListScreen()),
        ),
      ),
      DashboardKpiData(
        title: 'Realized Revenue',
        value: '₹${metrics.realizedRevenue}',
        subtitle: 'From completed visits',
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF059669), // Green
        bgColor: const Color(0xFFECFDF5),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StatisticsScreen()),
        ),
      ),
      DashboardKpiData(
        title: 'Waiting Patients',
        value: '${metrics.pendingCount}',
        subtitle: 'Awaiting doctor consultation',
        icon: Icons.hourglass_top_rounded,
        color: const Color(0xFFD97706), // Amber
        bgColor: const Color(0xFFFFFBEB),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AppointmentListScreen()),
        ),
      ),
      DashboardKpiData(
        title: 'Consulting Doctors',
        value: '${provider.doctors.length}',
        subtitle: 'Active OPD chambers',
        icon: Icons.medical_services_rounded,
        color: const Color(0xFF7C3AED), // Purple
        bgColor: const Color(0xFFF5F3FF),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DoctorListScreen()),
        ),
      ),
    ];

    if (screenWidth >= 900) {
      // Desktop / 14" Laptop: 4 columns in a sleek horizontal row
      return Row(
        children: cards.map((item) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: DashboardMetricCard(data: item),
            ),
          );
        }).toList(),
      );
    } else {
      // Mobile / Tablet: 2x2 compact grid with healthy aspect ratio (1.6)
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cards.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.6,
        ),
        itemBuilder: (ctx, i) => DashboardMetricCard(data: cards[i]),
      );
    }
  }
}

/// Standalone visual card for dashboard KPI item delegating to [MetricKpiCard].
class DashboardMetricCard extends StatelessWidget {
  final DashboardKpiData data;

  const DashboardMetricCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return MetricKpiCard(
      title: data.title,
      value: data.value,
      subtitle: data.subtitle,
      icon: data.icon,
      color: data.color,
      bgColor: data.bgColor,
      onTap: data.onTap,
      layout: MetricCardLayout.horizontal,
    );
  }
}

class DashboardKpiData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const DashboardKpiData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });
}
