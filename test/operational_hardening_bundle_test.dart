import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appointment_app/models/appointment.dart';
import 'package:appointment_app/models/consultation.dart';
import 'package:appointment_app/providers/delegates/live_queue_delegate.dart';
import 'package:appointment_app/screens/prescription_print_screen.dart';
import 'package:appointment_app/utils/app_constants.dart';
import 'package:appointment_app/widgets/encounter/advice_and_orders_section.dart';
import 'package:appointment_app/widgets/encounter/encounter_form_state.dart';
import 'package:appointment_app/widgets/encounter/vitals_and_exam_section.dart';

void main() {
  group('Operational Hardening Bundle Tests (AUDIT-15, AUDIT-21, AUDIT-24)', () {
    test('AUDIT-21: AppConstants defines clinical input limits', () {
      expect(AppConstants.maxComplaintLength, equals(150));
      expect(AppConstants.maxDiagnosisLength, equals(200));
      expect(AppConstants.maxExamNotesLength, equals(2000));
      expect(AppConstants.maxAdviceNotesLength, equals(2000));
      expect(AppConstants.maxAllergyLength, equals(100));
      expect(AppConstants.maxLabOrderLength, equals(150));
      expect(AppConstants.maxLabResultLength, equals(200));
    });

    test('AUDIT-15: LiveQueueDelegate dispose cleans up timers without throwing', () {
      final delegate = LiveQueueDelegate(
        enableMidnightObserver: false,
        notifyListeners: () {},
      );

      // Verify dispose cancels any pending debounce or observer timer cleanly
      expect(() => delegate.dispose(), returnsNormally);
    });

    testWidgets('AUDIT-24: PrescriptionPrintScreen prevents rapid double-print triggering', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final dummyConsultation = Consultation(
        id: 'c_test_print',
        appointmentId: 'apt_test_print',
        patientId: 'p_1',
        patientName: 'Test Patient',
        patientPhone: '9876543210',
        patientAge: 35,
        patientAgeDisplay: '35 yrs',
        patientGender: 'M',
        doctorId: 'd_1',
        doctorName: 'Dr. Test',
        createdAt: DateTime.now(),
        chiefComplaints: const ['Fever'],
        prescriptionItems: const [],
      );

      final dummyAppointment = Appointment(
        id: 'apt_test_print',
        patientId: 'p_1',
        patientName: 'Test Patient',
        patientPhone: '9876543210',
        doctorId: 'd_1',
        doctorName: 'Dr. Test',
        scheduledDate: DateTime.now(),
        queueNumber: 1,
        status: AppointmentStatus.completed,
        paymentType: PaymentType.paidCash,
        amountCollected: 500,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PrescriptionPrintScreen(
            consultation: dummyConsultation,
            appointment: dummyAppointment,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the print button
      final printButton = find.widgetWithText(FilledButton, 'Print Prescription');
      expect(printButton, findsOneWidget);

      // Tap print button once
      await tester.tap(printButton);
      await tester.pump();

      // Button should now transition to "Printing..." with disabled state
      expect(find.text('Printing...'), findsOneWidget);
      final disabledButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Printing...'),
      );
      expect(disabledButton.onPressed, isNull);

      // Advance past the 1500ms debounce cooldown
      await tester.pump(const Duration(milliseconds: 1600));

      // Should recover back to "Print Prescription"
      expect(find.widgetWithText(FilledButton, 'Print Prescription'), findsOneWidget);
    });

    testWidgets('AUDIT-21: VitalsAndExamSection enforces input limits on complaints & exam notes', (
      tester,
    ) async {
      final form = EncounterFormState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VitalsAndExamSection(
                form: form,
                onUpdate: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Test complaint input length limit (150 chars)
      final complaintField = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.hintText?.contains('Fever x 3 days') == true,
      );
      expect(complaintField, findsOneWidget);

      final longComplaint = 'A' * 200;
      await tester.enterText(complaintField, longComplaint);
      await tester.pump();

      // Text should be capped at AppConstants.maxComplaintLength (150)
      expect(form.complaintInputController.text.length, equals(AppConstants.maxComplaintLength));

      // Test clinical examination character counter
      final examField = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.hintText?.contains('Chest clear') == true,
      );
      expect(examField, findsOneWidget);

      final longExam = 'B' * 50;
      await tester.enterText(examField, longExam);
      await tester.pump();

      expect(find.text('50 / 2000'), findsOneWidget);
    });

    testWidgets('AUDIT-21: AdviceAndOrdersSection enforces input limits on ordered tests & advice', (
      tester,
    ) async {
      final form = EncounterFormState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdviceAndOrdersSection.fromForm(
                form: form,
                onUpdate: () {},
                onPickCustomDate: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Test ordered test input length limit (150 chars)
      final testOrderField = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.hintText?.contains('Fasting Blood Sugar') == true,
      );
      expect(testOrderField, findsOneWidget);

      final longTestName = 'T' * 200;
      await tester.enterText(testOrderField, longTestName);
      await tester.pump();

      // Text should be capped at AppConstants.maxLabOrderLength (150)
      expect(form.orderedTestInputController.text.length, equals(AppConstants.maxLabOrderLength));

      // Test advice notes length counter
      final adviceField = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.hintText?.contains('Low salt diet') == true,
      );
      expect(adviceField, findsOneWidget);

      final longAdvice = 'C' * 75;
      await tester.enterText(adviceField, longAdvice);
      await tester.pump();

      expect(find.text('75 / 2000'), findsOneWidget);
    });
  });
}
