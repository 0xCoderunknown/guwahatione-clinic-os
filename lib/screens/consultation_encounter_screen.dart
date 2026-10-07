import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
import '../utils/medicine_search_scorer.dart';
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
    _loadInitialData();
  }

  @override
  void dispose() {
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
                    // STEP 1: Patient Header & Allergies Alert Banner
                    _buildStep1PatientHeader(),
                    const SizedBox(height: 16),

                    // STEP 2: Vitals & Clinical Examination
                    _buildStep2VitalsAndExam(),
                    const SizedBox(height: 16),

                    // STEP 3: Diagnostic Investigations Review
                    _buildStep3DiagnosticReview(),
                    const SizedBox(height: 16),

                    // STEP 4: Medication Reconciliation & Prescribing
                    _buildStep4MedicationReconciliation(),
                    const SizedBox(height: 16),

                    // STEP 5: Advice, Lab Orders & Follow-up
                    _buildStep5AdviceAndFollowUp(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),

              // Bottom Completion Bar
              _buildBottomActionDock(),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // STEP 1: Patient Header & Allergies Banner
  // ===========================================================================

  Widget _buildStep1PatientHeader() {
    final hasAllergies = _allergies.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasAllergies ? Colors.red.shade200 : const Color(0xFFE2E8F0),
          width: hasAllergies ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Demographics bar
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.teal.shade50,
                  foregroundColor: Colors.teal.shade700,
                  radius: 20,
                  child: const Icon(Icons.person, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        widget.appointment.patientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        "Age: ${_patientAge > 0 ? _patientAge : widget.appointment.patientName} yrs • Sex: $_patientGender",
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                      Text(
                        "Phone: ${widget.appointment.patientPhone}",
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.medication_outlined, size: 16),
                  label: const Text('Prior Meds', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                  onPressed: _openPriorMedicationHistoryDialog,
                ),
              ],
            ),
          ),

          // Prominent Allergies Banner (Visual Alert Styling)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: hasAllergies ? Colors.red.shade50 : Colors.amber.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
              border: Border(
                top: BorderSide(
                  color: hasAllergies ? Colors.red.shade200 : Colors.amber.shade200,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  hasAllergies ? Icons.warning_amber_rounded : Icons.info_outline,
                  color: hasAllergies ? Colors.red.shade700 : Colors.amber.shade800,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "ALLERGIES: ",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: hasAllergies ? Colors.red.shade800 : Colors.amber.shade900,
                  ),
                ),
                Expanded(
                  child: hasAllergies
                      ? Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: _allergies.map((allergy) {
                            return Chip(
                              backgroundColor: Colors.white,
                              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                              visualDensity: VisualDensity.compact,
                              side: BorderSide(color: Colors.red.shade300),
                              label: Text(
                                allergy,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade800,
                                ),
                              ),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () {
                                setState(() {
                                  _allergies.remove(allergy);
                                });
                              },
                            );
                          }).toList(),
                        )
                      : Text(
                          "No known allergies recorded (Click + to add)",
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.amber.shade900,
                          ),
                        ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  tooltip: 'Add Known Drug/Substance Allergy',
                  color: hasAllergies ? Colors.red.shade700 : Colors.amber.shade900,
                  onPressed: _promptAddAllergy,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STEP 2: Vitals & Clinical Examination
  // ===========================================================================

  Widget _buildStep2VitalsAndExam() {
    return _buildSectionCard(
      title: 'Step 2: Vitals & Clinical Examination',
      icon: Icons.monitor_heart_outlined,
      iconColor: Colors.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Vitals Grid / Row
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildCompactVitalField(
                label: 'BP (Systolic)',
                unit: 'mmHg',
                controller: _systolicBpController,
                hint: '120',
                width: 140,
              ),
              _buildCompactVitalField(
                label: 'BP (Diastolic)',
                unit: 'mmHg',
                controller: _diastolicBpController,
                hint: '80',
                width: 140,
              ),
              _buildCompactVitalField(
                label: 'Pulse Rate',
                unit: 'bpm',
                controller: _pulseController,
                hint: '72',
                width: 130,
              ),
              _buildCompactVitalField(
                label: 'SpO2',
                unit: '%',
                controller: _spo2Controller,
                hint: '98',
                width: 110,
              ),
              _buildCompactVitalField(
                label: 'Temp',
                unit: '°F',
                controller: _tempController,
                hint: '98.6',
                width: 120,
              ),
              _buildCompactVitalField(
                label: 'Weight',
                unit: 'kg',
                controller: _weightController,
                hint: '68.5',
                width: 130,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Chief Complaints (directly above prescriptions)
          const Text(
            'Chief Complaints / Symptoms',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _complaintInputController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Fever x 3 days, dry cough, headache...',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addChiefComplaint(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: _addChiefComplaint,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
              ),
            ],
          ),
          if (_chiefComplaints.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _chiefComplaints.map((c) {
                return Chip(
                  label: Text(c, style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.teal.shade50,
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () {
                    setState(() => _chiefComplaints.remove(c));
                  },
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),

          // Provisional Diagnosis
          const Text(
            'Provisional / Working Diagnosis',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _diagnosisInputController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Acute Viral Bronchitis, Essential Hypertension...',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addProvisionalDiagnosis(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: _addProvisionalDiagnosis,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
              ),
            ],
          ),
          if (_provisionalDiagnoses.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _provisionalDiagnoses.map((d) {
                return Chip(
                  label: Text(d, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  backgroundColor: Colors.blue.shade50,
                  side: BorderSide(color: Colors.blue.shade200),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () {
                    setState(() => _provisionalDiagnoses.remove(d));
                  },
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),

          // Clinical Examination Notes
          const Text(
            'Physical & Systemic Examination (Optional)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _examController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'e.g., Chest clear, no wheezing, throat congested, abdomen soft...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactVitalField({
    required String label,
    required String unit,
    required TextEditingController controller,
    required String hint,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 3),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: hint,
              suffixText: unit,
              suffixStyle: const TextStyle(fontSize: 10, color: Colors.grey),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STEP 3: Diagnostic Investigations Review
  // ===========================================================================

  Widget _buildStep3DiagnosticReview() {
    final count = _reviewedInvestigations.length;

    return _buildSectionCard(
      title: 'Step 3: Past Diagnostic Investigations Review',
      icon: Icons.biotech_outlined,
      iconColor: Colors.purple,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: count > 0 ? Colors.purple.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count items',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: count > 0 ? Colors.purple.shade700 : Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              _isInvestigationsExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.grey.shade700,
            ),
            tooltip: _isInvestigationsExpanded ? 'Collapse' : 'Expand',
            onPressed: () {
              setState(() {
                _isInvestigationsExpanded = !_isInvestigationsExpanded;
              });
            },
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isInvestigationsExpanded)
            Text(
              count > 0
                  ? '$count investigations tracked. Click expand to enter results.'
                  : 'No pending lab tests from previous visits. (Click + to add outside reports)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
            )
          else ...[
            if (_reviewedInvestigations.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'No past ordered tests recorded for this patient.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _reviewedInvestigations.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                itemBuilder: (ctx, index) {
                  final inv = _reviewedInvestigations[index];
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            inv.testName,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            initialValue: inv.resultValue,
                            decoration: const InputDecoration(
                              hintText: 'Result value / findings',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              _reviewedInvestigations[index] = inv.copyWith(resultValue: val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: inv.performedDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                _reviewedInvestigations[index] =
                                    inv.copyWith(performedDate: picked);
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.event_outlined, size: 14, color: Colors.teal),
                                const SizedBox(width: 4),
                                Text(
                                  inv.performedDate != null
                                      ? DateFormat('dd/MM/yy').format(inv.performedDate!)
                                      : 'Date Done',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _reviewedInvestigations.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Outside Lab Report'),
              onPressed: _promptAddOutsideLabReview,
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // STEP 4: Medication Reconciliation & Prescribing
  // ===========================================================================

  Widget _buildStep4MedicationReconciliation() {
    return _buildSectionCard(
      title: 'Step 4: Medication Reconciliation & Prescribing',
      icon: Icons.medication_liquid_outlined,
      iconColor: Colors.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section A: Past Active Meds (Reconciliation)
          if (_reconciliationItems.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.published_with_changes_rounded, size: 18, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        "Medication Reconciliation (From Prior Visits)",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
                      ),
                      const Spacer(),
                      Text(
                        "${_reconciliationItems.length} active previously",
                        style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _reconciliationItems.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 6),
                    itemBuilder: (ctx, index) {
                      return _buildReconciliationItemRow(_reconciliationItems[index], index);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Section B: Prescribe New Medications (START)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Newly Initiated Medications (START)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Medication'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                onPressed: _openAddMedicationDialog,
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (_newPrescriptions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Text(
                  'No new medications added yet. Tap "Add Medication" to prescribe.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _newPrescriptions.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 6),
              itemBuilder: (ctx, index) {
                return _buildNewPrescriptionRow(_newPrescriptions[index], index);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildReconciliationItemRow(PrescriptionItem item, int index) {
    final isContinued = item.action == MedicationAction.continueAction;
    final isStopped = item.action == MedicationAction.stop;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isContinued
              ? Colors.teal.shade300
              : isStopped
                  ? Colors.red.shade300
                  : const Color(0xFFCBD5E1),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.effectiveName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    decoration: isStopped ? TextDecoration.lineThrough : null,
                    color: isStopped ? Colors.grey : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  "${item.composition} • ${item.dosage} • ${item.frequency} • ${item.timing}${item.durationDays != null ? ' (${item.durationDays}d)' : ' (Chronic)'}",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                if (isStopped && item.stopReason != null && item.stopReason!.isNotEmpty)
                  Text(
                    "Stopped Reason: ${item.stopReason}",
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.red),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 1-Tap CONTINUE Button
          ChoiceChip(
            label: const Text('CONTINUE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            selected: isContinued,
            selectedColor: Colors.teal.shade100,
            onSelected: (val) {
              if (val) {
                setState(() {
                  _reconciliationItems[index] = item.copyWith(
                    action: MedicationAction.continueAction,
                    stopReason: null,
                  );
                });
              }
            },
          ),
          const SizedBox(width: 6),

          // 1-Tap STOP Button
          ChoiceChip(
            label: const Text('STOP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            selected: isStopped,
            selectedColor: Colors.red.shade100,
            onSelected: (val) {
              if (val) {
                _promptStopReason(item, index);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNewPrescriptionRow(PrescriptionItem item, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text(
              'START',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.effectiveName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Text(
                  "${item.composition} • ${item.dosage} • ${item.frequency} • ${item.timing} • ${item.durationDays != null ? '${item.durationDays} days' : 'Chronic'}",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                if (item.instructions != null && item.instructions!.isNotEmpty)
                  Text(
                    "Note: ${item.instructions}",
                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade700),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
            onPressed: () {
              setState(() {
                _newPrescriptions.removeAt(index);
              });
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STEP 5: Advice & Follow-up
  // ===========================================================================

  Widget _buildStep5AdviceAndFollowUp() {
    return _buildSectionCard(
      title: 'Step 5: Advice & Follow-up Orders',
      icon: Icons.checklist_rtl_rounded,
      iconColor: Colors.indigo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order New Diagnostic Tests
          const Text(
            'Order New Investigations / Lab Tests',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _orderedTestInputController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Fasting Blood Sugar, Serum Creatinine, ECG...',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addOrderedTest(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: _addOrderedTest,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Order'),
              ),
            ],
          ),
          if (_orderedTests.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _orderedTests.map((t) {
                return Chip(
                  label: Text(t.testName, style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.indigo.shade50,
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () {
                    setState(() => _orderedTests.remove(t));
                  },
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),

          // Lifestyle & Dietary Advice
          const Text(
            'Advice & Instructions',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _adviceController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'e.g., Low salt diet, hydrate well, avoid cold drinks, consult SOS if fever persists...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16),

          // Next Follow-up Date with Quick Interval Chips
          const Text(
            'Next Follow-up Visit',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildIntervalChip('3 Days', 3),
              _buildIntervalChip('5 Days', 5),
              _buildIntervalChip('7 Days', 7),
              _buildIntervalChip('14 Days', 14),
              _buildIntervalChip('1 Month', 30),
              _buildIntervalChip('3 Months', 90),
              ActionChip(
                avatar: const Icon(Icons.calendar_today, size: 14),
                label: Text(
                  _nextFollowUpDate != null
                      ? DateFormat('dd MMM yyyy').format(_nextFollowUpDate!)
                      : 'Pick Date',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                backgroundColor: _nextFollowUpDate != null ? Colors.teal.shade50 : null,
                onPressed: _pickCustomFollowUpDate,
              ),
              if (_nextFollowUpDate != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  tooltip: 'Clear Follow-up Date',
                  onPressed: () => setState(() => _nextFollowUpDate = null),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalChip(String label, int days) {
    final target = DateTime.now().add(Duration(days: days));
    final isSelected = _nextFollowUpDate != null &&
        _nextFollowUpDate!.year == target.year &&
        _nextFollowUpDate!.month == target.month &&
        _nextFollowUpDate!.day == target.day;

    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (val) {
        setState(() {
          _nextFollowUpDate = val ? target : null;
        });
      },
    );
  }

  // ===========================================================================
  // Bottom Dock & Actions
  // ===========================================================================

  Widget _buildBottomActionDock() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel / Back'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: Text(
              _isSaving ? 'Signing & Saving...' : 'Complete & Sign Consultation',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            onPressed: _isSaving ? null : _completeAndSignConsultation,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              ?trailing,
            ],
          ),
          const Divider(height: 24, thickness: 0.8),
          child,
        ],
      ),
    );
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

  void _openAddMedicationDialog() {
    final searchCtrl = TextEditingController();
    final dosageCtrl = TextEditingController(text: '1 Tablet');
    final instrCtrl = TextEditingController();
    String timing = 'After Food';
    String frequency = '1-0-1';
    int? durationDays = 5;
    bool isChronic = false;

    // Selection state
    Medicine? selectedMedicine;
    String? selectedGenericName;
    String? selectedBrandName;
    String? selectedComposition;
    bool isUnlistedOutside = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final medicines = Provider.of<ClinicProvider>(context).medicines;
          final query = searchCtrl.text.trim();

          final scoredGroups = MedicineSearchScorer.searchAndGroup(
            catalog: medicines,
            query: query,
          );

          final hasSelection = selectedMedicine != null ||
              selectedGenericName != null ||
              isUnlistedOutside;

          return AlertDialog(
            title: const Text('Prescribe Medication (START)'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    TextField(
                      controller: searchCtrl,
                      decoration: InputDecoration(
                        labelText: 'Search Chemical Composition or Brand Name',
                        hintText: 'e.g., Azithromycin, Paracetamol, Dolo, Augmentin...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setDialogState(() {
                                    searchCtrl.clear();
                                    selectedMedicine = null;
                                    selectedGenericName = null;
                                    selectedBrandName = null;
                                    selectedComposition = null;
                                    isUnlistedOutside = false;
                                  });
                                },
                              )
                            : null,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 8),

                    // Active Selection Summary Card
                    if (hasSelection) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUnlistedOutside
                              ? Colors.amber.shade50
                              : Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isUnlistedOutside
                                ? Colors.amber.shade300
                                : Colors.teal.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isUnlistedOutside
                                  ? Icons.medication_outlined
                                  : Icons.check_circle_rounded,
                              color: isUnlistedOutside
                                  ? Colors.amber.shade800
                                  : Colors.teal.shade700,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isUnlistedOutside
                                        ? "Outside / Unlisted Drug: $selectedBrandName"
                                        : (selectedBrandName != null
                                            ? "$selectedBrandName (Brand)"
                                            : "Generic: $selectedGenericName"),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isUnlistedOutside
                                          ? Colors.amber.shade900
                                          : Colors.teal.shade900,
                                    ),
                                  ),
                                  Text(
                                    "Composition: ${selectedComposition ?? selectedBrandName}",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setDialogState(() {
                                  selectedMedicine = null;
                                  selectedGenericName = null;
                                  selectedBrandName = null;
                                  selectedComposition = null;
                                  isUnlistedOutside = false;
                                });
                              },
                              child: const Text('Change'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      // Zero-Friction Outside / Unlisted Medicine Fallback Chip
                      if (query.isNotEmpty) ...[
                        InkWell(
                          onTap: () {
                            setDialogState(() {
                              isUnlistedOutside = true;
                              selectedBrandName = query;
                              selectedComposition = query;
                              selectedMedicine = null;
                              selectedGenericName = null;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.add_shopping_cart, size: 16, color: Colors.amber),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Prescribe "$query" as Outside / Unlisted Medicine',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.amber),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Composition-First Scored Suggestion List
                      if (scoredGroups.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 220),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: scoredGroups.length,
                            separatorBuilder: (c, i) => const Divider(height: 1),
                            itemBuilder: (c, i) {
                              final group = scoredGroups[i];
                              return Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Chemical Composition Header
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: group.isCompositionMatch
                                                ? Colors.teal.shade50
                                                : Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: group.isCompositionMatch
                                                  ? Colors.teal.shade300
                                                  : Colors.blue.shade200,
                                            ),
                                          ),
                                          child: Text(
                                            group.isCompositionMatch ? 'MOLECULE MATCH' : 'BRAND MATCH',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: group.isCompositionMatch
                                                  ? Colors.teal.shade800
                                                  : Colors.blue.shade800,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "${group.compositionLabel} [${group.form}]",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),

                                    // Associated Clinic Brands + Generic Option Chips
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        // 1-tap Generic prescription
                                        ActionChip(
                                          avatar: const Icon(Icons.science_outlined, size: 14, color: Colors.teal),
                                          label: Text("Generic: ${group.composition}", style: const TextStyle(fontSize: 11)),
                                          backgroundColor: Colors.white,
                                          onPressed: () {
                                            setDialogState(() {
                                              selectedGenericName = "${group.composition} ${group.strength}";
                                              selectedComposition = group.compositionLabel;
                                              selectedBrandName = null;
                                              selectedMedicine = null;
                                              dosageCtrl.text = "1 ${group.form}";
                                            });
                                          },
                                        ),

                                        // Associated commercial products in clinic catalog
                                        ...group.associatedBrands.map((brand) {
                                          return ActionChip(
                                            avatar: const Icon(Icons.local_pharmacy_outlined, size: 14, color: Colors.indigo),
                                            label: Text(
                                              "${brand.productName}${brand.manufacturer != null ? ' (${brand.manufacturer})' : ''}",
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                            backgroundColor: Colors.indigo.shade50,
                                            onPressed: () {
                                              setDialogState(() {
                                                selectedMedicine = brand;
                                                selectedBrandName = brand.productName;
                                                selectedComposition = brand.fullCompositionLabel;
                                                selectedGenericName = null;
                                                dosageCtrl.text = "1 ${brand.form}";
                                              });
                                            },
                                          );
                                        }),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 12),
                    ],

                    // Dosage & Frequency Controls
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: dosageCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Dosage',
                              hintText: '1 Tablet / 5 ml',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: frequency,
                            decoration: const InputDecoration(
                              labelText: 'Frequency',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            items: ['1-0-1 (BD)', '1-0-0 (OD)', '0-0-1 (HS)', '1-1-1 (TDS)', 'SOS (As Needed)']
                                .map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 12))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => frequency = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Timing & Duration Controls
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: timing,
                            decoration: const InputDecoration(
                              labelText: 'Timing',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            items: ['After Food', 'Before Food', 'At Bedtime', 'With Food']
                                .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => timing = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            enabled: !isChronic,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: isChronic ? 'Duration' : 'Days',
                              hintText: isChronic ? 'Indefinite' : 'e.g., 5',
                              isDense: true,
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              durationDays = int.tryParse(val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Chronic Indefinite checkbox (sets durationDays = null)
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Chronic / Indefinite Maintenance Therapy (NULL duration)',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: isChronic,
                      onChanged: (val) {
                        setDialogState(() {
                          isChronic = val ?? false;
                          if (isChronic) {
                            durationDays = null;
                          } else {
                            durationDays = 5;
                          }
                        });
                      },
                    ),

                    // Special Instructions
                    TextField(
                      controller: instrCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Instructions / Notes',
                        hintText: 'e.g., With warm water, avoid dairy...',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  final activeName = selectedBrandName ??
                      selectedGenericName ??
                      searchCtrl.text.trim();

                  if (activeName.isEmpty) return;

                  final compText = selectedComposition ??
                      (selectedMedicine != null
                          ? selectedMedicine!.fullCompositionLabel
                          : activeName);

                  final newItem = PrescriptionItem(
                    id: _uuid.v4(),
                    action: MedicationAction.start,
                    medicineId: selectedMedicine?.id,
                    medicineName: selectedMedicine != null
                        ? selectedMedicine!.productName
                        : (selectedBrandName ?? activeName),
                    composition: compText,
                    dosage: dosageCtrl.text.trim(),
                    frequency: frequency,
                    timing: timing,
                    durationDays: isChronic ? null : (durationDays ?? 5),
                    unlistedName: (selectedMedicine == null && (isUnlistedOutside || selectedBrandName != null))
                        ? activeName
                        : null,
                    instructions: instrCtrl.text.trim().isNotEmpty
                        ? instrCtrl.text.trim()
                        : null,
                  );

                  setState(() {
                    _newPrescriptions.add(newItem);
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Add to Prescription'),
              ),
            ],
          );
        },
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
                                    DateFormat('dd MMM yyyy, hh:mm a').format(record.createdAt),
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
