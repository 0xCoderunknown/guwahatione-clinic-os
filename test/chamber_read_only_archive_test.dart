import 'package:appointment_app/models/appointment.dart';
import 'package:appointment_app/models/doctor.dart';
import 'package:appointment_app/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChamberAppBar Minimal Header Tests', () {
    final doctor = Doctor(
      id: 'doc-1',
      name: 'Dr. Bhaskar Thakuria',
      specialty: 'General Medicine',
      phone: '9876543210',
      consultationFee: 600,
      availableDays: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
      blockedDates: const [],
    );

    testWidgets(
      'Removes CHAMBER CATALOG badge and expands doctor name without truncation',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: ChamberAppBar(doctor: doctor, isPreviewMode: false),
            ),
          ),
        );

        expect(find.text('CHAMBER CATALOG'), findsNothing);
        expect(find.text('Dr. Bhaskar Thakuria'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('ChamberArchiveBanner Widget Tests', () {
    testWidgets('Renders single compact 1-line status banner', (tester) async {
      final pastDate = DateTime(2026, 10, 10);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ChamberArchiveBanner(date: pastDate)),
        ),
      );

      expect(
        find.text('🔒 Viewing Past Records (Read-Only)'),
        findsOneWidget,
      );
      // Repetition of date and verbose explanation removed
      expect(find.textContaining('10-10-2026'), findsNothing);
      expect(
        find.textContaining('Live calling and patient admission are disabled.'),
        findsNothing,
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
      'Past date pending token displays single No-Show badge, clean name, and is directly tappable',
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

        // Display patient name cleanly as #7 • Kavita Das
        expect(find.text('#7 • Kavita Das'), findsOneWidget);

        // Single muted No-Show pill
        expect(find.text('No-Show'), findsOneWidget);

        // Verbose redundant labels removed
        expect(find.text('UNATTENDED / NO-SHOW'), findsNothing);
        expect(find.text('Shift Closed • Past Date'), findsNothing);
        expect(find.text('Unattended'), findsNothing);

        // Must NOT display live status or live action buttons
        expect(find.text('WAITING'), findsNothing);
        expect(find.text('In Waiting Room'), findsNothing);
        expect(find.text('Waiting Reception Call'), findsNothing);
        expect(find.text('Enter Consultation'), findsNothing);
        expect(find.text('Admit'), findsNothing);

        // Card itself is directly tappable to view summary
        await tester.tap(find.byType(ChamberTokenCard));
        await tester.pump();

        expect(consultPressed, isTrue);
      },
    );

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

        expect(find.text('#8 • Anil Roy'), findsOneWidget);
        expect(find.text('COMPLETED'), findsOneWidget);
        expect(find.text('View Summary'), findsOneWidget);
        expect(find.text('Enter Consultation'), findsNothing);
        expect(find.text('Admit'), findsNothing);

        // Tapping View Summary invokes consult/record callback
        await tester.tap(find.text('View Summary'));
        await tester.pump();

        expect(consultPressed, isTrue);
      },
    );

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

        expect(find.text('Sunita Bora'), findsOneWidget);
        expect(find.text('WAITING'), findsOneWidget);
        expect(find.text('In Waiting Room'), findsOneWidget);
        expect(find.text('Waiting Reception Call'), findsOneWidget);
        expect(find.text('UNATTENDED / NO-SHOW'), findsNothing);
        expect(find.text('No-Show'), findsNothing);
        expect(find.text('Unattended'), findsNothing);
      },
    );

    testWidgets(
      'ChamberTokenCard renders cleanly without overflow on mobile (width 390)',
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

        expect(find.text('#7 • Kavita Das'), findsOneWidget);
        expect(find.text('No-Show'), findsOneWidget);
        expect(find.text('Shift Closed • Past Date'), findsNothing);
        expect(find.text('Unattended'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('ChamberQueueHeader Audit & Dynamic Label Tests', () {
    testWidgets(
      'Renders Previous Session and Past Queue on past dates',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChamberQueueHeader(totalBooked: 15, isPastDate: true),
            ),
          ),
        );

        expect(find.text('Previous Session'), findsOneWidget);
        expect(find.text('Past Queue'), findsOneWidget);
        expect(find.text("Today's Patient Queue"), findsNothing);
        expect(find.text('Live Updates'), findsNothing);
        expect(find.text('15 issued'), findsOneWidget);
      },
    );

    testWidgets('Renders Today Patient Queue and Live Updates on current date', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChamberQueueHeader(totalBooked: 15, isPastDate: false),
          ),
        ),
      );

      expect(find.text("Today's Patient Queue"), findsOneWidget);
      expect(find.text('Live Updates'), findsOneWidget);
      expect(find.text('Previous Session'), findsNothing);
      expect(find.text('Past Queue'), findsNothing);
      expect(find.text('15 issued'), findsOneWidget);
    });

    testWidgets(
      'ChamberQueueHeader renders without overflow on mobile (width 390)',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChamberQueueHeader(totalBooked: 24, isPastDate: true),
            ),
          ),
        );

        expect(find.text('Previous Session'), findsOneWidget);
        expect(find.text('Past Queue'), findsOneWidget);
        expect(find.text('24 issued'), findsOneWidget);
      },
    );
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
      'Reconciles unresolved tokens as Absent / No-Show and shows Shift closed on past dates',
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

        // Total Tokens: 3, subtitle: Shift closed
        expect(find.text('Total Tokens'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        expect(find.text('Shift closed'), findsOneWidget);
        expect(find.textContaining('in queue'), findsNothing);

        // Consulted: 1
        expect(find.text('Consulted'), findsOneWidget);
        expect(find.text('1'), findsOneWidget);

        // Absent / No-Show: 2 (2 unresolved tokens on past date)
        expect(find.text('Absent / No-Show'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('Unattended'), findsOneWidget);
        expect(find.text('Queue record retained'), findsNothing);

        // Doctor's Fees: ₹600 from 1 paid visit
        expect(find.text("Doctor's Fees"), findsOneWidget);
        expect(find.text('₹600'), findsOneWidget);
        expect(find.text('1 paid visits'), findsOneWidget);
      },
    );

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
        expect(find.text('1 in queue'), findsOneWidget);
        expect(find.text('Shift closed'), findsNothing);
        expect(find.text('Queue record retained'), findsOneWidget);
        expect(find.text('Unattended'), findsNothing);
        expect(find.text('0'), findsOneWidget); // 0 absent
      },
    );
  });
}
