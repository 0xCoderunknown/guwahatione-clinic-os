import 'package:flutter/material.dart';

import '../../models/appointment.dart';
import '../../providers/clinic_provider.dart';
import '../../screens/appointment_list_screen.dart';
import '../../utils/formatters.dart';
import '../common/appointment_status_chip.dart';
import '../common/token_badge.dart';

/// "Today's Live Queue" panel with token cards, status badges, and calling triggers.
class DashboardTodayQueueCard extends StatelessWidget {
  final ClinicProvider provider;

  const DashboardTodayQueueCard({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final list = provider.todayAppointments;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.queue_play_next_rounded, size: 20, color: Color(0xFF0F172A)),
                const SizedBox(width: 10),
                const Text(
                  "Today's Live Queue",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AppointmentListScreen()),
                  ),
                  child: const Text('Manage Queue →', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_available_rounded, size: 44, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    const Text(
                      'No appointments registered yet today',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap "+ Book Walk-In Patient" to assign the first token.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.take(8).length,
              separatorBuilder: (_, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (ctx, i) {
                final appt = list[i];
                return ListTile(
                  dense: true,
                  leading: TokenBadge(
                    queueNumber: appt.queueNumber,
                    size: 34,
                    isCompleted: appt.status == AppointmentStatus.completed,
                    isAbsent: appt.status == AppointmentStatus.absent,
                  ),
                  title: Row(
                    children: [
                      Text(
                        appt.patientName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${appt.patientPhone})',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    "Doctor: ${appt.doctorName} • Fee: ${AppFormatters.currency(appt.amountCollected)} (${appt.paymentType.displayName})",
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: appt.status == AppointmentStatus.pending
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.teal.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.record_voice_over_rounded, size: 14),
                              label: const Text('Call In', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: () async {
                                await provider.callTokenIntoChamber(
                                  doctorId: appt.doctorId,
                                  date: appt.scheduledDate,
                                  appointment: appt,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Called Token #${appt.queueNumber} (${appt.patientName}) to Dr. ${appt.doctorName} chamber'),
                                      backgroundColor: Colors.teal.shade800,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            AppointmentStatusChip(status: appt.status, isCompact: true),
                          ],
                        )
                      : AppointmentStatusChip(status: appt.status, isCompact: true),
                );
              },
            ),
        ],
      ),
    );
  }
}
