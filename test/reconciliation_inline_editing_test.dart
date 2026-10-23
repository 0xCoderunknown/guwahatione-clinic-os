import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:appointment_app/models/prescription_item.dart';
import 'package:appointment_app/widgets/encounter/rx/reconciliation_item_row.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleItem = PrescriptionItem(
    id: 'rx_1',
    action: MedicationAction.continueAction,
    medicineName: 'Telma 40 tablet',
    composition: 'TELMISARTAN 40MG',
    dosage: '1 Tablet',
    frequency: '1-0-1',
    timing: 'Before Food',
    durationText: 'To Continue',
  );

  group('QOL-14: Reconciled Regimen In-Place Duration Dropdown & Inline Dosage Editing Tests', () {
    testWidgets('ReconciliationItemRow renders duration dropdown and opens menu', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      PrescriptionItem? updatedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReconciliationItemRow(
              item: sampleItem,
              index: 0,
              onContinue: (_) {},
              onStop: (_) {},
              onItemUpdated: (_, item) => updatedItem = item,
            ),
          ),
        ),
      );

      expect(find.text('Telma 40 tablet'), findsOneWidget);
      expect(find.textContaining('TELMISARTAN 40MG'), findsOneWidget);
      expect(find.text('To Continue'), findsOneWidget);

      // Tap the duration dropdown trigger
      await tester.tap(find.text('To Continue'));
      await tester.pumpAndSettle();

      // Check menu items
      expect(find.text('3 Days'), findsOneWidget);
      expect(find.text('5 Days'), findsOneWidget);
      expect(find.text('7 Days'), findsOneWidget);
      expect(find.text('14 Days'), findsOneWidget);
      expect(find.text('1 Month (30 Days)'), findsOneWidget);
      expect(find.text('Custom Days...'), findsOneWidget);
      expect(find.text('STOP (Discontinue)'), findsOneWidget);

      // Select '5 Days'
      await tester.tap(find.text('5 Days'));
      await tester.pumpAndSettle();

      expect(updatedItem, isNotNull);
      expect(updatedItem!.durationDays, 5);
      expect(updatedItem!.durationText, '5 Days');
      expect(updatedItem!.action, MedicationAction.continueAction);
    });

    testWidgets('Duration dropdown selecting STOP marks item discontinued', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      int? stoppedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReconciliationItemRow(
              item: sampleItem,
              index: 2,
              onContinue: (_) {},
              onStop: (idx) => stoppedIndex = idx,
            ),
          ),
        ),
      );

      await tester.tap(find.text('To Continue'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('STOP (Discontinue)'));
      await tester.pumpAndSettle();

      expect(stoppedIndex, 2);
    });

    testWidgets('CustomDurationDialog allows entering custom days', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      PrescriptionItem? updatedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReconciliationItemRow(
              item: sampleItem,
              index: 0,
              onContinue: (_) {},
              onItemUpdated: (_, item) => updatedItem = item,
            ),
          ),
        ),
      );

      await tester.tap(find.text('To Continue'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Custom Days...'));
      await tester.pumpAndSettle();

      expect(find.text('Custom Duration'), findsOneWidget);
      expect(find.text('Enter prescription course duration in days:'), findsOneWidget);

      final textField = find.byType(TextField);
      await tester.enterText(textField, '21');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(updatedItem, isNotNull);
      expect(updatedItem!.durationDays, 21);
      expect(updatedItem!.durationText, '21 Days');
    });

    testWidgets('InlineDosageEditDialog opens from dosage tap and updates regimen', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      PrescriptionItem? updatedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReconciliationItemRow(
              item: sampleItem,
              index: 0,
              onContinue: (_) {},
              onItemUpdated: (_, item) => updatedItem = item,
            ),
          ),
        ),
      );

      // Tap on the dosage/timing segment
      await tester.tap(find.textContaining('1-0-1'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Regimen: Telma 40 tablet'), findsOneWidget);
      expect(find.text('Dosage Quantity'), findsOneWidget);
      expect(find.text('Frequency Schedule'), findsOneWidget);
      expect(find.text('Timing Relation to Food'), findsOneWidget);

      // Select '0.5 Tablet' dosage chip
      await tester.tap(find.text('0.5 Tablet'));
      await tester.pumpAndSettle();

      // Select '1-0-0 (OD)' frequency chip
      await tester.tap(find.text('1-0-0 (OD)'));
      await tester.pumpAndSettle();

      // Select 'After Food (PC)' timing chip
      await tester.tap(find.text('After Food (PC)'));
      await tester.pumpAndSettle();

      // Tap Save Changes
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(updatedItem, isNotNull);
      expect(updatedItem!.dosage, '0.5 Tablet');
      expect(updatedItem!.frequency, '1-0-0 (OD)');
      expect(updatedItem!.timing, 'After Food (PC)');
    });

    testWidgets('NewPrescriptionRow allows inline editing when onItemUpdated is provided', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      PrescriptionItem? updatedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NewPrescriptionRow(
              item: sampleItem,
              index: 0,
              onRemove: (_) {},
              onItemUpdated: (_, item) => updatedItem = item,
            ),
          ),
        ),
      );

      expect(find.text('START'), findsOneWidget);
      await tester.tap(find.textContaining('1-0-1'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Regimen: Telma 40 tablet'), findsOneWidget);

      await tester.tap(find.text('2 Tablets'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(updatedItem, isNotNull);
      expect(updatedItem!.dosage, '2 Tablets');
    });

    testWidgets('ReconciliationItemRow highlights CONTINUE chip only for indefinite continuation', (tester) async {
      final indefiniteItem = sampleItem.copyWith(durationText: 'To Continue');
      final acuteItem = sampleItem.copyWith(durationText: '3 Days', durationDays: 3);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReconciliationItemRow(
              item: indefiniteItem,
              index: 0,
              onContinue: (_) {},
              onStop: (_) {},
            ),
          ),
        ),
      );

      final continueChipFinder = find.widgetWithText(ChoiceChip, 'CONTINUE');
      expect(tester.widget<ChoiceChip>(continueChipFinder).selected, isTrue);

      // Pump acute item
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReconciliationItemRow(
              item: acuteItem,
              index: 0,
              onContinue: (_) {},
              onStop: (_) {},
            ),
          ),
        ),
      );

      expect(tester.widget<ChoiceChip>(continueChipFinder).selected, isFalse);
    });
  });
}

