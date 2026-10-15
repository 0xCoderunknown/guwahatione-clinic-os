import 'package:appointment_app/core/engines/medicine_engine.dart';
import 'package:appointment_app/models/medicine.dart';
import 'package:appointment_app/models/prescription_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MedicineEngine - Clinical Defaults Regimen Tests', () {
    test('Explicit default fields on Medicine take precedence', () {
      const customMed = Medicine(
        id: 'custom_1',
        productName: 'CustomDrug tablet',
        composition: 'CustomMolecule 10mg',
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
      const panto = Medicine(
        id: 'panto_40',
        productName: 'Pan 40 tablet',
        composition: 'Pantoprazole 40mg',
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
        const telma = Medicine(
          id: 'telma_40',
          productName: 'Telma 40 tablet',
          composition: 'Telmisartan 40mg',
        );

        final defaults = MedicineEngine.getDefaultsForMedicine(telma);
        expect(defaults.dosage, '1 Tablet');
        expect(defaults.frequency, '1-0-0 (OD)');
        expect(defaults.timing, 'After Food (Morning)');
        expect(defaults.durationDays, 30);
      },
    );

    test('Statins auto-resolve to Bedtime / HS and After Dinner', () {
      const atorva = Medicine(
        id: 'atorva_10',
        productName: 'Atorva 10 tablet',
        composition: 'Atorvastatin 10mg',
      );

      final defaults = MedicineEngine.getDefaultsForMedicine(atorva);
      expect(defaults.frequency, '0-0-1 (HS / Night)');
      expect(defaults.timing, 'After Dinner');
      expect(defaults.durationDays, 30);
    });

    test('Antibiotics auto-resolve to complete course (Azithromycin 3d, others 5d)', () {
      const azithro = Medicine(
        id: 'azithro_500',
        productName: 'Azithral 500 tablet',
        composition: 'Azithromycin 500mg',
      );

      final azithroDefaults = MedicineEngine.getDefaultsForMedicine(azithro);
      expect(azithroDefaults.frequency, '1-0-0 (OD)');
      expect(azithroDefaults.durationDays, 3);

      const amox = Medicine(
        id: 'mox_500',
        productName: 'Augmentin 625 Duo tablet',
        composition: 'Amoxicillin 500mg + Clavulanic Acid 125mg',
      );

      final amoxDefaults = MedicineEngine.getDefaultsForMedicine(amox);
      expect(amoxDefaults.frequency, '1-0-1 (BD)');
      expect(amoxDefaults.durationDays, 5);
      expect(amoxDefaults.instructions, contains('without skipping doses'));
    });

    test('Analgesics auto-resolve to SOS and 3 Days', () {
      const dolo = Medicine(
        id: 'dolo_650',
        productName: 'Dolo 650 tablet',
        composition: 'Paracetamol 650mg',
      );

      final defaults = MedicineEngine.getDefaultsForMedicine(dolo);
      expect(defaults.frequency, 'SOS (As Needed)');
      expect(defaults.timing, 'After Food');
      expect(defaults.durationDays, 3);
    });

    test('Form dosages adjust for Syrup, Inhaler, Gel, Drops', () {
      const syrup = Medicine(
        id: 'syrup_1',
        productName: 'Cough Syrup',
        composition: 'Dextromethorphan 10mg/5ml',
      );
      expect(MedicineEngine.getDefaultsForMedicine(syrup).dosage, '5 ml');

      const drops = Medicine(
        id: 'drop_1',
        productName: 'Eye Drop',
        composition: 'Carboxymethylcellulose 0.5%',
      );
      expect(MedicineEngine.getDefaultsForMedicine(drops).dosage, '2 Drops');

      const gel = Medicine(
        id: 'gel_1',
        productName: 'Pain Gel',
        composition: 'Diclofenac 1%',
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
          const PrescriptionItem(
            id: '1',
            action: MedicationAction.start,
            medicineName: 'Med A',
            composition: 'Comp A',
            dosage: '1 Tab',
            frequency: '1-0-1',
            timing: 'After Food',
          ),
          const PrescriptionItem(
            id: '2',
            action: MedicationAction.continueAction,
            medicineName: 'Med B',
            composition: 'Comp B',
            dosage: '1 Tab',
            frequency: '1-0-0',
            timing: 'After Food',
          ),
          const PrescriptionItem(
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
      const catalog = [
        Medicine(
          id: '1',
          productName: 'Dolo 650 tablet',
          composition: 'Paracetamol 650mg',
        ),
        Medicine(
          id: '2',
          productName: 'Calpol 650 tablet',
          composition: 'Paracetamol 650mg',
        ),
        Medicine(
          id: '3',
          productName: 'Pan 40 tablet',
          composition: 'Pantoprazole 40mg',
        ),
        Medicine(
          id: '4',
          productName: 'Mucolite Syrup',
          composition: 'Ambroxol 30mg/5ml',
        ),
      ];

      test('countUniqueMolecules correctly deduplicates by composition', () {
        expect(
          MedicineEngine.countUniqueMolecules(catalog),
          3,
        ); // Paracetamol 650mg, Pantoprazole 40mg, Ambroxol 30mg/5ml
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
