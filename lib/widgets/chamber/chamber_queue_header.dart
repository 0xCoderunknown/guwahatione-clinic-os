import 'package:flutter/material.dart';

import '../../models/appointment.dart';
import 'chamber_token_card.dart';

/// Header displaying queue count and live sync indicator.
class ChamberQueueHeader extends StatelessWidget {
  final int totalBooked;
  final bool isPastDate;
  final String? title;

  const ChamberQueueHeader({
    super.key,
    required this.totalBooked,
    this.isPastDate = false,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final displayTitle =
        title ?? (isPastDate ? "Previous Session" : "Today's Patient Queue");

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;

        final titleRow = Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.people_alt_rounded,
                  size: 20,
                  color: Color(0xFF334155),
                ),
                const SizedBox(width: 8),
                Text(
                  displayTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "$totalBooked issued",
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D4ED8),
                ),
              ),
            ),
          ],
        );

        final statusIndicator = isPastDate
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade300,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Past Queue",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.blueGrey.shade600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Live Updates",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [titleRow, const SizedBox(height: 6), statusIndicator],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [titleRow, statusIndicator],
        );
      },
    );
  }
}

/// Empty state banner when no appointments exist for the selected date.
class ChamberEmptyQueue extends StatelessWidget {
  const ChamberEmptyQueue({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 54,
            color: Colors.teal.shade200,
          ),
          const SizedBox(height: 16),
          const Text(
            "No appointments scheduled for this date",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Appointments booked at reception will appear here live.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

/// Renders either the empty queue placeholder or the sequential token card list
/// for the Doctor Chamber screen.
class ChamberQueueList extends StatelessWidget {
  final List<Appointment> appointments;
  final String? activeCallingApptId;
  final bool isPastDate;
  final ValueChanged<Appointment> onConsult;

  const ChamberQueueList({
    super.key,
    required this.appointments,
    required this.activeCallingApptId,
    this.isPastDate = false,
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
          isPastDate: isPastDate,
          onConsult: () => onConsult(appt),
        );
      },
    );
  }
}
