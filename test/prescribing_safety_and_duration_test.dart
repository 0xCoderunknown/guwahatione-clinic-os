import 'package:flutter_test/flutter_test.dart';
import 'package:appointment_app/core/engines/engines.dart';
import 'package:appointment_app/models/models.dart';
import 'package:appointment_app/widgets/encounter/encounter_form_state.dart';

void main() {
  group('Finding #16 — Flexible Duration Parsing & Sanity Engine Tests', () {
    test('parses acute numeric days (1-300) correctly', () {
      final p5 = MedicineEngine.parseDuration('5');
      expect(p5.isValid, isTrue);
      expect(p5.durationDays, equals(5));
      expect(p5.durationText, equals('5 Days'));

      final p14 = MedicineEngine.parseDuration('14 days');
      expect(p14.isValid, isTrue);
      expect(p14.durationDays, equals(14));
      expect(p14.durationText, equals('14 Days'));

      final p21d = MedicineEngine.parseDuration('21d');
      expect(p21d.isValid, isTrue);
      expect(p21d.durationDays, equals(21));
      expect(p21d.durationText, equals('21 Days'));

      final p300 = MedicineEngine.parseDuration('300');
      expect(p300.isValid, isTrue);
      expect(p300.durationDays, equals(300));
      expect(p300.durationText, equals('300 Days'));
    });

    test('parses SOS (as needed) duration variations correctly', () {
      for (final input in ['sos', 'SoS', 'SOS', 's.o.s', 's.o.s.', 'as needed', 'sos (when required)']) {
        final parsed = MedicineEngine.parseDuration(input);
        expect(parsed.isValid, isTrue, reason: 'Failed for $input');
        expect(parsed.durationDays, isNull);
        expect(parsed.durationText, equals('SOS'));
      }
    });

    test('parses Continue / Chronic / Ongoing variations correctly', () {
      for (final input in [
        'cont',
        'continue',
        'to continue',
        'Cont',
        'chronic',
        'ongoing',
        'To continue (Chronic)',
        '',
        '   ',
        null,
      ]) {
        final parsed = MedicineEngine.parseDuration(input);
        expect(parsed.isValid, isTrue, reason: 'Failed for $input');
        expect(parsed.durationDays, isNull);
        expect(parsed.durationText, equals('To Continue'));
      }
    });

    test('rejects negative, zero, or >300 duration values', () {
      final pZero = MedicineEngine.parseDuration('0');
      expect(pZero.isValid, isFalse);
      expect(pZero.errorMessage, contains('greater than 0'));

      final pNeg = MedicineEngine.parseDuration('-5');
      expect(pNeg.isValid, isFalse);
      expect(pNeg.errorMessage, contains('greater than 0'));

      final pTooLarge = MedicineEngine.parseDuration('301');
      expect(pTooLarge.isValid, isFalse);
      expect(pTooLarge.errorMessage, contains('cannot exceed 300 days'));

      final pMalformed = MedicineEngine.parseDuration('abcxyz');
      expect(pMalformed.isValid, isFalse);
      expect(pMalformed.errorMessage, contains("Enter days (1-300), 'cont' (continue), or 'SOS'"));
    });
  });

  group('PrescriptionItem — Strict 3-Column effectiveDuration Isolation Tests', () {
    test('renders To STOP when action == MedicationAction.stop', () {
      const item = PrescriptionItem(
        id: 'stop_1',
        action: MedicationAction.stop,
        medicineName: 'Amlodipine 5mg',
        composition: 'Amlodipine 5mg',
        dosage: '1 tab',
        durationDays: 30,
        stopReason: 'Switched therapy',
      );
      expect(item.effectiveDuration, equals('To STOP'));
    });

    test('renders SOS when durationText is SOS regardless of days', () {
      const item = PrescriptionItem(
        id: 'sos_1',
        action: MedicationAction.start,
        medicineName: 'Paracetamol 650',
        composition: 'Paracetamol 650mg',
        dosage: '1 tab',
        durationText: 'SOS',
      );
      expect(item.effectiveDuration, equals('SOS'));
      expect(item.isChronic, isFalse);
    });

    test('renders X Days for positive acute durations', () {
      const item = PrescriptionItem(
        id: 'acute_1',
        action: MedicationAction.start,
        medicineName: 'Azithromycin 500',
        composition: 'Azithromycin 500mg',
        dosage: '1 tab',
        durationDays: 5,
        durationText: '5 Days',
      );
      expect(item.effectiveDuration, equals('5 Days'));
      expect(item.isChronic, isFalse);
    });

    test('renders To Continue for chronic / continue regimens', () {
      const item = PrescriptionItem(
        id: 'chronic_1',
        action: MedicationAction.continueAction,
        medicineName: 'Telma 40 tablet',
        composition: 'Telmisartan 40mg',
        dosage: '1 tab',
        durationDays: null,
      );
      expect(item.effectiveDuration, equals('To Continue'));
      expect(item.isChronic, isTrue);
    });
  });

  group('Packaged Catalogue Defaults & Bundle Integrity Tests', () {
    test('Telma 40 bundled package defaults load intact into staging', () {
      const telmaMed = Medicine(
        id: 'med_telma40',
        productName: 'Telma 40 tablet',
        composition: 'Telmisartan 40mg',
        manufacturer: 'Glenmark',
        defaultDosage: '1 tab morning',
        defaultFrequency: '1-0-0 (OD)',
        defaultTiming: 'Before Food',
        defaultDuration: 'To continue',
      );

      final form = EncounterFormState();
      form.stageMedicine(telmaMed);

      expect(form.stagedMedicine, equals(telmaMed));
      expect(form.hasStagedMedicine, isTrue);
      expect(form.stagedMedicineDisplayName, equals('Telma 40 tablet'));
      expect(form.stagedDosageController.text, equals('1 tab morning'));
      expect(form.stagedFrequency, equals('1-0-0 (OD)'));
      expect(form.stagedTiming, equals('Before Food'));
      expect(form.stagedDurationController.text, equals('To Continue'));
      expect(form.stagedIsChronic, isTrue);

      final added = form.confirmAddStagedMedicine(() => 'item_101');
      expect(added, isTrue);
      expect(form.newPrescriptions.length, equals(1));
      final item = form.newPrescriptions.first;
      expect(item.medicineName, equals('Telma 40 tablet'));
      expect(item.dosage, equals('1 tab morning'));
      expect(item.frequency, equals('1-0-0 (OD)'));
      expect(item.timing, equals('Before Food'));
      expect(item.effectiveDuration, equals('To Continue'));
      expect(form.hasStagedMedicine, isFalse);
    });

    test('Acute packaged defaults (Azithral 500) load 5 days into staging', () {
      const azithroMed = Medicine(
        id: 'med_azithro',
        productName: 'Azithral 500 tablet',
        composition: 'Azithromycin 500mg',
        defaultDosage: '1 Tablet',
        defaultFrequency: '1-0-0 (OD)',
        defaultTiming: 'After Food',
        defaultDurationDays: 5,
      );

      final form = EncounterFormState();
      form.stageMedicine(azithroMed);

      expect(form.stagedDurationController.text, equals('5 Days'));
      expect(form.stagedIsChronic, isFalse);

      final added = form.confirmAddStagedMedicine(() => 'item_102');
      expect(added, isTrue);
      expect(form.newPrescriptions.first.effectiveDuration, equals('5 Days'));
      expect(form.newPrescriptions.first.durationDays, equals(5));
    });

    test('SOS packaged defaults load SOS into staging', () {
      const sosMed = Medicine(
        id: 'med_pcm',
        productName: 'Dolo 650 tablet',
        composition: 'Paracetamol 650mg',
        defaultDosage: '1 Tablet',
        defaultFrequency: 'SOS (As Needed)',
        defaultTiming: 'After Food',
        defaultDuration: 'SOS',
      );

      final form = EncounterFormState();
      form.stageMedicine(sosMed);

      expect(form.stagedDurationController.text, equals('SOS'));
      expect(form.stagedFrequency, equals('SOS (As Needed)'));

      final added = form.confirmAddStagedMedicine(() => 'item_103');
      expect(added, isTrue);
      expect(form.newPrescriptions.first.effectiveDuration, equals('SOS'));
    });
  });

  group('Finding #15 — Staged Medicine Discard Guard State Tests', () {
    test('correctly detects when a medicine is actively staged vs cleared', () {
      final form = EncounterFormState();
      expect(form.hasStagedMedicine, isFalse);
      expect(form.stagedMedicineDisplayName, isEmpty);

      form.stageUnlisted('Custom Unlisted Syrup');
      expect(form.hasStagedMedicine, isTrue);
      expect(form.stagedMedicineDisplayName, equals('Custom Unlisted Syrup'));

      form.cancelStaging();
      expect(form.hasStagedMedicine, isFalse);
      expect(form.stagedMedicineDisplayName, isEmpty);
    });

    test('confirmAddStagedMedicine blocks corrupted negative durations', () {
      final form = EncounterFormState();
      form.stageUnlisted('Bad Duration Med');
      form.stagedDurationController.text = '-5';

      final added = form.confirmAddStagedMedicine(() => 'item_err');
      expect(added, isFalse);
      expect(form.newPrescriptions, isEmpty);
      expect(form.hasStagedMedicine, isTrue); // Remains staged for correction
    });
  });

  group('Finding #17 — Longitudinal Diagnostic Test Deduplication Tests', () {
    test('deduplicates repeat test orders across historical consultations', () {
      final form = EncounterFormState();

      // Create fake consultations with duplicate orders for CBC and LFT
      final consult1 = Consultation(
        id: 'c1',
        appointmentId: 'a1',
        patientId: 'p1',
        patientPhone: '9876543210',
        patientName: 'John Doe',
        patientAge: 40,
        patientGender: 'Male',
        doctorId: 'd1',
        doctorName: 'Dr. Barua',
        doctorRegNumber: '12345',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        orderedTests: const [
          OrderedTest(testName: 'CBC'),
          OrderedTest(testName: 'Serum Creatinine'),
        ],
      );

      final consult2 = Consultation(
        id: 'c2',
        appointmentId: 'a2',
        patientId: 'p1',
        patientPhone: '9876543210',
        patientName: 'John Doe',
        patientAge: 40,
        patientGender: 'Male',
        doctorId: 'd1',
        doctorName: 'Dr. Barua',
        doctorRegNumber: '12345',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        orderedTests: const [
          OrderedTest(testName: 'cbc'), // duplicate lowercase
          OrderedTest(testName: 'LFT'),
          OrderedTest(testName: 'Serum Creatinine'), // duplicate
        ],
      );

      final seenTestNames = <String>{};
      int idCounter = 1;
      for (final past in [consult1, consult2]) {
        for (final ordered in past.orderedTests) {
          final clean = ordered.testName.trim().toLowerCase();
          if (clean.isNotEmpty && !seenTestNames.contains(clean)) {
            seenTestNames.add(clean);
            form.reviewedInvestigations.add(
              DiagnosticInvestigationReview(
                id: 'rev_${idCounter++}',
                testName: ordered.testName.trim(),
                resultValue: '',
                performedDate: null,
                notes: null,
              ),
            );
          }
        }
      }

      expect(form.reviewedInvestigations.length, equals(3));
      final names = form.reviewedInvestigations.map((r) => r.testName).toList();
      expect(names, equals(['CBC', 'Serum Creatinine', 'LFT']));
    });
  });
}
