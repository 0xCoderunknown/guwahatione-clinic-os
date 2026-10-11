import 'package:flutter/material.dart';

import '../../models/appointment.dart';
import 'chamber_queue_header.dart';
import 'chamber_token_card.dart';

/// Renders either the empty queue placeholder or the sequential token card list
/// for the Doctor Chamber screen.
class ChamberQueueList extends StatelessWidget {
  final List<Appointment> appointments;
  final String? activeCallingApptId;
  final ValueChanged<Appointment> onConsult;

  const ChamberQueueList({
    super.key,
    required this.appointments,
    required this.activeCallingApptId,
    required this.onConsult,
  });

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return const ChamberEmptyQueue();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: appointments.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 8),
      itemBuilder: (ctx, index) {
        final appt = appointments[index];
        return ChamberTokenCard(
          appointment: appt,
          isCallingNow: appt.id == activeCallingApptId,
          onConsult: () => onConsult(appt),
        );
      },
    );
  }
}
