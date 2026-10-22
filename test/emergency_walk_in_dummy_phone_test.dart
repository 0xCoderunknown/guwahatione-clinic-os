import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:appointment_app/core/engines/appointment_engine.dart';
import 'package:appointment_app/widgets/booking/booking_patient_fields.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QOL-01: Emergency / No-Mobile Walk-In Dummy Phone Tests', () {
    test('generateEmergencyDummyPhone produces valid 10-digit string starting with 99', () {
      final t1 = DateTime(2026, 10, 22, 10, 30, 0);
      final phone1 = AppointmentEngine.generateEmergencyDummyPhone(timestamp: t1);

      expect(phone1.length, 10);
      expect(phone1.startsWith('99'), isTrue);
      expect(int.tryParse(phone1), isNotNull);

      // Verify different timestamps produce distinct dummy keys
      final t2 = DateTime(2026, 10, 22, 10, 31, 0);
      final phone2 = AppointmentEngine.generateEmergencyDummyPhone(timestamp: t2);
      expect(phone2.length, 10);
      expect(phone1, isNot(equals(phone2)));
    });

    test('isEmergencyDummyPhone correctly identifies 99-prefixed internal dummy numbers', () {
      expect(AppointmentEngine.isEmergencyDummyPhone('9912345678'), isTrue);
      expect(AppointmentEngine.isEmergencyDummyPhone('9900000001'), isTrue);

      // Regular Indian mobile numbers
      expect(AppointmentEngine.isEmergencyDummyPhone('9864012345'), isFalse);
      expect(AppointmentEngine.isEmergencyDummyPhone('7002012345'), isFalse);
      expect(AppointmentEngine.isEmergencyDummyPhone('8638012345'), isFalse);
      expect(AppointmentEngine.isEmergencyDummyPhone('99123'), isFalse); // Short
    });

    testWidgets('BookingPatientFields renders No Phone button and triggers callback', (tester) async {
      final phoneController = TextEditingController();
      final nameController = TextEditingController();
      final ageController = TextEditingController();
      final guardianNameController = TextEditingController();
      final guardianRelationController = TextEditingController();

      bool emergencyTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BookingPatientFields(
                phoneController: phoneController,
                nameController: nameController,
                ageController: ageController,
                selectedGender: null,
                onGenderChanged: (_) {},
                onPhoneChanged: (_) {},
                isLoading: false,
                phoneFocusNode: FocusNode(),
                nameFocusNode: FocusNode(),
                ageFocusNode: FocusNode(),
                genderFocusNode: FocusNode(),
                onSelectPatient: (_) {},
                onAgeUnitChanged: (_) {},
                guardianNameController: guardianNameController,
                guardianRelationController: guardianRelationController,
                onGenerateEmergencyPhone: () {
                  emergencyTriggered = true;
                  phoneController.text = '9912345678';
                },
              ),
            ),
          ),
        ),
      );

      // Verify the 'No Phone' button exists in suffix
      expect(find.text('No Phone'), findsOneWidget);
      expect(find.byIcon(Icons.bolt), findsOneWidget);

      // Tap 'No Phone'
      await tester.tap(find.text('No Phone'));
      await tester.pumpAndSettle();

      expect(emergencyTriggered, isTrue);
      expect(phoneController.text, '9912345678');

      // Re-pump to see emergency alert banner
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BookingPatientFields(
                phoneController: phoneController,
                nameController: nameController,
                ageController: ageController,
                selectedGender: null,
                onGenderChanged: (_) {},
                onPhoneChanged: (_) {},
                isLoading: false,
                phoneFocusNode: FocusNode(),
                nameFocusNode: FocusNode(),
                ageFocusNode: FocusNode(),
                genderFocusNode: FocusNode(),
                onSelectPatient: (_) {},
                onAgeUnitChanged: (_) {},
                guardianNameController: guardianNameController,
                guardianRelationController: guardianRelationController,
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('No-Mobile / Emergency Walk-In Key: 9912345678'), findsOneWidget);
    });
  });
}
