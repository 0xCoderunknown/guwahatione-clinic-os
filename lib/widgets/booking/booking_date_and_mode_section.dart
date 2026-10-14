import 'package:flutter/material.dart';

import '../../models/appointment.dart';
import '../../utils/formatters.dart';

/// Form section allowing receptionist to select booking date and check-in mode
/// (Walk-In vs Phone / Advance reservation).
class BookingDateAndModeSection extends StatelessWidget {
  final DateTime selectedDate;
  final VisitStatus selectedVisitStatus;
  final VoidCallback onPickDate;
  final ValueChanged<VisitStatus> onVisitStatusChanged;

  const BookingDateAndModeSection({
    super.key,
    required this.selectedDate,
    required this.selectedVisitStatus,
    required this.onPickDate,
    required this.onVisitStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Date Selector
        ListTile(
          title: Text("Date: ${AppFormatters.date(selectedDate)}"),
          trailing: const Icon(Icons.calendar_today),
          tileColor: Colors.grey.shade100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          onTap: onPickDate,
        ),
        const SizedBox(height: 12),

        // Booking Mode Toggle: Walk-in (Immediate Lobby) vs Phone / Advance
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<VisitStatus>(
            segments: const [
              ButtonSegment<VisitStatus>(
                value: VisitStatus.waitingInLobby,
                icon: Icon(
                  Icons.person_pin_circle_outlined,
                  size: 16,
                ),
                label: Text(
                  'Walk-In (Desk Check-In)',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              ButtonSegment<VisitStatus>(
                value: VisitStatus.booked,
                icon: Icon(Icons.phone_in_talk_outlined, size: 16),
                label: Text(
                  'Phone / Advance',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
            selected: {selectedVisitStatus},
            onSelectionChanged: (newSelection) {
              onVisitStatusChanged(newSelection.first);
            },
          ),
        ),
      ],
    );
  }
}
