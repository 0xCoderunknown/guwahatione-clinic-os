import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/appointment.dart';
import '../models/consultation.dart';
import '../models/diagnostic_investigation.dart';
import '../models/doctor.dart';
import '../models/medicine.dart';
import '../models/prescription_item.dart';
import '../models/vitals.dart';
import '../providers/clinic_provider.dart';
import '../utils/clinical_defaults_helper.dart';
import '../utils/formatters.dart';
import '../utils/medicine_search_scorer.dart';
import '../widgets/widgets.dart';
import 'prescription_print_screen.dart';

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
  bool _isLoading = true;
  bool _isSaving = false;

  // Section Ergonomics
  bool _isFindingsExpanded = true;
  bool _isMedicineExpanded = true;

  // Real-time chamber incoming alert
  StreamSubscription? _chamberSessionSub;
  String? _incomingCallingApptId;
  String? _incomingCallingPatientName;
  int? _incomingCallingQueueNumber;

  // Inline Medicine Prescribing & Staging
  late String _searchMode;
  final TextEditingController _medSearchController = TextEditingController();
  bool _isSearchActive = false;
  Medicine? _stagedMedicine;
  CompositionGroupResult? _stagedGenericGroup;
  String? _stagedUnlistedName;
  String? _stagedComposition;
  final TextEditingController _stagedDosageController = TextEditingController(text: '1 Tablet');
  final TextEditingController _stagedDurationController = TextEditingController(text: '30');
  final TextEditingController _stagedInstructionsController = TextEditingController();
  String _stagedFrequency = '1-0-0 (OD)';
  String _stagedTiming = 'After Food';
  bool _stagedIsChronic = false;

  // Patient state
  List<String> _allergies = [];
  String _patientGender = 'Unspecified';
  int _patientAge = 0;

  // Step 2: Vitals & Exam Controllers
  final TextEditingController _systolicBpController = TextEditingController();
  final TextEditingController _diastolicBpController = TextEditingController();
  final TextEditingController _pulseController = TextEditingController();
  final TextEditingController _tempController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _spo2Controller = TextEditingController();
  final TextEditingController _complaintInputController = TextEditingController();
  final TextEditingController _diagnosisInputController = TextEditingController();
  final TextEditingController _examController = TextEditingController();

  final List<String> _chiefComplaints = [];
  final List<String> _provisionalDiagnoses = [];

  // Step 3: Diagnostic Reviews
  final List<DiagnosticInvestigationReview> _reviewedInvestigations = [];
  bool _isInvestigationsExpanded = false;

  // Step 4: Medication Reconciliation & Prescriptions
  final List<PrescriptionItem> _reconciliationItems = [];
  final List<PrescriptionItem> _newPrescriptions = [];

  // Step 5: Advice & Follow-up
  final List<OrderedTest> _orderedTests = [];
  final TextEditingController _orderedTestInputController = TextEditingController();
  final TextEditingController _adviceController = TextEditingController();
  DateTime? _nextFollowUpDate;

  @override
  void initState() {
    super.initState();
    _searchMode = widget.doctor.searchPreference;
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

      if (status == 'calling' &&
          activeApptId != null &&
          activeApptId.isNotEmpty &&
          activeApptId != widget.appointment.id) {
        setState(() {
          _incomingCallingApptId = activeApptId;
          _incomingCallingPatientName = data['patientName'] as String? ?? 'Next Patient';
          _incomingCallingQueueNumber = (data['activeQueueNumber'] as num?)?.toInt();
        });
      } else if (status == 'idle' || activeApptId == null) {
        setState(() {
          _incomingCallingApptId = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _chamberSessionSub?.cancel();
    _medSearchController.dispose();
    _stagedDosageController.dispose();
    _stagedDurationController.dispose();
    _stagedInstructionsController.dispose();
    _systolicBpController.dispose();
    _diastolicBpController.dispose();
    _pulseController.dispose();
    _tempController.dispose();
    _weightController.dispose();
    _spo2Controller.dispose();
    _complaintInputController.dispose();
    _diagnosisInputController.dispose();
    _examController.dispose();
    _orderedTestInputController.dispose();
    _adviceController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final clinic = Provider.of<ClinicProvider>(context, listen: false);
    final phone = widget.appointment.patientPhone;

    try {
      // 1. Fetch patient record
      final patient = await clinic.searchPatient(phone);
      if (patient != null) {
        _allergies = List.from(patient.allergies);
        _patientGender = patient.gender;
        _patientAge = patient.age;
      }

      // 2. Fetch past consultations for medication reconciliation & lab reviews
      final pastConsultations = await clinic.getPatientConsultations(phone);

      if (pastConsultations.isNotEmpty) {
        final latest = pastConsultations.first;

        // Pull active meds from previous consultation for 1-click CONTINUE / STOP
        final priorActive = latest.activePrescriptions;
        for (final item in priorActive) {
          _reconciliationItems.add(
            item.copyWith(
              id: _uuid.v4(),
              // Default to continueAction so doctor can 1-click continue or stop
              action: MedicationAction.continueAction,
            ),
          );
        }

        // Pull previously ordered tests that haven't been reviewed yet
        for (final past in pastConsultations) {
          for (final ordered in past.orderedTests) {
            _reviewedInvestigations.add(
              DiagnosticInvestigationReview(
                id: _uuid.v4(),
                testName: ordered.testName,
                resultValue: '',
                performedDate: null,
                notes: null,
              ),
            );
          }
        }
        if (_reviewedInvestigations.isNotEmpty) {
          _isInvestigationsExpanded = true;
        }
      }
    } catch (e) {
      debugPrint('Error loading consultation history: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
                Text(
                  widget.appointment.patientName,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
              "Dr. ${widget.doctor.name} • ${widget.doctor.specialty}",
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Preview & Print Prescription',
            onPressed: _previewCurrentPrescription,
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'View Past Visits',
            onPressed: _viewLongitudinalHistory,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_incomingCallingApptId != null) ...[
                      ChamberCallingAlertBar(
                        queueNumber: _incomingCallingQueueNumber,
                        patientName: _incomingCallingPatientName,
                        onSwitch: _switchToIncomingPatient,
                        onDismiss: () => setState(() => _incomingCallingApptId = null),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // STEP 1: Patient Header & Allergies Alert Banner
                    PatientHeaderSection(
                      patientName: widget.appointment.patientName,
                      patientAge: _patientAge,
                      patientGender: _patientGender,
                      patientPhone: widget.appointment.patientPhone,
                      allergies: _allergies,
                      onAddAllergy: _promptAddAllergy,
                      onRemoveAllergy: (allergy) => setState(() => _allergies.remove(allergy)),
                      onPriorMedsPressed: _openPriorMedicationHistoryDialog,
                    ),
                    const SizedBox(height: 16),

                    // STEP 2: Vitals & Clinical Examination
                    VitalsAndExamSection(
                      isExpanded: _isFindingsExpanded,
                      onToggleExpand: () => setState(() => _isFindingsExpanded = !_isFindingsExpanded),
                      systolicBpController: _systolicBpController,
                      diastolicBpController: _diastolicBpController,
                      pulseController: _pulseController,
                      tempController: _tempController,
                      weightController: _weightController,
                      spo2Controller: _spo2Controller,
                      complaintInputController: _complaintInputController,
                      diagnosisInputController: _diagnosisInputController,
                      examController: _examController,
                      chiefComplaints: _chiefComplaints,
                      provisionalDiagnoses: _provisionalDiagnoses,
                      onAddChiefComplaint: _addChiefComplaint,
                      onRemoveChiefComplaint: (c) => setState(() => _chiefComplaints.remove(c)),
                      onAddProvisionalDiagnosis: _addProvisionalDiagnosis,
                      onRemoveProvisionalDiagnosis: (d) => setState(() => _provisionalDiagnoses.remove(d)),
                    ),
                    const SizedBox(height: 16),

                    // STEP 3: Diagnostic Investigations Review
                    DiagnosticReviewSection(
                      reviewedInvestigations: _reviewedInvestigations,
                      isExpanded: _isInvestigationsExpanded,
                      onToggleExpand: () => setState(() => _isInvestigationsExpanded = !_isInvestigationsExpanded),
                      onResultChanged: (index, val) {
                        _reviewedInvestigations[index] = _reviewedInvestigations[index].copyWith(resultValue: val);
                      },
                      onDateChanged: (index, date) {
                        setState(() {
                          _reviewedInvestigations[index] = _reviewedInvestigations[index].copyWith(performedDate: date);
                        });
                      },
                      onRemoveItem: (index) {
                        setState(() => _reviewedInvestigations.removeAt(index));
                      },
                      onAddOutsideLab: _promptAddOutsideLabReview,
                    ),
                    const SizedBox(height: 16),

                    // STEP 4: Medication Reconciliation & Prescribing
                    RxReconciliationSection(
                      isExpanded: _isMedicineExpanded,
                      onToggleExpand: () => setState(() => _isMedicineExpanded = !_isMedicineExpanded),
                      searchMode: _searchMode,
                      onSearchModeChanged: (mode) => setState(() => _searchMode = mode),
                      medSearchController: _medSearchController,
                      isSearchActive: _isSearchActive,
                      searchResults: _medSearchController.text.trim().isNotEmpty
                          ? MedicineSearchScorer.searchAndGroup(
                              catalog: Provider.of<ClinicProvider>(context).medicines,
                              query: _medSearchController.text,
                              searchMode: _searchMode,
                            )
                          : <CompositionGroupResult>[],
                      onSearchChanged: (val) => setState(() => _isSearchActive = val.trim().isNotEmpty),
                      onClearSearch: () {
                        setState(() {
                          _medSearchController.clear();
                          _isSearchActive = false;
                        });
                      },
                      reconciliationItems: _reconciliationItems,
                      onContinueItem: (index) {
                        setState(() {
                          _reconciliationItems[index] = _reconciliationItems[index].copyWith(
                            action: MedicationAction.continueAction,
                            stopReason: null,
                          );
                        });
                      },
                      onPromptStopReason: _promptStopReason,
                      stagedMedicine: _stagedMedicine,
                      stagedGenericGroup: _stagedGenericGroup,
                      stagedUnlistedName: _stagedUnlistedName,
                      stagedComposition: _stagedComposition,
                      stagedDosageController: _stagedDosageController,
                      stagedDurationController: _stagedDurationController,
                      stagedInstructionsController: _stagedInstructionsController,
                      stagedFrequency: _stagedFrequency,
                      onFrequencyChanged: (val) {
                        if (val != null) setState(() => _stagedFrequency = val);
                      },
                      stagedTiming: _stagedTiming,
                      onTimingChanged: (val) {
                        if (val != null) setState(() => _stagedTiming = val);
                      },
                      stagedIsChronic: _stagedIsChronic,
                      onChronicChanged: (val) => setState(() => _stagedIsChronic = val),
                      onCancelStaging: () {
                        setState(() {
                          _stagedMedicine = null;
                          _stagedGenericGroup = null;
                          _stagedUnlistedName = null;
                          _stagedComposition = null;
                        });
                      },
                      onConfirmAddStaged: _confirmAddStagedMedicine,
                      onStageMedicine: _stageMedicine,
                      onStageGeneric: _stageGeneric,
                      onStageUnlisted: _stageUnlisted,
                      newPrescriptions: _newPrescriptions,
                      onRemoveNewPrescription: (index) {
                        setState(() => _newPrescriptions.removeAt(index));
                      },
                    ),
                    const SizedBox(height: 16),

                    // STEP 5: Advice, Lab Orders & Follow-up
                    AdviceAndOrdersSection(
                      orderedTestInputController: _orderedTestInputController,
                      orderedTests: _orderedTests,
                      onAddOrderedTest: _addOrderedTest,
                      onRemoveOrderedTest: (t) => setState(() => _orderedTests.remove(t)),
                      adviceController: _adviceController,
                      nextFollowUpDate: _nextFollowUpDate,
                      onFollowUpDateChanged: (d) => setState(() => _nextFollowUpDate = d),
                      onPickCustomDate: _pickCustomFollowUpDate,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),

              // Bottom Completion Bar
              ConsultationBottomDock(
                isSaving: _isSaving,
                onCancel: () => Navigator.pop(context),
                onCompleteAndSign: _completeAndSignConsultation,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Medication Staging & Prescribing Handlers
  // ===========================================================================

  void _stageMedicine(Medicine med) {
    final defaults = ClinicalDefaultsHelper.getDefaultsForMedicine(med);
    setState(() {
      _stagedMedicine = med;
      _stagedGenericGroup = null;
      _stagedUnlistedName = null;
      _stagedComposition = med.fullCompositionLabel;
      _stagedDosageController.text = defaults.dosage;
      _stagedFrequency = defaults.frequency;
      _stagedTiming = defaults.timing;
      _stagedIsChronic = defaults.durationDays == null;
      _stagedDurationController.text = defaults.durationDays != null ? '${defaults.durationDays}' : '30';
      _stagedInstructionsController.text = defaults.instructions ?? '';
      _isSearchActive = false;
    });
  }

  void _stageGeneric(CompositionGroupResult group) {
    final dummy = Medicine(
      id: 'gen_${_uuid.v4()}',
      productName: group.compositionLabel,
      composition: group.composition,
      strength: group.strength,
      form: group.form,
    );
    final defaults = ClinicalDefaultsHelper.getDefaultsForMedicine(dummy);
    setState(() {
      _stagedMedicine = null;
      _stagedGenericGroup = group;
      _stagedUnlistedName = null;
      _stagedComposition = group.compositionLabel;
      _stagedDosageController.text = defaults.dosage;
      _stagedFrequency = defaults.frequency;
      _stagedTiming = defaults.timing;
      _stagedIsChronic = defaults.durationDays == null;
      _stagedDurationController.text = defaults.durationDays != null ? '${defaults.durationDays}' : '30';
      _stagedInstructionsController.text = defaults.instructions ?? '';
      _isSearchActive = false;
    });
  }

  void _stageUnlisted(String query) {
    final clean = query.trim();
    if (clean.isEmpty) return;
    setState(() {
      _stagedMedicine = null;
      _stagedGenericGroup = null;
      _stagedUnlistedName = clean;
      _stagedComposition = clean;
      _stagedDosageController.text = '1 Tablet';
      _stagedFrequency = '1-0-1 (BD)';
      _stagedTiming = 'After Food';
      _stagedIsChronic = false;
      _stagedDurationController.text = '5';
      _stagedInstructionsController.text = '';
      _isSearchActive = false;
    });
  }

  void _confirmAddStagedMedicine() {
    String name;
    String comp = _stagedComposition ?? '';
    String? medId;
    String? unlisted;

    if (_stagedMedicine != null) {
      name = _stagedMedicine!.productName;
      if (comp.isEmpty) comp = _stagedMedicine!.fullCompositionLabel;
      medId = _stagedMedicine!.id;
    } else if (_stagedGenericGroup != null) {
      name = _stagedGenericGroup!.compositionLabel;
      if (comp.isEmpty) comp = _stagedGenericGroup!.compositionLabel;
    } else if (_stagedUnlistedName != null) {
      name = _stagedUnlistedName!;
      if (comp.isEmpty) comp = _stagedUnlistedName!;
      unlisted = _stagedUnlistedName!;
    } else {
      return;
    }

    final int? duration = _stagedIsChronic
        ? null
        : int.tryParse(_stagedDurationController.text.trim());

    final item = PrescriptionItem(
      id: _uuid.v4(),
      action: MedicationAction.start,
      medicineId: medId,
      medicineName: name,
      composition: comp,
      dosage: _stagedDosageController.text.trim().isNotEmpty
          ? _stagedDosageController.text.trim()
          : '1 Tablet',
      frequency: _stagedFrequency,
      timing: _stagedTiming,
      durationDays: duration,
      unlistedName: unlisted,
      instructions: _stagedInstructionsController.text.trim().isNotEmpty
          ? _stagedInstructionsController.text.trim()
          : null,
    );

    setState(() {
      _newPrescriptions.add(item);
      _stagedMedicine = null;
      _stagedGenericGroup = null;
      _stagedUnlistedName = null;
      _stagedComposition = null;
      _medSearchController.clear();
      _isSearchActive = false;
    });
  }


  Future<void> _switchToIncomingPatient() async {
    final apptId = _incomingCallingApptId;
    if (apptId == null) return;
    final clinic = Provider.of<ClinicProvider>(context, listen: false);
    final appts = clinic.todayAppointments;
    Appointment? target;
    for (final a in appts) {
      if (a.id == apptId) {
        target = a;
        break;
      }
    }
    if (target != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (ctx) => ConsultationEncounterScreen(
            appointment: target!,
            doctor: widget.doctor,
          ),
        ),
      );
    }
  }


  // ===========================================================================
  // Helpers & Dialog Handlers
  // ===========================================================================

  void _addChiefComplaint() {
    final text = _complaintInputController.text.trim();
    if (text.isNotEmpty && !_chiefComplaints.contains(text)) {
      setState(() {
        _chiefComplaints.add(text);
        _complaintInputController.clear();
      });
    }
  }

  void _addProvisionalDiagnosis() {
    final text = _diagnosisInputController.text.trim();
    if (text.isNotEmpty && !_provisionalDiagnoses.contains(text)) {
      setState(() {
        _provisionalDiagnoses.add(text);
        _diagnosisInputController.clear();
      });
    }
  }

  void _addOrderedTest() {
    final text = _orderedTestInputController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _orderedTests.add(OrderedTest(testName: text));
        _orderedTestInputController.clear();
      });
    }
  }

  void _promptAddAllergy() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Allergy'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Allergen / Drug Name',
            hintText: 'e.g., Penicillin, Sulfa, NSAIDs, Peanuts...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                setState(() => _allergies.add(val));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _promptAddOutsideLabReview() {
    final nameCtrl = TextEditingController();
    final resultCtrl = TextEditingController();
    DateTime pickedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Outside Lab Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Test Name',
                hintText: 'e.g., HbA1c, Lipid Profile, Ultrasound...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: resultCtrl,
              decoration: const InputDecoration(
                labelText: 'Findings / Result Value',
                hintText: 'e.g., 6.8%, Normal sinus rhythm...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _reviewedInvestigations.add(
                    DiagnosticInvestigationReview(
                      id: _uuid.v4(),
                      testName: name,
                      resultValue: resultCtrl.text.trim(),
                      performedDate: pickedDate,
                    ),
                  );
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _promptStopReason(PrescriptionItem item, int index) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Stop ${item.effectiveName}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select or type the clinical reason for discontinuing this drug:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: ['Condition Resolved', 'Adverse Effect / Intolerance', 'Ineffective', 'Switched']
                  .map((chip) => ActionChip(
                        label: Text(chip, style: const TextStyle(fontSize: 11)),
                        onPressed: () => reasonCtrl.text = chip,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Stop Reason (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              setState(() {
                _reconciliationItems[index] = item.copyWith(
                  action: MedicationAction.stop,
                  stopReason: reasonCtrl.text.trim().isEmpty ? 'Discontinued by Doctor' : reasonCtrl.text.trim(),
                );
              });
              Navigator.pop(ctx);
            },
            child: const Text('Confirm Stop'),
          ),
        ],
      ),
    );
  }



  void _openPriorMedicationHistoryDialog() {
    final medCtrl = TextEditingController();
    final doseCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Prior Outside Regimen Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add outside medications that a new patient was already taking prior to this encounter. These will be added as ongoing baseline medications.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: medCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Medication Name & Strength',
                hintText: 'e.g., Metformin 500mg, Telmisartan 40mg...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: doseCtrl,
              decoration: const InputDecoration(
                labelText: 'Schedule / Frequency',
                hintText: 'e.g., Once daily morning after food',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final val = medCtrl.text.trim();
              if (val.isNotEmpty) {
                setState(() {
                  _reconciliationItems.add(
                    PrescriptionItem(
                      id: _uuid.v4(),
                      action: MedicationAction.continueAction,
                      medicineName: val,
                      composition: val,
                      dosage: '1 Dose',
                      frequency: doseCtrl.text.trim().isNotEmpty ? doseCtrl.text.trim() : 'Once daily',
                      timing: 'After Food',
                      durationDays: null, // baseline chronic
                      unlistedName: val,
                    ),
                  );
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add to Baseline'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustomFollowUpDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextFollowUpDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _nextFollowUpDate = picked;
      });
    }
  }

  void _viewLongitudinalHistory() async {
    final clinic = Provider.of<ClinicProvider>(context, listen: false);
    final history = await clinic.getPatientConsultations(widget.appointment.patientPhone);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded, color: Colors.teal),
                  const SizedBox(width: 8),
                  Text(
                    "Longitudinal Record (${history.length} visits)",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: history.isEmpty
                  ? const Center(child: Text('No previous consultation records for this patient.'))
                  : ListView.separated(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      itemCount: history.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 12),
                      itemBuilder: (c, i) {
                        final record = history[i];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppFormatters.dateTime(record.createdAt),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    "Dr. ${record.doctorName}",
                                    style: TextStyle(fontSize: 12, color: Colors.teal.shade800),
                                  ),
                                ],
                              ),
                              if (record.vitals?.bpFormatted != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text("BP: ${record.vitals!.bpFormatted}", style: const TextStyle(fontSize: 12)),
                                ),
                              if (record.provisionalDiagnosis.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    "Diagnosis: ${record.provisionalDiagnosis.join(', ')}",
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              const SizedBox(height: 6),
                              Text(
                                "Rx: ${record.activePrescriptions.map((p) => p.effectiveName).join(', ')}",
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeAndSignConsultation() async {
    setState(() => _isSaving = true);

    try {
      final clinic = Provider.of<ClinicProvider>(context, listen: false);

      // Build Vitals
      final vitals = Vitals(
        systolicBp: int.tryParse(_systolicBpController.text.trim()),
        diastolicBp: int.tryParse(_diastolicBpController.text.trim()),
        pulseRate: int.tryParse(_pulseController.text.trim()),
        temperature: double.tryParse(_tempController.text.trim()),
        weightKg: double.tryParse(_weightController.text.trim()),
        spO2: int.tryParse(_spo2Controller.text.trim()),
      );

      // Combine all reconciled and new prescription items
      final allPrescriptionItems = [
        ..._reconciliationItems,
        ..._newPrescriptions,
      ];

      // Build append-only Consultation record
      final consultation = Consultation(
        id: _uuid.v4(),
        appointmentId: widget.appointment.id,
        patientPhone: widget.appointment.patientPhone,
        patientName: widget.appointment.patientName,
        patientAge: _patientAge > 0 ? _patientAge : 0,
        patientGender: _patientGender,
        doctorId: widget.doctor.id,
        doctorName: widget.doctor.name,
        createdAt: DateTime.now(),
        vitals: vitals.hasAny ? vitals : null,
        chiefComplaints: _chiefComplaints,
        clinicalExamination: _examController.text.trim().isNotEmpty ? _examController.text.trim() : null,
        provisionalDiagnosis: _provisionalDiagnoses,
        reviewedInvestigations: _reviewedInvestigations,
        prescriptionItems: allPrescriptionItems,
        orderedTests: _orderedTests,
        adviceNotes: _adviceController.text.trim().isNotEmpty ? _adviceController.text.trim() : null,
        nextFollowUpDate: _nextFollowUpDate,
      );

      // Atomically save consultation, update appointment status to completed, and sync patient
      await clinic.saveConsultation(consultation);

      // Clear chamber calling session so doctor chamber returns to idle
      await clinic.clearChamberSession(widget.doctor.id, widget.appointment.scheduledDate);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Consultation signed and saved for ${widget.appointment.patientName}"),
          backgroundColor: Colors.teal.shade800,
        ),
      );

      // Launch Prescription Print Screen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => PrescriptionPrintScreen(
            consultation: consultation,
            appointment: widget.appointment,
            patientAllergies: _allergies,
            doctorSpecialty: widget.doctor.specialty,
          ),
        ),
      );

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

  void _previewCurrentPrescription() {
    final vitals = Vitals(
      systolicBp: int.tryParse(_systolicBpController.text.trim()),
      diastolicBp: int.tryParse(_diastolicBpController.text.trim()),
      pulseRate: int.tryParse(_pulseController.text.trim()),
      temperature: double.tryParse(_tempController.text.trim()),
      weightKg: double.tryParse(_weightController.text.trim()),
      spO2: int.tryParse(_spo2Controller.text.trim()),
    );

    final draftConsultation = Consultation(
      id: 'draft-${_uuid.v4()}',
      appointmentId: widget.appointment.id,
      patientPhone: widget.appointment.patientPhone,
      patientName: widget.appointment.patientName,
      patientAge: _patientAge > 0 ? _patientAge : 0,
      patientGender: _patientGender,
      doctorId: widget.doctor.id,
      doctorName: widget.doctor.name,
      createdAt: DateTime.now(),
      vitals: vitals.hasAny ? vitals : null,
      chiefComplaints: _chiefComplaints,
      clinicalExamination: _examController.text.trim().isNotEmpty ? _examController.text.trim() : null,
      provisionalDiagnosis: _provisionalDiagnoses,
      reviewedInvestigations: _reviewedInvestigations,
      prescriptionItems: [
        ..._reconciliationItems,
        ..._newPrescriptions,
      ],
      orderedTests: _orderedTests,
      adviceNotes: _adviceController.text.trim().isNotEmpty ? _adviceController.text.trim() : null,
      nextFollowUpDate: _nextFollowUpDate,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => PrescriptionPrintScreen(
          consultation: draftConsultation,
          appointment: widget.appointment,
          patientAllergies: _allergies,
          doctorSpecialty: widget.doctor.specialty,
        ),
      ),
    );
  }
}
