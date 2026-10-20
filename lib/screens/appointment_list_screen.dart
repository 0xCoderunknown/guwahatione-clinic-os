import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/engines/engines.dart';
import '../models/models.dart';
import '../providers/clinic_provider.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';

/// Reception desk screen for managing, dispatching, and tracking the live patient queue.
///
/// Features:
/// - Top-level collapsible accordion for archiving completed consultations.
/// - Active in-chamber patient isolation with real-time chamber synchronization.
/// - Single-expansion accordion behavior across waiting tokens.
/// - Discretionary [SEND IN] chamber calling with occupancy collision protection.
/// - Multi-chamber concurrent patient tracking and date-specific doctor filters.
class AppointmentListScreen extends StatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedDoctorId; // null = All Doctors
  String? _expandedAppointmentId;
  final BookingService _bookingService = BookingService();

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 850;
    final canPop = Navigator.canPop(context);
    final showAppBar = !isDesktop || canPop;
    final clinicProvider = Provider.of<ClinicProvider>(context, listen: false);
    final doctors = context.select<ClinicProvider, List<Doctor>>(
      (p) => p.doctors,
    );

    return Scaffold(
      appBar: showAppBar
          ? AppBar(title: const Text('Appointments & Live Queue'), elevation: 0)
          : null,
      body: Column(
        children: [
          // Top Navigation & Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 8.0,
            ),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  child: ClinicDateNavBar(
                    selectedDate: _selectedDate,
                    onDateChanged: (picked) {
                      setState(() {
                        _selectedDate = picked;
                        _expandedAppointmentId = null;
                      });
                    },
                    onTodayPressed: () {
                      final now = DateTime.now();
                      setState(() {
                        _selectedDate = DateTime(now.year, now.month, now.day);
                        _expandedAppointmentId = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Consumer<SoundService>(
                  builder: (_, sound, _) => Tooltip(
                    message: sound.isMuted
                        ? 'Lobby Chime Muted (Click to Unmute)'
                        : 'Lobby Chime Active (Click to Mute)',
                    child: IconButton(
                      icon: Icon(
                        sound.isMuted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        color: sound.isMuted
                            ? Colors.grey.shade500
                            : Colors.teal.shade700,
                        size: 20,
                      ),
                      onPressed: () => sound.toggleMute(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Queue Content with dynamically filtered Doctor chips for _selectedDate
          Expanded(
            child: StreamBuilder<List<Appointment>>(
              stream: _bookingService.getAppointmentsForDate(_selectedDate),
              builder: (context, apptSnapshot) {
                if (apptSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (apptSnapshot.hasError) {
                  return Center(child: Text('Error: ${apptSnapshot.error}'));
                }

                final allAppointments = apptSnapshot.data ?? [];

                // Filter doctors for this specific calendar date:
                // Doctor must have OPD scheduled on this date (and not on leave), OR have existing appointments on this date.
                final activeDoctorsForDate = doctors.where((doc) {
                  final isScheduled = AppointmentEngine.isDoctorAvailableOnDate(
                    doctor: doc,
                    date: _selectedDate,
                  );
                  final isOnLeave = AppointmentEngine.isDoctorOnLeave(
                    doctor: doc,
                    date: _selectedDate,
                  );
                  final hasAppts = allAppointments.any(
                    (a) => a.doctorId == doc.id,
                  );
                  return (isScheduled && !isOnLeave) || hasAppts;
                }).toList();

                // If currently selected doctor is no longer in the active doctor list for this date, reset
                final effectiveDoctorFilter =
                    (_selectedDoctorId != null &&
                            activeDoctorsForDate.any(
                              (d) => d.id == _selectedDoctorId,
                            ))
                        ? _selectedDoctorId
                        : null;

                final currentEffectiveDoctorId =
                    effectiveDoctorFilter ??
                    (activeDoctorsForDate.length == 1
                        ? activeDoctorsForDate.first.id
                        : (doctors.length == 1 ? doctors.first.id : null));

                final filtered = effectiveDoctorFilter == null
                    ? allAppointments
                    : allAppointments
                          .where((a) => a.doctorId == effectiveDoctorFilter)
                          .toList();

                return Column(
                  children: [
                    // Doctor Filter Chips (when multiple doctors are scheduled/present for this date)
                    if (activeDoctorsForDate.length > 1) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        color: const Color(0xFFF8FAFC),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              FilterChip(
                                selected: effectiveDoctorFilter == null,
                                label: Text(
                                  'All Doctors (${allAppointments.length})',
                                ),
                                onSelected: (_) {
                                  setState(() {
                                    _selectedDoctorId = null;
                                    _expandedAppointmentId = null;
                                  });
                                },
                                selectedColor: Colors.teal.shade100,
                                checkmarkColor: Colors.teal.shade800,
                                visualDensity: VisualDensity.compact,
                              ),
                              const SizedBox(width: 8),
                              ...activeDoctorsForDate.map((doc) {
                                final isSelected =
                                    effectiveDoctorFilter == doc.id;
                                final docCount = allAppointments
                                    .where((a) => a.doctorId == doc.id)
                                    .length;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: FilterChip(
                                    selected: isSelected,
                                    label: Text('${doc.titleName} ($docCount)'),
                                    onSelected: (_) {
                                      setState(() {
                                        _selectedDoctorId = doc.id;
                                        _expandedAppointmentId = null;
                                      });
                                    },
                                    selectedColor: Colors.teal.shade100,
                                    checkmarkColor: Colors.teal.shade800,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFE2E8F0),
                      ),
                    ],

                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_available_rounded,
                                    size: 56,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No appointments scheduled for this date.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : (currentEffectiveDoctorId != null
                              ? StreamBuilder<ChamberSession>(
                                  stream: clinicProvider.streamChamberSession(
                                    currentEffectiveDoctorId,
                                    _selectedDate,
                                  ),
                                  builder: (context, chamberSnap) {
                                    final session = chamberSnap.data;

                                    final queueView =
                                        AppointmentEngine.partitionQueueForReception(
                                          appointments: filtered,
                                          activeAppointmentId:
                                              session?.activeAppointmentId,
                                          activeQueueNumber:
                                              session?.activeQueueNumber,
                                        );

                                    return _buildQueueListView(queueView);
                                  },
                                )
                              : StreamBuilder<Map<String, ChamberSession>>(
                                  stream: clinicProvider
                                      .streamAllChamberSessions(_selectedDate),
                                  builder: (context, allSessionsSnap) {
                                    final sessions =
                                        allSessionsSnap.data ?? {};
                                    final activeIds = sessions.values
                                        .map((s) => s.activeAppointmentId)
                                        .where(
                                          (id) => id != null && id.isNotEmpty,
                                        )
                                        .cast<String>()
                                        .toSet();

                                    final queueView =
                                        AppointmentEngine.partitionQueueForReception(
                                          appointments: filtered,
                                          activeAppointmentIds: activeIds,
                                        );

                                    return _buildQueueListView(queueView);
                                  },
                                )),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueListView(ReceptionQueueView queueView) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // 1. Top Collapsible Completed Accordion
        if (queueView.completed.isNotEmpty)
          CompletedConsultationsAccordion(
            completedAppointments: queueView.completed,
            showDoctorTag: _selectedDoctorId == null,
          ),

        // 2. Active In-Chamber Patient(s) Banner / Card
        if (queueView.inChamberPatients.isNotEmpty) ...[
          ...queueView.inChamberPatients.map((activeAppt) {
            return AppointmentAccordion(
              key: ValueKey(activeAppt.id),
              appointment: activeAppt,
              isInChamber: true,
              isExpanded: _expandedAppointmentId == activeAppt.id,
              showDoctorTag: _selectedDoctorId == null,
              onExpansionChanged: (expanded) {
                setState(() {
                  _expandedAppointmentId =
                      expanded ? activeAppt.id : null;
                });
              },
            );
          }),
        ],

        // 3. Waiting Queue Header & Count
        if (queueView.waiting.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 10, left: 2),
            child: Row(
              children: [
                const Icon(
                  Icons.hourglass_top_rounded,
                  size: 16,
                  color: Color(0xFF0F766E),
                ),
                const SizedBox(width: 6),
                Text(
                  'Waiting in Lobby (${queueView.waiting.length})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F766E),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Click card to reveal [SEND IN]',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          ...queueView.waiting.map((appt) {
            final isExpanded = _expandedAppointmentId == appt.id;

            return AppointmentAccordion(
              key: ValueKey(appt.id),
              appointment: appt,
              isInChamber: false,
              isExpanded: isExpanded,
              showDoctorTag: _selectedDoctorId == null,
              onExpansionChanged: (expanded) {
                setState(() {
                  _expandedAppointmentId = expanded ? appt.id : null;
                });
              },
            );
          }),
        ],

        // 4. Advance / Phone Bookings Section
        if (queueView.booked.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 10, left: 2),
            child: Row(
              children: [
                const Icon(
                  Icons.phone_in_talk_rounded,
                  size: 16,
                  color: Color(0xFFB45309),
                ),
                const SizedBox(width: 6),
                Text(
                  'Upcoming Appointments (${queueView.booked.length})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB45309),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Admit to lobby upon arrival',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF92400E),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          ...queueView.booked.map((appt) {
            final isExpanded = _expandedAppointmentId == appt.id;

            return AppointmentAccordion(
              key: ValueKey(appt.id),
              appointment: appt,
              isInChamber: false,
              isExpanded: isExpanded,
              showDoctorTag: _selectedDoctorId == null,
              onExpansionChanged: (expanded) {
                setState(() {
                  _expandedAppointmentId = expanded ? appt.id : null;
                });
              },
            );
          }),
        ],
        if (queueView.waiting.isEmpty &&
            queueView.booked.isEmpty &&
            queueView.inChamberPatients.isEmpty &&
            queueView.completed.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(top: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 44,
                  color: Color(0xFF15803D),
                ),
                const SizedBox(height: 10),
                const Text(
                  'All Consultations Completed!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15803D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${queueView.completed.length} ${queueView.completed.length == 1 ? 'patient was' : 'patients were'} seen. All records are archived in the top accordion.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.green.shade800),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
