import 'package:flutter/material.dart';

import '../../models/consultation.dart';
import '../../models/diagnostic_investigation.dart';
import '../../models/medicine.dart';
import '../../models/prescription_item.dart';
import '../../models/vitals.dart';
import '../../providers/clinic_provider.dart';
import '../../utils/clinical_defaults_helper.dart';
import '../../utils/medicine_search_scorer.dart';

/// Encapsulates all state, controllers, and mutation logic for a clinical consultation encounter.
class EncounterFormState {
  // Step 2: Vitals & Examination Controllers
  final TextEditingController systolicBpController = TextEditingController();
  final TextEditingController diastolicBpController = TextEditingController();
  final TextEditingController pulseController = TextEditingController();
  final TextEditingController tempController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController spo2Controller = TextEditingController();
  final TextEditingController complaintInputController = TextEditingController();
  final TextEditingController diagnosisInputController = TextEditingController();
  final TextEditingController examController = TextEditingController();

  final List<String> chiefComplaints = [];
  final List<String> provisionalDiagnoses = [];

  // Step 3: Diagnostic Reviews
  final List<DiagnosticInvestigationReview> reviewedInvestigations = [];
  bool isInvestigationsExpanded = false;

  // Step 4: Staged Medicine & Prescribing State
  String searchMode = 'both';
  final TextEditingController medSearchController = TextEditingController();
  bool isSearchActive = false;

  Medicine? stagedMedicine;
  CompositionGroupResult? stagedGenericGroup;
  String? stagedUnlistedName;
  String? stagedComposition;

  final TextEditingController stagedDosageController = TextEditingController(text: '1 Tablet');
  final TextEditingController stagedDurationController = TextEditingController(text: '30');
  final TextEditingController stagedInstructionsController = TextEditingController();
  String stagedFrequency = '1-0-0 (OD)';
  String stagedTiming = 'After Food';
  bool stagedIsChronic = false;

  final List<PrescriptionItem> reconciliationItems = [];
  final List<PrescriptionItem> newPrescriptions = [];

  // Step 5: Advice & Follow-up
  final List<OrderedTest> orderedTests = [];
  final TextEditingController orderedTestInputController = TextEditingController();
  final TextEditingController adviceController = TextEditingController();
  DateTime? nextFollowUpDate;

  // Patient Demographic & Allergy State
  List<String> allergies = [];
  String patientGender = 'Unspecified';
  int patientAge = 0;

  // Ergonomic Accordion Toggles
  bool isFindingsExpanded = true;
  bool isMedicineExpanded = true;

  // ---------------------------------------------------------------------------
  // Chief Complaints & Provisional Diagnoses Handlers
  // ---------------------------------------------------------------------------

  void addChiefComplaint() {
    final text = complaintInputController.text.trim();
    if (text.isNotEmpty && !chiefComplaints.contains(text)) {
      chiefComplaints.add(text);
      complaintInputController.clear();
    }
  }

  void removeChiefComplaint(String text) {
    chiefComplaints.remove(text);
  }

  void addProvisionalDiagnosis() {
    final text = diagnosisInputController.text.trim();
    if (text.isNotEmpty && !provisionalDiagnoses.contains(text)) {
      provisionalDiagnoses.add(text);
      diagnosisInputController.clear();
    }
  }

  void removeProvisionalDiagnosis(String text) {
    provisionalDiagnoses.remove(text);
  }

  // ---------------------------------------------------------------------------
  // Orders & Allergies Handlers
  // ---------------------------------------------------------------------------

  void addOrderedTest() {
    final text = orderedTestInputController.text.trim();
    if (text.isNotEmpty) {
      orderedTests.add(OrderedTest(testName: text));
      orderedTestInputController.clear();
    }
  }

  void removeOrderedTest(OrderedTest test) {
    orderedTests.remove(test);
  }

  void addAllergy(String allergy) {
    final text = allergy.trim();
    if (text.isNotEmpty && !allergies.contains(text)) {
      allergies.add(text);
    }
  }

  void removeAllergy(String allergy) {
    allergies.remove(allergy);
  }

  // ---------------------------------------------------------------------------
  // Staging & Medication Handlers
  // ---------------------------------------------------------------------------

  void stageMedicine(Medicine med) {
    final defaults = ClinicalDefaultsHelper.getDefaultsForMedicine(med);
    stagedMedicine = med;
    stagedGenericGroup = null;
    stagedUnlistedName = null;
    stagedComposition = med.fullCompositionLabel;
    stagedDosageController.text = defaults.dosage;
    stagedFrequency = defaults.frequency;
    stagedTiming = defaults.timing;
    stagedIsChronic = defaults.durationDays == null;
    stagedDurationController.text = defaults.durationDays != null ? '${defaults.durationDays}' : '30';
    stagedInstructionsController.text = defaults.instructions ?? '';
    isSearchActive = false;
  }

  void stageGeneric(CompositionGroupResult group, String Function() uuidGenerator) {
    final dummy = Medicine(
      id: 'gen_${uuidGenerator()}',
      productName: group.compositionLabel,
      composition: group.composition,
      strength: group.strength,
      form: group.form,
    );
    final defaults = ClinicalDefaultsHelper.getDefaultsForMedicine(dummy);
    stagedMedicine = null;
    stagedGenericGroup = group;
    stagedUnlistedName = null;
    stagedComposition = group.compositionLabel;
    stagedDosageController.text = defaults.dosage;
    stagedFrequency = defaults.frequency;
    stagedTiming = defaults.timing;
    stagedIsChronic = defaults.durationDays == null;
    stagedDurationController.text = defaults.durationDays != null ? '${defaults.durationDays}' : '30';
    stagedInstructionsController.text = defaults.instructions ?? '';
    isSearchActive = false;
  }

  void stageUnlisted(String query) {
    final clean = query.trim();
    if (clean.isEmpty) return;
    stagedMedicine = null;
    stagedGenericGroup = null;
    stagedUnlistedName = clean;
    stagedComposition = clean;
    stagedDosageController.text = '1 Tablet';
    stagedFrequency = '1-0-1 (BD)';
    stagedTiming = 'After Food';
    stagedIsChronic = false;
    stagedDurationController.text = '5';
    stagedInstructionsController.text = '';
    isSearchActive = false;
  }

  void cancelStaging() {
    stagedMedicine = null;
    stagedGenericGroup = null;
    stagedUnlistedName = null;
    stagedComposition = null;
  }

  void confirmAddStagedMedicine(String Function() uuidGenerator) {
    String name;
    String comp = stagedComposition ?? '';
    String? medId;
    String? unlisted;

    if (stagedMedicine != null) {
      name = stagedMedicine!.productName;
      if (comp.isEmpty) comp = stagedMedicine!.fullCompositionLabel;
      medId = stagedMedicine!.id;
    } else if (stagedGenericGroup != null) {
      name = stagedGenericGroup!.compositionLabel;
      if (comp.isEmpty) comp = stagedGenericGroup!.compositionLabel;
    } else if (stagedUnlistedName != null) {
      name = stagedUnlistedName!;
      if (comp.isEmpty) comp = stagedUnlistedName!;
      unlisted = stagedUnlistedName!;
    } else {
      return;
    }

    final int? duration = stagedIsChronic
        ? null
        : int.tryParse(stagedDurationController.text.trim());

    final item = PrescriptionItem(
      id: uuidGenerator(),
      action: MedicationAction.start,
      medicineId: medId,
      medicineName: name,
      composition: comp,
      dosage: stagedDosageController.text.trim().isNotEmpty
          ? stagedDosageController.text.trim()
          : '1 Tablet',
      frequency: stagedFrequency,
      timing: stagedTiming,
      durationDays: duration,
      unlistedName: unlisted,
      instructions: stagedInstructionsController.text.trim().isNotEmpty
          ? stagedInstructionsController.text.trim()
          : null,
    );

    newPrescriptions.add(item);
    cancelStaging();
    medSearchController.clear();
    isSearchActive = false;
  }

  // ---------------------------------------------------------------------------
  // Builder Helpers
  // ---------------------------------------------------------------------------

  Vitals buildVitals() {
    return Vitals(
      systolicBp: int.tryParse(systolicBpController.text.trim()),
      diastolicBp: int.tryParse(diastolicBpController.text.trim()),
      pulseRate: int.tryParse(pulseController.text.trim()),
      temperature: double.tryParse(tempController.text.trim()),
      weightKg: double.tryParse(weightController.text.trim()),
      spO2: int.tryParse(spo2Controller.text.trim()),
    );
  }

  List<PrescriptionItem> get allPrescriptionItems => [
        ...reconciliationItems,
        ...newPrescriptions,
      ];

  Consultation buildConsultation({
    required String id,
    required String appointmentId,
    required String patientPhone,
    required String patientName,
    required String doctorId,
    required String doctorName,
  }) {
    final vitals = buildVitals();
    return Consultation(
      id: id,
      appointmentId: appointmentId,
      patientPhone: patientPhone,
      patientName: patientName,
      patientAge: patientAge > 0 ? patientAge : 0,
      patientGender: patientGender,
      doctorId: doctorId,
      doctorName: doctorName,
      createdAt: DateTime.now(),
      vitals: vitals.hasAny ? vitals : null,
      chiefComplaints: List.from(chiefComplaints),
      clinicalExamination: examController.text.trim().isNotEmpty ? examController.text.trim() : null,
      provisionalDiagnosis: List.from(provisionalDiagnoses),
      reviewedInvestigations: List.from(reviewedInvestigations),
      prescriptionItems: allPrescriptionItems,
      orderedTests: List.from(orderedTests),
      adviceNotes: adviceController.text.trim().isNotEmpty ? adviceController.text.trim() : null,
      nextFollowUpDate: nextFollowUpDate,
    );
  }

  /// Loads patient profile and prior consultation history into encounter state.
  Future<void> loadInitialData({
    required ClinicProvider clinic,
    required String patientPhone,
    required String Function() uuidGenerator,
  }) async {
    final patient = await clinic.searchPatient(patientPhone);
    if (patient != null) {
      allergies = List.from(patient.allergies);
      patientGender = patient.gender;
      patientAge = patient.age;
    }

    final pastConsultations = await clinic.getPatientConsultations(patientPhone);
    if (pastConsultations.isNotEmpty) {
      final latest = pastConsultations.first;
      for (final item in latest.activePrescriptions) {
        reconciliationItems.add(
          item.copyWith(
            id: uuidGenerator(),
            action: MedicationAction.continueAction,
          ),
        );
      }

      for (final past in pastConsultations) {
        for (final ordered in past.orderedTests) {
          reviewedInvestigations.add(
            DiagnosticInvestigationReview(
              id: uuidGenerator(),
              testName: ordered.testName,
              resultValue: '',
              performedDate: null,
              notes: null,
            ),
          );
        }
      }
      if (reviewedInvestigations.isNotEmpty) {
        isInvestigationsExpanded = true;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  void dispose() {
    systolicBpController.dispose();
    diastolicBpController.dispose();
    pulseController.dispose();
    tempController.dispose();
    weightController.dispose();
    spo2Controller.dispose();
    complaintInputController.dispose();
    diagnosisInputController.dispose();
    examController.dispose();
    medSearchController.dispose();
    stagedDosageController.dispose();
    stagedDurationController.dispose();
    stagedInstructionsController.dispose();
    orderedTestInputController.dispose();
    adviceController.dispose();
  }
}
