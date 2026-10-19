import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appointment_app/config/clinic_config.dart';
import 'package:appointment_app/models/models.dart';
import 'package:appointment_app/widgets/print/print_medications_table.dart';

void main() {
  group('PrintMedicationsTable - Strict 3-Column Isolation & Composition Tests', () {
    const telmaItem = PrescriptionItem(
      id: 'item_1',
      action: MedicationAction.continueAction,
      medicineName: 'Telma 40 tablet',
      composition: 'Telmisartan 40mg',
      dosage: '1 tab',
      frequency: 'in morning',
      timing: 'before food',
      durationDays: null,
    );

    const cinodItem = PrescriptionItem(
      id: 'item_2',
      action: MedicationAction.stop,
      medicineName: 'Cinod Beta 25 tablet',
      composition: 'Cilnidipine 10mg + Metoprolol 25mg',
      dosage: '1 tablet',
      frequency: 'in morning',
      timing: 'before food',
      stopReason: 'BP stabilized, switched to monotherapy',
    );

    const acuteItem = PrescriptionItem(
      id: 'item_3',
      action: MedicationAction.start,
      medicineName: 'Azithral 500 tablet',
      composition: 'Azithromycin 500mg',
      dosage: '1 Tablet',
      frequency: '1-0-0 (OD)',
      timing: 'After Food',
      durationDays: 5,
      instructions: 'Take after heavy lunch',
    );

    test('formatMedicineName formats uppercase bracketed composition by default', () {
      final formatted = PrintMedicationsTable.formatMedicineName(telmaItem);
      expect(formatted, equals('Telma 40 tablet [TELMISARTAN 40MG]'));
    });

    test('formatMedicineName suppresses composition when hideComposition is true', () {
      final formatted = PrintMedicationsTable.formatMedicineName(
        telmaItem,
        hideComposition: true,
      );
      expect(formatted, equals('Telma 40 tablet'));
      expect(formatted, isNot(contains('TELMISARTAN')));
    });

    test('formatMedicineName avoids redundant duplication for pure generic', () {
      const genericItem = PrescriptionItem(
        id: 'item_gen',
        action: MedicationAction.start,
        medicineName: 'Paracetamol 650mg',
        composition: 'Paracetamol 650mg',
      );
      final formatted = PrintMedicationsTable.formatMedicineName(genericItem);
      expect(formatted, equals('Paracetamol 650mg'));
    });

    testWidgets(
      'Renders strict 3 columns with Telma 40 to Continue and Cinod Beta to STOP (No [NEW] badge)',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PrintMedicationsTable(
                activeMeds: [telmaItem, acuteItem],
                stoppedMeds: [cinodItem],
              ),
            ),
          ),
        );

        // Header verification (strictly 3 headers)
        expect(find.text('Medicine'), findsOneWidget);
        expect(find.text('Dosage & Timing'), findsOneWidget);
        expect(find.text('Duration'), findsOneWidget);

        // Verification of Column 1: Medicine with uppercase bracketed composition
        expect(
          find.text('1. Telma 40 tablet [TELMISARTAN 40MG]'),
          findsOneWidget,
        );
        expect(
          find.text('2. Azithral 500 tablet [AZITHROMYCIN 500MG]'),
          findsOneWidget,
        );
        expect(
          find.text(
            '3. Cinod Beta 25 tablet [CILNIDIPINE 10MG + METOPROLOL 25MG]',
          ),
          findsOneWidget,
        );

        // Verify [NEW] and [CONT] badges do NOT exist
        expect(find.text('[NEW]'), findsNothing);
        expect(find.text('[CONT]'), findsNothing);

        // Verification of Column 2: Dosage & Timing (No mixing)
        expect(find.text('1 tab • in morning • before food'), findsOneWidget);
        expect(find.text('1 Tablet • 1-0-0 (OD) • After Food'), findsOneWidget);
        expect(find.text('Note: Take after heavy lunch'), findsOneWidget);
        expect(
          find.text('1 tablet • in morning • before food'),
          findsOneWidget,
        );

        // Verification of Column 3: Duration / Action
        expect(find.text('To Continue'), findsOneWidget);
        expect(find.text('5 Days'), findsOneWidget);
        expect(find.text('To STOP'), findsOneWidget);
      },
    );

    testWidgets(
      'Experimental flag hidePrescriptionComposition: true hides composition from table',
      (tester) async {
        const customConfig = ClinicConfig(
          features: ClinicFeatureFlags(
            hidePrescriptionComposition: true,
          ),
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PrintMedicationsTable(
                activeMeds: [telmaItem],
                stoppedMeds: [cinodItem],
                config: customConfig,
              ),
            ),
          ),
        );

        // Should render brand only
        expect(find.text('1. Telma 40 tablet'), findsOneWidget);
        expect(find.text('2. Cinod Beta 25 tablet'), findsOneWidget);
        expect(find.textContaining('TELMISARTAN'), findsNothing);
        expect(find.textContaining('CILNIDIPINE'), findsNothing);

        // Duration remains intact
        expect(find.text('To Continue'), findsOneWidget);
        expect(find.text('To STOP'), findsOneWidget);
      },
    );
  });
}
