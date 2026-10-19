import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/appointment.dart';
import '../../models/chamber_session.dart';
import '../../providers/clinic_provider.dart';
import '../../utils/formatters.dart';

/// Chamber handshake dispatch section for reception appointment queue tile.
///
/// Listens to the doctor's live [ChamberSession] stream and renders dynamic readiness
/// status banners (Doctor Ready, Taking Breather, Chamber Occupied) along with a prominent
/// [SEND IN TO DOCTOR] dispatch button guarded by collision confirmation dialogs.
class AccordionDispatchSection extends StatelessWidget {
  final Appointment appointment;
  final bool isInChamber;

  const AccordionDispatchSection({
    super.key,
    required this.appointment,
    required this.isInChamber,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ChamberSession>(
      stream: Provider.of<ClinicProvider>(
        context,
        listen: false,
      ).streamChamberSession(appointment.doctorId, appointment.scheduledDate),
      builder: (context, chamberSnap) {
        final session = chamberSnap.data;
        final isDoctorReady = session?.isReadyForNext ?? false;
        final isDoctorOnBreak = session?.isConsultationEnded ?? false;
        final activeApptId = session?.activeAppointmentId;
        final activeQueueNum = session?.activeQueueNumber;
        final activePatName = session?.patientName ?? 'Patient';

        final isThisInChamber = isInChamber || (activeApptId == appointment.id);
        final isAnotherPatientInChamber =
            activeApptId != null &&
            activeApptId.isNotEmpty &&
            activeApptId != appointment.id;

        String buttonLabel;
        IconData buttonIcon;
        VoidCallback? onDispatch;

        if (isThisInChamber) {
          buttonLabel = 'Already in Chamber';
          buttonIcon = Icons.meeting_room_rounded;
          onDispatch = null;
        } else if (isAnotherPatientInChamber) {
          buttonLabel = 'Chamber Occupied (Token #$activeQueueNum Inside)';
          buttonIcon = Icons.lock_clock_rounded;
          onDispatch = null;
        } else if (isDoctorOnBreak) {
          buttonLabel = 'Doctor on Break (Waiting for Doctor)';
          buttonIcon = Icons.coffee_rounded;
          onDispatch = null;
        } else if (isDoctorReady) {
          buttonLabel = appointment.isPaused
              ? 'RESUME CONSULTATION IN CHAMBER'
              : 'SEND IN TO DOCTOR';
          buttonIcon = appointment.isPaused
              ? Icons.play_arrow_rounded
              : Icons.check_circle_outline_rounded;
          onDispatch = () async {
            final clinic = Provider.of<ClinicProvider>(context, listen: false);
            await clinic.callTokenIntoChamber(
              doctorId: appointment.doctorId,
              date: appointment.scheduledDate,
              appointment: appointment,
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    appointment.isPaused
                        ? 'Resumed Token #${appointment.queueNumber} (${appointment.patientName}) to ${AppFormatters.doctorTitle(appointment.doctorName)}'
                        : 'Dispatched Token #${appointment.queueNumber} (${appointment.patientName}) to ${AppFormatters.doctorTitle(appointment.doctorName)}',
                  ),
                  backgroundColor: appointment.isPaused
                      ? const Color(0xFF7E22CE)
                      : const Color(0xFF15803D),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          };
        } else {
          // Doctor is idle, has not clicked "Ready for First Patient"
          buttonLabel = 'Waiting for doctor';
          buttonIcon = Icons.hourglass_top_rounded;
          onDispatch = null;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isThisInChamber)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.meeting_room_rounded,
                      size: 14,
                      color: Color(0xFF15803D),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Token #${appointment.queueNumber} is currently in chamber with ${AppFormatters.doctorTitle(appointment.doctorName)}.',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (isAnotherPatientInChamber)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Token #$activeQueueNum ($activePatName) is currently consulting ${AppFormatters.doctorTitle(appointment.doctorName)}.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB45309),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (isDoctorOnBreak)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.coffee_rounded,
                      size: 14,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${AppFormatters.doctorTitle(appointment.doctorName)} is on a break. Reception queue is held until doctor clicks \'NEXT PATIENT\'.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB45309),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (isDoctorReady)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: Color(0xFF15803D),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${AppFormatters.doctorTitle(appointment.doctorName)} is READY for next patient!',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.hourglass_top_rounded,
                      size: 14,
                      color: Color(0xFF475569),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${AppFormatters.doctorTitle(appointment.doctorName)} has not signaled ready yet. Chamber is idle.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: appointment.isPaused
                    ? const Color(0xFF7E22CE)
                    : const Color(0xFF15803D),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE2E8F0),
                disabledForegroundColor: const Color(0xFF64748B),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              icon: Icon(buttonIcon, size: 18),
              label: Text(
                buttonLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              onPressed: onDispatch,
            ),
          ],
        );
      },
    );
  }
}
