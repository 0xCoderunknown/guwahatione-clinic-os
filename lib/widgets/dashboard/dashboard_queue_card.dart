import 'package:flutter/material.dart';

import '../../core/engines/engines.dart';
import '../../models/appointment.dart';
import '../../models/chamber_session.dart';
import '../../providers/clinic_provider.dart';
import '../../screens/appointment_list_screen.dart';
import '../../utils/formatters.dart';
import '../booking/quick_check_in_dialog.dart';
import '../common/appointment_status_chip.dart';
import '../common/token_badge.dart';

/// "Today's Live Queue" panel with doctor filters, dynamic consultation arrival windows,
/// status badges, and 1-tap chamber admission triggers.
class DashboardTodayQueueCard extends StatefulWidget {
  final ClinicProvider provider;

  const DashboardTodayQueueCard({super.key, required this.provider});

  @override
  State<DashboardTodayQueueCard> createState() =>
      _DashboardTodayQueueCardState();
}

class _DashboardTodayQueueCardState extends State<DashboardTodayQueueCard> {
  String? _selectedDoctorId; // null = All Doctors

  @override
  Widget build(BuildContext context) {
    final list = widget.provider.getFilteredAppointments(
      doctorId: _selectedDoctorId,
    );
    final doctors = widget.provider.doctors;

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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                const Icon(
                  Icons.queue_play_next_rounded,
                  size: 20,
                  color: Color(0xFF0F172A),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Today's Live Queue",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    list.length == 1 ? '1 token' : '${list.length} tokens',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade800,
                    ),
                  ),
                ),
                if (widget.provider.isOfflineFallback) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          size: 12,
                          color: Color(0xFFB45309),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.provider.offlineCacheTimestamp != null
                              ? 'Offline data · Updated at ${AppFormatters.time(widget.provider.offlineCacheTimestamp)}'
                              : 'Offline data',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AppointmentListScreen(),
                    ),
                  ),
                  child: const Text(
                    'Full Ledger →',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

          // Doctor Queue Filter Tabs
          if (doctors.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: const Color(0xFFF8FAFC),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      selected: _selectedDoctorId == null,
                      label: Text(
                        'All Doctors (${widget.provider.todayAppointments.length})',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: _selectedDoctorId == null
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      onSelected: (_) =>
                          setState(() => _selectedDoctorId = null),
                      selectedColor: Colors.teal.shade100,
                      checkmarkColor: Colors.teal.shade800,
                    ),
                    const SizedBox(width: 8),
                    ...doctors.map((doc) {
                      final count = AppointmentEngine.countDoctorAppointments(
                        appointments: widget.provider.todayAppointments,
                        doctorId: doc.id,
                      );
                      final isSelected = _selectedDoctorId == doc.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(
                            '${doc.name} ($count)',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          onSelected: (_) =>
                              setState(() => _selectedDoctorId = doc.id),
                          selectedColor: Colors.teal.shade100,
                          checkmarkColor: Colors.teal.shade800,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      size: 44,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.provider.dashboardSearchQuery.isNotEmpty
                          ? 'No patient tokens match "${widget.provider.dashboardSearchQuery}"'
                          : 'No appointments to show',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.provider.dashboardSearchQuery.isNotEmpty
                          ? 'Check the 10-digit phone number or clear search.'
                          : 'Tap "+ Book Walk-In Patient" to assign the first token.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.take(10).length,
              separatorBuilder: (_, index) =>
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (ctx, i) {
                final appt = list[i];

                // Calculate estimated consultation arrival window for pending tokens
                final docAppointments = widget.provider.todayAppointments
                    .where((a) => a.doctorId == appt.doctorId)
                    .toList();
                final estimate = AppointmentEngine.calculateEstimatedWindow(
                  doctorAppointments: docAppointments,
                  targetQueueNumber: appt.queueNumber,
                );

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  leading: TokenBadge(
                    queueNumber: appt.queueNumber,
                    doctorTag: _selectedDoctorId == null
                        ? AppFormatters.doctorInitials(appt.doctorName)
                        : null,
                    size: 44,
                    isCompleted: appt.status == AppointmentStatus.completed,
                    isAbsent: appt.status == AppointmentStatus.absent,
                  ),
                  title: Row(
                    children: [
                      Text(
                        appt.patientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${appt.patientPhone})',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (appt.visitStatus == VisitStatus.booked)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
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
                        )
                      else if (appt.visitStatus == VisitStatus.waitingInLobby)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
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
                        ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${AppFormatters.doctorTitle(appt.doctorName)} • Fee: ${AppFormatters.currency(appt.amountCollected)} (${appt.paymentType.displayName})",
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF475569),
                          ),
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
                                Text(
                                  estimate.relativeSummary,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                                Text(
                                  " • Estimated wait: ${estimate.formattedRange}",
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  trailing: _buildTrailingAction(appt, context),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTrailingAction(Appointment appt, BuildContext context) {
    if (appt.visitStatus == VisitStatus.booked) {
      return FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF0F766E),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.how_to_reg_rounded, size: 16),
        label: const Text(
          'Check In',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        onPressed: () => QuickCheckInDialog.show(context, appointment: appt),
      );
    }

    if (appt.status == AppointmentStatus.pending) {
      return StreamBuilder<ChamberSession>(
        stream: widget.provider.streamChamberSession(
          appt.doctorId,
          appt.scheduledDate,
        ),
        builder: (context, chamberSnap) {
          final session = chamberSnap.data;
          final isDoctorReady = session?.isReadyForNext ?? false;
          final isDoctorOnBreak = session?.isConsultationEnded ?? false;
          final activeApptId = session?.activeAppointmentId;
          final activeQueueNum = session?.activeQueueNumber;
          final isThisInChamber = activeApptId == appt.id;
          final isAnotherPatientInChamber =
              activeApptId != null &&
              activeApptId.isNotEmpty &&
              activeApptId != appt.id;

          if (isThisInChamber) {
            return Tooltip(
              message:
                  'Token #${appt.queueNumber} is currently in chamber with ${AppFormatters.doctorTitle(appt.doctorName)}',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.meeting_room_rounded,
                      size: 14,
                      color: Color(0xFF15803D),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'In Chamber',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (isAnotherPatientInChamber) {
            return Tooltip(
              message:
                  '${AppFormatters.doctorTitle(appt.doctorName)} is currently consulting Token #$activeQueueNum',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_clock_rounded,
                      size: 14,
                      color: Colors.blueGrey.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Doctor Busy (#$activeQueueNum)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (isDoctorOnBreak) {
            return Tooltip(
              message:
                  '${AppFormatters.doctorTitle(appt.doctorName)} is on a break. Waiting for doctor to call next patient.',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.coffee_rounded,
                      size: 14,
                      color: Color(0xFFB45309),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'On Break',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!isDoctorReady) {
            return Tooltip(
              message:
                  '${AppFormatters.doctorTitle(appt.doctorName)} has not signaled ready yet. Chamber is idle.',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.hourglass_top_rounded,
                      size: 14,
                      color: Colors.blueGrey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Waiting for Doctor',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ONLY reached when isDoctorReady == true (Doctor clicked "READY FOR FIRST PATIENT" / "NEXT PATIENT")
          return FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF15803D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.login_rounded, size: 16),
            label: const Text(
              'Send In',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            onPressed: () async {
              await widget.provider.callTokenIntoChamber(
                doctorId: appt.doctorId,
                date: appt.scheduledDate,
                appointment: appt,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Dispatched Token #${appt.queueNumber} (${appt.patientName}) to ${AppFormatters.doctorTitle(appt.doctorName)} chamber',
                    ),
                    backgroundColor: const Color(0xFF15803D),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
          );
        },
      );
    }

    return AppointmentStatusChip(status: appt.status, isCompact: true);
  }
}
