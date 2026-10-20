import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../providers/clinic_provider.dart';
import '../utils/formatters.dart';
import '../widgets/widgets.dart';
import 'screens.dart';

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

  @override
  void initState() {
    super.initState();
    form.searchMode = widget.doctor.searchPreference;
    _loadInitialData();
  }

  @override
  void dispose() {
    form.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final clinic = Provider.of<ClinicProvider>(context, listen: false);
    try {
      await form.loadInitialData(
        clinic: clinic,
        patientPhone: widget.appointment.patientPhone,
        patientId: widget.appointment.patientId,
        uuidGenerator: _uuid.v4,
      );

      // Restore saved local draft if this consultation was paused previously
      final savedDraft = await EncounterFormState.loadDraft(
        widget.appointment.id,
      );
      if (savedDraft != null) {
        form.restoreFromDraftMap(savedDraft);
      }

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

  Future<void> _navigateToPrint(Consultation consultation) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => PrescriptionPrintScreen(
          consultation: consultation,
          appointment: widget.appointment,
          patientAllergies: form.allergies,
          doctorSpecialty: widget.doctor.specialty,
          doctorRegNumber: widget.doctor.medicalRegNumber,
        ),
      ),
    );
  }

  Future<void> _completeAndSignConsultation() async {
    if (_isSaving) return;

    if (form.hasStagedMedicine) {
      final medicineName = form.stagedMedicineDisplayName;
      final choice = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.medication_outlined, color: Colors.teal),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Unadded Staged Medicine',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            'You have staged "$medicineName" but have not added it to the prescription yet.\n\n'
            'Would you like to include it before completing and signing?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: const Text('Review / Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'discard'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Discard & Sign'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, 'add'),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add to Prescription & Sign'),
              style: FilledButton.styleFrom(backgroundColor: Colors.teal.shade700),
            ),
          ],
        ),
      );

      if (!mounted) return;
      if (choice == 'cancel' || choice == null) {
        return;
      }
      if (choice == 'add') {
        final added = form.confirmAddStagedMedicine(() => _uuid.v4());
        if (!added) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please check medicine duration (e.g. 1-300 days, cont, or SOS) before signing.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      } else if (choice == 'discard') {
        form.cancelStaging();
      }
    }

    setState(() => _isSaving = true);
    try {
      final clinic = Provider.of<ClinicProvider>(context, listen: false);
      final consultation = form.buildConsultation(
        id: _uuid.v4(),
        appointmentId: widget.appointment.id,
        patientId: widget.appointment.patientId,
        patientPhone: widget.appointment.patientPhone,
        patientName: widget.appointment.patientName,
        patientAgeDisplay: widget.appointment.patientAgeDisplay,
        guardianName: widget.appointment.guardianName,
        guardianRelation: widget.appointment.guardianRelation,
        doctorId: widget.doctor.id,
        doctorName: widget.doctor.name,
        doctorRegNumber: widget.doctor.medicalRegNumber,
      );

      await clinic.saveConsultation(consultation);
      await clinic.notifyConsultationEnded(
        doctorId: widget.doctor.id,
        date: widget.appointment.scheduledDate,
        queueNumber: widget.appointment.queueNumber,
        patientName: widget.appointment.patientName,
      );
      await EncounterFormState.clearDraft(widget.appointment.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "✅ Consultation signed and saved for ${widget.appointment.patientName}",
          ),
          backgroundColor: Colors.teal.shade800,
        ),
      );

      await _navigateToPrint(consultation);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving consultation: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pauseAndSaveConsultation() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final clinic = Provider.of<ClinicProvider>(context, listen: false);
      // 1. Save typed draft locally
      await EncounterFormState.saveDraft(
        widget.appointment.id,
        form.toDraftMap(),
      );

      // 2. Mark appointment paused and free doctor chamber
      await clinic.pauseConsultation(
        appointmentId: widget.appointment.id,
        doctorId: widget.doctor.id,
        date: widget.appointment.scheduledDate,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "⏸️ Consultation paused for Token #${widget.appointment.queueNumber} (${widget.appointment.patientName}). Draft saved.",
          ),
          backgroundColor: Colors.purple.shade800,
        ),
      );

      Navigator.pop(context, false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error pausing consultation: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _discardAndExitConsultation() async {
    final clinic = Provider.of<ClinicProvider>(context, listen: false);
    await EncounterFormState.clearDraft(widget.appointment.id);
    await clinic.notifyReadyForNext(
      doctorId: widget.doctor.id,
      date: widget.appointment.scheduledDate,
    );
    if (mounted) Navigator.pop(context, false);
  }

  Future<void> _showExitOrPauseDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.pause_circle_outline_rounded,
              color: Colors.purple.shade700,
            ),
            const SizedBox(width: 8),
            const Text('Pause Consultation?'),
          ],
        ),
        content: const Text(
          'Patient needs to step out for lab tests or outside reports?\n\n'
          '• Pause & Save Draft: Keeps your typed vitals, observations, and prescription draft intact. Frees your chamber for the next patient. Reception can resume when the patient returns.\n\n'
          '• Discard: Wipes out draft changes and returns chamber to ready state.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: const Text('Discard'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, 'pause'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.purple.shade700,
            ),
            icon: const Icon(Icons.pause_rounded, size: 16),
            label: const Text('Pause & Save Draft'),
          ),
        ],
      ),
    );

    if (result == 'pause') {
      await _pauseAndSaveConsultation();
    } else if (result == 'discard') {
      await _discardAndExitConsultation();
    }
  }

  void _previewCurrentPrescription() {
    final draft = form.buildConsultation(
      id: 'draft-${_uuid.v4()}',
      appointmentId: widget.appointment.id,
      patientId: widget.appointment.patientId,
      patientPhone: widget.appointment.patientPhone,
      patientName: widget.appointment.patientName,
      patientAgeDisplay: widget.appointment.patientAgeDisplay,
      guardianName: widget.appointment.guardianName,
      guardianRelation: widget.appointment.guardianRelation,
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _showExitOrPauseDialog();
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    widget.appointment.patientName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Text(
                    "Token #${widget.appointment.queueNumber.toString().padLeft(2, '0')}",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade800,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              "${widget.doctor.titleName} • ${widget.doctor.specialty}",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'View Patient History',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => EncounterDialogs.showLongitudinalHistory(
              context,
              patientId: widget.appointment.patientId,
              patientPhone: widget.appointment.patientPhone,
              onCarryForward: (record) {
                final count = form.carryForwardFromConsultation(
                  consultation: record,
                  uuidGenerator: _uuid.v4,
                );
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Carried forward $count medication${count > 1 ? 's' : ''} from visit on ${AppFormatters.date(record.createdAt)}',
                    ),
                    backgroundColor: Colors.teal.shade800,
                  ),
                );
              },
            ),
          ),
          IconButton(
            tooltip: 'Preview Rx Print Draft',
            icon: const Icon(Icons.print_outlined),
            onPressed: _previewCurrentPrescription,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  PatientHeaderSection.fromForm(
                    appointment: widget.appointment,
                    form: form,
                    onAddAllergy: () => EncounterDialogs.promptAddAllergy(
                      context,
                      (a) => setState(() => form.addAllergy(a)),
                    ),
                    onPriorMedsPressed: () =>
                        EncounterDialogs.openPriorMedicationHistoryDialog(
                          context,
                          _uuid.v4,
                          (item) => setState(
                            () => form.reconciliationItems.add(item),
                          ),
                        ),
                    onUpdate: () => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  VitalsAndExamSection.fromForm(
                    form: form,
                    onUpdate: () => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  DiagnosticReviewSection.fromForm(
                    form: form,
                    onUpdate: () => setState(() {}),
                    onAddOutsideLab: () =>
                        EncounterDialogs.promptAddOutsideLabReview(
                          context,
                          _uuid.v4,
                          (rev) => setState(
                            () => form.reviewedInvestigations.add(rev),
                          ),
                        ),
                  ),
                  const SizedBox(height: 16),
                  RxReconciliationSection.fromForm(
                    form: form,
                    catalog: Provider.of<ClinicProvider>(context).medicines,
                    uuidGenerator: _uuid.v4,
                    onPromptStopReason: (item, idx) =>
                        EncounterDialogs.promptStopReason(context, item, (
                          reason,
                        ) {
                          setState(
                            () => form.reconciliationItems[idx] = item.copyWith(
                              action: MedicationAction.stop,
                              stopReason: reason,
                            ),
                          );
                        }),
                    onUpdate: () => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  AdviceAndOrdersSection.fromForm(
                    form: form,
                    onUpdate: () => setState(() {}),
                    onPickCustomDate: () async {
                      final picked =
                          await EncounterDialogs.pickCustomFollowUpDate(
                            context,
                            currentDate: form.nextFollowUpDate,
                          );
                      if (picked != null) {
                        setState(() => form.nextFollowUpDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
            ConsultationBottomDock(
              isSaving: _isSaving,
              onPause: _showExitOrPauseDialog,
              onCompleteAndSign: _completeAndSignConsultation,
            ),
          ],
        ),
      ),
    ),
  );
  }
}

/// Bottom persistent docking bar for saving, pausing, and signing consultation encounter.
class ConsultationBottomDock extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onPause;
  final VoidCallback onCompleteAndSign;

  const ConsultationBottomDock({
    super.key,
    required this.isSaving,
    required this.onPause,
    required this.onCompleteAndSign,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 550;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: isMobile
          ? Row(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purple.shade800,
                    side: BorderSide(color: Colors.purple.shade300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.pause_circle_outline_rounded, size: 16),
                  onPressed: isSaving ? null : onPause,
                  label: const Text('Pause'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    icon: isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 18,
                          ),
                    label: Text(
                      isSaving ? 'Saving...' : 'End Consultation & Sign',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    onPressed: isSaving ? null : onCompleteAndSign,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purple.shade800,
                    side: BorderSide(color: Colors.purple.shade300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.pause_circle_outline_rounded, size: 18),
                  onPressed: isSaving ? null : onPause,
                  label: const Text('Pause / Step Out'),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                        ),
                  label: Text(
                    isSaving
                        ? 'Saving & Ending...'
                        : 'Finish Consultation & Sign',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  onPressed: isSaving ? null : onCompleteAndSign,
                ),
              ],
            ),
    );
  }
}
