import 'package:appointment_app/config/clinic_config.dart';
import 'package:appointment_app/core/engines/medicine_engine.dart';
import 'package:appointment_app/models/prescription_item.dart';
import 'package:appointment_app/models/prescription_template.dart';
import 'package:appointment_app/widgets/encounter/encounter_form_state.dart';
import 'package:appointment_app/widgets/encounter/rx/rx_template_presets_bar.dart';
import 'package:appointment_app/widgets/encounter/rx_reconciliation_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PrescriptionTemplate Domain & MedicineEngine Tests', () {
    test(
      'Default templates list is populated with standard clinical presets',
      () {
        final templates = MedicineEngine.getDefaultPrescriptionTemplates();
        expect(templates.isNotEmpty, isTrue);
        expect(templates.length, greaterThanOrEqualTo(5));

        final uri = templates.firstWhere((t) => t.id == 'tmpl_uri_flu');
        expect(uri.name, 'URI / Pharyngitis');
        expect(uri.emoji, '🤧');
        expect(uri.items.length, greaterThanOrEqualTo(3));
        expect(uri.items.any((i) => i.medicineName.contains('Dolo')), isTrue);
        expect(
          uri.items.any((i) => i.medicineName.contains('Levocet')),
          isTrue,
        );

        final gastritis = templates.firstWhere(
          (t) => t.id == 'tmpl_acute_gastritis',
        );
        expect(gastritis.name, 'Acute Gastritis');
        expect(gastritis.emoji, '🔥');
        expect(
          gastritis.items.any((i) => i.medicineName.contains('Pan 40')),
          isTrue,
        );
      },
    );

    test(
      'toPrescriptionItem maps fields cleanly and marks action as start',
      () {
        const item = PrescriptionTemplateItem(
          medicineName: 'Azithral 500',
          composition: 'Azithromycin 500mg',
          dosage: '1 Tablet',
          frequency: '1-0-0 (OD)',
          timing: 'After Food',
          durationDays: 3,
          instructions: 'Take at the same hour daily',
        );

        final rx = item.toPrescriptionItem(id: 'rx_test_1');
        expect(rx.id, 'rx_test_1');
        expect(rx.action, MedicationAction.start);
        expect(rx.medicineName, 'Azithral 500');
        expect(rx.composition, 'Azithromycin 500mg');
        expect(rx.dosage, '1 Tablet');
        expect(rx.frequency, '1-0-0 (OD)');
        expect(rx.timing, 'After Food');
        expect(rx.durationDays, 3);
        expect(rx.instructions, 'Take at the same hour daily');
      },
    );

    test('evaluateTemplateApplication adds all items when encounter has no active meds', () {
      final templates = MedicineEngine.getDefaultPrescriptionTemplates();
      final uri = templates.firstWhere((t) => t.id == 'tmpl_uri_flu');

      var counter = 0;
      final result = MedicineEngine.evaluateTemplateApplication(
        template: uri,
        existingItems: const [],
        uuidGenerator: () => 'uuid_${++counter}',
      );

      expect(result.templateName, uri.name);
      expect(result.hasAdded, isTrue);
      expect(result.hasSkipped, isFalse);
      expect(result.addedItems.length, uri.items.length);
      expect(result.skippedDuplicates.isEmpty, isTrue);
      expect(result.addedItems.first.id, 'uuid_1');
    });

    test('evaluateTemplateApplication skips exact brand duplicate', () {
      final templates = MedicineEngine.getDefaultPrescriptionTemplates();
      final fever = templates.firstWhere((t) => t.id == 'tmpl_fever_viral');

      // Existing prescription already has Dolo 650
      final existing = [
        const PrescriptionItem(
          id: 'existing_dolo',
          action: MedicationAction.continueAction,
          medicineName: 'Dolo 650',
          composition: 'Paracetamol 650mg',
          dosage: '1 Tablet',
          frequency: '1-0-1 (BD)',
          timing: 'After Food',
        ),
      ];

      var counter = 0;
      final result = MedicineEngine.evaluateTemplateApplication(
        template: fever,
        existingItems: existing,
        uuidGenerator: () => 'uuid_${++counter}',
      );

      expect(result.hasSkipped, isTrue);
      expect(result.skippedDuplicates.length, 1);
      expect(result.skippedDuplicates.first.medicineName, 'Dolo 650');
      // Added other items from fever template (Pan 40, Limcee 500)
      expect(result.addedItems.length, fever.items.length - 1);
      expect(
        result.addedItems.any((i) => i.medicineName == 'Dolo 650'),
        isFalse,
      );
      expect(result.addedItems.any((i) => i.medicineName == 'Pan 40'), isTrue);
    });

    test(
      'evaluateTemplateApplication skips duplicate by composition match',
      () {
        final templates = MedicineEngine.getDefaultPrescriptionTemplates();
        final uri = templates.firstWhere((t) => t.id == 'tmpl_uri_flu');

        // Patient is taking generic Paracetamol 650mg under a different brand name (Calpol 650)
        final existing = [
          const PrescriptionItem(
            id: 'existing_calpol',
            action: MedicationAction.start,
            medicineName: 'Calpol 650',
            composition: 'Paracetamol 650mg',
            dosage: '1 Tablet',
            frequency: '1-0-1 (BD)',
            timing: 'After Food',
          ),
        ];

        var counter = 0;
        final result = MedicineEngine.evaluateTemplateApplication(
          template: uri,
          existingItems: existing,
          uuidGenerator: () => 'uuid_${++counter}',
        );

        expect(result.hasSkipped, isTrue);
        // Dolo 650 in URI template should be skipped because composition 'Paracetamol 650mg' is matched
        expect(
          result.skippedDuplicates.any(
            (d) => d.composition.contains('Paracetamol 650mg'),
          ),
          isTrue,
        );
        expect(
          result.addedItems.any((i) => i.medicineName == 'Dolo 650'),
          isFalse,
        );
      },
    );

    test('evaluateTemplateApplication does not treat STOPPED medication as duplicate', () {
      final templates = MedicineEngine.getDefaultPrescriptionTemplates();
      final uri = templates.firstWhere((t) => t.id == 'tmpl_uri_flu');

      // Patient was previously on Dolo 650, but doctor explicitly STOPPED it
      final existing = [
        const PrescriptionItem(
          id: 'stopped_dolo',
          action: MedicationAction.stop,
          medicineName: 'Dolo 650',
          composition: 'Paracetamol 650mg',
          dosage: '1 Tablet',
          frequency: '1-0-1 (BD)',
          timing: 'After Food',
          stopReason: 'Finished course',
        ),
      ];

      var counter = 0;
      final result = MedicineEngine.evaluateTemplateApplication(
        template: uri,
        existingItems: existing,
        uuidGenerator: () => 'uuid_${++counter}',
      );

      // Stopped medication does not block template prescribing
      expect(result.hasSkipped, isFalse);
      expect(
        result.addedItems.any((i) => i.medicineName == 'Dolo 650'),
        isTrue,
      );
    });
  });

  group('EncounterFormState Template Integration', () {
    test('applyPrescriptionTemplate appends to newPrescriptions correctly', () {
      final form = EncounterFormState();
      final templates = MedicineEngine.getDefaultPrescriptionTemplates();
      final gastritis = templates.firstWhere(
        (t) => t.id == 'tmpl_acute_gastritis',
      );

      var counter = 0;
      final result = form.applyPrescriptionTemplate(
        template: gastritis,
        uuidGenerator: () => 'test_id_${++counter}',
      );

      expect(result.addedItems.length, gastritis.items.length);
      expect(form.newPrescriptions.length, gastritis.items.length);
      expect(form.allPrescriptionItems.length, gastritis.items.length);

      // Applying again should skip all as duplicates
      final secondResult = form.applyPrescriptionTemplate(
        template: gastritis,
        uuidGenerator: () => 'test_id_${++counter}',
      );

      expect(secondResult.hasAdded, isFalse);
      expect(secondResult.hasSkipped, isTrue);
      expect(secondResult.skippedDuplicates.length, gastritis.items.length);
      expect(
        form.newPrescriptions.length,
        gastritis.items.length,
      ); // Unchanged count

      form.dispose();
    });
  });

  group('RxTemplatePresetsBar Widget Tests', () {
    testWidgets(
      'renders all template preset chips and triggers addition on tap',
      (tester) async {
        final form = EncounterFormState();
        var idCounter = 0;
        var updated = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RxTemplatePresetsBar(
                form: form,
                uuidGenerator: () => 'chip_id_${++idCounter}',
                onUpdate: () {
                  updated = true;
                },
              ),
            ),
          ),
        );

        expect(find.text('Common prescription templates'), findsOneWidget);
        expect(find.text('URI / Pharyngitis'), findsOneWidget);
        expect(find.text('Viral Fever / SOS'), findsOneWidget);

        // Tap on URI / Pharyngitis
        await tester.tap(find.text('URI / Pharyngitis'));
        await tester.pump();

        expect(updated, isTrue);
        expect(form.newPrescriptions.isNotEmpty, isTrue);
        expect(
          form.newPrescriptions.any((i) => i.medicineName.contains('Dolo')),
          isTrue,
        );

        // Check SnackBar feedback
        expect(
          find.textContaining('Applied "URI / Pharyngitis"'),
          findsOneWidget,
        );

        form.dispose();
      },
    );
  });

  group('ClinicConfig Experimental Feature Flag Tests', () {
    testWidgets(
      'RxReconciliationSection hides RxTemplatePresetsBar when enablePrescriptionTemplatePresets is false',
      (tester) async {
        final form = EncounterFormState();
        form.isMedicineExpanded = true;
        const config = ClinicConfig(
          features: ClinicFeatureFlags(enablePrescriptionTemplatePresets: false),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: RxReconciliationSection(
                  form: form,
                  catalog: const [],
                  uuidGenerator: () => 'uid_1',
                  onPromptStopReason: (item, index) {},
                  onUpdate: () {},
                  config: config,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(RxTemplatePresetsBar), findsNothing);
        expect(find.text('Common prescription templates'), findsNothing);
        form.dispose();
      },
    );

    testWidgets(
      'RxReconciliationSection displays RxTemplatePresetsBar when enablePrescriptionTemplatePresets is true',
      (tester) async {
        final form = EncounterFormState();
        form.isMedicineExpanded = true;
        const config = ClinicConfig(
          features: ClinicFeatureFlags(enablePrescriptionTemplatePresets: true),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: RxReconciliationSection(
                  form: form,
                  catalog: const [],
                  uuidGenerator: () => 'uid_1',
                  onPromptStopReason: (item, index) {},
                  onUpdate: () {},
                  config: config,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(RxTemplatePresetsBar), findsOneWidget);
        expect(find.text('Common prescription templates'), findsOneWidget);
        form.dispose();
      },
    );
  });
}
