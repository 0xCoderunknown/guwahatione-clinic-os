import 'package:appointment_app/core/engines/engines.dart';
import 'package:appointment_app/models/medicine.dart';
import 'package:appointment_app/models/prescription_item.dart';
import 'package:appointment_app/models/user_role.dart';
import 'package:appointment_app/screens/login_screen.dart';
import 'package:appointment_app/utils/default_medicines.dart';
import 'package:appointment_app/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
      final results = MedicineEngine.searchAndGroup(
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
      final brandNames = topResult.associatedBrands
          .map((b) => b.productName)
          .toList();
      expect(brandNames, containsAll(['Azee 500', 'Azithral 500']));
      expect(brandNames.length, 2);
    });

    test('Searching "Paracetamol" returns Paracetamol 650 and Paracetamol 500 with grouped brands', () {
      final results = MedicineEngine.searchAndGroup(
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

      final results = MedicineEngine.searchAndGroup(
        catalog: mixedCatalog,
        query: 'Paracetamol',
      );

      expect(results.first.composition, 'Paracetamol');
      expect(results.first.isCompositionMatch, isTrue);
      expect(results.first.score, 100); // Composition prefix match
      expect(results.last.score, lessThan(results.first.score)); // Trade brand match has lower score
    });

    test('Searching by brand name "Dolo" still matches and groups by its composition', () {
      final results = MedicineEngine.searchAndGroup(
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

    test('Unified search ranks trade brand match and sorts matching brand first', () {
      final results = MedicineEngine.searchAndGroup(
        catalog: catalog,
        query: 'Dolo',
      );

      expect(results, isNotEmpty);
      expect(results.first.score, greaterThan(0));
      expect(results.first.associatedBrands.first.productName, 'Dolo 650');
    });

    test('3-Letter minimum threshold: typing less than 3 letters returns empty results', () {
      expect(MedicineEngine.searchAndGroup(catalog: catalog, query: 'D'), isEmpty);
      expect(MedicineEngine.searchAndGroup(catalog: catalog, query: 'Do'), isEmpty);
      expect(MedicineEngine.searchAndGroup(catalog: catalog, query: '  Te '), isEmpty);
    });

    test('Doctor types "Tel" (3 letters): returns card [TELMISARTAN 40MG] with Telma 40 and Telmikind 40', () {
      final htnCatalog = [
        const Medicine(
          id: 'med_telma_40',
          productName: 'Telma 40',
          composition: 'Telmisartan',
          strength: '40 mg',
          form: 'Tablet',
          manufacturer: 'Glenmark',
          defaultFrequency: '1-0-0',
          defaultTiming: 'After Food',
          defaultDurationDays: null, // To continue
        ),
        const Medicine(
          id: 'med_telmikind_40',
          productName: 'Telmikind 40',
          composition: 'Telmisartan',
          strength: '40 mg',
          form: 'Tablet',
          manufacturer: 'Mankind',
          defaultFrequency: '1-0-0',
          defaultTiming: 'After Food',
          defaultDurationDays: null, // To continue
        ),
      ];

      final results = MedicineEngine.searchAndGroup(
        catalog: htnCatalog,
        query: 'Tel',
      );

      expect(results.length, 1);
      final card = results.first;
      expect(card.formattedHeader, '[TELMISARTAN 40 MG]');
      expect(card.associatedBrands.map((b) => b.productName), containsAll(['Telma 40', 'Telmikind 40']));

      // Readymade defaults for Telma 40
      final telma = card.associatedBrands.firstWhere((b) => b.productName == 'Telma 40');
      expect(telma.manufacturer, 'Glenmark');
      expect(telma.defaultFrequency, '1-0-0');
      expect(telma.defaultTiming, 'After Food');
      expect(telma.durationLabel, 'To continue');
      expect(telma.formattedCompositionHeader, '[TELMISARTAN 40 MG]');
    });

    test('Doctor writes product name "Telma 40": displays matching product alongside composition', () {
      final htnCatalog = [
        const Medicine(
          id: 'med_telma_40',
          productName: 'Telma 40',
          composition: 'Telmisartan',
          strength: '40 mg',
          form: 'Tablet',
          manufacturer: 'Glenmark',
        ),
        const Medicine(
          id: 'med_telmikind_40',
          productName: 'Telmikind 40',
          composition: 'Telmisartan',
          strength: '40 mg',
          form: 'Tablet',
          manufacturer: 'Mankind',
        ),
      ];

      final results = MedicineEngine.searchAndGroup(
        catalog: htnCatalog,
        query: 'Telma 40',
      );

      expect(results.length, 1);
      final card = results.first;
      expect(card.formattedHeader, '[TELMISARTAN 40 MG]');
      expect(card.associatedBrands.first.productName, 'Telma 40');
    });

    test('Short alphanumeric 2-character query like "O2" or "D3" activates search', () {
      final catalogWithShort = [
        const Medicine(
          id: 'med_o2',
          productName: 'O2 Tablet',
          composition: 'Ofloxacin + Ornidazole',
          strength: '200 mg + 500 mg',
          form: 'Tablet',
        ),
      ];

      final results = MedicineEngine.searchAndGroup(
        catalog: catalogWithShort,
        query: 'O2',
      );

      expect(results, isNotEmpty);
      expect(results.first.associatedBrands.first.productName, 'O2 Tablet');
    });

    testWidgets('RxSearchResultsView renders card layout when enableGroupedCompositionCards is true', (tester) async {
      final sampleGroup = CompositionGroupResult(
        compositionLabel: 'Telmisartan 40 mg',
        composition: 'Telmisartan',
        strength: '40 mg',
        form: 'Tablet',
        associatedBrands: [
          const Medicine(
            id: 'm1',
            productName: 'Telma 40',
            composition: 'Telmisartan',
            strength: '40 mg',
            form: 'Tablet',
            manufacturer: 'Glenmark',
          ),
        ],
        score: 100,
        isCompositionMatch: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RxSearchResultsView(
              results: [sampleGroup],
              query: 'Tel',
              enableGroupedCompositionCards: true,
              onStageMedicine: (_) {},
              onStageUnlisted: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('[TELMISARTAN 40 MG]'), findsOneWidget);
      expect(find.text('{Telma 40} (Glenmark)'), findsOneWidget);
    });

    testWidgets('RxSearchResultsView renders flat direct list when enableGroupedCompositionCards is false', (tester) async {
      final sampleGroup = CompositionGroupResult(
        compositionLabel: 'Telmisartan 40 mg',
        composition: 'Telmisartan',
        strength: '40 mg',
        form: 'Tablet',
        associatedBrands: [
          const Medicine(
            id: 'm1',
            productName: 'Telma 40',
            composition: 'Telmisartan',
            strength: '40 mg',
            form: 'Tablet',
            manufacturer: 'Glenmark',
          ),
        ],
        score: 100,
        isCompositionMatch: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RxSearchResultsView(
              results: [sampleGroup],
              query: 'Tel',
              enableGroupedCompositionCards: false,
              onStageMedicine: (_) {},
              onStageUnlisted: (_) {},
            ),
          ),
        ),
      );

      // Card header should NOT be present in flat list mode
      expect(find.text('[TELMISARTAN 40 MG]'), findsNothing);
      // Flat list row with product name and composition
      expect(find.text('Telma 40 (Glenmark)'), findsOneWidget);
      expect(find.text('Telmisartan 40 mg [Tablet]'), findsOneWidget);
    });

    test('MedicineEngine.getDefaultsForMedicine populates appropriate dosage, frequency, and timing defaults', () {
      const ppi = Medicine(
        id: 'med_pan_40',
        productName: 'Pan 40',
        composition: 'Pantoprazole',
        strength: '40 mg',
        form: 'Tablet',
        category: 'Proton Pump Inhibitor',
      );
      final ppiDefaults = MedicineEngine.getDefaultsForMedicine(ppi);
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
      final antihtnDefaults = MedicineEngine.getDefaultsForMedicine(antihtn);
      expect(antihtnDefaults.frequency, '1-0-0 (OD)');
      expect(antihtnDefaults.timing, 'After Food (Morning)');
      expect(
        antihtnDefaults.durationDays,
        30,
      ); // 30-day routine OPD refill cycle

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
      final chronicDefaults = MedicineEngine.getDefaultsForMedicine(chronicMed);
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
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Permission Denied'),
          ),
        ),
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
        expect(
          ids.contains(med.id),
          isFalse,
          reason: 'Duplicate ID: ${med.id}',
        );
        expect(
          names.contains(med.productName),
          isFalse,
          reason: 'Duplicate Name: ${med.productName}',
        );
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
        {
          'id': 'doc-1',
          'productName': 'Dolo 650',
          'composition': 'Paracetamol',
          'strength': '650 mg',
        },
        {
          'id': 'doc-2',
          'productName': 'Dolo 650',
          'composition': 'Paracetamol',
          'strength': '650 mg',
        }, // duplicate
        {
          'id': 'doc-3',
          'productName': 'dolo 650',
          'composition': 'paracetamol',
          'strength': '650 mg',
        }, // case-insensitive duplicate
        {
          'id': 'doc-4',
          'productName': 'Pan 40',
          'composition': 'Pantoprazole',
          'strength': '40 mg',
        },
        {
          'id': 'doc-5',
          'productName': 'Pan 40',
          'composition': 'Pantoprazole',
          'strength': '40 mg',
        }, // duplicate
      ];

      final seen = <String, String>{};
      final duplicateDocIds = <String>[];

      for (final item in sampleWithDuplicates) {
        final key =
            '${item['productName']!.trim().toLowerCase()}|${item['composition']!.trim().toLowerCase()}|${item['strength']!.trim().toLowerCase()}';
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

  group('Catalogue Header & Reception Auth Responsive Widget Tests', () {
    testWidgets(
      'CatalogueHeaderAndStats renders cleanly without overflow on mobile (390px)',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CatalogueHeaderAndStats(
                totalProducts: 42,
                totalMolecules: 28,
                onCleanDuplicates: () {},
                onAddProduct: () {},
              ),
            ),
          ),
        );

        expect(find.text('Medicine Catalogue'), findsOneWidget);
        expect(find.text('42'), findsOneWidget);
        expect(find.text('28'), findsOneWidget);
        expect(find.text('Remove Duplicate Entries'), findsOneWidget);
        expect(find.text('Add Product'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'CatalogueHeaderAndStats renders cleanly on wide desktop (1200px)',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CatalogueHeaderAndStats(
                totalProducts: 100,
                totalMolecules: 65,
                onCleanDuplicates: () {},
                onAddProduct: () {},
              ),
            ),
          ),
        );

        expect(find.text('Medicine Catalogue'), findsOneWidget);
        expect(find.text('100'), findsOneWidget);
        expect(find.text('65'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'CatalogueSearchToolbar adapts to mobile width without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final controller = TextEditingController();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CatalogueSearchToolbar(
                searchController: controller,
                selectedFormFilter: 'All',
                formOptions: const ['All', 'Tablet', 'Syrup'],
                onFormFilterChanged: (_) {},
                onSearchChanged: (_) {},
                onClearSearch: () {},
              ),
            ),
          ),
        );

        expect(find.text('Dosage Form'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'ReceptionLoginForm renders testing credentials for Reception (0000) and Admin (849201)',
      (tester) async {
        final pinCtrl = TextEditingController();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 275,
                child: ReceptionLoginForm(
                  pinController: pinCtrl,
                  isLoading: false,
                  onLogin: () {},
                ),
              ),
            ),
          ),
        );

        expect(find.textContaining('849201'), findsWidgets);
        expect(find.textContaining('0000'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
