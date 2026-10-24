import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/engines/engines.dart';
import '../../models/consultation.dart';
import '../../models/diagnostic_investigation.dart';
import '../../models/medicine.dart';
import '../../models/prescription_item.dart';
import '../../models/prescription_template.dart';
import '../../models/vitals.dart';
import '../../providers/clinic_provider.dart';

/// Encapsulates all state, controllers, and mutation logic for a clinical consultation encounter.
class EncounterFormState {
  // Step 2: Vitals & Examination Controllers
  final TextEditingController systolicBpController = TextEditingController();
  final TextEditingController diastolicBpController = TextEditingController();
  final TextEditingController pulseController = TextEditingController();
  final TextEditingController tempController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController spo2Controller = TextEditingController();
  final TextEditingController complaintInputController =
      TextEditingController();
  final TextEditingController diagnosisInputController =
      TextEditingController();
  final TextEditingController examController = TextEditingController();

  final List<String> chiefComplaints = [];
  final List<String> provisionalDiagnoses = [];

  // Step 3: Diagnostic Reviews
  final List<DiagnosticInvestigationReview> reviewedInvestigations = [];
  bool isInvestigationsExpanded = false;

  // Step 4: Staged Medicine & Prescribing State
  String searchMode = 'both';
  final TextEditingController medSearchController = TextEditingController();
  final FocusNode medSearchFocusNode = FocusNode();
  bool isSearchActive = false;

  Medicine? stagedMedicine;
  CompositionGroupResult? stagedGenericGroup;
  String? stagedUnlistedName;
  String? stagedComposition;

  /// Returns true if a medicine has been selected and is actively staged
  bool get hasStagedMedicine =>
      stagedMedicine != null ||
      stagedGenericGroup != null ||
      stagedUnlistedName != null;

  /// Descriptive trade name or composition of currently staged medicine
  String get stagedMedicineDisplayName {
    if (stagedMedicine != null) return stagedMedicine!.productName;
    if (stagedGenericGroup != null) return stagedGenericGroup!.compositionLabel;
    if (stagedUnlistedName != null) return stagedUnlistedName!;
    return '';
  }

  final TextEditingController stagedDosageController = TextEditingController(
    text: '1 Tablet',
  );
  final TextEditingController stagedDurationController = TextEditingController(
    text: '30 days',
  );
  final TextEditingController stagedInstructionsController =
      TextEditingController();
  String stagedFrequency = '1-0-0 (OD)';
  String stagedTiming = 'After Food';
  bool stagedIsChronic = false;

  final List<PrescriptionItem> reconciliationItems = [];
  final List<PrescriptionItem> newPrescriptions = [];

  // Step 5: Advice & Follow-up
  final List<OrderedTest> orderedTests = [];
  final TextEditingController orderedTestInputController =
      TextEditingController();
  final TextEditingController adviceController = TextEditingController();
  DateTime? nextFollowUpDate;

  // Patient Demographic & Allergy State
  String patientName = '';
  List<String> allergies = [];
  String patientGender = 'Unspecified';
  int patientAge = 0;

  /// Updates patient demographics directly from the active encounter.
  void updatePatientDemographics({
    required String name,
    required int age,
    required String gender,
  }) {
    patientName = name.trim();
    patientAge = age;
    patientGender = gender;
  }

  // Longitudinal History & Carried-Forward Regimens
  List<Consultation> pastConsultations = [];

  /// Returns the most recent prior consultation that contains active prescription items.
  Consultation? get lastConsultationWithRx {
    for (final c in pastConsultations) {
      if (c.activePrescriptions.isNotEmpty) {
        return c;
      }
    }
    return null;
  }

  // Ergonomic Accordion Toggles
  bool isFindingsExpanded = true;
  bool isMedicineExpanded = true;

  /// Clones active medications from a prior [consultation] into [reconciliationItems]
  /// as `MedicationAction.continueAction` ("To continue"), skipping duplicates.
  int carryForwardFromConsultation({
    required Consultation consultation,
    required String Function() uuidGenerator,
  }) {
    int addedCount = 0;
    final existingNames = reconciliationItems
        .map((r) => r.effectiveName.trim().toLowerCase())
        .toSet();

    for (final item in consultation.activePrescriptions) {
      final name = item.effectiveName.trim().toLowerCase();
      if (!existingNames.contains(name)) {
        existingNames.add(name);
        reconciliationItems.add(
          item.copyWith(
            id: uuidGenerator(),
            action: MedicationAction.continueAction,
            stopReason: null,
          ),
        );
        addedCount++;
      }
    }
    return addedCount;
  }

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

  /// Copies recorded numerical vitals from a prior consultation into the active form controllers.
  void copyVitalsFromConsultation(Consultation past) {
    final v = past.vitals;
    if (v == null) return;
    if (v.systolicBp != null) systolicBpController.text = v.systolicBp.toString();
    if (v.diastolicBp != null) diastolicBpController.text = v.diastolicBp.toString();
    if (v.pulseRate != null) pulseController.text = v.pulseRate.toString();
    if (v.spO2 != null) spo2Controller.text = v.spO2.toString();
    if (v.temperature != null) tempController.text = v.temperature.toString();
    if (v.weightKg != null) weightController.text = v.weightKg.toString();
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
    final defaults = MedicineEngine.getDefaultsForMedicine(med);
    stagedMedicine = med;
    stagedGenericGroup = null;
    stagedUnlistedName = null;
    stagedComposition = med.fullCompositionLabel;
    stagedDosageController.text = defaults.dosage;
    stagedFrequency = defaults.frequency;
    stagedTiming = defaults.timing;
    stagedIsChronic = defaults.durationDays == null &&
        (defaults.durationText == null ||
            defaults.durationText!.toLowerCase().startsWith('cont') ||
            defaults.durationText!.toLowerCase() == 'to continue');
    stagedDurationController.text = defaults.durationText ??
        (defaults.durationDays != null
            ? '${defaults.durationDays} days'
            : 'To continue');
    stagedInstructionsController.text = defaults.instructions ?? '';
    isSearchActive = false;
  }

  void stageGeneric(
    CompositionGroupResult group,
    String Function() uuidGenerator,
  ) {
    final dummy = Medicine(
      id: 'gen_${uuidGenerator()}',
      productName: group.compositionLabel,
      composition: group.composition,
    );
    final defaults = MedicineEngine.getDefaultsForMedicine(dummy);
    stagedMedicine = null;
    stagedGenericGroup = group;
    stagedUnlistedName = null;
    stagedComposition = group.compositionLabel;
    stagedDosageController.text = defaults.dosage;
    stagedFrequency = defaults.frequency;
    stagedTiming = defaults.timing;
    stagedIsChronic = defaults.durationDays == null &&
        (defaults.durationText == null ||
            defaults.durationText!.toLowerCase().startsWith('cont') ||
            defaults.durationText!.toLowerCase() == 'to continue');
    stagedDurationController.text = defaults.durationText ??
        (defaults.durationDays != null
            ? '${defaults.durationDays} days'
            : 'To continue');
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
    stagedDurationController.text = '5 days';
    stagedInstructionsController.text = '';
    isSearchActive = false;
  }

  void cancelStaging() {
    stagedMedicine = null;
    stagedGenericGroup = null;
    stagedUnlistedName = null;
    stagedComposition = null;
  }

  bool confirmAddStagedMedicine(String Function() uuidGenerator) {
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
      return false;
    }

    final parsed = MedicineEngine.parseDuration(
      stagedIsChronic ? 'To continue' : stagedDurationController.text,
    );
    if (!parsed.isValid) {
      return false;
    }

    final item = PrescriptionItem(
      id: uuidGenerator(),
      action: MedicationAction.start,
      medicineId: medId,
      medicineName: name,
      composition: comp,
      manufacturer: stagedMedicine?.manufacturer,
      dosage: stagedDosageController.text.trim().isNotEmpty
          ? stagedDosageController.text.trim()
          : '1 Tablet',
      frequency: stagedFrequency,
      timing: stagedTiming,
      durationDays: parsed.durationDays,
      durationText: parsed.durationText,
      unlistedName: unlisted,
      instructions: stagedInstructionsController.text.trim().isNotEmpty
          ? stagedInstructionsController.text.trim()
          : null,
    );

    newPrescriptions.add(item);
    cancelStaging();
    medSearchController.clear();
    isSearchActive = false;
    medSearchFocusNode.requestFocus();
    return true;
  }

  /// Evaluates and applies a clinical prescription template bundle.
  /// Skips duplicate medications that are already active on the prescription.
  TemplateApplicationResult applyPrescriptionTemplate({
    required PrescriptionTemplate template,
    required String Function() uuidGenerator,
  }) {
    final result = MedicineEngine.evaluateTemplateApplication(
      template: template,
      existingItems: allPrescriptionItems,
      uuidGenerator: uuidGenerator,
    );
    newPrescriptions.addAll(result.addedItems);
    return result;
  }

  // ---------------------------------------------------------------------------
  // Builder Helpers
  // ---------------------------------------------------------------------------

  Vitals buildVitals() {
    int? parseBoundedInt(String raw, int min, int max) {
      final v = int.tryParse(raw.trim());
      if (v == null || v < min || v > max) return null;
      return v;
    }

    double? parseBoundedDouble(String raw, double min, double max) {
      final v = double.tryParse(raw.trim());
      if (v == null || v < min || v > max) return null;
      return v;
    }

    return Vitals(
      systolicBp: parseBoundedInt(systolicBpController.text, 40, 300),
      diastolicBp: parseBoundedInt(diastolicBpController.text, 20, 200),
      pulseRate: parseBoundedInt(pulseController.text, 30, 250),
      temperature: parseBoundedDouble(tempController.text, 70.0, 115.0),
      weightKg: parseBoundedDouble(weightController.text, 0.5, 500.0),
      spO2: parseBoundedInt(spo2Controller.text, 40, 100),
    );
  }

  List<PrescriptionItem> get allPrescriptionItems => [
    ...reconciliationItems,
    ...newPrescriptions,
  ];

  Consultation buildConsultation({
    required String id,
    required String appointmentId,
    String? patientId,
    required String patientPhone,
    required String patientName,
    String? patientAgeDisplay,
    String? guardianName,
    String? guardianRelation,
    required String doctorId,
    required String doctorName,
    String? doctorRegNumber,
  }) {
    final vitals = buildVitals();
    return Consultation(
      id: id,
      appointmentId: appointmentId,
      patientId: patientId ?? patientPhone,
      patientPhone: patientPhone,
      patientName: patientName,
      patientAge: patientAge > 0 ? patientAge : 0,
      patientAgeDisplay: patientAgeDisplay,
      guardianName: guardianName,
      guardianRelation: guardianRelation,
      patientGender: patientGender,
      doctorId: doctorId,
      doctorName: doctorName,
      doctorRegNumber: doctorRegNumber,
      createdAt: DateTime.now(),
      vitals: vitals.hasAny ? vitals : null,
      chiefComplaints: List.from(chiefComplaints),
      clinicalExamination: examController.text.trim().isNotEmpty
          ? examController.text.trim()
          : null,
      provisionalDiagnosis: List.from(provisionalDiagnoses),
      reviewedInvestigations: List.from(reviewedInvestigations),
      prescriptionItems: allPrescriptionItems,
      orderedTests: List.from(orderedTests),
      adviceNotes: adviceController.text.trim().isNotEmpty
          ? adviceController.text.trim()
          : null,
      nextFollowUpDate: nextFollowUpDate,
    );
  }

  /// Loads patient profile and prior consultation history into encounter state.
  Future<void> loadInitialData({
    required ClinicProvider clinic,
    required String patientPhone,
    String? patientId,
    required String Function() uuidGenerator,
  }) async {
    final effectiveId = (patientId != null && patientId.isNotEmpty)
        ? patientId
        : patientPhone;
    final patient = await clinic.searchPatient(effectiveId);
    if (patient != null) {
      patientName = patient.name;
      allergies = List.from(patient.allergies);
      patientGender = patient.gender;
      patientAge = patient.age;
    }

    pastConsultations = await clinic.getPatientConsultations(
      effectiveId,
      phone: patientPhone,
    );
    if (pastConsultations.isNotEmpty) {
      final latest = pastConsultations.first;
      // Auto-prepopulate ongoing chronic maintenance medications as CONTINUE
      for (final item in latest.activePrescriptions) {
        if (item.isChronic) {
          reconciliationItems.add(
            item.copyWith(
              id: uuidGenerator(),
              action: MedicationAction.continueAction,
              stopReason: null,
            ),
          );
        }
      }

      final seenTestNames = <String>{};
      for (final past in pastConsultations) {
        for (final ordered in past.orderedTests) {
          final clean = ordered.testName.trim().toLowerCase();
          if (clean.isNotEmpty && !seenTestNames.contains(clean)) {
            seenTestNames.add(clean);
            reviewedInvestigations.add(
              DiagnosticInvestigationReview(
                id: uuidGenerator(),
                testName: ordered.testName.trim(),
                resultValue: '',
                performedDate: null,
                notes: null,
              ),
            );
          }
        }
      }
      if (reviewedInvestigations.isNotEmpty) {
        isInvestigationsExpanded = true;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Draft Serialization & Local Storage (Pause & Resume Handshake)
  // ---------------------------------------------------------------------------

  static const String _draftKeyPrefix = 'draft_encounter_';

  Map<String, dynamic> toDraftMap() {
    return {
      'systolicBp': systolicBpController.text,
      'diastolicBp': diastolicBpController.text,
      'pulse': pulseController.text,
      'temp': tempController.text,
      'weight': weightController.text,
      'spo2': spo2Controller.text,
      'clinicalExamination': examController.text,
      'chiefComplaints': List<String>.from(chiefComplaints),
      'provisionalDiagnoses': List<String>.from(provisionalDiagnoses),
      'allergies': List<String>.from(allergies),
      'patientGender': patientGender,
      'patientAge': patientAge,
      'reviewedInvestigations':
          reviewedInvestigations.map((r) => r.toJson()).toList(),
      'reconciliationItems':
          reconciliationItems.map((r) => r.toJson()).toList(),
      'newPrescriptions': newPrescriptions.map((r) => r.toJson()).toList(),
      'orderedTests': orderedTests.map((o) => o.toJson()).toList(),
      'adviceNotes': adviceController.text,
      'nextFollowUpDate': nextFollowUpDate?.toIso8601String(),
      'stagedMedicine': stagedMedicine?.toJson(),
      'stagedUnlistedName': stagedUnlistedName,
      'stagedComposition': stagedComposition,
      'stagedDosage': stagedDosageController.text,
      'stagedDuration': stagedDurationController.text,
      'stagedInstructions': stagedInstructionsController.text,
      'stagedFrequency': stagedFrequency,
      'stagedTiming': stagedTiming,
      'stagedIsChronic': stagedIsChronic,
      'isFindingsExpanded': isFindingsExpanded,
      'isMedicineExpanded': isMedicineExpanded,
      'isInvestigationsExpanded': isInvestigationsExpanded,
    };
  }

  void restoreFromDraftMap(Map<String, dynamic> map) {
    systolicBpController.text = (map['systolicBp'] as String?) ?? '';
    diastolicBpController.text = (map['diastolicBp'] as String?) ?? '';
    pulseController.text = (map['pulse'] as String?) ?? '';
    tempController.text = (map['temp'] as String?) ?? '';
    weightController.text = (map['weight'] as String?) ?? '';
    spo2Controller.text = (map['spo2'] as String?) ?? '';
    examController.text = (map['clinicalExamination'] as String?) ?? '';

    chiefComplaints.clear();
    if (map['chiefComplaints'] is List) {
      chiefComplaints.addAll(
        (map['chiefComplaints'] as List).map((e) => e.toString()),
      );
    }

    provisionalDiagnoses.clear();
    if (map['provisionalDiagnoses'] is List) {
      provisionalDiagnoses.addAll(
        (map['provisionalDiagnoses'] as List).map((e) => e.toString()),
      );
    }

    allergies.clear();
    if (map['allergies'] is List) {
      allergies.addAll((map['allergies'] as List).map((e) => e.toString()));
    }

    if (map['patientGender'] != null) {
      patientGender = map['patientGender'] as String;
    }
    if (map['patientAge'] != null) {
      patientAge = (map['patientAge'] as num).toInt();
    }

    reviewedInvestigations.clear();
    if (map['reviewedInvestigations'] is List) {
      for (final item in map['reviewedInvestigations']) {
        if (item is Map<String, dynamic>) {
          reviewedInvestigations.add(
            DiagnosticInvestigationReview.fromJson(item),
          );
        }
      }
    }

    reconciliationItems.clear();
    if (map['reconciliationItems'] is List) {
      for (final item in map['reconciliationItems']) {
        if (item is Map<String, dynamic>) {
          reconciliationItems.add(PrescriptionItem.fromJson(item));
        }
      }
    }

    newPrescriptions.clear();
    if (map['newPrescriptions'] is List) {
      for (final item in map['newPrescriptions']) {
        if (item is Map<String, dynamic>) {
          newPrescriptions.add(PrescriptionItem.fromJson(item));
        }
      }
    }

    orderedTests.clear();
    if (map['orderedTests'] is List) {
      for (final item in map['orderedTests']) {
        if (item is Map<String, dynamic>) {
          orderedTests.add(OrderedTest.fromJson(item));
        }
      }
    }

    adviceController.text = (map['adviceNotes'] as String?) ?? '';

    if (map['nextFollowUpDate'] != null) {
      nextFollowUpDate = DateTime.tryParse(map['nextFollowUpDate'] as String);
    }

    if (map['stagedMedicine'] is Map<String, dynamic>) {
      stagedMedicine = Medicine.fromJson(
        map['stagedMedicine'] as Map<String, dynamic>,
      );
    }
    stagedUnlistedName = map['stagedUnlistedName'] as String?;
    stagedComposition = map['stagedComposition'] as String?;
    if (map['stagedDosage'] != null) {
      stagedDosageController.text = map['stagedDosage'] as String;
    }
    if (map['stagedDuration'] != null) {
      stagedDurationController.text = map['stagedDuration'] as String;
    }
    if (map['stagedInstructions'] != null) {
      stagedInstructionsController.text = map['stagedInstructions'] as String;
    }
    if (map['stagedFrequency'] != null) {
      stagedFrequency = map['stagedFrequency'] as String;
    }
    if (map['stagedTiming'] != null) {
      stagedTiming = map['stagedTiming'] as String;
    }
    if (map['stagedIsChronic'] != null) {
      stagedIsChronic = map['stagedIsChronic'] as bool;
    }

    if (map['isFindingsExpanded'] != null) {
      isFindingsExpanded = map['isFindingsExpanded'] as bool;
    }
    if (map['isMedicineExpanded'] != null) {
      isMedicineExpanded = map['isMedicineExpanded'] as bool;
    }
    if (map['isInvestigationsExpanded'] != null) {
      isInvestigationsExpanded = map['isInvestigationsExpanded'] as bool;
    }
  }

  static Future<void> saveDraft(
    String appointmentId,
    Map<String, dynamic> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_draftKeyPrefix$appointmentId', jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> loadDraft(String appointmentId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_draftKeyPrefix$appointmentId');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (e) {
      debugPrint('Failed to decode draft for $appointmentId: $e');
    }
    return null;
  }

  static Future<void> clearDraft(String appointmentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_draftKeyPrefix$appointmentId');
  }

  static Future<bool> hasDraft(String appointmentId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('$_draftKeyPrefix$appointmentId');
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
    medSearchFocusNode.dispose();
    stagedDosageController.dispose();
    stagedDurationController.dispose();
    stagedInstructionsController.dispose();
    orderedTestInputController.dispose();
    adviceController.dispose();
  }
}
