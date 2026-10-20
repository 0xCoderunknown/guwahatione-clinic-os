import 'package:flutter/material.dart';

import '../../core/engines/engines.dart';
import '../../models/appointment.dart';
import '../../utils/formatters.dart';
import '../booking/quick_check_in_dialog.dart';
import '../common/appointment_status_chip.dart';
import '../common/token_badge.dart';
import '../queue/queue_chamber_dispatch_action.dart';

/// Individual appointment row displayed in the reception live queue table.
/// Handles both desktop ListTile and compact mobile Card presentation.
class DashboardQueueItemRow extends StatelessWidget {
  final Appointment appt;
  final EstimatedConsultationWindow estimate;
  final String? selectedDoctorId;
  final bool isMobile;

  const DashboardQueueItemRow({
    super.key,
    required this.appt,
    required this.estimate,
    this.selectedDoctorId,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return _buildMobileLayout(context);
    }
    return _buildDesktopLayout(context);
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TokenBadge(
                queueNumber: appt.queueNumber,
                doctorTag: selectedDoctorId == null
                    ? AppFormatters.doctorInitials(appt.doctorName)
                    : null,
                size: 38,
                isCompleted: appt.status == AppointmentStatus.completed,
                isAbsent: appt.status == AppointmentStatus.absent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appt.patientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${appt.patientPhone} • ${AppFormatters.doctorTitle(appt.doctorName)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appt.paymentSummary,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF475569),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildVisitStatusBadge(appt),
            ],
          ),
          if (appt.status == AppointmentStatus.pending) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 13,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      '${estimate.relativeSummary} • Estimated wait: ${estimate.formattedRange}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (appt.visitStatus == VisitStatus.booked ||
              appt.status == AppointmentStatus.pending) ...[
            const SizedBox(height: 8),
            _buildActionRow(appt, context, isMobile: true),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      leading: TokenBadge(
        queueNumber: appt.queueNumber,
        doctorTag: selectedDoctorId == null
            ? AppFormatters.doctorInitials(appt.doctorName)
            : null,
        size: 44,
        isCompleted: appt.status == AppointmentStatus.completed,
        isAbsent: appt.status == AppointmentStatus.absent,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              appt.patientName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF0F172A),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '(${appt.patientPhone})',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(width: 10),
          _buildVisitStatusBadge(appt),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${AppFormatters.doctorTitle(appt.doctorName)} • ${appt.paymentSummary}",
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
            ),
            if (appt.status == AppointmentStatus.pending) ...[
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        estimate.relativeSummary,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        " • Estimated wait: ${estimate.formattedRange}",
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.blue.shade800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      trailing: _buildActionRow(appt, context, isMobile: false),
    );
  }

  Widget _buildVisitStatusBadge(Appointment appt) {
    if (appt.visitStatus == VisitStatus.booked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFF59E0B)),
        ),
        child: const Text(
          'Phone booking',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF92400E),
          ),
        ),
      );
    } else if (appt.visitStatus == VisitStatus.waitingInLobby) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF86EFAC)),
        ),
        child: const Text(
          'In Lobby',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF166534),
          ),
        ),
      );
    }
    return AppointmentStatusChip(status: appt.status, isCompact: true);
  }

  Widget _buildActionRow(
    Appointment appt,
    BuildContext context, {
    required bool isMobile,
  }) {
    if (appt.visitStatus == VisitStatus.booked) {
      final btn = FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF0F766E),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.how_to_reg_rounded, size: 16),
        label: Text(
          isMobile ? 'Check In Patient into Lobby' : 'Check In',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        onPressed: () => QuickCheckInDialog.show(context, appointment: appt),
      );
      if (isMobile) {
        return SizedBox(width: double.infinity, child: btn);
      }
      return btn;
    }

    if (appt.status == AppointmentStatus.pending) {
      return QueueChamberDispatchAction(appointment: appt, isMobile: isMobile);
    }

    if (isMobile) {
      return const SizedBox.shrink();
    }
    return AppointmentStatusChip(status: appt.status, isCompact: true);
  }
}
