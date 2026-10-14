import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/engines/engines.dart';
import '../../models/chamber_session.dart';
import '../../providers/auth_provider.dart';
import '../../providers/clinic_provider.dart';
import '../../screens/doctor_list_screen.dart';
import '../../utils/formatters.dart';

/// "Doctor Chamber Roster" panel displaying active consulting physicians and live token counts.
class DashboardDoctorRosterCard extends StatelessWidget {
  final ClinicProvider provider;

  const DashboardDoctorRosterCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final doctors = provider.doctors;
    final isOwner = Provider.of<AuthProvider>(context, listen: false).isOwner;

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
                const Icon(
                  Icons.meeting_room_outlined,
                  size: 20,
                  color: Color(0xFF0F172A),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Doctor Chamber Roster',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DoctorListScreen()),
                  ),
                  child: Text(
                    isOwner ? 'Manage PINs →' : 'View Doctors →',
                    style: const TextStyle(fontSize: 12),
                  ),
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
              separatorBuilder: (_, index) =>
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (ctx, i) {
                final doc = doctors[i];
                final patientCount = AppointmentEngine.countDoctorAppointments(
                  appointments: provider.todayAppointments,
                  doctorId: doc.id,
                );

                return StreamBuilder<ChamberSession>(
                  stream: provider.streamChamberSession(doc.id, DateTime.now()),
                  builder: (context, chamberSnap) {
                    final session = chamberSnap.data;
                    final isReady = session?.isReadyForNext ?? false;
                    final isEnded = session?.isConsultationEnded ?? false;
                    final isCalling = session?.isCalling ?? false;
                    final isInConsultation = session?.isInConsultation ?? false;

                    Color statusBadgeBg;
                    Color statusBadgeFg;
                    String statusLabel;
                    String statusSubtitle;

                    if (isReady) {
                      statusBadgeBg = const Color(0xFFDCFCE7);
                      statusBadgeFg = const Color(0xFF15803D);
                      statusLabel = 'READY FOR NEXT';
                      statusSubtitle =
                          '🟢 Ready for next patient • Typical consultation: 8–10 min';
                    } else if (isEnded) {
                      statusBadgeBg = const Color(0xFFFEF3C7);
                      statusBadgeFg = const Color(0xFFB45309);
                      statusLabel = 'ON BREAK';
                      statusSubtitle =
                          '☕ Ended #${session?.lastCompletedQueueNumber ?? '--'} • Doctor is on a break';
                    } else if (isCalling) {
                      statusBadgeBg = const Color(0xFFDBEAFE);
                      statusBadgeFg = const Color(0xFF1D4ED8);
                      statusLabel = 'ADMITTED';
                      statusSubtitle =
                          '🚪 Token #${session?.activeQueueNumber ?? '--'} entering chamber';
                    } else if (isInConsultation) {
                      statusBadgeBg = const Color(0xFFEDE9FE);
                      statusBadgeFg = const Color(0xFF6D28D9);
                      statusLabel = 'CONSULTING';
                      final activePName = session?.patientName;
                      statusSubtitle =
                          '🩺 Consulting Token #${session?.activeQueueNumber ?? '--'}${activePName != null && activePName.isNotEmpty ? ' ($activePName)' : ''} • Typical consultation: 8–10 min';
                    } else {
                      statusBadgeBg = const Color(0xFFF1F5F9);
                      statusBadgeFg = const Color(0xFF64748B);
                      statusLabel = 'IDLE';
                      statusSubtitle =
                          '${AppFormatters.specialty(doc.specialty)} • Fee: ₹${doc.consultationFee} • Typical consultation: 8–10 min';
                    }

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 6,
                      ),
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.indigo.shade50,
                            child: Text(
                              doc.name.isNotEmpty
                                  ? doc.name[0].toUpperCase()
                                  : 'D',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo.shade800,
                              ),
                            ),
                          ),
                          if (isReady)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              AppFormatters.doctorTitle(doc.name),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: statusBadgeBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: statusBadgeFg,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          statusSubtitle,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isReady
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isReady
                                ? const Color(0xFF15803D)
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isReady
                              ? const Color(0xFFDCFCE7)
                              : (isInConsultation
                                    ? const Color(0xFFEDE9FE)
                                    : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isReady
                                ? const Color(0xFF86EFAC)
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          isReady
                              ? '▶ CALL NEXT'
                              : (isInConsultation
                                    ? 'Token #${session?.activeQueueNumber ?? '--'}'
                                    : (patientCount == 1
                                          ? '1 token'
                                          : '$patientCount tokens')),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isReady
                                ? const Color(0xFF15803D)
                                : (isInConsultation
                                      ? const Color(0xFF6D28D9)
                                      : Colors.grey.shade800),
                          ),
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
