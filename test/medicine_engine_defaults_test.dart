import 'package:appointment_app/core/engines/medicine_engine.dart';
import 'package:appointment_app/models/medicine.dart';
import 'package:appointment_app/models/prescription_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MedicineEngine - Clinical Defaults Regimen Tests', () {
    test('Explicit default fields on Medicine take precedence', () {
      final customMed = Medicine(
        id: 'custom_1',
        productName: 'CustomDrug',
        composition: 'CustomMolecule',
        strength: '10mg',
        form: 'Tablet',
        defaultDosage: '2 Tablets',
        defaultFrequency: '1-1-1 (TDS)',
        defaultTiming: 'With Milk',
        defaultDurationDays: 10,
      );

      final defaults = MedicineEngine.getDefaultsForMedicine(customMed);
      expect(defaults.dosage, '2 Tablets');
      expect(defaults.frequency, '1-1-1 (TDS)');
      expect(defaults.timing, 'With Milk');
      expect(defaults.durationDays, 10);
    });

    test('PPIs auto-resolve to Empty Stomach / Fasting and OD', () {
      final panto = Medicine(
        id: 'panto_40',
        productName: 'Pan 40',
        composition: 'Pantoprazole',
        strength: '40 mg',
        form: 'Tablet',
      );

      final defaults = MedicineEngine.getDefaultsForMedicine(panto);
      expect(defaults.dosage, '1 Tablet');
      expect(defaults.frequency, '1-0-0 (OD)');
      expect(defaults.timing, 'Before Food (Empty Stomach)');
      expect(defaults.durationDays, 14);
      expect(defaults.instructions, contains('morning breakfast'));
    });

    test(
      'Antihypertensives auto-resolve to Morning After Food and 30 Days',
      () {
        final telma = Medicine(
          id: 'telma_40',
          productName: 'Telma 40',
          composition: 'Telmisartan',
          strength: '40 mg',
          form: 'Tablet',
        );

        final defaults = MedicineEngine.getDefaultsForMedicine(telma);
        expect(defaults.dosage, '1 Tablet');
        expect(defaults.frequency, '1-0-0 (OD)');
        expect(defaults.timing, 'After Food (Morning)');
        expect(defaults.durationDays, 30);
      },
    );

    test('Statins auto-resolve to Bedtime / HS and After Dinner', () {
      final atorva = Medicine(
        id: 'atorva_10',
        productName: 'Atorva 10',
        composition: 'Atorvastatin',
        strength: '10 mg',
        form: 'Tablet',
      );

      final defaults = MedicineEngine.getDefaultsForMedicine(atorva);
      expect(defaults.frequency, '0-0-1 (HS / Night)');
      expect(defaults.timing, 'After Dinner');
      expect(defaults.durationDays, 30);
    });

    test('Antibiotics auto-resolve to complete course (Azithromycin 3d, others 5d)', () {
      final azithro = Medicine(
        id: 'azithro_500',
        productName: 'Azithral 500',
        composition: 'Azithromycin',
        strength: '500 mg',
        form: 'Tablet',
      );

      final azithroDefaults = MedicineEngine.getDefaultsForMedicine(azithro);
      expect(azithroDefaults.frequency, '1-0-0 (OD)');
      expect(azithroDefaults.durationDays, 3);

      final amox = Medicine(
        id: 'mox_500',
        productName: 'Augmentin 625',
        composition: 'Amoxicillin + Clavulanic Acid',
        strength: '625 mg',
        form: 'Tablet',
      );

      final amoxDefaults = MedicineEngine.getDefaultsForMedicine(amox);
      expect(amoxDefaults.frequency, '1-0-1 (BD)');
      expect(amoxDefaults.durationDays, 5);
      expect(amoxDefaults.instructions, contains('without skipping doses'));
    });

    test('Analgesics auto-resolve to SOS and 3 Days', () {
      final dolo = Medicine(
        id: 'dolo_650',
        productName: 'Dolo 650',
        composition: 'Paracetamol',
        strength: '650 mg',
        form: 'Tablet',
      );

      final defaults = MedicineEngine.getDefaultsForMedicine(dolo);
      expect(defaults.frequency, 'SOS (As Needed)');
      expect(defaults.timing, 'After Food');
      expect(defaults.durationDays, 3);
    });

    test('Form dosages adjust for Syrup, Inhaler, Gel, Drops', () {
      final syrup = Medicine(
        id: 'syrup_1',
        productName: 'Cough Syrup',
        composition: 'Dextromethorphan',
        strength: '10 mg/5ml',
        form: 'Syrup',
      );
      expect(MedicineEngine.getDefaultsForMedicine(syrup).dosage, '5 ml');

      final drops = Medicine(
        id: 'drop_1',
        productName: 'Eye Drop',
        composition: 'Carboxymethylcellulose',
        strength: '0.5%',
        form: 'Eye Drop',
      );
      expect(MedicineEngine.getDefaultsForMedicine(drops).dosage, '2 Drops');

      final gel = Medicine(
        id: 'gel_1',
        productName: 'Pain Gel',
        composition: 'Diclofenac',
        strength: '1%',
        form: 'Ointment',
      );
      expect(
        MedicineEngine.getDefaultsForMedicine(gel).dosage,
        'Apply thin layer',
      );
    });
  });

  group('MedicineEngine - Prescription Segregation Tests', () {
    test(
      'segregatePrescriptions correctly partitions active vs stopped items',
      () {
        final items = [
          PrescriptionItem(
            id: '1',
            action: MedicationAction.start,
            medicineName: 'Med A',
            composition: 'Comp A',
            dosage: '1 Tab',
            frequency: '1-0-1',
            timing: 'After Food',
          ),
          PrescriptionItem(
            id: '2',
            action: MedicationAction.continueAction,
            medicineName: 'Med B',
            composition: 'Comp B',
            dosage: '1 Tab',
            frequency: '1-0-0',
            timing: 'After Food',
          ),
          PrescriptionItem(
            id: '3',
            action: MedicationAction.stop,
            medicineName: 'Med C',
            composition: 'Comp C',
            dosage: '1 Tab',
            frequency: '1-0-0',
            timing: 'After Food',
            stopReason: 'Allergic reaction / Urticaria',
          ),
        ];

        final partition = MedicineEngine.segregatePrescriptions(items);
        expect(partition.activeMeds.length, 2);
        expect(partition.startedMeds.length, 1);
        expect(partition.continuedMeds.length, 1);
        expect(partition.stoppedMeds.length, 1);
        expect(partition.hasActive, isTrue);
        expect(partition.hasStopped, isTrue);
        expect(partition.stoppedMeds.first.stopReason, contains('Allergic'));
      },
    );
  });

  group(
    'MedicineEngine - Catalogue Filter and Unique Molecule Count Tests',
    () {
      final catalog = [
        Medicine(
          id: '1',
          productName: 'Dolo 650',
          composition: 'Paracetamol',
          strength: '650 mg',
          form: 'Tablet',
        ),
        Medicine(
          id: '2',
          productName: 'Calpol 650',
          composition: 'Paracetamol',
          strength: '650 mg',
          form: 'Tablet',
        ),
        Medicine(
          id: '3',
          productName: 'Pan 40',
          composition: 'Pantoprazole',
          strength: '40 mg',
          form: 'Tablet',
        ),
        Medicine(
          id: '4',
          productName: 'Mucolite Syrup',
          composition: 'Ambroxol',
          strength: '30 mg/5ml',
          form: 'Syrup',
        ),
      ];

      test('countUniqueMolecules correctly deduplicates by composition', () {
        expect(
          MedicineEngine.countUniqueMolecules(catalog),
          3,
        ); // Paracetamol, Pantoprazole, Ambroxol
      });

      test('filterAndSortCatalogue filters by text query and dosage form', () {
        final syrupOnly = MedicineEngine.filterAndSortCatalogue(
          catalog: catalog,
          query: '',
          formFilter: 'Syrup',
        );
        expect(syrupOnly.length, 1);
        expect(syrupOnly.first.productName, 'Mucolite Syrup');

        final paracetamolOnly = MedicineEngine.filterAndSortCatalogue(
          catalog: catalog,
          query: 'paracetamol',
        );
        expect(paracetamolOnly.length, 2);
      });
    },
  );
}
