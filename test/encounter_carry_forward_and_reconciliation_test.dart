import 'package:appointment_app/core/engines/engines.dart';
import 'package:appointment_app/models/models.dart';
import 'package:appointment_app/widgets/encounter/encounter_form_state.dart';
import 'package:appointment_app/config/clinic_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrescriptionItem.formattedDosageTiming Tests', () {
    test('Synthesizes discrete dosage, frequency, and timing cleanly with bullet separators', () {
      const item = PrescriptionItem(
        id: 'p1',
        action: MedicationAction.start,
        medicineName: 'Telma 40 tablet',
        composition: 'TELMISARTAN 40MG',
        dosage: '1 Tablet',
        frequency: '1-0-1',
        timing: 'After Food (PC)',
      );

      expect(item.formattedDosageTiming, '1 Tablet • 1-0-1 • After Food (PC)');
    });

    test('Prevents clumsy repetition when dosage already contains natural timing phrase', () {
      const item = PrescriptionItem(
        id: 'p2',
        action: MedicationAction.continueAction,
        medicineName: 'Telma 40 tablet',
        composition: 'TELMISARTAN 40MG',
        dosage: '1 tablet daily morning before food',
        frequency: 'Morning',
        timing: 'Before Food',
      );

      // Does not repeat 'Morning' or 'Before Food' because dosage string already contains them
      expect(item.formattedDosageTiming, '1 tablet daily morning before food');
    });

    test('Falls back to safe default if dosage is blank', () {
      const item = PrescriptionItem(
        id: 'p3',
        action: MedicationAction.start,
        medicineName: 'Paracetamol',
        composition: 'Paracetamol',
        dosage: '',
        frequency: '1-0-1',
        timing: 'After Food',
      );

      expect(item.formattedDosageTiming, '1-0-1 • After Food');
    });
  });

  group('EncounterFormState 1-Click Carry Forward Tests', () {
    test('Clones active medications from prior consultation into reconciliationItems as CONTINUE', () {
      final form = EncounterFormState();

      final priorConsultation = Consultation(
        id: 'c-prior-1',
        appointmentId: 'a-prior-1',
        patientId: 'pat-1',
        patientPhone: '9864012345',
        patientName: 'Ratul Sharma',
        patientAge: 45,
        patientGender: 'Male',
        doctorId: 'doc-original',
        doctorName: 'Dr. Original',
        createdAt: DateTime(2026, 10, 1),
        prescriptionItems: [
          const PrescriptionItem(
            id: 'rx-1',
            action: MedicationAction.start,
            medicineName: 'Telma 40 tablet',
            composition: 'TELMISARTAN 40MG',
            dosage: '1 Tablet',
            frequency: '1-0-0',
            timing: 'Before Food (Khali Pet)',
            durationText: 'To Continue',
          ),
          const PrescriptionItem(
            id: 'rx-2',
            action: MedicationAction.continueAction,
            medicineName: 'Met Small 500mg',
            composition: 'METFORMIN 500MG',
            dosage: '1 Tablet',
            frequency: '1-0-1',
            timing: 'After Food (PC)',
            durationText: 'To Continue',
          ),
          const PrescriptionItem(
            id: 'rx-stopped',
            action: MedicationAction.stop,
            medicineName: 'Old Antacid',
            composition: 'PANTOPRAZOLE',
            dosage: '1 Tab',
            frequency: '1-0-0',
            timing: 'Before Food',
            stopReason: 'Condition Resolved',
          ),
        ],
      );

      int uuidCounter = 100;
      final addedCount = form.carryForwardFromConsultation(
        consultation: priorConsultation,
        uuidGenerator: () => 'uuid-${uuidCounter++}',
      );

      // Only active prescriptions (2 of 3) are cloned; stopped drugs are ignored
      expect(addedCount, 2);
      expect(form.reconciliationItems.length, 2);

      // Verified cloned attributes: new IDs, action is continueAction, stopReason is cleared
      final clonedTelma = form.reconciliationItems.first;
      expect(clonedTelma.id, 'uuid-100');
      expect(clonedTelma.action, MedicationAction.continueAction);
      expect(clonedTelma.effectiveName, 'Telma 40 tablet');
      expect(clonedTelma.stopReason, isNull);

      final clonedMet = form.reconciliationItems[1];
      expect(clonedMet.id, 'uuid-101');
      expect(clonedMet.action, MedicationAction.continueAction);

      // Idempotency check: Carrying forward again does not introduce duplicate items
      final secondPass = form.carryForwardFromConsultation(
        consultation: priorConsultation,
        uuidGenerator: () => 'uuid-${uuidCounter++}',
      );
      expect(secondPass, 0);
      expect(form.reconciliationItems.length, 2);
    });
  });

  group('Doctor Revenue Share & Fee Payout Tests', () {
    test('RevenueEngine calculates doctor payout based on percentage split', () {
      expect(
        RevenueEngine.calculateDoctorPayout(
          totalDoctorFees: 10000,
          doctorSharePercentage: 100,
        ),
        10000,
      );

      expect(
        RevenueEngine.calculateDoctorPayout(
          totalDoctorFees: 10000,
          doctorSharePercentage: 70,
        ),
        7000,
      );

      expect(
        RevenueEngine.calculateDoctorPayout(
          totalDoctorFees: 10000,
          doctorSharePercentage: 0,
        ),
        0,
      );

      expect(
        RevenueEngine.calculateDoctorPayout(
          totalDoctorFees: 750,
          doctorSharePercentage: 60,
        ),
        450,
      );
    });

    test('Doctor model serializes doctorSharePercentage with default 100', () {
      final doc = Doctor(
        id: 'doc-share',
        name: 'Dr. Split',
        specialty: 'Cardiology',
        phone: '9864012345',
        availableDays: ['Mon', 'Wed'],
        blockedDates: [],
        doctorSharePercentage: 80,
      );

      final json = doc.toJson();
      expect(json['doctorSharePercentage'], 80);

      final fromJson = Doctor.fromJson(json);
      expect(fromJson.doctorSharePercentage, 80);

      // Default fallback when omitted in legacy JSON
      final legacyJson = Map<String, dynamic>.from(json)
        ..remove('doctorSharePercentage');
      final legacyDoc = Doctor.fromJson(legacyJson);
      expect(legacyDoc.doctorSharePercentage, 100);
    });
  });

  group('ClinicConfig Letterhead Top Margin Tests', () {
    test('defaultLetterheadTopMarginMm defaults to 35.0 mm', () {
      const config = ClinicConfig();
      expect(config.defaultLetterheadTopMarginMm, 35.0);
    });
  });
}
