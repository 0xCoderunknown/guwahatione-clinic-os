import 'package:appointment_app/models/models.dart';
import 'package:appointment_app/screens/add_doctor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddDoctorScreen & DoctorForm Widget Tests', () {
    testWidgets('DoctorForm renders department dropdown and 30-min timing dropdowns',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DoctorForm(
              doctor: null,
              onSaved: _dummyOnSaved,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Doctor Name field exists
      expect(find.text('Doctor Name (e.g., Dr. Sharma)'), findsOneWidget);

      // Check Department / Specialty Dropdown exists with default 'General Medicine / Physician'
      expect(find.text('Department / Specialty'), findsOneWidget);
      expect(find.text('General Medicine / Physician'), findsOneWidget);

      // Check Shift Timing Start and End dropdowns exist
      expect(find.text('Shift Start'), findsOneWidget);
      expect(find.text('Shift End'), findsOneWidget);
      expect(find.text('6:00 PM'), findsOneWidget);
      expect(find.text('8:30 PM'), findsOneWidget);

      // Free Review Window is present
      expect(find.text('Free Review Window (0 to 30 Days)'), findsOneWidget);

      // Available Days chips exist
      expect(find.text('Available Days'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
    });

    testWidgets('DoctorForm shows custom specialty text field when Other is selected',
        (tester) async {
      final customDoctor = Doctor(
        id: 'doc-custom',
        name: 'Dr. John',
        specialty: 'Diabetology & Endocrinology',
        phone: '9876543210',
        availableDays: ['Mon', 'Tue'],
        blockedDates: [],
        shiftTiming: '11:00 AM – 2:30 PM',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorForm(
              doctor: customDoctor,
              onSaved: _dummyOnSaved,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Since 'Diabetology & Endocrinology' is non-standard, it selects 'Other (Custom)...'
      expect(find.text('Other (Custom)...'), findsOneWidget);
      expect(find.text('Specify Custom Specialty'), findsOneWidget);
      expect(find.text('Diabetology & Endocrinology'), findsOneWidget);

      // Shift timings 11:00 AM to 2:30 PM are correctly pre-filled
      expect(find.text('11:00 AM'), findsOneWidget);
      expect(find.text('2:30 PM'), findsOneWidget);
    });

    testWidgets('DoctorForm triggers warning banner for overnight / midnight timing',
        (tester) async {
      final overnightDoctor = Doctor(
        id: 'doc-night',
        name: 'Dr. Night Shift',
        specialty: 'General Medicine / Physician',
        phone: '9876543210',
        availableDays: ['Mon', 'Wed'],
        blockedDates: [],
        shiftTiming: '8:00 PM – 2:00 AM',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorForm(
              doctor: overnightDoctor,
              onSaved: _dummyOnSaved,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should render the amber warning banner for overnight timing
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(
        find.textContaining('Overnight shift'),
        findsOneWidget,
      );
    });
  });
}

void _dummyOnSaved() {}
