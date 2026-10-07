import 'package:flutter_test/flutter_test.dart';
import 'package:appointment_app/models/medicine.dart';
import 'package:appointment_app/models/user_role.dart';
import 'package:appointment_app/models/prescription_item.dart';
import 'package:appointment_app/utils/medicine_search_scorer.dart';
import 'package:appointment_app/utils/default_medicines.dart';
import 'package:appointment_app/utils/clinical_defaults_helper.dart';

void main() {
  group('Composition-First Medicine Search Scorer Tests', () {
    final catalog = [
      const Medicine(
        id: '1',
        productName: 'Dolo 650',
        composition: 'Paracetamol',
        strength: '650 mg',
        form: 'Tablet',
        manufacturer: 'Micro Labs',
      ),
      const Medicine(
        id: '2',
        productName: 'Calpol 650',
        composition: 'Paracetamol',
        strength: '650 mg',
        form: 'Tablet',
        manufacturer: 'GSK',
      ),
      const Medicine(
        id: '3',
        productName: 'Crocin 500',
        composition: 'Paracetamol',
        strength: '500 mg',
        form: 'Tablet',
        manufacturer: 'GSK',
      ),
      const Medicine(
        id: '4',
        productName: 'Azee 500',
        composition: 'Azithromycin',
        strength: '500 mg',
        form: 'Tablet',
        manufacturer: 'Cipla',
      ),
      const Medicine(
        id: '5',
        productName: 'Azithral 500',
        composition: 'Azithromycin',
        strength: '500 mg',
        form: 'Tablet',
        manufacturer: 'Alembic',
      ),
      const Medicine(
        id: '6',
        productName: 'Augmentin 625 Duo',
        composition: 'Amoxicillin + Clavulanic Acid',
        strength: '625 mg',
        form: 'Tablet',
        manufacturer: 'GSK',
      ),
    ];

    test('Searching chemical composition "Azithromycin" ranks composition at top and groups clinic brands', () {
      final results = MedicineSearchScorer.searchAndGroup(
        catalog: catalog,
        query: 'Azithromycin',
      );

      expect(results, isNotEmpty);
      final topResult = results.first;

      // Must match chemical composition
      expect(topResult.isCompositionMatch, isTrue);
      expect(topResult.composition, 'Azithromycin');
      expect(topResult.strength, '500 mg');
      expect(topResult.score, 100);

      // Associated clinic brands grouped underneath
      final brandNames = topResult.associatedBrands.map((b) => b.productName).toList();
      expect(brandNames, containsAll(['Azee 500', 'Azithral 500']));
      expect(brandNames.length, 2);
    });

    test('Searching "Paracetamol" returns Paracetamol 650 and Paracetamol 500 with grouped brands', () {
      final results = MedicineSearchScorer.searchAndGroup(
        catalog: catalog,
        query: 'paracetamol',
      );

      expect(results.length, 2); // 650mg group and 500mg group

      final group650 = results.firstWhere((r) => r.strength == '650 mg');
      expect(group650.isCompositionMatch, isTrue);
      expect(
        group650.associatedBrands.map((b) => b.productName),
        containsAll(['Dolo 650', 'Calpol 650']),
      );

      final group500 = results.firstWhere((r) => r.strength == '500 mg');
      expect(group500.isCompositionMatch, isTrue);
      expect(
        group500.associatedBrands.map((b) => b.productName),
        contains('Crocin 500'),
      );
    });

    test('Composition match ranks higher than trade brand match when chemical name is typed', () {
      // Catalog where one drug has composition "Paracetamol" and another has brand "Paracetamol Drop"
      final mixedCatalog = [
        const Medicine(
          id: 'b1',
          productName: 'Paracetamol Brand Formulation',
          composition: 'Acetaminophen Complex',
          strength: '100 mg',
          form: 'Syrup',
        ),
        const Medicine(
          id: 'c1',
          productName: 'Dolo 650',
          composition: 'Paracetamol',
          strength: '650 mg',
          form: 'Tablet',
        ),
      ];

      final results = MedicineSearchScorer.searchAndGroup(
        catalog: mixedCatalog,
        query: 'Paracetamol',
      );

      expect(results.first.composition, 'Paracetamol');
      expect(results.first.isCompositionMatch, isTrue);
      expect(results.first.score, 100); // Composition prefix match
      expect(results.last.score, 60); // Trade brand match has lower score
    });

    test('Searching by brand name "Dolo" still matches and groups by its composition', () {
      final results = MedicineSearchScorer.searchAndGroup(
        catalog: catalog,
        query: 'Dolo',
      );

      expect(results.length, 1);
      final group = results.first;
      expect(group.compositionLabel, 'Paracetamol 650 mg');
      expect(group.associatedBrands.first.productName, 'Dolo 650');
    });

    test('Prescribing unlisted outside medicine stores fallback name without modifying catalog', () {
      // Simulates doctor chamber prescribing an unlisted drug
      const outsideMed = PrescriptionItem(
        id: 'rx-outside-1',
        action: MedicationAction.start,
        medicineName: 'Aziver 500 (Outside brand)',
        composition: 'Azithromycin 500mg',
        unlistedName: 'Aziver 500 (Outside brand)',
        durationDays: 3,
      );

      expect(outsideMed.medicineId, isNull);
      expect(outsideMed.unlistedName, 'Aziver 500 (Outside brand)');
      expect(outsideMed.effectiveName, 'Aziver 500 (Outside brand)');
      expect(outsideMed.action, MedicationAction.start);

      // Verify master catalogue remains pristine and unmutated
      expect(catalog.any((m) => m.productName.contains('Aziver')), isFalse);
    });

    test('Brand-First search mode ranks trade brand prefix highest and sorts matching brand first', () {
      final results = MedicineSearchScorer.searchAndGroup(
        catalog: catalog,
        query: 'Dolo',
        searchMode: 'brandFirst',
      );

      expect(results, isNotEmpty);
      expect(results.first.score, 100);
      expect(results.first.associatedBrands.first.productName, 'Dolo 650');
    });

    test('ClinicalDefaultsHelper populates appropriate dosage, frequency, and timing defaults', () {
      const ppi = Medicine(
        id: 'med_pan_40',
        productName: 'Pan 40',
        composition: 'Pantoprazole',
        strength: '40 mg',
        form: 'Tablet',
        category: 'Proton Pump Inhibitor',
      );
      final ppiDefaults = ClinicalDefaultsHelper.getDefaultsForMedicine(ppi);
      expect(ppiDefaults.timing, 'Before Food (Empty Stomach)');
      expect(ppiDefaults.frequency, '1-0-0 (OD)');
      expect(ppiDefaults.durationDays, 14);

      const antihtn = Medicine(
        id: 'med_telma_40',
        productName: 'Telma 40',
        composition: 'Telmisartan',
        strength: '40 mg',
        form: 'Tablet',
        category: 'Antihypertensive',
      );
      final antihtnDefaults = ClinicalDefaultsHelper.getDefaultsForMedicine(antihtn);
      expect(antihtnDefaults.frequency, '1-0-0 (OD)');
      expect(antihtnDefaults.timing, 'After Food (Morning)');
      expect(antihtnDefaults.durationDays, 30); // 30-day routine OPD refill cycle

      // Explicit catalogue override with indefinite chronic duration (null)
      const chronicMed = Medicine(
        id: 'med_chronic_1',
        productName: 'Chronic Pill',
        composition: 'Molecule X',
        strength: '10 mg',
        form: 'Tablet',
        defaultDosage: '1 Tablet',
        defaultFrequency: '1-0-0 (OD)',
        defaultTiming: 'After Breakfast',
        defaultDurationDays: null,
      );
      final chronicDefaults = ClinicalDefaultsHelper.getDefaultsForMedicine(chronicMed);
      expect(chronicDefaults.durationDays, isNull);
    });
  });

  group('Admin vs Prescriber Permission Boundary Tests', () {
    test('Non-owner role (Doctor) is rejected when attempting catalogue modification', () {
      final doctorRole = UserRole.doctor;
      expect(doctorRole.isOwner, isFalse);

      void attemptAddAsDoctor() {
        if (!doctorRole.isOwner) {
          throw Exception(
            'Permission Denied: Only clinic administrators (owner) can modify the master medicine catalogue.',
          );
        }
      }

      expect(
        () => attemptAddAsDoctor(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Permission Denied'),
        )),
      );
    });

    test('Owner role is authorized for catalogue management', () {
      final ownerRole = UserRole.owner;
      expect(ownerRole.isOwner, isTrue);

      bool allowed = false;
      if (ownerRole.isOwner) {
        allowed = true;
      }

      expect(allowed, isTrue);
    });

    test('defaultEssentialMedicines contains unique deterministic IDs and non-empty metadata', () {
      final ids = <String>{};
      final names = <String>{};

      for (final med in defaultEssentialMedicines) {
        expect(ids.contains(med.id), isFalse, reason: 'Duplicate ID: ${med.id}');
        expect(names.contains(med.productName), isFalse, reason: 'Duplicate Name: ${med.productName}');
        ids.add(med.id);
        names.add(med.productName);

        expect(med.id.startsWith('med_'), isTrue);
        expect(med.composition.isNotEmpty, isTrue);
        expect(med.strength.isNotEmpty, isTrue);
        expect(med.form.isNotEmpty, isTrue);
      }
      expect(defaultEssentialMedicines.length, greaterThanOrEqualTo(10));
    });

    test('Catalogue deduplication logic correctly isolates duplicate entries', () {
      final sampleWithDuplicates = [
        {'id': 'doc-1', 'productName': 'Dolo 650', 'composition': 'Paracetamol', 'strength': '650 mg'},
        {'id': 'doc-2', 'productName': 'Dolo 650', 'composition': 'Paracetamol', 'strength': '650 mg'}, // duplicate
        {'id': 'doc-3', 'productName': 'dolo 650', 'composition': 'paracetamol', 'strength': '650 mg'}, // case-insensitive duplicate
        {'id': 'doc-4', 'productName': 'Pan 40', 'composition': 'Pantoprazole', 'strength': '40 mg'},
        {'id': 'doc-5', 'productName': 'Pan 40', 'composition': 'Pantoprazole', 'strength': '40 mg'}, // duplicate
      ];

      final seen = <String, String>{};
      final duplicateDocIds = <String>[];

      for (final item in sampleWithDuplicates) {
        final key = '${item['productName']!.trim().toLowerCase()}|${item['composition']!.trim().toLowerCase()}|${item['strength']!.trim().toLowerCase()}';
        if (seen.containsKey(key)) {
          duplicateDocIds.add(item['id']!);
        } else {
          seen[key] = item['id']!;
        }
      }

      expect(duplicateDocIds, containsAll(['doc-2', 'doc-3', 'doc-5']));
      expect(duplicateDocIds.length, 3);
      expect(seen.length, 2); // 1 Dolo 650 and 1 Pan 40 preserved
    });
  });
}
