import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appointment_app/models/appointment.dart';
import 'package:appointment_app/widgets/chamber/chamber_archive_banner.dart';
import 'package:appointment_app/widgets/chamber/chamber_token_card.dart';

void main() {
  group('ChamberArchiveBanner Widget Tests', () {
    testWidgets('Renders closed shift title and Indian formatted date',
        (tester) async {
      final pastDate = DateTime(2026, 10, 10);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChamberArchiveBanner(date: pastDate),
          ),
        ),
      );

      expect(
        find.text('🔒 Chamber Shift Closed • Read-Only Archive'),
        findsOneWidget,
      );
      expect(
        find.textContaining('10-10-2026'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Live calling and patient admission are disabled.'),
        findsOneWidget,
      );
    });
  });

  group('ChamberTokenCard Read-Only Past Date Tests', () {
    final pastDate = DateTime(2026, 10, 10);
    final today = DateTime.now();

    final pendingAppt = Appointment(
      id: 'appt-past-1',
      queueNumber: 7,
      patientName: 'Kavita Das',
      patientPhone: '9876543210',
      status: AppointmentStatus.pending,
      visitStatus: VisitStatus.waitingInLobby,
      paymentType: PaymentType.paidCash,
      amountCollected: 500,
      scheduledDate: pastDate,
      doctorId: 'doc-1',
      doctorName: 'Dr. Test',
    );

    final completedAppt = Appointment(
      id: 'appt-past-2',
      queueNumber: 8,
      patientName: 'Anil Roy',
      patientPhone: '9876543211',
      status: AppointmentStatus.completed,
      visitStatus: VisitStatus.completed,
      paymentType: PaymentType.paidCash,
      amountCollected: 500,
      scheduledDate: pastDate,
      doctorId: 'doc-1',
      doctorName: 'Dr. Test',
    );

    testWidgets(
        'Past date pending token displays UNATTENDED / NO-SHOW and Unattended static pill',
        (tester) async {
      bool consultPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChamberTokenCard(
              appointment: pendingAppt,
              isCallingNow: false,
              isPastDate: true,
              onConsult: () => consultPressed = true,
            ),
          ),
        ),
      );

      // Verify EOD unresolved tokens show Unattended / No-Show
      expect(find.text('UNATTENDED / NO-SHOW'), findsOneWidget);
      expect(find.text('Shift Closed • Past Date'), findsOneWidget);
      expect(find.text('Unattended'), findsOneWidget);

      // Must NOT display live status or action buttons
      expect(find.text('WAITING'), findsNothing);
      expect(find.text('In Waiting Room'), findsNothing);
      expect(find.text('Waiting Reception Call'), findsNothing);
      expect(find.text('Enter Consultation'), findsNothing);
      expect(find.text('Admit'), findsNothing);

      // Tapping card must NOT invoke consult
      await tester.tap(find.byType(ChamberTokenCard));
      await tester.pump();

      expect(consultPressed, isFalse);
    });

    testWidgets(
        'Past date completed token displays COMPLETED and View Summary button',
        (tester) async {
      bool consultPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChamberTokenCard(
              appointment: completedAppt,
              isCallingNow: false,
              isPastDate: true,
              onConsult: () => consultPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('View Summary'), findsOneWidget);
      expect(find.text('Enter Consultation'), findsNothing);
      expect(find.text('Admit'), findsNothing);

      // Tapping View Summary invokes consult/record callback
      await tester.tap(find.text('View Summary'));
      await tester.pump();

      expect(consultPressed, isTrue);
    });

    testWidgets(
        'Today pending token retains standard WAITING and Waiting Reception Call state',
        (tester) async {
      final todayPendingAppt = Appointment(
        id: 'appt-today-1',
        queueNumber: 3,
        patientName: 'Sunita Bora',
        patientPhone: '9876543212',
        status: AppointmentStatus.pending,
        visitStatus: VisitStatus.waitingInLobby,
        paymentType: PaymentType.paidCash,
        amountCollected: 500,
        scheduledDate: today,
        doctorId: 'doc-1',
        doctorName: 'Dr. Test',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChamberTokenCard(
              appointment: todayPendingAppt,
              isCallingNow: false,
              isPastDate: false,
              onConsult: () {},
            ),
          ),
        ),
      );

      expect(find.text('WAITING'), findsOneWidget);
      expect(find.text('In Waiting Room'), findsOneWidget);
      expect(find.text('Waiting Reception Call'), findsOneWidget);
      expect(find.text('UNATTENDED / NO-SHOW'), findsNothing);
      expect(find.text('Unattended'), findsNothing);
    });
  });
}
