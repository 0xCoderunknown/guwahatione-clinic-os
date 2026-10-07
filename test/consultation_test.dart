import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appointment_app/models/patient.dart';
import 'package:appointment_app/models/vitals.dart';
import 'package:appointment_app/models/medicine.dart';
import 'package:appointment_app/models/prescription_item.dart';
import 'package:appointment_app/models/diagnostic_investigation.dart';
import 'package:appointment_app/models/consultation.dart';

void main() {
  group('Patient Model Backward Compatibility Tests', () {
    test('Parses legacy JSON missing gender and allergies gracefully', () {
      final legacyJson = {
        'id': '9876543210',
        'name': 'Legacy Patient',
        'age': 45,
        'lastVisitDate': '2026-10-01T10:00:00.000',
        'phoneNumber': '9876543210',
      };

      final patient = Patient.fromJson(legacyJson);
      expect(patient.gender, 'Unspecified');
      expect(patient.allergies, isEmpty);
      expect(patient.name, 'Legacy Patient');
    });

    test('Serializes and deserializes patient with gender and allergies', () {
      final patient = Patient(
        id: '9876543210',
        name: 'Jane Doe',
        age: 34,
        gender: 'Female',
        allergies: ['Penicillin', 'Sulfa'],
        lastVisitDate: DateTime(2026, 10, 5),
        phoneNumber: '9876543210',
      );

      final json = patient.toJson();
      expect(json['gender'], 'Female');
      expect(json['allergies'], ['Penicillin', 'Sulfa']);

      final fromJson = Patient.fromJson(json);
      expect(fromJson.gender, 'Female');
      expect(fromJson.allergies, ['Penicillin', 'Sulfa']);
    });
  });

  group('Vitals Model Tests', () {
    test('Calculates bpFormatted correctly', () {
      const v1 = Vitals(systolicBp: 120, diastolicBp: 80);
      expect(v1.bpFormatted, '120/80 mmHg');
      expect(v1.hasAny, isTrue);

      const v2 = Vitals(systolicBp: 130);
      expect(v2.bpFormatted, '130 mmHg (Sys)');

      const v3 = Vitals();
      expect(v3.bpFormatted, isNull);
      expect(v3.hasAny, isFalse);
    });

    test('Serializes and deserializes all vital signs', () {
      const vitals = Vitals(
        systolicBp: 130,
        diastolicBp: 85,
        pulseRate: 74,
        temperature: 98.4,
        weightKg: 72.5,
        spO2: 99,
        respiratoryRate: 18,
        bloodSugar: 110.0,
      );

      final json = vitals.toJson();
      final fromJson = Vitals.fromJson(json);

      expect(fromJson.systolicBp, 130);
      expect(fromJson.diastolicBp, 85);
      expect(fromJson.pulseRate, 74);
      expect(fromJson.temperature, 98.4);
      expect(fromJson.weightKg, 72.5);
      expect(fromJson.spO2, 99);
      expect(fromJson.respiratoryRate, 18);
      expect(fromJson.bloodSugar, 110.0);
    });
  });

  group('Medicine Master Catalogue Tests', () {
    test('Decouples product name from chemical composition and strength', () {
      const med = Medicine(
        id: 'med-dolo',
        productName: 'Dolo 650',
        composition: 'Paracetamol',
        strength: '650 mg',
        form: 'Tablet',
        manufacturer: 'Micro Labs',
        category: 'Antipyretic',
      );

      expect(med.fullCompositionLabel, 'Paracetamol 650 mg');
      expect(med.displayName, 'Dolo 650 (Paracetamol 650 mg) [Tablet]');

      final json = med.toJson();
      final fromJson = Medicine.fromJson(json);

      expect(fromJson.id, 'med-dolo');
      expect(fromJson.productName, 'Dolo 650');
      expect(fromJson.composition, 'Paracetamol');
      expect(fromJson.strength, '650 mg');
      expect(fromJson.form, 'Tablet');
      expect(fromJson.manufacturer, 'Micro Labs');
    });
  });

  group('PrescriptionItem Lifecycle State Machine Tests', () {
    test('START: Newly initiated acute medication with duration', () {
      const item = PrescriptionItem(
        id: 'rx-1',
        action: MedicationAction.start,
        medicineId: 'med-aug',
        medicineName: 'Augmentin 625 Duo',
        composition: 'Amoxicillin + Clavulanic Acid 625mg',
        dosage: '1 Tablet',
        frequency: '1-0-1 (BD)',
        timing: 'After Food',
        durationDays: 5,
      );

      expect(item.action, MedicationAction.start);
      expect(item.action.code, 'START');
      expect(item.isChronic, isFalse);
      expect(item.isActive, isTrue);
      expect(item.durationDays, 5);
      expect(item.effectiveName, 'Augmentin 625 Duo');
    });

    test('CONTINUE: Ongoing chronic medication with NULL duration', () {
      const chronicItem = PrescriptionItem(
        id: 'rx-2',
        action: MedicationAction.continueAction,
        medicineId: 'med-met',
        medicineName: 'Glycomet 500',
        composition: 'Metformin 500mg',
        dosage: '1 Tablet',
        frequency: '1-0-0 (OD)',
        timing: 'Before Food',
        durationDays: null, // Chronic medication has NULL duration
      );

      expect(chronicItem.action, MedicationAction.continueAction);
      expect(chronicItem.action.code, 'CONTINUE');
      expect(chronicItem.isChronic, isTrue);
      expect(chronicItem.isActive, isTrue);
      expect(chronicItem.durationDays, isNull);
    });

    test('STOP: Discontinued medication with stop reason', () {
      const stoppedItem = PrescriptionItem(
        id: 'rx-3',
        action: MedicationAction.stop,
        medicineName: 'Amlodipine 5mg',
        composition: 'Amlodipine 5mg',
        stopReason: 'Switched to Telmisartan due to pedal edema',
      );

      expect(stoppedItem.action, MedicationAction.stop);
      expect(stoppedItem.action.code, 'STOP');
      expect(stoppedItem.isActive, isFalse);
      expect(stoppedItem.stopReason, 'Switched to Telmisartan due to pedal edema');
    });

    test('Fallback unlistedName for outside medications', () {
      const outsideDrug = PrescriptionItem(
        id: 'rx-4',
        action: MedicationAction.start,
        medicineName: '',
        composition: 'Atorvastatin 20mg',
        unlistedName: 'Atorva 20 (Local Pharmacy brand)',
        durationDays: null,
      );

      expect(outsideDrug.effectiveName, 'Atorva 20 (Local Pharmacy brand)');
    });

    test('Serializes and deserializes PrescriptionItem accurately', () {
      const original = PrescriptionItem(
        id: 'rx-5',
        action: MedicationAction.continueAction,
        medicineId: 'med-123',
        medicineName: 'Ecosprin 75',
        composition: 'Aspirin 75mg',
        dosage: '1 Tab',
        frequency: '0-0-1',
        timing: 'After Dinner',
        durationDays: null,
        instructions: 'Do not take on empty stomach',
      );

      final json = original.toJson();
      expect(json['action'], 'CONTINUE');
      expect(json['durationDays'], isNull);

      final fromJson = PrescriptionItem.fromJson(json);
      expect(fromJson.action, MedicationAction.continueAction);
      expect(fromJson.medicineName, 'Ecosprin 75');
      expect(fromJson.isChronic, isTrue);
      expect(fromJson.instructions, 'Do not take on empty stomach');
    });
  });

  group('Append-Only Consultation Encounter Tests', () {
    test('Consultation serializes, deserializes, and categorizes active vs stopped prescriptions', () {
      final now = DateTime(2026, 10, 7, 10, 30);
      final labDate = DateTime(2026, 10, 5);
      final followUp = DateTime(2026, 10, 21);

      final consultation = Consultation(
        id: 'c-001',
        appointmentId: 'appt-101',
        patientPhone: '9876543210',
        patientName: 'Ram Das',
        patientAge: 52,
        patientGender: 'Male',
        doctorId: 'doc-1',
        doctorName: 'Dr. Sharma',
        createdAt: now,
        vitals: const Vitals(systolicBp: 130, diastolicBp: 80, pulseRate: 72),
        chiefComplaints: ['Headache for 3 days', 'Routine follow-up'],
        clinicalExamination: 'Chest clear, No peripheral edema',
        provisionalDiagnosis: ['Essential Hypertension (Controlled)', 'Type 2 Diabetes'],
        reviewedInvestigations: [
          DiagnosticInvestigationReview(
            id: 'rev-1',
            testName: 'HbA1c',
            resultValue: '6.7%',
            performedDate: labDate,
            notes: 'Well controlled on current regimen',
          ),
        ],
        prescriptionItems: [
          const PrescriptionItem(
            id: 'rx-c1',
            action: MedicationAction.continueAction,
            medicineName: 'Glycomet 500',
            composition: 'Metformin 500mg',
            durationDays: null, // chronic
          ),
          const PrescriptionItem(
            id: 'rx-c2',
            action: MedicationAction.start,
            medicineName: 'Telma 40',
            composition: 'Telmisartan 40mg',
            durationDays: 30,
          ),
          const PrescriptionItem(
            id: 'rx-c3',
            action: MedicationAction.stop,
            medicineName: 'Amlodipine 5mg',
            composition: 'Amlodipine 5mg',
            stopReason: 'Switched to Telma',
          ),
        ],
        orderedTests: const [
          OrderedTest(
            testName: 'Lipid Profile',
            instructions: '12 hours fasting required',
          ),
        ],
        adviceNotes: 'Low salt diet, brisk walk 30 mins daily',
        nextFollowUpDate: followUp,
      );

      // Verify active vs stopped categorization
      expect(consultation.activePrescriptions.length, 2);
      expect(consultation.continuedPrescriptions.length, 1);
      expect(consultation.startedPrescriptions.length, 1);
      expect(consultation.stoppedPrescriptions.length, 1);
      expect(consultation.stoppedPrescriptions.first.medicineName, 'Amlodipine 5mg');

      // Test JSON round-trip with Firestore Timestamps
      final json = consultation.toJson();
      expect(json['createdAt'], isA<Timestamp>());
      expect(json['nextFollowUpDate'], isA<Timestamp>());

      final fromJson = Consultation.fromJson(json);
      expect(fromJson.id, 'c-001');
      expect(fromJson.patientPhone, '9876543210');
      expect(fromJson.patientGender, 'Male');
      expect(fromJson.vitals?.bpFormatted, '130/80 mmHg');
      expect(fromJson.reviewedInvestigations.first.testName, 'HbA1c');
      expect(fromJson.reviewedInvestigations.first.performedDate, labDate);
      expect(fromJson.orderedTests.first.testName, 'Lipid Profile');
      expect(fromJson.activePrescriptions.length, 2);
      expect(fromJson.nextFollowUpDate, followUp);
    });
  });
}
