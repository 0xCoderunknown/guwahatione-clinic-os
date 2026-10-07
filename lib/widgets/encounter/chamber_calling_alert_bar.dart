import 'package:flutter/material.dart';

/// Notification banner alerting doctor that reception has called the next patient into the chamber.
class ChamberCallingAlertBar extends StatelessWidget {
  final int? queueNumber;
  final String? patientName;
  final VoidCallback onSwitch;
  final VoidCallback onDismiss;

  const ChamberCallingAlertBar({
    super.key,
    required this.queueNumber,
    required this.patientName,
    required this.onSwitch,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_rounded, color: Color(0xFFB45309), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Token #${queueNumber ?? ''} (${patientName ?? 'Next Patient'}) was called to chamber by Reception.",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
            ),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB45309),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: onSwitch,
            child: const Text('Switch Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Color(0xFF92400E)),
            tooltip: 'Dismiss',
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
