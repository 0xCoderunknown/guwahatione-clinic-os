import 'package:flutter/material.dart';

import '../../providers/clinic_provider.dart';
import '../../screens/add_appointment_dialog.dart';
import '../../screens/appointment_list_screen.dart';
import '../../screens/doctor_list_screen.dart';
import '../../screens/statistics_screen.dart';
import '../../utils/formatters.dart';

/// Top clinic greeting and live date bar with daily revenue collected badge.
class DashboardHeaderBar extends StatelessWidget {
  final ClinicProvider provider;

  const DashboardHeaderBar({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final todayStr = AppFormatters.dateWithDay(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.today_rounded, color: Colors.teal.shade700, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todayStr,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Text(
                    'OPD Consultation Chamber & Reception Desk',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.currency_rupee, size: 14, color: Colors.green),
                    const SizedBox(width: 2),
                    Text(
                      "₹${provider.dailyRevenue}",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "collected today",
                      style: TextStyle(fontSize: 11, color: Colors.green.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Quick Reception Navigation Action Chips.
class DashboardQuickActionChips extends StatelessWidget {
  const DashboardQuickActionChips({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        ActionChip(
          avatar: const Icon(Icons.add_circle_outline, size: 16, color: Colors.teal),
          label: const Text('Book Walk-In Patient'),
          onPressed: () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const AddAppointmentDialog(),
            );
          },
        ),
        ActionChip(
          avatar: const Icon(Icons.format_list_numbered, size: 16, color: Color(0xFF2563EB)),
          label: const Text('View Full Token Queue'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AppointmentListScreen()),
          ),
        ),
        ActionChip(
          avatar: const Icon(Icons.people_alt_outlined, size: 16, color: Color(0xFF7C3AED)),
          label: const Text('Doctor Chamber PINs'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DoctorListScreen()),
          ),
        ),
        ActionChip(
          avatar: const Icon(Icons.bar_chart_outlined, size: 16, color: Color(0xFF059669)),
          label: const Text('Financial Audit & Payouts'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StatisticsScreen()),
          ),
        ),
      ],
    );
  }
}
