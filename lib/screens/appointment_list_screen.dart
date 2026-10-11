import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/engines/engines.dart';
import '../models/appointment.dart';
import '../models/chamber_session.dart';
import '../providers/clinic_provider.dart';
import '../services/firebase_service.dart';
import '../widgets/widgets.dart';

/// Reception desk screen for managing, dispatching, and tracking the live patient queue.
///
/// Features:
/// - Top-level collapsible accordion for archiving completed consultations.
/// - Active in-chamber patient isolation with real-time chamber synchronization.
/// - Single-expansion accordion behavior across waiting tokens.
/// - Discretionary [SEND IN] chamber calling with occupancy collision protection.
/// - Clear visual tagging for bypassed/late patients without destructive state changes.
class AppointmentListScreen extends StatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedDoctorId; // null = All Doctors
  String? _expandedAppointmentId;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 850;
    final canPop = Navigator.canPop(context);
    final showAppBar = !isDesktop || canPop;
    final clinicProvider = Provider.of<ClinicProvider>(context);
    final doctors = clinicProvider.doctors;

    // If only 1 doctor exists in clinic, automatically select that doctor for live chamber sync
    final effectiveDoctorId = _selectedDoctorId ??
        (doctors.length == 1 ? doctors.first.id : null);

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text('Appointments & Live Queue'),
              elevation: 0,
            )
          : null,
      body: Column(
        children: [
          // Top Navigation & Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
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
              ],
            ),
          ),

          // Doctor Filter Chips (when multiple doctors exist)
          if (doctors.length > 1) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              color: const Color(0xFFF8FAFC),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      selected: _selectedDoctorId == null,
                      label: const Text('All Doctors'),
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
                    ...doctors.map((doc) {
                      final isSelected = _selectedDoctorId == doc.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(doc.name),
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
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
          ],

          // Main Queue Content
          Expanded(
            child: StreamBuilder<List<Appointment>>(
              stream: _firebaseService.getAppointmentsForDate(_selectedDate),
              builder: (context, apptSnapshot) {
                if (apptSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (apptSnapshot.hasError) {
                  return Center(child: Text('Error: ${apptSnapshot.error}'));
                }

                final allAppointments = apptSnapshot.data ?? [];
                final filtered = _selectedDoctorId == null
                    ? allAppointments
                    : allAppointments
                        .where((a) => a.doctorId == _selectedDoctorId)
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
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
                  );
                }

                // If effectiveDoctorId is known, stream their chamber session doc for chamber sync
                if (effectiveDoctorId != null) {
                  return StreamBuilder<ChamberSession>(
                    stream: clinicProvider.streamChamberSession(
                      effectiveDoctorId,
                      _selectedDate,
                    ),
                    builder: (context, chamberSnap) {
                      final session = chamberSnap.data;

                      final queueView =
                          AppointmentEngine.partitionQueueForReception(
                        appointments: filtered,
                        activeAppointmentId: session?.activeAppointmentId,
                        activeQueueNumber: session?.activeQueueNumber,
                      );

                      return _buildQueueListView(queueView);
                    },
                  );
                }

                // Fallback when viewing "All Doctors" across multiple practitioners
                final queueView =
                    AppointmentEngine.partitionQueueForReception(
                  appointments: filtered,
                );

                return _buildQueueListView(queueView);
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

        // 2. Active In-Chamber Patient Banner / Card
        if (queueView.inChamber != null) ...[
          AppointmentAccordion(
            key: ValueKey(queueView.inChamber!.id),
            appointment: queueView.inChamber!,
            isInChamber: true,
            isBypassed: false,
            isExpanded: _expandedAppointmentId == queueView.inChamber!.id,
            showDoctorTag: _selectedDoctorId == null,
            onExpansionChanged: (expanded) {
              setState(() {
                _expandedAppointmentId =
                    expanded ? queueView.inChamber!.id : null;
              });
            },
          ),
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

          // 4. Waiting / Bypassed Patient Cards with single-expansion control
          ...queueView.waiting.map((appt) {
            final isBypassed = queueView.isBypassed(appt.id);
            final isExpanded = _expandedAppointmentId == appt.id;

            return AppointmentAccordion(
              key: ValueKey(appt.id),
              appointment: appt,
              isInChamber: false,
              isBypassed: isBypassed,
              isExpanded: isExpanded,
              showDoctorTag: _selectedDoctorId == null,
              onExpansionChanged: (expanded) {
                setState(() {
                  _expandedAppointmentId = expanded ? appt.id : null;
                });
              },
            );
          }),
        ] else if (queueView.inChamber == null && queueView.completed.isNotEmpty) ...[
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
                  '${queueView.completed.length} patient${queueView.completed.length == 1 ? '' : 's'} were consulted. All records are archived in the top accordion.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
