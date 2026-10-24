import 'package:flutter/material.dart';

import '../../core/engines/engines.dart';
import '../../providers/clinic_provider.dart';
import '../../screens/appointment_list_screen.dart';
import '../../utils/formatters.dart';
import 'dashboard_queue_item_row.dart';
import 'queue_doctor_filter_bar.dart';
import 'upcoming_bookings_section.dart';

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
                              _buildTabItem(
                                index: 0,
                                icon: Icons.queue_play_next_rounded,
                                label:
                                    "Today's Queue (${widget.provider.todayAppointments.length})",
                              ),
                              const SizedBox(width: 3),
                              _buildTabItem(
                                index: 1,
                                icon: Icons.calendar_month_rounded,
                                label: 'Upcoming Bookings',
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

          // 7-day advance booking view or Today's live queue
          if (_activeTab == 1)
            UpcomingBookingsSection(provider: widget.provider)
          else ...[
            QueueDoctorFilterBar(
              doctors: effectiveDoctorList,
              selectedDoctorId: effectiveDoctorId,
              todayAppointments: widget.provider.todayAppointments,
              onDoctorSelected: (id) => setState(() => _selectedDoctorId = id),
            ),
            if (effectiveDoctorList.length > 1)
              const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 36,
                  horizontal: 20,
                ),
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
                itemCount: list.length > 10 ? 11 : list.length,
                separatorBuilder: (_, index) =>
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (ctx, i) {
                  if (i == 10) {
                    final remaining = list.length - 10;
                    return InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AppointmentListScreen(),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 13,
                          horizontal: 16,
                        ),
                        color: const Color(0xFFF8FAFC),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.people_outline_rounded,
                              size: 16,
                              color: Color(0xFF0F766E),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '+ $remaining more patients in queue — Tap to view full list',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F766E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final appt = list[i];

                  final docAppointments = widget.provider.todayAppointments
                      .where((a) => a.doctorId == appt.doctorId)
                      .toList();
                  final estimate = AppointmentEngine.calculateEstimatedWindow(
                    doctorAppointments: docAppointments,
                    targetQueueNumber: appt.queueNumber,
                  );

                  final isMobile = MediaQuery.of(context).size.width < 750;

                  return DashboardQueueItemRow(
                    appt: appt,
                    estimate: estimate,
                    selectedDoctorId: _selectedDoctorId,
                    isMobile: isMobile,
                  );
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _activeTab == index;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
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
              icon,
              size: 15,
              color: isSelected
                  ? const Color(0xFF0F766E)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
                color: isSelected
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
