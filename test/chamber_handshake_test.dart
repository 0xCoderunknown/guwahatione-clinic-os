import 'dart:async';

import 'package:appointment_app/core/engines/appointment_engine.dart';
import 'package:appointment_app/models/models.dart';
import 'package:appointment_app/providers/clinic_provider.dart';
import 'package:appointment_app/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('Doctor-Reception Chamber Handshake Protocol Widget Tests', () {
    testWidgets(
      'ChamberControlBanner renders consultation_ended state with NEXT PATIENT button',
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
      },
    );

    testWidgets(
      'ChamberControlBanner renders ready_for_next state with signal sent badge',
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
      },
    );

    testWidgets(
      'ChamberControlBanner renders calling state with incoming patient details',
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
      },
    );

    testWidgets('ChamberControlBanner renders idle state with start action', (
      tester,
    ) async {
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

    testWidgets(
      'ChamberControlBanner renders responsive stacked layout on mobile (width < 600)',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

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

        // Verify that in compact mode, Column structure is used so button does not squish text
        final filledButton = find.byType(FilledButton);
        expect(filledButton, findsOneWidget);

        await tester.tap(filledButton);
        await tester.pump();

        expect(readyFirstPressed, isTrue);
      },
    );
  });

  group('Reception-Only Patient Admission Enforcement on ChamberTokenCard', () {
    final pendingAppt = Appointment(
      id: 'appt-13',
      patientPhone: '9876543210',
      patientName: 'Priya Das',
      status: AppointmentStatus.pending,
      paymentType: PaymentType.paidCash,
      amountCollected: 500,
      queueNumber: 13,
      scheduledDate: DateTime(2026, 10, 10),
      doctorId: 'doc-1',
      doctorName: 'Dr. Sharma',
    );

    testWidgets(
      'Pending token without isCallingNow displays Waiting Reception Call and prevents consult',
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
      },
    );

    testWidgets(
      'Pending token WITH isCallingNow displays Enter Consultation button and invokes onConsult',
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
      },
    );

    testWidgets(
      'Completed token displays Record button and allows reviewing Rx',
      (tester) async {
        bool recordPressed = false;

        final completedAppt = Appointment(
          id: 'appt-12',
          patientPhone: '9876543210',
          patientName: 'Rahul Sharma',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.paidCash,
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
      },
    );
  });

  group('ChamberSession Domain Model Tests', () {
    final testDate = DateTime(2026, 10, 11);

    test('ChamberSession.empty initializes idle defaults', () {
      final session = ChamberSession.empty('doc-1', testDate);

      expect(session.doctorId, 'doc-1');
      expect(session.date, testDate);
      expect(session.status, 'idle');
      expect(session.isIdle, isTrue);
      expect(session.isReadyForNext, isFalse);
      expect(session.isConsultationEnded, isFalse);
      expect(session.isCalling, isFalse);
      expect(session.isInConsultation, isFalse);
      expect(session.hasActivePatient, isFalse);
      expect(session.activeAppointmentId, isNull);
    });

    test('ChamberSession.fromMap handles null and empty maps cleanly', () {
      final sessionFromNull = ChamberSession.fromMap(
        null,
        doctorId: 'doc-1',
        date: testDate,
      );
      expect(sessionFromNull.isIdle, isTrue);

      final sessionFromEmpty = ChamberSession.fromMap(
        {},
        doctorId: 'doc-1',
        date: testDate,
      );
      expect(sessionFromEmpty.isIdle, isTrue);
    });

    test('ChamberSession.fromMap correctly parses active and finished chamber states', () {
      final callingMap = {
        'status': 'calling',
        'activeAppointmentId': 'appt-123',
        'activeQueueNumber': 5,
        'patientName': 'Sunita Das',
        'patientPhone': '9864012345',
      };
      final callingSession = ChamberSession.fromMap(
        callingMap,
        doctorId: 'doc-1',
        date: testDate,
      );
      expect(callingSession.isCalling, isTrue);
      expect(callingSession.hasActivePatient, isTrue);
      expect(callingSession.activeAppointmentId, 'appt-123');
      expect(callingSession.activeQueueNumber, 5);
      expect(callingSession.patientName, 'Sunita Das');

      final readyMap = {'status': 'ready_for_next'};
      final readySession = ChamberSession.fromMap(
        readyMap,
        doctorId: 'doc-1',
        date: testDate,
      );
      expect(readySession.isReadyForNext, isTrue);
      expect(readySession.hasActivePatient, isFalse);

      final breakMap = {
        'status': 'consultation_ended',
        'lastCompletedQueueNumber': 4,
        'lastCompletedPatientName': 'Previous Patient',
      };
      final breakSession = ChamberSession.fromMap(
        breakMap,
        doctorId: 'doc-1',
        date: testDate,
      );
      expect(breakSession.isConsultationEnded, isTrue);
      expect(breakSession.lastCompletedQueueNumber, 4);
      expect(breakSession.lastCompletedPatientName, 'Previous Patient');
    });
  });

  group('AccordionDispatchSection Doctor-Paced Readiness Guard Tests', () {
    final testAppt = Appointment(
      id: 'appt-1',
      patientPhone: '9864011111',
      patientName: 'Bikash Das',
      status: AppointmentStatus.pending,
      paymentType: PaymentType.paidCash,
      amountCollected: 500,
      queueNumber: 3,
      scheduledDate: DateTime(2026, 10, 13),
      doctorId: 'doc-1',
      doctorName: 'Dr. Sharma',
    );

    testWidgets('Idle chamber locks dispatch button with waiting indicator', (
      tester,
    ) async {
      final fakeProvider = _TestClinicProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<ClinicProvider>.value(
          value: fakeProvider,
          child: MaterialApp(
            home: Scaffold(
              body: AccordionDispatchSection(
                appointment: testAppt,
                isInChamber: false,
              ),
            ),
          ),
        ),
      );

      fakeProvider.sessionController.add(
        ChamberSession.empty('doc-1', testAppt.scheduledDate),
      );
      await tester.pump();

      expect(find.text('Waiting for doctor'), findsOneWidget);
      expect(find.textContaining('Chamber is idle'), findsOneWidget);

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('Breather state locks dispatch button with holding message', (
      tester,
    ) async {
      final fakeProvider = _TestClinicProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<ClinicProvider>.value(
          value: fakeProvider,
          child: MaterialApp(
            home: Scaffold(
              body: AccordionDispatchSection(
                appointment: testAppt,
                isInChamber: false,
              ),
            ),
          ),
        ),
      );

      fakeProvider.sessionController.add(
        ChamberSession(
          doctorId: 'doc-1',
          date: testAppt.scheduledDate,
          status: 'consultation_ended',
          lastCompletedQueueNumber: 2,
          lastCompletedPatientName: 'Previous',
        ),
      );
      await tester.pump();

      expect(
        find.text('Doctor on Break (Waiting for Doctor)'),
        findsOneWidget,
      );
      expect(find.textContaining('is on a break'), findsOneWidget);

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('Ready for next state enables SEND IN TO DOCTOR button', (
      tester,
    ) async {
      final fakeProvider = _TestClinicProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<ClinicProvider>.value(
          value: fakeProvider,
          child: MaterialApp(
            home: Scaffold(
              body: AccordionDispatchSection(
                appointment: testAppt,
                isInChamber: false,
              ),
            ),
          ),
        ),
      );

      fakeProvider.sessionController.add(
        ChamberSession(
          doctorId: 'doc-1',
          date: testAppt.scheduledDate,
          status: 'ready_for_next',
        ),
      );
      await tester.pump();

      expect(find.text('SEND IN TO DOCTOR'), findsOneWidget);
      expect(find.textContaining('is READY for next patient!'), findsOneWidget);

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);

      await tester.tap(find.text('SEND IN TO DOCTOR'));
      await tester.pump();

      expect(fakeProvider.calledToken, isTrue);
    });

    testWidgets(
      'Active consultation state locks SEND IN TO DOCTOR button with chamber occupied notice',
      (tester) async {
        final fakeProvider = _TestClinicProvider();

        await tester.pumpWidget(
          ChangeNotifierProvider<ClinicProvider>.value(
            value: fakeProvider,
            child: MaterialApp(
              home: Scaffold(
                body: AccordionDispatchSection(
                  appointment: testAppt,
                  isInChamber: false,
                ),
              ),
            ),
          ),
        );

        fakeProvider.sessionController.add(
          ChamberSession(
            doctorId: 'doc-1',
            date: testAppt.scheduledDate,
            status: 'in_consultation',
            activeAppointmentId: 'other-appt',
            activeQueueNumber: 1,
            patientName: 'Occupant Patient',
          ),
        );
        await tester.pump();

        expect(find.text('Chamber Occupied (Token #1 Inside)'), findsOneWidget);
        expect(find.textContaining('currently consulting'), findsOneWidget);

        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.onPressed, isNull);
      },
    );

    test('AppointmentEngine.partitionQueueForReception segregates active in-chamber appointments even if status is pending', () {
      final appt1 = testAppt.copyWith(
        id: 'appt-1',
        queueNumber: 1,
        visitStatus: VisitStatus.waitingInLobby,
      );
      final appt2 = testAppt.copyWith(
        id: 'appt-2',
        queueNumber: 2,
        visitStatus: VisitStatus.waitingInLobby,
      );
      final appt3 = testAppt.copyWith(
        id: 'appt-3',
        queueNumber: 3,
        visitStatus: VisitStatus.booked,
      );

      final partitioned = AppointmentEngine.partitionQueueForReception(
        appointments: [appt1, appt2, appt3],
        activeAppointmentIds: {'appt-1'},
      );

      expect(partitioned.inChamber, isNotNull);
      expect(partitioned.inChamber!.id, 'appt-1');
      expect(partitioned.waiting.length, 1);
      expect(partitioned.waiting.first.id, 'appt-2');
      expect(partitioned.booked.length, 1);
      expect(partitioned.booked.first.id, 'appt-3');
    });
  });
}

class _TestClinicProvider extends ChangeNotifier implements ClinicProvider {
  final StreamController<ChamberSession> sessionController =
      StreamController<ChamberSession>.broadcast();
  bool calledToken = false;

  @override
  Stream<ChamberSession> streamChamberSession(String doctorId, DateTime date) {
    return sessionController.stream;
  }

  @override
  Future<void> callTokenIntoChamber({
    required String doctorId,
    required DateTime date,
    required Appointment appointment,
    bool forceOverride = false,
  }) async {
    calledToken = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
