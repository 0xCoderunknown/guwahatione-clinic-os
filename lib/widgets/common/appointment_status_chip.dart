import 'package:flutter/material.dart';
import '../../models/appointment.dart';

/// Standardized status indicator chip for GuwahatiOne Clinic OS appointments.
class AppointmentStatusChip extends StatelessWidget {
  final AppointmentStatus status;
  final bool isCalling;
  final bool isCompact;

  const AppointmentStatusChip({
    super.key,
    required this.status,
    this.isCalling = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textColor;
    String label;
    IconData icon;

    if (isCalling) {
      bg = const Color(0xFFEFF6FF);
      textColor = const Color(0xFF1D4ED8);
      label = 'CALLING';
      icon = Icons.campaign_rounded;
    } else {
      switch (status) {
        case AppointmentStatus.pending:
          bg = const Color(0xFFFEF3C7);
          textColor = const Color(0xFFB45309);
          label = 'WAITING';
          icon = Icons.schedule_rounded;
          break;
        case AppointmentStatus.completed:
          bg = const Color(0xFFD1FAE5);
          textColor = const Color(0xFF047857);
          label = 'COMPLETED';
          icon = Icons.check_circle_outline_rounded;
          break;
        case AppointmentStatus.absent:
          bg = const Color(0xFFFEE2E2);
          textColor = const Color(0xFFB91C1C);
          label = 'ABSENT';
          icon = Icons.person_off_outlined;
          break;
      }
    }

    final verticalPadding = isCompact ? 2.0 : 4.0;
    final horizontalPadding = isCompact ? 6.0 : 8.0;
    final fontSize = isCompact ? 10.0 : 11.0;
    final iconSize = isCompact ? 11.0 : 13.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
