import 'dart:async';
import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../models/doctor.dart';
import '../services/firebase_service.dart';
import '../widgets/widgets.dart';
import 'consultation_encounter_screen.dart';

/// Doctor Chamber Screen: queue listener and layout coordinator shell.
class DoctorChamberScreen extends StatefulWidget {
  final Doctor doctor;
  final bool isPreviewMode;

  const DoctorChamberScreen({
    super.key,
    required this.doctor,
    this.isPreviewMode = false,
  });

  @override
  State<DoctorChamberScreen> createState() => _DoctorChamberScreenState();
}

class _DoctorChamberScreenState extends State<DoctorChamberScreen> {
  DateTime _selectedDate = DateTime.now();
  final FirebaseService _firebaseService = FirebaseService();
  StreamSubscription? _chamberSessionSub;
  String? _activeCallingApptId;
  String? _lastHandledCallingAppointmentId;
  bool _isAutoNavigating = false;
  List<Appointment> _latestAppointments = [];

  @override
  void initState() {
    super.initState();
    _listenToChamberSession();
  }

  @override
  void dispose() {
    _chamberSessionSub?.cancel();
    super.dispose();
  }

  void _listenToChamberSession() {
    _chamberSessionSub?.cancel();
    _chamberSessionSub = _firebaseService
        .streamChamberSession(widget.doctor.id, _selectedDate)
        .listen((snapshot) {
      if (!snapshot.exists || !mounted) return;
      final data = snapshot.data();
      if (data == null) return;

      final status = data['status'] as String?;
      final activeApptId = data['activeAppointmentId'] as String?;

      setState(() {
        _activeCallingApptId = (status == 'calling' || status == 'in_consultation')
            ? activeApptId
            : null;
      });

      if (status == 'calling' &&
          activeApptId != null &&
          activeApptId.isNotEmpty &&
          activeApptId != _lastHandledCallingAppointmentId &&
          !_isAutoNavigating) {
        _lastHandledCallingAppointmentId = activeApptId;
        _autoOpenConsultationForId(activeApptId);
      }
    });
  }

  Future<void> _autoOpenConsultationForId(String appointmentId) async {
    _isAutoNavigating = true;
    try {
      Appointment? targetAppt = _latestAppointments.where((a) => a.id == appointmentId).firstOrNull;
      if (targetAppt == null) {
        await Future.delayed(const Duration(milliseconds: 400));
        targetAppt = _latestAppointments.where((a) => a.id == appointmentId).firstOrNull;
      }

      if (targetAppt != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.record_voice_over_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Token #${targetAppt.queueNumber} (${targetAppt.patientName}) called into chamber! Auto-loading...',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.teal.shade800,
            duration: const Duration(seconds: 3),
          ),
        );

        await _openConsultation(targetAppt);
      }
    } finally {
      if (mounted) {
        _isAutoNavigating = false;
      }
    }
  }

  Future<void> _openConsultation(Appointment appt) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ConsultationEncounterScreen(
          appointment: appt,
          doctor: widget.doctor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: ChamberAppBar(
        doctor: widget.doctor,
        isPreviewMode: widget.isPreviewMode,
      ),
      body: StreamBuilder<List<Appointment>>(
        stream: _firebaseService.getAppointmentsForDoctorAndDate(
          widget.doctor.id,
          _selectedDate,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('Error loading appointments: ${snapshot.error}'),
              ),
            );
          }

          final appointments = snapshot.data ?? [];
          appointments.sort((a, b) => a.queueNumber.compareTo(b.queueNumber));
          _latestAppointments = appointments;

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClinicDateNavBar(
                        selectedDate: _selectedDate,
                        onDateChanged: (newDate) {
                          setState(() => _selectedDate = newDate);
                          _listenToChamberSession();
                        },
                        onTodayPressed: () {
                          final now = DateTime.now();
                          setState(() => _selectedDate = DateTime(now.year, now.month, now.day));
                          _listenToChamberSession();
                        },
                      ),
                      const SizedBox(height: 16),
                      ChamberMetricsGrid.fromAppointments(
                        appointments: appointments,
                        isDesktop: isDesktop,
                      ),
                      const SizedBox(height: 24),
                      ChamberQueueHeader(totalBooked: appointments.length),
                      const SizedBox(height: 12),
                      if (appointments.isEmpty)
                        const ChamberEmptyQueue()
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: appointments.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                          itemBuilder: (ctx, index) {
                            final appt = appointments[index];
                            return ChamberTokenCard(
                              appointment: appt,
                              isCallingNow: appt.id == _activeCallingApptId,
                              onConsult: () => _openConsultation(appt),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
