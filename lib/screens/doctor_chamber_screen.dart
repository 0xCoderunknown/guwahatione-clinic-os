import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/services.dart';
import '../utils/app_constants.dart';
import '../widgets/widgets.dart';
import 'screens.dart';

/// Doctor Chamber Screen: queue listener and layout coordinator shell.
class DoctorChamberScreen extends StatefulWidget {
  final Doctor doctor;
  final bool isPreviewMode;
  final BookingService? bookingService;
  final ChamberService? chamberService;

  const DoctorChamberScreen({
    super.key,
    required this.doctor,
    this.isPreviewMode = false,
    this.bookingService,
    this.chamberService,
  });

  @override
  State<DoctorChamberScreen> createState() => _DoctorChamberScreenState();
}

class _DoctorChamberScreenState extends State<DoctorChamberScreen> {
  DateTime _selectedDate = DateTime.now();
  late final BookingService _bookingService =
      widget.bookingService ?? BookingService();
  late final ChamberService _chamberService =
      widget.chamberService ?? ChamberService();
  StreamSubscription? _chamberSessionSub;
  String? _activeCallingApptId;
  String? _lastHandledCallingAppointmentId;
  bool _isAutoNavigating = false;
  bool _isConsultationOpen = false;
  List<Appointment> _latestAppointments = [];

  ChamberStatus _chamberStatus = ChamberStatus.idle;
  int? _lastCompletedQueueNumber;
  String? _lastCompletedPatientName;
  int? _activeQueueNumber;
  String? _activePatientName;
  bool _isBusySignaling = false;

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

  bool get _isToday => DateUtils.isSameDay(_selectedDate, DateTime.now());

  bool get _isPastDate =>
      _selectedDate.isBefore(DateUtils.dateOnly(DateTime.now()));

  String get _queueHeaderTitle =>
      _isPastDate ? "Previous Session" : "Today's Patient Queue";

  void _listenToChamberSession() {
    _chamberSessionSub?.cancel();
    if (!_isToday) {
      if (mounted) {
        setState(() {
          _chamberStatus = ChamberStatus.idle;
          _activeCallingApptId = null;
          _activeQueueNumber = null;
          _activePatientName = null;
          _lastCompletedQueueNumber = null;
          _lastCompletedPatientName = null;
        });
      }
      return;
    }

    if (_isToday && !widget.isPreviewMode) {
      _chamberService
          .notifyDoctorArrived(
            doctorId: widget.doctor.id,
            date: _selectedDate,
          )
          .catchError((e) {
            debugPrint('Error notifying doctor arrived: $e');
          });
    }

    _chamberSessionSub = _chamberService
        .streamChamberSession(widget.doctor.id, _selectedDate)
        .listen((session) {
          if (!mounted) return;

          setState(() {
            _chamberStatus = session.statusEnum;
            _activeCallingApptId = session.hasActivePatient
                ? session.activeAppointmentId
                : null;
            _activeQueueNumber = session.activeQueueNumber;
            _activePatientName = session.patientName;
            _lastCompletedQueueNumber = session.lastCompletedQueueNumber;
            _lastCompletedPatientName = session.lastCompletedPatientName;
          });

          if (session.isCalling &&
              session.activeAppointmentId != null &&
              session.activeAppointmentId!.isNotEmpty &&
              session.activeAppointmentId != _lastHandledCallingAppointmentId &&
              !_isAutoNavigating &&
              !_isConsultationOpen) {
            _lastHandledCallingAppointmentId = session.activeAppointmentId!;
            _autoOpenConsultationForId(session.activeAppointmentId!);
          }
        });
  }

  Future<void> _handleNextPatient() async {
    setState(() => _isBusySignaling = true);
    try {
      await _chamberService.notifyReadyForNext(
        doctorId: widget.doctor.id,
        date: _selectedDate,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Signaled Reception: Chamber Ready for Next Patient!'),
              ],
            ),
            backgroundColor: Colors.teal.shade800,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final message =
            e is StateError ? e.message : 'Error signaling reception: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusySignaling = false);
    }
  }

  Future<void> _handleReopenShift() async {
    setState(() => _isBusySignaling = true);
    try {
      await _chamberService.notifyReadyForNext(
        doctorId: widget.doctor.id,
        date: _selectedDate,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Shift re-opened! Reception signaled chamber is ready.'),
              ],
            ),
            backgroundColor: Colors.teal.shade800,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error re-opening shift: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusySignaling = false);
    }
  }

  Future<void> _handleLogout() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_person_rounded, color: Color(0xFF334155)),
            SizedBox(width: 8),
            Text('Doctor Session & Logout'),
          ],
        ),
        content: const Text(
          'Choose whether to lock your session temporarily, or conclude your OPD shift for today.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Cancel'),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.lock_outline_rounded, size: 16),
            label: const Text('Lock / Log Out Only'),
            onPressed: () => Navigator.pop(ctx, 'logout_only'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF334155),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.nightlife_rounded, size: 16),
            label: const Text('End Shift & Logout'),
            onPressed: () => Navigator.pop(ctx, 'end_shift'),
          ),
        ],
      ),
    );

    if (result == null || result == 'cancel' || !mounted) return;

    if (result == 'end_shift') {
      try {
        if (_isToday) {
          await _chamberService.notifyShiftEnded(
            doctorId: widget.doctor.id,
            date: _selectedDate,
          );
        }
      } catch (e) {
        debugPrint('Error concluding shift on logout: $e');
      }
    }

    if (mounted) {
      await Provider.of<AuthProvider>(context, listen: false).logout();
    }
  }

  Future<void> _autoOpenConsultationForId(String appointmentId) async {
    _isAutoNavigating = true;
    try {
      Appointment? targetAppt = _latestAppointments
          .where((a) => a.id == appointmentId)
          .firstOrNull;
      if (targetAppt == null) {
        await Future.delayed(const Duration(milliseconds: 400));
        targetAppt = _latestAppointments
            .where((a) => a.id == appointmentId)
            .firstOrNull;
      }

      if (targetAppt != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.record_voice_over_rounded,
                  color: Colors.white,
                  size: 20,
                ),
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

  Future<void> _handleDoorAdmit(Appointment appt) async {
    if (!_isToday) return;
    setState(() => _isBusySignaling = true);
    try {
      // 1. Claim atomic chamber occupancy lock first (throws if chamber is occupied)
      await _chamberService.callTokenIntoChamber(
        doctorId: widget.doctor.id,
        date: _selectedDate,
        appointment: appt,
      );

      // 2. Once atomic chamber lock is secured, admit patient to chamber in database
      await _bookingService.admitPatientToChamber(appt.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.meeting_room_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Token #${appt.queueNumber} (${appt.patientName}) admitted directly from door.',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.teal.shade800,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // 3. Open consultation encounter workspace
      await _openConsultation(appt);
    } catch (e) {
      if (mounted) {
        final message =
            e is StateError ? e.message : 'Error admitting patient: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusySignaling = false);
    }
  }

  Future<void> _openConsultation(Appointment appt) async {
    if (_isPastDate) {
      if (appt.status == AppointmentStatus.completed) {
        await EncounterDialogs.showLongitudinalHistory(
          context,
          patientId: appt.patientId,
          patientPhone: appt.patientPhone,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Token #${appt.queueNumber} (${appt.patientName}) was unattended. Past chamber shifts are read-only.',
            ),
            backgroundColor: Colors.blueGrey.shade800,
          ),
        );
      }
      return;
    }

    if (_isConsultationOpen) return;
    _isConsultationOpen = true;

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => ConsultationEncounterScreen(
            appointment: appt,
            doctor: widget.doctor,
          ),
        ),
      );
    } finally {
      _isConsultationOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: ChamberAppBar(
        doctor: widget.doctor,
        isPreviewMode: widget.isPreviewMode,
        onLogout: _handleLogout,
      ),
      body: StreamBuilder<List<Appointment>>(
        stream: _bookingService.getAppointmentsForDoctorAndDate(
          widget.doctor.id,
          _selectedDate,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2.5),
            );
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

          // Chamber Queue: Strictly isolate patients physically present in clinic (waiting in lobby, in consultation, or completed/absent).
          // Advance phone bookings (VisitStatus.booked) do not clutter the doctor's active live queue.
          final chamberQueue = appointments
              .where((a) => a.visitStatus != VisitStatus.booked)
              .toList();

          // Emergency Door Fallback: Strictly capped to next 1-2 patients who are:
          // 1. AppointmentStatus.pending
          // 2. VisitStatus.waitingInLobby
          // 3. PaymentType != PaymentType.unpaid
          // Strictly disabled on past dates and whenever chamber is already occupied or calling a patient.
          final isChamberOccupied =
              _chamberStatus == ChamberStatus.inConsultation ||
              _chamberStatus == ChamberStatus.calling ||
              (_activeCallingApptId != null &&
                  _activeCallingApptId!.isNotEmpty);

          final isShiftEnded = _chamberStatus == ChamberStatus.shiftEnded;

          final doorEligibleTokens =
              (!_isToday || isChamberOccupied || isShiftEnded)
                  ? <Appointment>[]
                  : appointments
                        .where(
                          (a) =>
                              a.status == AppointmentStatus.pending &&
                              a.visitStatus == VisitStatus.waitingInLobby &&
                              a.paymentType != PaymentType.unpaid,
                        )
                        .take(2)
                        .toList();

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : 16,
                vertical: 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClinicDateNavBar(
                        selectedDate: _selectedDate,
                        firstDate: AppConstants.clinicEpochDate,
                        onDateChanged: (newDate) {
                          setState(() => _selectedDate = newDate);
                          _listenToChamberSession();
                        },
                        onTodayPressed: () {
                          final now = DateTime.now();
                          setState(
                            () => _selectedDate = DateTime(
                              now.year,
                              now.month,
                              now.day,
                            ),
                          );
                          _listenToChamberSession();
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_isToday) ...[
                        ChamberControlBanner(
                          status: _chamberStatus,
                          lastCompletedQueueNumber: _lastCompletedQueueNumber,
                          lastCompletedPatientName: _lastCompletedPatientName,
                          activeQueueNumber: _activeQueueNumber,
                          activePatientName: _activePatientName,
                          isBusy: _isBusySignaling,
                          onNextPatient: _handleNextPatient,
                          onOpenActivePatient: _activeCallingApptId != null
                              ? () => _autoOpenConsultationForId(
                                  _activeCallingApptId!,
                                )
                              : null,
                          onReopenShift: _handleReopenShift,
                        ),
                        if (doorEligibleTokens.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          ChamberDoorOverrideBar(
                            eligibleTokens: doorEligibleTokens,
                            onAdmit: _handleDoorAdmit,
                            isBusy: _isBusySignaling,
                          ),
                        ],
                      ] else if (_isPastDate) ...[
                        ChamberArchiveBanner(date: _selectedDate),
                      ],
                      const SizedBox(height: 16),
                      ChamberMetricsGrid.fromAppointments(
                        appointments: appointments,
                        isDesktop: isDesktop,
                        isPastDate: _isPastDate,
                      ),
                      const SizedBox(height: 24),
                      ChamberQueueHeader(
                        title: _queueHeaderTitle,
                        totalBooked: chamberQueue.length,
                        isPastDate: _isPastDate,
                      ),
                      const SizedBox(height: 12),
                      ChamberQueueList(
                        appointments: chamberQueue,
                        activeCallingApptId: _activeCallingApptId,
                        isPastDate: _isPastDate,
                        onConsult: _openConsultation,
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
