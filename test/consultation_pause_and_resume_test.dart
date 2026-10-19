import 'package:appointment_app/models/models.dart';
import 'package:appointment_app/widgets/encounter/encounter_form_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Appointment isPaused Serialization & Audit Tests', () {
    test('Default appointment has isPaused false', () {
      final appt = Appointment(
        id: 'appt_101',
        patientPhone: '9876543210',
        patientName: 'Bipul Sarma',
        paymentType: PaymentType.paidCash,
        amountCollected: 500,
        queueNumber: 1,
        scheduledDate: DateTime(2026, 10, 19),
        doctorId: 'doc_1',
        doctorName: 'Dr. A. Sharma',
      );

      expect(appt.isPaused, isFalse);
      expect(appt.toJson().containsKey('isPaused'), isFalse);
    });

    test('Appointment serializes and deserializes isPaused: true', () {
      final appt = Appointment(
        id: 'appt_102',
        patientPhone: '9876543210',
        patientName: 'Bipul Sarma',
        visitStatus: VisitStatus.waitingInLobby,
        paymentType: PaymentType.paidCash,
        amountCollected: 500,
        queueNumber: 2,
        scheduledDate: DateTime(2026, 10, 19),
        doctorId: 'doc_1',
        doctorName: 'Dr. A. Sharma',
        isPaused: true,
      );

      expect(appt.isPaused, isTrue);
      final json = appt.toJson();
      expect(json['isPaused'], isTrue);

      final restored = Appointment.fromJson(json);
      expect(restored.isPaused, isTrue);
      expect(restored.visitStatus, VisitStatus.waitingInLobby);

      final unpaused = restored.copyWith(isPaused: false);
      expect(unpaused.isPaused, isFalse);
    });
  });

  group('EncounterFormState Draft Serialization & Local Storage Tests', () {
    test('Serializes full clinical draft map accurately', () {
      final form = EncounterFormState();

      // Vitals & Examination
      form.systolicBpController.text = '130';
      form.diastolicBpController.text = '85';
      form.pulseController.text = '76';
      form.tempController.text = '98.6';
      form.weightController.text = '70.5';
      form.spo2Controller.text = '99';
      form.examController.text = 'Chest clear, S1 S2 heard';

      form.complaintInputController.text = 'Chest heaviness on exertion';
      form.addChiefComplaint();
      form.diagnosisInputController.text = 'Stable Angina / HTN';
      form.addProvisionalDiagnosis();
      form.addAllergy('Penicillin');

      form.reconciliationItems.add(
        const PrescriptionItem(
          id: 'rx_prior_1',
          action: MedicationAction.continueAction,
          medicineName: 'Telma 40',
          composition: 'Telmisartan 40mg',
          dosage: '1 Tablet',
          frequency: '1-0-0 (OD)',
          timing: 'Before Food',
        ),
      );

      form.newPrescriptions.add(
        const PrescriptionItem(
          id: 'rx_new_1',
          action: MedicationAction.start,
          medicineName: 'Monotrate 20',
          composition: 'Isosorbide Mononitrate 20mg',
          dosage: '1 Tablet',
          frequency: '1-0-1 (BD)',
          timing: 'After Food',
          durationDays: 14,
        ),
      );

      form.orderedTestInputController.text = 'Lipid Profile & ECG';
      form.addOrderedTest();
      form.adviceController.text = 'Low salt diet, avoid strenuous exertion';
      form.nextFollowUpDate = DateTime(2026, 11, 2);

      final draftMap = form.toDraftMap();

      expect(draftMap['systolicBp'], '130');
      expect(draftMap['diastolicBp'], '85');
      expect(draftMap['pulse'], '76');
      expect(draftMap['temp'], '98.6');
      expect(draftMap['weight'], '70.5');
      expect(draftMap['spo2'], '99');
      expect(draftMap['clinicalExamination'], 'Chest clear, S1 S2 heard');
      expect(draftMap['chiefComplaints'], ['Chest heaviness on exertion']);
      expect(draftMap['provisionalDiagnoses'], ['Stable Angina / HTN']);
      expect(draftMap['allergies'], ['Penicillin']);
      expect(draftMap['adviceNotes'], 'Low salt diet, avoid strenuous exertion');
      expect(draftMap['nextFollowUpDate'], isNotNull);

      final List recList = draftMap['reconciliationItems'] as List;
      expect(recList.length, 1);
      expect(recList.first['medicineName'], 'Telma 40');

      final List newList = draftMap['newPrescriptions'] as List;
      expect(newList.length, 1);
      expect(newList.first['medicineName'], 'Monotrate 20');

      final List testList = draftMap['orderedTests'] as List;
      expect(testList.length, 1);
      expect(testList.first['testName'], 'Lipid Profile & ECG');

      form.dispose();
    });

    test('Restores form state cleanly from draft map (zero data loss)', () {
      final source = EncounterFormState();
      source.systolicBpController.text = '140';
      source.diastolicBpController.text = '90';
      source.pulseController.text = '82';
      source.examController.text = 'Bilateral wheeze';
      source.complaintInputController.text = 'Dry cough x 3 weeks';
      source.addChiefComplaint();
      source.diagnosisInputController.text = 'Cough Variant Asthma';
      source.addProvisionalDiagnosis();
      source.adviceController.text = 'Steam inhalation BD';
      source.newPrescriptions.add(
        const PrescriptionItem(
          id: 'rx_test',
          action: MedicationAction.start,
          medicineName: 'Asthalin 100mcg Inhaler',
          composition: 'Salbutamol 100mcg',
          dosage: '2 Puffs',
          frequency: 'SOS',
          timing: 'As Needed',
        ),
      );

      final draft = source.toDraftMap();
      source.dispose();

      // Simulate doctor re-opening chamber encounter 1 hour later
      final target = EncounterFormState();
      target.restoreFromDraftMap(draft);

      expect(target.systolicBpController.text, '140');
      expect(target.diastolicBpController.text, '90');
      expect(target.pulseController.text, '82');
      expect(target.examController.text, 'Bilateral wheeze');
      expect(target.chiefComplaints, ['Dry cough x 3 weeks']);
      expect(target.provisionalDiagnoses, ['Cough Variant Asthma']);
      expect(target.adviceController.text, 'Steam inhalation BD');
      expect(target.newPrescriptions.length, 1);
      expect(target.newPrescriptions.first.medicineName, 'Asthalin 100mcg Inhaler');
      expect(target.newPrescriptions.first.dosage, '2 Puffs');

      target.dispose();
    });

    test('SharedPreferences persistence lifecycle (save -> load -> clear)', () async {
      const apptId = 'appt_pause_test_999';
      expect(await EncounterFormState.hasDraft(apptId), isFalse);
      expect(await EncounterFormState.loadDraft(apptId), isNull);

      final dummyDraft = {
        'systolicBp': '124',
        'diastolicBp': '78',
        'chiefComplaints': ['Mild headache'],
      };

      await EncounterFormState.saveDraft(apptId, dummyDraft);
      expect(await EncounterFormState.hasDraft(apptId), isTrue);

      final loaded = await EncounterFormState.loadDraft(apptId);
      expect(loaded, isNotNull);
      expect(loaded!['systolicBp'], '124');
      expect(loaded['chiefComplaints'], ['Mild headache']);

      await EncounterFormState.clearDraft(apptId);
      expect(await EncounterFormState.hasDraft(apptId), isFalse);
      expect(await EncounterFormState.loadDraft(apptId), isNull);
    });
  });
}
