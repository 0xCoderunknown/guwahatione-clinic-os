import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appointment_app/models/appointment.dart';
import 'package:appointment_app/widgets/widgets.dart';

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

    testWidgets('ChamberTokenCard renders responsive 2-row layout on mobile (width 390)',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChamberTokenCard(
              appointment: pendingAppt,
              isCallingNow: false,
              isPastDate: true,
              onConsult: () {},
            ),
          ),
        ),
      );

      expect(find.text('UNATTENDED / NO-SHOW'), findsOneWidget);
      expect(find.text('Shift Closed • Past Date'), findsOneWidget);
      expect(find.text('Unattended'), findsOneWidget);
      expect(find.text('Kavita Das'), findsOneWidget);
    });
  });

  group('ChamberQueueHeader Audit & Dynamic Label Tests', () {
    testWidgets('Renders Past Session Roster and Archived Snapshot on past dates',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChamberQueueHeader(
              totalBooked: 15,
              isPastDate: true,
            ),
          ),
        ),
      );

      expect(find.text('Past Session Roster'), findsOneWidget);
      expect(find.text('Archived Snapshot'), findsOneWidget);
      expect(find.text("Today's Patient Queue"), findsNothing);
      expect(find.text('Live Sync'), findsNothing);
      expect(find.text('15 issued'), findsOneWidget);
    });

    testWidgets('Renders Today Patient Queue and Live Sync on current date',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChamberQueueHeader(
              totalBooked: 15,
              isPastDate: false,
            ),
          ),
        ),
      );

      expect(find.text("Today's Patient Queue"), findsOneWidget);
      expect(find.text('Live Sync'), findsOneWidget);
      expect(find.text('Past Session Roster'), findsNothing);
      expect(find.text('Archived Snapshot'), findsNothing);
      expect(find.text('15 issued'), findsOneWidget);
    });

    testWidgets('ChamberQueueHeader renders without overflow on mobile (width 390)',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChamberQueueHeader(
              totalBooked: 24,
              isPastDate: true,
            ),
          ),
        ),
      );

      expect(find.text('Past Session Roster'), findsOneWidget);
      expect(find.text('Archived Snapshot'), findsOneWidget);
      expect(find.text('24 issued'), findsOneWidget);
    });
  });

  group('ChamberMetricsGrid Audit & Reconciliation Tests', () {
    final pastDate = DateTime(2026, 10, 10);
    final appointments = [
      Appointment(
        id: 'appt-1',
        queueNumber: 1,
        patientName: 'Patient 1',
        patientPhone: '9876543210',
        status: AppointmentStatus.completed,
        visitStatus: VisitStatus.completed,
        paymentType: PaymentType.paidCash,
        amountCollected: 600,
        scheduledDate: pastDate,
        doctorId: 'doc-1',
        doctorName: 'Dr. Test',
      ),
      Appointment(
        id: 'appt-2',
        queueNumber: 2,
        patientName: 'Patient 2',
        patientPhone: '9876543211',
        status: AppointmentStatus.pending,
        visitStatus: VisitStatus.waitingInLobby,
        paymentType: PaymentType.paidCash,
        amountCollected: 600,
        scheduledDate: pastDate,
        doctorId: 'doc-1',
        doctorName: 'Dr. Test',
      ),
      Appointment(
        id: 'appt-3',
        queueNumber: 3,
        patientName: 'Patient 3',
        patientPhone: '9876543212',
        status: AppointmentStatus.pending,
        visitStatus: VisitStatus.booked,
        paymentType: PaymentType.unpaid,
        amountCollected: 0,
        scheduledDate: pastDate,
        doctorId: 'doc-1',
        doctorName: 'Dr. Test',
      ),
    ];

    testWidgets(
        'Reconciles unresolved tokens as Absent / No-Show and shows Shift completed on past dates',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChamberMetricsGrid.fromAppointments(
              appointments: appointments,
              isDesktop: true,
              isPastDate: true,
            ),
          ),
        ),
      );

      // Total Tokens: 3, subtitle: Shift completed
      expect(find.text('Total Tokens'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Shift completed'), findsOneWidget);
      expect(find.textContaining('still in queue'), findsNothing);

      // Consulted: 1
      expect(find.text('Consulted'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      // Absent / No-Show: 2 (2 unresolved tokens on past date)
      expect(find.text('Absent / No-Show'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Unattended / Closed'), findsOneWidget);
      expect(find.text('Slots preserved'), findsNothing);
    });

    testWidgets(
        'Maintains live waiting queue and preserved slots subtitle on current date',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChamberMetricsGrid.fromAppointments(
              appointments: appointments,
              isDesktop: true,
              isPastDate: false,
            ),
          ),
        ),
      );

      // Live mode: 1 waiting in lobby, 0 absent
      expect(find.text('1 still in queue'), findsOneWidget);
      expect(find.text('Shift completed'), findsNothing);
      expect(find.text('Slots preserved'), findsOneWidget);
      expect(find.text('Unattended / Closed'), findsNothing);
      expect(find.text('0'), findsOneWidget); // 0 absent
    });
  });
}
