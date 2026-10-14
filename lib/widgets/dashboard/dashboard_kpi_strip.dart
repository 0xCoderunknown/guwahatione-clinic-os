import 'package:flutter/material.dart';

import '../../providers/clinic_provider.dart';
import '../../screens/appointment_list_screen.dart';
import '../common/metric_kpi_card.dart';

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
    final cards = [
      DashboardKpiData(
        title: 'Waiting in Lobby',
        value: '${provider.waitingInLobbyCount}',
        subtitle: 'Physically at desk / lobby',
        icon: Icons.hourglass_top_rounded,
        color: const Color(0xFFD97706), // Amber
        bgColor: const Color(0xFFFFFBEB),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AppointmentListScreen()),
        ),
      ),
      DashboardKpiData(
        title: 'Expected / Booked',
        value: '${provider.expectedBookedCount}',
        subtitle: 'Advance & phone reservations',
        icon: Icons.phone_in_talk_rounded,
        color: const Color(0xFF2563EB), // Blue
        bgColor: const Color(0xFFEFF6FF),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AppointmentListScreen()),
        ),
      ),
      DashboardKpiData(
        title: 'Inside Chamber',
        value: '${provider.inConsultationCount}',
        subtitle: 'In active consultation',
        icon: Icons.meeting_room_rounded,
        color: const Color(0xFF7C3AED), // Purple
        bgColor: const Color(0xFFF5F3FF),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AppointmentListScreen()),
        ),
      ),
      DashboardKpiData(
        title: 'Completed',
        value: '${provider.completedCount}',
        subtitle: '${provider.absentCount} absent / no-shows',
        icon: Icons.check_circle_outline_rounded,
        color: const Color(0xFF059669), // Green
        bgColor: const Color(0xFFECFDF5),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AppointmentListScreen()),
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 720) {
          // Desktop / Laptop: 4 columns in a sleek horizontal row
          return Row(
            children: cards.map((item) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: DashboardMetricCard(data: item),
                ),
              );
            }).toList(),
          );
        } else {
          // Mobile / Compact Tablet: 2x2 compact grid with healthy aspect ratio (1.6)
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
      },
    );
  }
}

/// Standalone visual card for dashboard KPI item delegating to [MetricKpiCard].
class DashboardMetricCard extends StatelessWidget {
  final DashboardKpiData data;

  const DashboardMetricCard({super.key, required this.data});

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
