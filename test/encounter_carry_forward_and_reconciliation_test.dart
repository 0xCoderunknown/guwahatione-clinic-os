import 'package:appointment_app/core/engines/engines.dart';
import 'package:appointment_app/models/models.dart';
import 'package:appointment_app/widgets/encounter/encounter_form_state.dart';
import 'package:appointment_app/widgets/common/appointment_status_chip.dart';
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

    test('copyVitalsFromConsultation copies vitals into active form controllers', () {
      final form = EncounterFormState();
      final priorConsultation = Consultation(
        id: 'c-prior-vitals',
        appointmentId: 'apt-0',
        patientId: 'pat-0',
        patientPhone: '9864012345',
        patientName: 'Test Patient',
        patientAge: 40,
        patientGender: 'Male',
        doctorId: 'doc-0',
        doctorName: 'Dr. Barua',
        provisionalDiagnosis: const ['Hypertension'],
        createdAt: DateTime(2026, 10, 10),
        vitals: const Vitals(
          systolicBp: 130,
          diastolicBp: 85,
          pulseRate: 78,
          temperature: 98.6,
          weightKg: 68.5,
          spO2: 99,
          bloodSugar: 110.0,
          respiratoryRate: 18,
        ),
      );

      form.copyVitalsFromConsultation(priorConsultation);

      expect(form.systolicBpController.text, '130');
      expect(form.diastolicBpController.text, '85');
      expect(form.pulseController.text, '78');
      expect(form.tempController.text, '98.6');
      expect(form.weightController.text, '68.5');
      expect(form.spo2Controller.text, '99');
    });
  });

  group('Doctor Revenue Share & Fee Payout Tests', () {

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

  group('AppointmentStatusChip & VisitStatus.inConsultation Sync Tests', () {
    test('AppointmentStatusChip renders IN CHAMBER when visitStatus is inConsultation', () {
      const chip = AppointmentStatusChip(
        status: AppointmentStatus.pending,
        visitStatus: VisitStatus.inConsultation,
      );
      expect(chip.visitStatus, VisitStatus.inConsultation);
    });

    test('AppointmentEngine.calculateEstimatedWindow excludes inConsultation patients from patientsAhead', () {
      final apptInChamber = Appointment(
        id: 'apt-1',
        patientPhone: '9864012345',
        patientName: 'In Chamber Patient',
        doctorId: 'doc-1',
        doctorName: 'Dr. Thakuria',
        queueNumber: 1,
        paymentType: PaymentType.paidCash,
        amountCollected: 500,
        scheduledDate: DateTime.now(),
        visitStatus: VisitStatus.inConsultation,
      );

      final apptInLobby = Appointment(
        id: 'apt-2',
        patientPhone: '9864099999',
        patientName: 'Lobby Patient',
        doctorId: 'doc-1',
        doctorName: 'Dr. Thakuria',
        queueNumber: 2,
        paymentType: PaymentType.paidCash,
        amountCollected: 500,
        scheduledDate: DateTime.now(),
        visitStatus: VisitStatus.waitingInLobby,
      );

      final windowForToken2 = AppointmentEngine.calculateEstimatedWindow(
        doctorAppointments: [apptInChamber, apptInLobby],
        targetQueueNumber: 2,
      );

      // Token 2 has 0 waiting ahead in lobby because Token 1 is inside chamber!
      expect(windowForToken2.patientsAhead, 0);
      expect(windowForToken2.relativeSummary, 'Next in line');
    });

    test('lastConsultationWithRx resolves the latest consultation with active medicines', () {
      final form = EncounterFormState();
      final c1 = Consultation(
        id: 'c-old',
        appointmentId: 'a-old',
        patientId: 'pat-1',
        patientPhone: '9864012345',
        patientName: 'Patient 1',
        patientAge: 45,
        patientGender: 'Male',
        doctorId: 'doc-1',
        doctorName: 'Dr. Thakuria',
        createdAt: DateTime(2026, 10, 10),
        prescriptionItems: const [
          PrescriptionItem(
            id: 'rx-old-1',
            action: MedicationAction.start,
            medicineName: 'Telma 40 tablet',
            composition: 'TELMISARTAN 40MG',
            durationText: 'To Continue',
          ),
        ],
      );

      final c2NoRx = Consultation(
        id: 'c-advisory',
        appointmentId: 'a-adv',
        patientId: 'pat-1',
        patientPhone: '9864012345',
        patientName: 'Patient 1',
        patientAge: 45,
        patientGender: 'Male',
        doctorId: 'doc-1',
        doctorName: 'Dr. Thakuria',
        createdAt: DateTime(2026, 10, 15),
        prescriptionItems: const [],
      );

      form.pastConsultations = [c2NoRx, c1];
      expect(form.lastConsultationWithRx, isNotNull);
      expect(form.lastConsultationWithRx!.id, 'c-old');
      expect(form.lastConsultationWithRx!.consultationDate, DateTime(2026, 10, 10));
    });
  });
}
