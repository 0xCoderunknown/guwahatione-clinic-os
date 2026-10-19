import 'package:flutter/material.dart';

import '../../core/engines/engines.dart';
import '../../models/appointment.dart';
import '../../providers/clinic_provider.dart';
import '../../screens/appointment_list_screen.dart';
import '../../utils/formatters.dart';
import '../booking/quick_check_in_dialog.dart';
import '../common/appointment_status_chip.dart';
import '../common/token_badge.dart';
import '../queue/queue_chamber_dispatch_action.dart';

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
  int _activeTab = 0; // 0 = Today's Live Queue, 1 = Upcoming Bookings

  @override
  Widget build(BuildContext context) {
    final doctors = widget.provider.doctors;
    final today = DateTime.now();

    // Filter doctors for today: scheduled on today (not on leave) OR have appointments registered today
    final activeDoctorsForToday = doctors.where((doc) {
      final isAvailable = AppointmentEngine.isDoctorAvailableOnDate(
        doctor: doc,
        date: today,
      );
      final isOnLeave = AppointmentEngine.isDoctorOnLeave(
        doctor: doc,
        date: today,
      );
      final hasAppts = widget.provider.todayAppointments.any(
        (a) => a.doctorId == doc.id,
      );
      return (isAvailable && !isOnLeave) || hasAppts;
    }).toList();

    final effectiveDoctorList = activeDoctorsForToday.isNotEmpty
        ? activeDoctorsForToday
        : doctors;

    final effectiveDoctorId = (_selectedDoctorId != null &&
            effectiveDoctorList.any((d) => d.id == _selectedDoctorId))
        ? _selectedDoctorId
        : null;

    final list = widget.provider.getFilteredAppointments(
      doctorId: effectiveDoctorId,
    );

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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    // Segmented Tab Selector
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(3),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => setState(() => _activeTab = 0),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _activeTab == 0
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: _activeTab == 0
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.06),
                                              blurRadius: 3,
                                              offset: const Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.queue_play_next_rounded,
                                        size: 15,
                                        color: _activeTab == 0
                                            ? const Color(0xFF0F766E)
                                            : const Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Today's Queue (${widget.provider.todayAppointments.length})",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.5,
                                          color: _activeTab == 0
                                              ? const Color(0xFF0F172A)
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 3),
                              InkWell(
                                onTap: () => setState(() => _activeTab = 1),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _activeTab == 1
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: _activeTab == 1
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.06),
                                              blurRadius: 3,
                                              offset: const Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_month_rounded,
                                        size: 15,
                                        color: _activeTab == 1
                                            ? const Color(0xFF0F766E)
                                            : const Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Upcoming Bookings',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.5,
                                          color: _activeTab == 1
                                              ? const Color(0xFF0F172A)
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
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
                if (widget.provider.isOfflineFallback) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
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
                        Expanded(
                          child: Text(
                            widget.provider.offlineCacheTimestamp != null
                                ? 'Offline data · Updated at ${AppFormatters.time(widget.provider.offlineCacheTimestamp)}'
                                : 'Offline data',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB45309),
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
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

          // When Upcoming Bookings tab is active, show the 7-day advance booking view
          if (_activeTab == 1)
            _buildUpcomingBookingsView(context)
          else ...[
            // Doctor Queue Filter Tabs (filtered to doctors active/scheduled today)
            if (effectiveDoctorList.length > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                color: const Color(0xFFF8FAFC),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        selected: effectiveDoctorId == null,
                        label: Text(
                          'All Doctors (${widget.provider.todayAppointments.length})',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: effectiveDoctorId == null
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: effectiveDoctorId == null
                                ? Colors.white
                                : const Color(0xFF334155),
                          ),
                        ),
                        onSelected: (_) =>
                            setState(() => _selectedDoctorId = null),
                        selectedColor: Colors.teal.shade700,
                        backgroundColor: Colors.white,
                        checkmarkColor: Colors.white,
                        side: BorderSide(
                          color: effectiveDoctorId == null
                              ? Colors.teal.shade700
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...effectiveDoctorList.map((doc) {
                        final count = AppointmentEngine.countDoctorAppointments(
                          appointments: widget.provider.todayAppointments,
                          doctorId: doc.id,
                        );
                        final isSelected = effectiveDoctorId == doc.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            selected: isSelected,
                            label: Text(
                              '${doc.titleName} ($count)',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF334155),
                              ),
                            ),
                            onSelected: (_) =>
                                setState(() => _selectedDoctorId = doc.id),
                            selectedColor: Colors.teal.shade700,
                            backgroundColor: Colors.white,
                            checkmarkColor: Colors.white,
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.teal.shade700
                                  : const Color(0xFFCBD5E1),
                            ),
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
                          : 'No patients registered today',
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
                          : 'Press F2 or click + Book Walk-In to issue Token #1.',
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

                final isMobile = MediaQuery.of(context).size.width < 750;

                if (isMobile) {
                  return _buildMobileQueueItem(appt, estimate, context);
                }

                return _buildDesktopQueueItem(appt, estimate, context);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileQueueItem(
    Appointment appt,
    EstimatedConsultationWindow estimate,
    BuildContext context,
  ) {
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
                doctorTag: _selectedDoctorId == null
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

  Widget _buildDesktopQueueItem(
    Appointment appt,
    EstimatedConsultationWindow estimate,
    BuildContext context,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
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

  Widget _buildUpcomingBookingsView(BuildContext context) {
    return StreamBuilder<List<Appointment>>(
      stream: widget.provider.streamUpcomingAppointments(daysAhead: 7),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            child: Center(
              child: Text(
                'Unable to load upcoming bookings: ${snapshot.error}',
                style: const TextStyle(fontSize: 13, color: Colors.red),
              ),
            ),
          );
        }

        final upcomingList = snapshot.data ?? [];
        if (upcomingList.isEmpty) {
          return Padding(
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
                  const Text(
                    'No advance bookings scheduled for the next 7 days',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Advance appointments booked for tomorrow onwards will appear here.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Group appointments by formatted calendar date (DD-MM-YYYY)
        final Map<String, List<Appointment>> grouped = {};
        for (final appt in upcomingList) {
          final dateKey = AppFormatters.date(appt.scheduledDate);
          grouped.putIfAbsent(dateKey, () => []).add(appt);
        }

        final isMobile = MediaQuery.of(context).size.width < 750;

        return ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 4),
          children: [
            for (final entry in grouped.entries) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: const Color(0xFFF8FAFC),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: Color(0xFF0F766E),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Text(
                        '${entry.value.length} booking${entry.value.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...entry.value.map((appt) {
                return _buildUpcomingAppointmentRow(appt, isMobile: isMobile);
              }),
            ],
          ],
        );
      },
    );
  }

  Widget _buildUpcomingAppointmentRow(
    Appointment appt, {
    required bool isMobile,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          TokenBadge(
            queueNumber: appt.queueNumber,
            doctorTag: AppFormatters.doctorInitials(appt.doctorName),
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        appt.patientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (appt.patientAgeDisplay != null &&
                        appt.patientAgeDisplay!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(${appt.patientAgeDisplay!})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      appt.patientPhone,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        AppFormatters.doctorTitle(appt.doctorName),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0F766E),
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFCD34D)),
            ),
            child: Text(
              appt.paymentType == PaymentType.paidCash ||
                      appt.paymentType == PaymentType.paidUpi
                  ? 'Paid ₹${appt.amountCollected}'
                  : 'Pay at Desk',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
