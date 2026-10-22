import 'package:appointment_app/models/patient.dart';
import 'package:appointment_app/widgets/booking/booking_patient_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QOL-17: BookingPatientFields Family Member Matching & Banner Tests', () {
    late TextEditingController phoneController;
    late TextEditingController nameController;
    late TextEditingController ageController;
    late TextEditingController guardianNameController;
    late TextEditingController guardianRelationController;
    late FocusNode phoneFocusNode;
    late FocusNode nameFocusNode;
    late FocusNode ageFocusNode;
    late FocusNode genderFocusNode;

    final mockPatient = Patient(
      id: 'pat-1',
      name: 'Shayana Sarma',
      phoneNumber: '9864012345',
      age: 45,
      gender: 'Female',
    );

    setUp(() {
      phoneController = TextEditingController(text: '9864012345');
      nameController = TextEditingController(text: 'Shayana Sarma');
      ageController = TextEditingController(text: '45');
      guardianNameController = TextEditingController();
      guardianRelationController = TextEditingController();
      phoneFocusNode = FocusNode();
      nameFocusNode = FocusNode();
      ageFocusNode = FocusNode();
      genderFocusNode = FocusNode();
    });

    tearDown(() {
      phoneController.dispose();
      nameController.dispose();
      ageController.dispose();
      guardianNameController.dispose();
      guardianRelationController.dispose();
      phoneFocusNode.dispose();
      nameFocusNode.dispose();
      ageFocusNode.dispose();
      genderFocusNode.dispose();
    });

    Widget createWidget({
      required List<Patient> familyMembers,
      required String? selectedPatientId,
      required ValueChanged<Patient?> onSelectPatient,
      String? primaryContactName,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: BookingPatientFields(
              phoneController: phoneController,
              nameController: nameController,
              ageController: ageController,
              selectedGender: 'Female',
              onGenderChanged: (_) {},
              onPhoneChanged: (_) {},
              isLoading: false,
              phoneFocusNode: phoneFocusNode,
              nameFocusNode: nameFocusNode,
              ageFocusNode: ageFocusNode,
              genderFocusNode: genderFocusNode,
              familyMembers: familyMembers,
              selectedPatientId: selectedPatientId,
              primaryContactName: primaryContactName,
              onSelectPatient: onSelectPatient,
              onAgeUnitChanged: (_) {},
              guardianNameController: guardianNameController,
              guardianRelationController: guardianRelationController,
            ),
          ),
        ),
      );
    }

    testWidgets('Renders compact green confirmation strip when existing patient is selected', (tester) async {
      await tester.pumpWidget(
        createWidget(
          familyMembers: [mockPatient],
          selectedPatientId: 'pat-1',
          onSelectPatient: (_) {},
        ),
      );

      // Verify Registered Patient strip
      expect(
        find.text('Registered: Shayana Sarma (45 Years) • Auto-filled'),
        findsOneWidget,
      );
      expect(find.textContaining('New Member for'), findsNothing);

      // Verify quick add member button in phone row
      expect(find.byIcon(Icons.person_add_alt_1_rounded), findsOneWidget);
    });

    testWidgets('Renders compact blue New Member banner when adding family member', (tester) async {
      await tester.pumpWidget(
        createWidget(
          familyMembers: [mockPatient],
          selectedPatientId: null, // Adding family member
          onSelectPatient: (_) {},
          primaryContactName: 'Shayana Sarma',
        ),
      );

      // Verify New Member strip
      expect(find.text('New Member for Shayana Sarma'), findsOneWidget);
      expect(find.textContaining('Registered:'), findsNothing);

      // Verify + Add Member ChoiceChip is selected
      final addMemberChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, '+ Add Member'),
      );
      expect(addMemberChip.selected, isTrue);
    });

    testWidgets('Clicking quick add button in phone row calls onSelectPatient(null)', (tester) async {
      Patient? selected;
      bool called = false;

      await tester.pumpWidget(
        createWidget(
          familyMembers: [mockPatient],
          selectedPatientId: 'pat-1',
          onSelectPatient: (p) {
            called = true;
            selected = p;
          },
        ),
      );

      await tester.tap(find.byIcon(Icons.person_add_alt_1_rounded));
      await tester.pump();

      expect(called, isTrue);
      expect(selected, isNull);
    });

    testWidgets('Clicking + Add Member chip calls onSelectPatient(null)', (tester) async {
      Patient? selected;
      bool called = false;

      await tester.pumpWidget(
        createWidget(
          familyMembers: [mockPatient],
          selectedPatientId: 'pat-1',
          onSelectPatient: (p) {
            called = true;
            selected = p;
          },
        ),
      );

      await tester.tap(find.widgetWithText(ChoiceChip, '+ Add Member'));
      await tester.pump();

      expect(called, isTrue);
      expect(selected, isNull);
    });
  });
}
