import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:appointment_app/models/models.dart';
import 'package:appointment_app/widgets/encounter/encounter_dialogs.dart';
import 'package:appointment_app/widgets/encounter/encounter_form_state.dart';
import 'package:appointment_app/widgets/encounter/patient_header_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QOL-04: Edit Patient Demographics from Chamber Encounter Tests', () {
    test('EncounterFormState.updatePatientDemographics updates fields without clearing staged Rx', () {
      final form = EncounterFormState();
      form.stagedDosageController.text = '2 Tablets';
      form.reconciliationItems.add(
        const PrescriptionItem(
          id: 'item-1',
          action: MedicationAction.continueAction,
          medicineName: 'Telma 40',
          composition: 'TELMISARTAN 40MG',
          dosage: '1 tab',
          frequency: '1-0-0',
          timing: 'Before Food',
          durationText: '30 days',
        ),
      );

      expect(form.patientName, '');
      expect(form.patientAge, 0);

      form.updatePatientDemographics(
        name: 'Rahul Borah',
        age: 38,
        gender: 'Male',
      );

      expect(form.patientName, 'Rahul Borah');
      expect(form.patientAge, 38);
      expect(form.patientGender, 'Male');

      // Staged state and reconciliation regimen are completely preserved
      expect(form.stagedDosageController.text, '2 Tablets');
      expect(form.reconciliationItems.length, 1);
    });

    testWidgets('PatientHeaderSection renders edit icon and invokes onEditDemographics', (tester) async {
      bool editTapped = false;

      final appt = Appointment(
        id: 'appt-1',
        patientId: 'pat-1',
        patientName: 'Rahul Borah',
        patientPhone: '9864012345',
        scheduledDate: DateTime(2026, 10, 22),
        doctorId: 'doc-1',
        doctorName: 'Dr. Baruah',
        queueNumber: 1,
        paymentType: PaymentType.paidCash,
        amountCollected: 500,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PatientHeaderSection(
              patientName: appt.patientName,
              patientAge: 35,
              patientGender: 'Male',
              patientPhone: appt.patientPhone,
              allergies: const ['Penicillin'],
              onAddAllergy: () {},
              onRemoveAllergy: (_) {},
              onPriorMedsPressed: () {},
              onEditDemographics: () {
                editTapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Rahul Borah'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(editTapped, isTrue);
    });

    testWidgets('EncounterDialogs.showEditPatientDemographicsDialog edits and submits values', (tester) async {
      String savedName = '';
      int savedAge = 0;
      String savedGender = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => EncounterDialogs.showEditPatientDemographicsDialog(
                  context: context,
                  initialName: 'Rohit Das',
                  initialAge: 29,
                  initialGender: 'Male',
                  onSave: ({required name, required age, required gender}) async {
                    savedName = name;
                    savedAge = age;
                    savedGender = gender;
                  },
                ),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Patient Details'), findsOneWidget);
      expect(find.text('Rohit Das'), findsOneWidget);
      expect(find.text('29'), findsOneWidget);

      // Edit name and age
      await tester.enterText(find.widgetWithText(TextField, 'Patient Full Name'), 'Rohit Kumar Das');
      await tester.enterText(find.widgetWithText(TextField, 'Age (Years)'), '30');

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(savedName, 'Rohit Kumar Das');
      expect(savedAge, 30);
      expect(savedGender, 'Male');
    });
  });
}
