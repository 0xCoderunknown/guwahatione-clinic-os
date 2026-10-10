import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appointment_app/models/appointment.dart';
import 'package:appointment_app/widgets/chamber/chamber_control_banner.dart';
import 'package:appointment_app/widgets/chamber/chamber_token_card.dart';

void main() {
  group('Doctor-Reception Chamber Handshake Protocol Widget Tests', () {
    testWidgets('ChamberControlBanner renders consultation_ended state with NEXT PATIENT button',
        (tester) async {
      bool nextPatientPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChamberControlBanner(
              status: 'consultation_ended',
              lastCompletedQueueNumber: 12,
              lastCompletedPatientName: 'Rahul Sharma',
              onNextPatient: () => nextPatientPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Consultation Ended: Token #12'), findsOneWidget);
      expect(find.text('(Rahul Sharma)'), findsOneWidget);
      expect(find.text('NEXT PATIENT'), findsOneWidget);

      await tester.tap(find.text('NEXT PATIENT'));
      await tester.pump();

      expect(nextPatientPressed, isTrue);
    });

    testWidgets('ChamberControlBanner renders ready_for_next state with signal sent badge',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChamberControlBanner(
              status: 'ready_for_next',
              onNextPatient: () {},
            ),
          ),
        ),
      );

      expect(find.text('Chamber Ready for Next Patient'), findsOneWidget);
      expect(find.text('SIGNAL SENT'), findsOneWidget);
      expect(find.text('Re-Signal Reception'), findsOneWidget);
    });

    testWidgets('ChamberControlBanner renders calling state with incoming patient details',
        (tester) async {
      bool openFilePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChamberControlBanner(
              status: 'calling',
              activeQueueNumber: 14,
              activePatientName: 'Amit Roy',
              onNextPatient: () {},
              onOpenActivePatient: () => openFilePressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Incoming: Token #14'), findsOneWidget);
      expect(find.text('(Amit Roy)'), findsOneWidget);
      expect(find.text('Open Clinical File'), findsOneWidget);

      await tester.tap(find.text('Open Clinical File'));
      await tester.pump();

      expect(openFilePressed, isTrue);
    });

    testWidgets('ChamberControlBanner renders idle state with start action',
        (tester) async {
      bool readyFirstPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChamberControlBanner(
              status: 'idle',
              onNextPatient: () => readyFirstPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('OPD Chamber Open'), findsOneWidget);
      expect(find.text('READY FOR FIRST PATIENT'), findsOneWidget);

      await tester.tap(find.text('READY FOR FIRST PATIENT'));
      await tester.pump();

      expect(readyFirstPressed, isTrue);
    });
  });

  group('Reception-Only Patient Admission Enforcement on ChamberTokenCard', () {
    final pendingAppt = Appointment(
      id: 'appt-13',
      patientPhone: '9876543210',
      patientName: 'Priya Das',
      status: AppointmentStatus.pending,
      paymentType: PaymentType.paid,
      amountCollected: 500,
      queueNumber: 13,
      scheduledDate: DateTime(2026, 10, 10),
      doctorId: 'doc-1',
      doctorName: 'Dr. Sharma',
    );

    testWidgets('Pending token without isCallingNow displays Waiting Reception Call and prevents consult',
        (tester) async {
      bool consultPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChamberTokenCard(
              appointment: pendingAppt,
              isCallingNow: false,
              onConsult: () => consultPressed = true,
            ),
          ),
        ),
      );

      // Must show waiting badge
      expect(find.text('Waiting Reception Call'), findsOneWidget);
      // Must NOT show consult or admitted button
      expect(find.text('Enter Consultation'), findsNothing);
      expect(find.text('Consult'), findsNothing);

      // Tapping the card must NOT invoke consult callback
      await tester.tap(find.byType(ChamberTokenCard));
      await tester.pump();

      expect(consultPressed, isFalse);
    });

    testWidgets('Pending token WITH isCallingNow displays Enter Consultation button and invokes onConsult',
        (tester) async {
      bool consultPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChamberTokenCard(
              appointment: pendingAppt,
              isCallingNow: true,
              onConsult: () => consultPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Enter Consultation'), findsOneWidget);

      await tester.tap(find.text('Enter Consultation'));
      await tester.pump();

      expect(consultPressed, isTrue);
    });

    testWidgets('Completed token displays Record button and allows reviewing Rx',
        (tester) async {
      bool recordPressed = false;

      final completedAppt = Appointment(
        id: 'appt-12',
        patientPhone: '9876543210',
        patientName: 'Rahul Sharma',
        status: AppointmentStatus.completed,
        paymentType: PaymentType.paid,
        amountCollected: 500,
        queueNumber: 12,
        scheduledDate: DateTime(2026, 10, 10),
        doctorId: 'doc-1',
        doctorName: 'Dr. Sharma',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChamberTokenCard(
              appointment: completedAppt,
              isCallingNow: false,
              onConsult: () => recordPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Record'), findsOneWidget);

      await tester.tap(find.text('Record'));
      await tester.pump();

      expect(recordPressed, isTrue);
    });
  });
}
