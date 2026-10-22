import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appointment_app/models/consultation.dart';
import 'package:appointment_app/screens/consultation_encounter_screen.dart';
import 'package:appointment_app/widgets/patient/doctor_consultation_accordion.dart';

void main() {
  group('QOL-15: ConsultationBottomDock Print Preview Tests', () {
    testWidgets('Renders Print Preview button and triggers callback on desktop',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool previewClicked = false;
      bool completeClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: ConsultationBottomDock(
              isSaving: false,
              onCompleteAndSign: () => completeClicked = true,
              onPause: () {},
              onPreview: () => previewClicked = true,
            ),
          ),
        ),
      );

      // Verify Print Preview button exists
      expect(find.text('Print Preview'), findsOneWidget);
      expect(find.text('Finish Consultation & Sign'), findsOneWidget);

      await tester.tap(find.text('Print Preview'));
      await tester.pump();
      expect(previewClicked, isTrue);

      await tester.tap(find.text('Finish Consultation & Sign'));
      await tester.pump();
      expect(completeClicked, isTrue);
    });

    testWidgets('Renders Print Preview icon button on mobile viewport',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool previewClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: ConsultationBottomDock(
              isSaving: false,
              onCompleteAndSign: () {},
              onPause: () {},
              onPreview: () => previewClicked = true,
            ),
          ),
        ),
      );

      // Mobile renders an IconButton with print_outlined and tooltip
      final previewIcon = find.byTooltip('Print Preview');
      expect(previewIcon, findsOneWidget);

      await tester.tap(previewIcon);
      await tester.pump();
      expect(previewClicked, isTrue);
    });
  });

  group('QOL-18: DoctorConsultationAccordion WhatsApp Rx Tests', () {
    testWidgets('Renders WhatsApp Rx button alongside View Prescription',
        (tester) async {
      final consultation = Consultation(
        id: 'c1',
        patientId: 'p1',
        patientName: 'Rahul Das',
        patientAge: 32,
        patientGender: 'Male',
        patientPhone: '9864012345',
        doctorId: 'd1',
        doctorName: 'Dr. Bikash Sharma',
        doctorRegNumber: 'AMC-12345',
        appointmentId: 'a1',
        createdAt: DateTime(2026, 10, 22),
        vitals: null,
        prescriptionItems: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DoctorConsultationAccordion(
                latestConsultation: consultation,
                totalVisitsWithDoctor: 1,
                patientAllergies: const ['None'],
              ),
            ),
          ),
        ),
      );

      // Expand the accordion
      await tester.tap(find.text('Dr. Bikash Sharma'));
      await tester.pumpAndSettle();

      // Check for both buttons
      expect(find.text('WhatsApp Rx'), findsOneWidget);
      expect(find.text('View Prescription'), findsOneWidget);

      // Tap WhatsApp Rx button
      await tester.tap(find.text('WhatsApp Rx'));
      await tester.pump(); // SnackBar displays
      expect(find.textContaining('Opening WhatsApp for Rahul Das...'), findsOneWidget);
    });
  });
}
