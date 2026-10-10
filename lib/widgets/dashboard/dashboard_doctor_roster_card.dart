import 'package:flutter/material.dart';

import '../../providers/clinic_provider.dart';
import '../../screens/doctor_list_screen.dart';

/// "Doctor Chamber Roster" panel displaying active consulting physicians and live token counts.
class DashboardDoctorRosterCard extends StatelessWidget {
  final ClinicProvider provider;

  const DashboardDoctorRosterCard({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final doctors = provider.doctors;

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
                const Icon(Icons.meeting_room_outlined, size: 20, color: Color(0xFF0F172A)),
                const SizedBox(width: 10),
                const Text(
                  'Doctor Chamber Roster',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DoctorListScreen()),
                  ),
                  child: const Text('Manage PINs →', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          if (doctors.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              child: Center(
                child: Text(
                  'No consulting doctors registered yet.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: doctors.length,
              separatorBuilder: (_, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (ctx, i) {
                final doc = doctors[i];
                final patientCount = provider.todayAppointments
                    .where((a) => a.doctorId == doc.id)
                    .length;

                return StreamBuilder(
                  stream: provider.streamChamberSession(doc.id, DateTime.now()),
                  builder: (context, chamberSnap) {
                    final chamberData = chamberSnap.data?.data();
                    final chamberStatus = (chamberData?['status'] as String?) ?? 'idle';
                    final lastCompletedQNum = (chamberData?['lastCompletedQueueNumber'] as num?)?.toInt();
                    final activeQNum = (chamberData?['activeQueueNumber'] as num?)?.toInt();
                    final activePName = chamberData?['patientName'] as String?;

                    Color statusBadgeBg;
                    Color statusBadgeFg;
                    String statusLabel;
                    String statusSubtitle;

                    if (chamberStatus == 'ready_for_next') {
                      statusBadgeBg = const Color(0xFFDCFCE7);
                      statusBadgeFg = const Color(0xFF15803D);
                      statusLabel = 'READY FOR NEXT';
                      statusSubtitle = '🟢 Doctor is READY! Call next patient.';
                    } else if (chamberStatus == 'consultation_ended') {
                      statusBadgeBg = const Color(0xFFFEF3C7);
                      statusBadgeFg = const Color(0xFFB45309);
                      statusLabel = 'ON BREAK';
                      statusSubtitle = '☕ Ended #${lastCompletedQNum ?? '--'} • Taking breather';
                    } else if (chamberStatus == 'calling') {
                      statusBadgeBg = const Color(0xFFDBEAFE);
                      statusBadgeFg = const Color(0xFF1D4ED8);
                      statusLabel = 'ADMITTED';
                      statusSubtitle = '🚪 Token #${activeQNum ?? '--'} entering chamber';
                    } else if (chamberStatus == 'in_consultation') {
                      statusBadgeBg = const Color(0xFFEDE9FE);
                      statusBadgeFg = const Color(0xFF6D28D9);
                      statusLabel = 'CONSULTING';
                      statusSubtitle = '🩺 Consulting Token #${activeQNum ?? '--'}${activePName != null && activePName.isNotEmpty ? ' ($activePName)' : ''}';
                    } else {
                      statusBadgeBg = const Color(0xFFF1F5F9);
                      statusBadgeFg = const Color(0xFF64748B);
                      statusLabel = 'IDLE';
                      statusSubtitle = '${doc.specialty} • Fee: ₹${doc.consultationFee}';
                    }

                    return ListTile(
                      dense: true,
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.indigo.shade50,
                            child: Text(
                              doc.name.isNotEmpty ? doc.name[0].toUpperCase() : 'D',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo.shade800,
                              ),
                            ),
                          ),
                          if (chamberStatus == 'ready_for_next')
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              "Dr. ${doc.name}",
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: statusBadgeBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: statusBadgeFg,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        statusSubtitle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: chamberStatus == 'ready_for_next'
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: chamberStatus == 'ready_for_next'
                              ? const Color(0xFF15803D)
                              : Colors.grey.shade700,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "$patientCount tokens",
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}
