import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/clinic_config.dart';
import '../../core/engines/engines.dart';
import '../../models/chamber_session.dart';
import '../../models/doctor.dart';
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.meeting_room_outlined,
                  size: 20,
                  color: Color(0xFF0F172A),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Doctor Chamber Roster',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
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
            StreamBuilder<Map<String, ChamberSession>>(
              stream: provider.streamAllChamberSessions(DateTime.now()),
              builder: (context, chamberSnap) {
                final sessionMap = chamberSnap.data ?? const {};
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: doctors.length,
                  separatorBuilder: (_, index) =>
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (ctx, i) {
                    final doc = doctors[i];
                    final session = sessionMap[doc.id];
                    final patientCount = AppointmentEngine.countDoctorAppointments(
                      appointments: provider.todayAppointments,
                      doctorId: doc.id,
                    );
                    final isReady = session?.isReadyForNext ?? false;
                    final isCalling = session?.isCalling ?? false;
                    final isInConsultation = session?.isInConsultation ?? false;

                    Color statusBadgeBg;
                    Color statusBadgeFg;
                    String statusLabel;
                    final statusSubtitle =
                        '${AppFormatters.specialty(doc.specialty)} • ${doc.formattedSchedule}';

                    final isOnLeave = AppointmentEngine.isDoctorOnLeave(
                      doctor: doc,
                      date: DateTime.now(),
                    );

                    // Doctor has arrived and signaled ready / taken patient today
                    final hasArrived = session != null &&
                        (!session.isIdle ||
                            session.lastCompletedQueueNumber != null);

                    if (isOnLeave) {
                      statusBadgeBg = const Color(0xFFFEE2E2);
                      statusBadgeFg = const Color(0xFFDC2626);
                      statusLabel = 'ABSENT';
                    } else if (isCalling || isInConsultation) {
                      statusBadgeBg = const Color(0xFFDBEAFE);
                      statusBadgeFg = const Color(0xFF1D4ED8);
                      final activePatient = session?.patientName?.trim();
                      statusLabel =
                          (activePatient != null && activePatient.isNotEmpty)
                              ? 'Consulting: $activePatient'
                              : 'CONSULTING';
                    } else if (hasArrived) {
                      statusBadgeBg = const Color(0xFFDCFCE7);
                      statusBadgeFg = const Color(0xFF15803D);
                      statusLabel = 'IN CHAMBER';
                    } else {
                      statusBadgeBg = const Color(0xFFF1F5F9);
                      statusBadgeFg = const Color(0xFF64748B);
                      statusLabel = 'NOT ARRIVED';
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
                              AppFormatters.doctorInitials(doc.name),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo.shade800,
                              ),
                            ),
                          ),
                          if (hasArrived)
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
                          Flexible(
                            child: Container(
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
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: statusBadgeFg,
                                  letterSpacing: 0.3,
                                ),
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
                            fontWeight: hasArrived
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: hasArrived
                                ? const Color(0xFF15803D)
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isReady
                                  ? const Color(0xFFDCFCE7)
                                  : (isInConsultation || isCalling
                                        ? const Color(0xFFDBEAFE)
                                        : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isReady
                                    ? const Color(0xFF86EFAC)
                                    : (isInConsultation || isCalling
                                        ? const Color(0xFF93C5FD)
                                        : Colors.transparent),
                              ),
                            ),
                            child: Text(
                              isReady
                                  ? '▶ CALL NEXT'
                                  : ((isInConsultation || isCalling)
                                        ? 'Token #${session?.activeQueueNumber ?? '--'}'
                                        : (patientCount == 1
                                              ? '1 token'
                                              : '$patientCount tokens')),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isReady
                                    ? const Color(0xFF15803D)
                                    : ((isInConsultation || isCalling)
                                          ? const Color(0xFF1D4ED8)
                                          : Colors.grey.shade800),
                              ),
                            ),
                          ),
                          if (ClinicConfig.current.features.enableBulkSessionClose &&
                              isOwner &&
                              patientCount > 0) ...[
                            const SizedBox(width: 4),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 18),
                              tooltip: 'Doctor Session Options',
                              padding: EdgeInsets.zero,
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'close_session',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.event_busy,
                                        color: Colors.redAccent,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Close Session (Doctor Absent)',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (val) {
                                if (val == 'close_session') {
                                  final auth = Provider.of<AuthProvider>(
                                    context,
                                    listen: false,
                                  );
                                  _confirmCloseSession(context, doc, auth);
                                }
                              },
                            ),
                          ],
                        ],
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

  Future<void> _confirmCloseSession(
    BuildContext context,
    Doctor doc,
    AuthProvider auth,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.event_busy, color: Colors.redAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Close Session • ${AppFormatters.doctorTitle(doc.name)}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppFormatters.doctorTitle(doc.name)} will be marked absent for today.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'All remaining un-consulted tokens (pending / lobby) will be marked as ABSENT with ₹0 collection.\n\nAudit Ledger Invariant: Zero appointments will be deleted from the database. All token slots remain visible in the ledger.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mark Absent & Close Session'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final count = await provider.closeDoctorSession(
          doctorId: doc.id,
          date: DateTime.now(),
          requestingRole: auth.currentRole,
          reason: 'Doctor absent / session closed by clinic admin',
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppFormatters.doctorTitle(doc.name)}\'s session closed. $count pending token(s) marked absent.',
              ),
              backgroundColor: Colors.amber.shade900,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
