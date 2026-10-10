import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/appointment.dart';
import '../models/consultation.dart';
import '../models/doctor.dart';
import '../models/prescription_item.dart';
import '../providers/clinic_provider.dart';
import '../widgets/widgets.dart';
import 'prescription_print_screen.dart';

/// Coordinator Scaffold assembling the clinical encounter steps and binding the encounter state.
class ConsultationEncounterScreen extends StatefulWidget {
  final Appointment appointment;
  final Doctor doctor;

  const ConsultationEncounterScreen({
    super.key,
    required this.appointment,
    required this.doctor,
  });

  @override
  State<ConsultationEncounterScreen> createState() =>
      _ConsultationEncounterScreenState();
}

class _ConsultationEncounterScreenState
    extends State<ConsultationEncounterScreen> {
  final Uuid _uuid = const Uuid();
  final EncounterFormState form = EncounterFormState();

  bool _isLoading = true;
  bool _isSaving = false;

  // Real-time chamber incoming alert
  StreamSubscription? _chamberSessionSub;
  String? _incomingCallingApptId;
  String? _incomingCallingPatientName;
  int? _incomingCallingQueueNumber;

  @override
  void initState() {
    super.initState();
    form.searchMode = widget.doctor.searchPreference;
    _listenToChamberSessionAlert();
    _loadInitialData();
  }

  void _listenToChamberSessionAlert() {
    final clinic = Provider.of<ClinicProvider>(context, listen: false);
    _chamberSessionSub = clinic
        .streamChamberSession(widget.doctor.id, widget.appointment.scheduledDate)
        .listen((snapshot) {
      if (!snapshot.exists || !mounted) return;
      final data = snapshot.data();
      if (data == null) return;
      final activeApptId = data['activeAppointmentId'] as String?;
      final status = data['status'] as String?;

      if (status == 'calling' && activeApptId != null && activeApptId.isNotEmpty && activeApptId != widget.appointment.id) {
        setState(() {
          _incomingCallingApptId = activeApptId;
          _incomingCallingPatientName = data['patientName'] as String? ?? 'Next Patient';
          _incomingCallingQueueNumber = (data['activeQueueNumber'] as num?)?.toInt();
        });
      } else if (status == 'idle' || activeApptId == null) {
        setState(() => _incomingCallingApptId = null);
      }
    });
  }

  @override
  void dispose() {
    _chamberSessionSub?.cancel();
    form.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final clinic = Provider.of<ClinicProvider>(context, listen: false);
    try {
      await form.loadInitialData(
        clinic: clinic,
        patientPhone: widget.appointment.patientPhone,
        uuidGenerator: _uuid.v4,
      );
      await clinic.notifyConsultationStarted(
        doctorId: widget.doctor.id,
        date: widget.appointment.scheduledDate,
        appointment: widget.appointment,
      );
    } catch (e) {
      debugPrint('Error loading consultation history: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _switchToIncomingPatient() async {
    final apptId = _incomingCallingApptId;
    if (apptId == null) return;
    final clinic = Provider.of<ClinicProvider>(context, listen: false);
    final target = clinic.todayAppointments.where((a) => a.id == apptId).firstOrNull;
    if (target != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (ctx) => ConsultationEncounterScreen(
            appointment: target,
            doctor: widget.doctor,
          ),
        ),
      );
    }
  }

  Future<void> _navigateToPrint(Consultation consultation) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => PrescriptionPrintScreen(
          consultation: consultation,
          appointment: widget.appointment,
          patientAllergies: form.allergies,
          doctorSpecialty: widget.doctor.specialty,
        ),
      ),
    );
  }

  Future<void> _completeAndSignConsultation() async {
    setState(() => _isSaving = true);
    try {
      final clinic = Provider.of<ClinicProvider>(context, listen: false);
      final consultation = form.buildConsultation(
        id: _uuid.v4(),
        appointmentId: widget.appointment.id,
        patientPhone: widget.appointment.patientPhone,
        patientName: widget.appointment.patientName,
        doctorId: widget.doctor.id,
        doctorName: widget.doctor.name,
      );

      await clinic.saveConsultation(consultation);
      await clinic.notifyConsultationEnded(
        doctorId: widget.doctor.id,
        date: widget.appointment.scheduledDate,
        queueNumber: widget.appointment.queueNumber,
        patientName: widget.appointment.patientName,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Consultation signed and saved for ${widget.appointment.patientName}"),
          backgroundColor: Colors.teal.shade800,
        ),
      );

      await _navigateToPrint(consultation);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving consultation: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _previewCurrentPrescription() {
    final draft = form.buildConsultation(
      id: 'draft-${_uuid.v4()}',
      appointmentId: widget.appointment.id,
      patientPhone: widget.appointment.patientPhone,
      patientName: widget.appointment.patientName,
      doctorId: widget.doctor.id,
      doctorName: widget.doctor.name,
    );
    _navigateToPrint(draft);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Clinical File...')),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(widget.appointment.patientName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.teal.shade200)),
                  child: Text("Token #${widget.appointment.queueNumber.toString().padLeft(2, '0')}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
                ),
              ],
            ),
            Text("Dr. ${widget.doctor.name} • ${widget.doctor.specialty}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'View Longitudinal History',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => EncounterDialogs.showLongitudinalHistory(context, patientPhone: widget.appointment.patientPhone),
          ),
          IconButton(tooltip: 'Preview Rx Print Draft', icon: const Icon(Icons.print_outlined), onPressed: _previewCurrentPrescription),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_incomingCallingApptId != null)
              ChamberCallingAlertBar(
                queueNumber: _incomingCallingQueueNumber,
                patientName: _incomingCallingPatientName,
                onSwitch: _switchToIncomingPatient,
                onDismiss: () => setState(() => _incomingCallingApptId = null),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  PatientHeaderSection.fromForm(
                    appointment: widget.appointment,
                    form: form,
                    onAddAllergy: () => EncounterDialogs.promptAddAllergy(context, (a) => setState(() => form.addAllergy(a))),
                    onPriorMedsPressed: () => EncounterDialogs.openPriorMedicationHistoryDialog(context, _uuid.v4, (item) => setState(() => form.reconciliationItems.add(item))),
                    onUpdate: () => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  VitalsAndExamSection.fromForm(form: form, onUpdate: () => setState(() {})),
                  const SizedBox(height: 16),
                  DiagnosticReviewSection.fromForm(
                    form: form,
                    onUpdate: () => setState(() {}),
                    onAddOutsideLab: () => EncounterDialogs.promptAddOutsideLabReview(context, _uuid.v4, (rev) => setState(() => form.reviewedInvestigations.add(rev))),
                  ),
                  const SizedBox(height: 16),
                  RxReconciliationSection.fromForm(
                    form: form,
                    catalog: Provider.of<ClinicProvider>(context).medicines,
                    uuidGenerator: _uuid.v4,
                    onPromptStopReason: (item, idx) => EncounterDialogs.promptStopReason(context, item, (reason) {
                      setState(() => form.reconciliationItems[idx] = item.copyWith(action: MedicationAction.stop, stopReason: reason));
                    }),
                    onUpdate: () => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  AdviceAndOrdersSection.fromForm(
                    form: form,
                    onUpdate: () => setState(() {}),
                    onPickCustomDate: () async {
                      final picked = await EncounterDialogs.pickCustomFollowUpDate(context, currentDate: form.nextFollowUpDate);
                      if (picked != null) setState(() => form.nextFollowUpDate = picked);
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
            ConsultationBottomDock(isSaving: _isSaving, onCancel: () => Navigator.pop(context), onCompleteAndSign: _completeAndSignConsultation),
          ],
        ),
      ),
    );
  }
}
