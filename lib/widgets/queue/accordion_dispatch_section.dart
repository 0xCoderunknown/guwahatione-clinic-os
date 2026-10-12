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
      stream: Provider.of<ClinicProvider>(context, listen: false)
          .streamChamberSession(
            appointment.doctorId,
            appointment.scheduledDate,
          ),
      builder: (context, chamberSnap) {
        final session = chamberSnap.data;
        final isDoctorReady = session?.isReadyForNext ?? false;
        final isDoctorOnBreak = session?.isConsultationEnded ?? false;
        final activeApptId = session?.activeAppointmentId;
        final activeQueueNum = session?.activeQueueNumber;
        final activePatName = session?.patientName ?? 'Patient';

        final isThisInChamber =
            isInChamber || (activeApptId == appointment.id);
        final isAnotherPatientInChamber =
            activeApptId != null &&
            activeApptId.isNotEmpty &&
            activeApptId != appointment.id;

        String buttonLabel = 'SEND IN TO DOCTOR';
        Color buttonBg = const Color(0xFF0F766E); // Teal 700
        IconData buttonIcon = Icons.login_rounded;

        if (isDoctorReady) {
          buttonLabel = 'SEND IN (Doctor is Ready)';
          buttonBg = const Color(0xFF15803D); // Green 700
          buttonIcon = Icons.check_circle_outline_rounded;
        } else if (isDoctorOnBreak) {
          buttonLabel = 'Doctor on Break • Send In Anyway';
          buttonBg = const Color(0xFFB45309); // Amber 700
          buttonIcon = Icons.coffee_rounded;
        } else if (isAnotherPatientInChamber) {
          buttonLabel = 'SEND IN (Token #$activeQueueNum Inside)';
          buttonBg = const Color(0xFFD97706); // Amber 600
          buttonIcon = Icons.swap_horiz_rounded;
        } else if (isThisInChamber) {
          buttonLabel = 'Already in Chamber';
          buttonBg = const Color(0xFF059669);
          buttonIcon = Icons.meeting_room_rounded;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isDoctorReady)
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
                        '${AppFormatters.doctorTitle(appointment.doctorName)} is taking a breather. Verify patient presence before dispatching.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB45309),
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
              ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: buttonBg,
                foregroundColor: Colors.white,
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
              onPressed: () async {
                final clinic = Provider.of<ClinicProvider>(
                  context,
                  listen: false,
                );

                // Guard 1: Another patient is already in chamber
                if (isAnotherPatientInChamber) {
                  final proceed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Row(
                        children: [
                          Icon(
                            Icons.swap_horiz_rounded,
                            color: Color(0xFFD97706),
                          ),
                          SizedBox(width: 8),
                          Text('Chamber Currently Occupied'),
                        ],
                      ),
                      content: Text(
                        '${AppFormatters.doctorTitle(appointment.doctorName)} is currently consulting '
                        'Token #$activeQueueNum ($activePatName).\n\n'
                        'Admitting Token #${appointment.queueNumber} (${appointment.patientName}) '
                        'will replace the active patient in chamber. Send inside anyway?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Wait'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Send Inside Anyway'),
                        ),
                      ],
                    ),
                  );
                  if (proceed != true) return;
                } else if (isDoctorOnBreak) {
                  // Guard 2: Doctor taking a breather
                  final proceed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Row(
                        children: [
                          Icon(
                            Icons.coffee_rounded,
                            color: Colors.amber.shade800,
                          ),
                          const SizedBox(width: 8),
                          const Text('Doctor Taking Breather'),
                        ],
                      ),
                      content: Text(
                        '${AppFormatters.doctorTitle(appointment.doctorName)} is taking a breather and hasn\'t clicked \'NEXT PATIENT\' yet.\n\n'
                        'Send Token #${appointment.queueNumber} (${appointment.patientName}) inside anyway?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Wait for Doctor'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFB45309),
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Send Inside Anyway'),
                        ),
                      ],
                    ),
                  );
                  if (proceed != true) return;
                }

                await clinic.callTokenIntoChamber(
                  doctorId: appointment.doctorId,
                  date: appointment.scheduledDate,
                  appointment: appointment,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Dispatched Token #${appointment.queueNumber} (${appointment.patientName}) to ${AppFormatters.doctorTitle(appointment.doctorName)}',
                      ),
                      backgroundColor: Colors.teal.shade800,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
