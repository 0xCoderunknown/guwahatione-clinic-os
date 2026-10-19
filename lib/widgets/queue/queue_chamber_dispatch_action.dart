import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/appointment.dart';
import '../../models/chamber_session.dart';
import '../../providers/clinic_provider.dart';
import '../../utils/formatters.dart';

/// Dynamic chamber dispatch action widget for reception queue items.
///
/// Subscribes to the doctor's live [ChamberSession] stream and renders
/// real-time status badges (In Chamber, Busy, On Break, Waiting) or the
/// active [Send In] dispatch button when the doctor signals readiness.
class QueueChamberDispatchAction extends StatelessWidget {
  final Appointment appointment;
  final bool isMobile;

  const QueueChamberDispatchAction({
    super.key,
    required this.appointment,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ClinicProvider>(context, listen: false);

    return StreamBuilder<ChamberSession>(
      stream: provider.streamChamberSession(
        appointment.doctorId,
        appointment.scheduledDate,
      ),
      builder: (context, chamberSnap) {
        final session = chamberSnap.data;
        final isDoctorReady = session?.isReadyForNext ?? false;
        final isDoctorOnBreak = session?.isConsultationEnded ?? false;
        final activeApptId = session?.activeAppointmentId;
        final activeQueueNum = session?.activeQueueNumber;
        final isThisInChamber = activeApptId == appointment.id;
        final isAnotherPatientInChamber =
            activeApptId != null &&
            activeApptId.isNotEmpty &&
            activeApptId != appointment.id;

        if (isThisInChamber) {
          final badge = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: isMobile
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                const Icon(
                  Icons.meeting_room_rounded,
                  size: 14,
                  color: Color(0xFF15803D),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    isMobile
                        ? 'In Chamber with ${AppFormatters.doctorTitle(appointment.doctorName)}'
                        : 'In Chamber',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15803D),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
          return Tooltip(
            message:
                'Token #${appointment.queueNumber} is currently in chamber with ${AppFormatters.doctorTitle(appointment.doctorName)}',
            child: badge,
          );
        }

        if (isAnotherPatientInChamber) {
          final badge = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: isMobile
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  Icons.lock_clock_rounded,
                  size: 14,
                  color: Colors.blueGrey.shade700,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Doctor Busy (#$activeQueueNum)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey.shade800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
          return Tooltip(
            message:
                '${AppFormatters.doctorTitle(appointment.doctorName)} is currently consulting Token #$activeQueueNum',
            child: badge,
          );
        }

        if (isDoctorOnBreak) {
          final badge = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: isMobile
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                const Icon(
                  Icons.coffee_rounded,
                  size: 14,
                  color: Color(0xFFB45309),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    isMobile
                        ? 'Doctor on Break • Waiting for doctor'
                        : 'On Break',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB45309),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
          return Tooltip(
            message:
                '${AppFormatters.doctorTitle(appointment.doctorName)} is on a break. Waiting for doctor to call next patient.',
            child: badge,
          );
        }

        if (!isDoctorReady) {
          final badge = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: isMobile
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  Icons.hourglass_top_rounded,
                  size: 14,
                  color: Colors.blueGrey.shade600,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    isMobile
                        ? 'Waiting for Doctor to Signal Ready'
                        : 'Waiting for Doctor',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
          return Tooltip(
            message:
                '${AppFormatters.doctorTitle(appointment.doctorName)} has not signaled ready yet. Chamber is idle.',
            child: badge,
          );
        }

        // ONLY reached when isDoctorReady == true (Doctor clicked "READY FOR FIRST PATIENT" / "NEXT PATIENT")
        final isPaused = appointment.isPaused;
        final btn = FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: isPaused
                ? const Color(0xFF7E22CE)
                : const Color(0xFF15803D),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: Icon(
            isPaused ? Icons.play_arrow_rounded : Icons.login_rounded,
            size: 16,
          ),
          label: Text(
            isMobile
                ? (isPaused
                      ? 'Resume Token #${appointment.queueNumber} into Chamber'
                      : 'Send Token #${appointment.queueNumber} into Chamber')
                : (isPaused ? 'Resume In' : 'Send In'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          onPressed: () async {
            await provider.callTokenIntoChamber(
              doctorId: appointment.doctorId,
              date: appointment.scheduledDate,
              appointment: appointment,
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isPaused
                        ? 'Resumed Token #${appointment.queueNumber} (${appointment.patientName}) to ${AppFormatters.doctorTitle(appointment.doctorName)} chamber'
                        : 'Dispatched Token #${appointment.queueNumber} (${appointment.patientName}) to ${AppFormatters.doctorTitle(appointment.doctorName)} chamber',
                  ),
                  backgroundColor: isPaused
                      ? const Color(0xFF7E22CE)
                      : const Color(0xFF15803D),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
        );
        if (isMobile) {
          return SizedBox(width: double.infinity, child: btn);
        }
        return btn;
      },
    );
  }
}
