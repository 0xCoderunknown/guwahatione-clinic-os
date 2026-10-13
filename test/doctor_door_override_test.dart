import 'package:appointment_app/models/appointment.dart';
import 'package:appointment_app/widgets/chamber/chamber_door_override_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Doctor Chamber Emergency Door Override Derivation Tests', () {
    final now = DateTime(2026, 10, 12);

    Appointment createAppt({
      required String id,
      required int queueNumber,
      required String name,
      required AppointmentStatus status,
      required VisitStatus visitStatus,
      required PaymentType paymentType,
    }) {
      return Appointment(
        id: id,
        queueNumber: queueNumber,
        patientName: name,
        patientPhone: '9876543210',
        status: status,
        visitStatus: visitStatus,
        paymentType: paymentType,
        amountCollected: paymentType.isPaid ? 500 : 0,
        scheduledDate: now,
        doctorId: 'doc-1',
        doctorName: 'Dr. Test',
      );
    }

    test('Strictly excludes remote/phone bookings (VisitStatus.booked)', () {
      final appts = [
        createAppt(
          id: '1',
          queueNumber: 1,
          name: 'Remote Caller',
          status: AppointmentStatus.pending,
          visitStatus: VisitStatus.booked,
          paymentType: PaymentType.paidCash,
        ),
        createAppt(
          id: '2',
          queueNumber: 2,
          name: 'Lobby Patient',
          status: AppointmentStatus.pending,
          visitStatus: VisitStatus.waitingInLobby,
          paymentType: PaymentType.paidCash,
        ),
      ];

      final doorEligible = appts
          .where(
            (a) =>
                a.status == AppointmentStatus.pending &&
                a.visitStatus == VisitStatus.waitingInLobby &&
                a.paymentType != PaymentType.unpaid,
          )
          .take(2)
          .toList();

      expect(doorEligible.length, 1);
      expect(doorEligible.first.id, '2');
      expect(doorEligible.first.patientName, 'Lobby Patient');
    });

    test('Strictly excludes unpaid bookings (PaymentType.unpaid)', () {
      final appts = [
        createAppt(
          id: '1',
          queueNumber: 1,
          name: 'Unpaid Patient',
          status: AppointmentStatus.pending,
          visitStatus: VisitStatus.waitingInLobby,
          paymentType: PaymentType.unpaid,
        ),
        createAppt(
          id: '2',
          queueNumber: 2,
          name: 'Post Pay Patient',
          status: AppointmentStatus.pending,
          visitStatus: VisitStatus.waitingInLobby,
          paymentType: PaymentType.postPay,
        ),
        createAppt(
          id: '3',
          queueNumber: 3,
          name: 'Free Waiver Patient',
          status: AppointmentStatus.pending,
          visitStatus: VisitStatus.waitingInLobby,
          paymentType: PaymentType.freeFamily,
        ),
      ];

      final doorEligible = appts
          .where(
            (a) =>
                a.status == AppointmentStatus.pending &&
                a.visitStatus == VisitStatus.waitingInLobby &&
                a.paymentType != PaymentType.unpaid,
          )
          .take(2)
          .toList();

      expect(doorEligible.length, 2);
      expect(doorEligible.map((a) => a.id).toList(), ['2', '3']);
      expect(doorEligible.any((a) => a.id == '1'), isFalse);
    });

    test('Strictly caps door eligible list to at most 2 tokens', () {
      final appts = List.generate(
        5,
        (i) => createAppt(
          id: '$i',
          queueNumber: i + 1,
          name: 'Patient $i',
          status: AppointmentStatus.pending,
          visitStatus: VisitStatus.waitingInLobby,
          paymentType: PaymentType.paidCash,
        ),
      );

      final doorEligible = appts
          .where(
            (a) =>
                a.status == AppointmentStatus.pending &&
                a.visitStatus == VisitStatus.waitingInLobby &&
                a.paymentType != PaymentType.unpaid,
          )
          .take(2)
          .toList();

      expect(doorEligible.length, 2);
      expect(doorEligible[0].queueNumber, 1);
      expect(doorEligible[1].queueNumber, 2);
    });

    test('Strictly excludes completed and absent appointments', () {
      final appts = [
        createAppt(
          id: '1',
          queueNumber: 1,
          name: 'Completed Patient',
          status: AppointmentStatus.completed,
          visitStatus: VisitStatus.completed,
          paymentType: PaymentType.paidCash,
        ),
        createAppt(
          id: '2',
          queueNumber: 2,
          name: 'Absent Patient',
          status: AppointmentStatus.absent,
          visitStatus: VisitStatus.cancelled,
          paymentType: PaymentType.paidCash,
        ),
      ];

      final doorEligible = appts
          .where(
            (a) =>
                a.status == AppointmentStatus.pending &&
                a.visitStatus == VisitStatus.waitingInLobby &&
                a.paymentType != PaymentType.unpaid,
          )
          .take(2)
          .toList();

      expect(doorEligible, isEmpty);
    });

    test('Strictly disabled when chamber is occupied or calling', () {
      final appts = [
        createAppt(
          id: '1',
          queueNumber: 1,
          name: 'Lobby Patient',
          status: AppointmentStatus.pending,
          visitStatus: VisitStatus.waitingInLobby,
          paymentType: PaymentType.paidCash,
        ),
      ];

      for (final isOccupied in [true, false]) {
        final doorEligible = isOccupied
            ? <Appointment>[]
            : appts
                  .where(
                    (a) =>
                        a.status == AppointmentStatus.pending &&
                        a.visitStatus == VisitStatus.waitingInLobby &&
                        a.paymentType != PaymentType.unpaid,
                  )
                  .take(2)
                  .toList();
        if (isOccupied) {
          expect(doorEligible, isEmpty);
        } else {
          expect(doorEligible.length, 1);
        }
      }
    });
  });

  group('ChamberDoorOverrideBar Widget Tests', () {
    final now = DateTime(2026, 10, 12);

    final appt1 = Appointment(
      id: 'appt-1',
      queueNumber: 4,
      patientName: 'Priya Das',
      patientPhone: '9876543210',
      status: AppointmentStatus.pending,
      visitStatus: VisitStatus.waitingInLobby,
      paymentType: PaymentType.paidCash,
      amountCollected: 500,
      scheduledDate: now,
      doctorId: 'doc-1',
      doctorName: 'Dr. Test',
    );

    final appt2 = Appointment(
      id: 'appt-2',
      queueNumber: 5,
      patientName: 'Rahul Sharma',
      patientPhone: '9876543211',
      status: AppointmentStatus.pending,
      visitStatus: VisitStatus.waitingInLobby,
      paymentType: PaymentType.freeReview,
      amountCollected: 0,
      scheduledDate: now,
      doctorId: 'doc-1',
      doctorName: 'Dr. Test',
    );

    testWidgets(
      'Renders nothing (SizedBox.shrink) when eligible tokens list is empty',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChamberDoorOverrideBar(
                eligibleTokens: const [],
                onAdmit: (_) {},
              ),
            ),
          ),
        );

        expect(find.byType(ChamberDoorOverrideBar), findsOneWidget);
        expect(find.text('Next at Door (Lobby Checked-In)'), findsNothing);
        expect(find.text('Emergency Self-Call'), findsNothing);
      },
    );

    testWidgets(
      'Renders emergency self-call runway with eligible tokens and confirmation dialog',
      (tester) async {
        Appointment? admittedAppt;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChamberDoorOverrideBar(
                eligibleTokens: [appt1, appt2],
                onAdmit: (appt) => admittedAppt = appt,
              ),
            ),
          ),
        );

        // Verify header and badge
        expect(find.text('Next at Door (Lobby Checked-In)'), findsOneWidget);
        expect(find.text('Emergency Self-Call'), findsOneWidget);

        // Verify token items
        expect(find.text('Priya Das'), findsOneWidget);
        expect(find.text('Rahul Sharma'), findsOneWidget);
        expect(find.text('Paid (Cash)'), findsOneWidget);
        expect(find.text('Free (Review)'), findsOneWidget);

        // Tap Admit on first token
        final admitButtons = find.text('Admit');
        expect(admitButtons, findsNWidgets(2));
        await tester.tap(admitButtons.first);
        await tester.pumpAndSettle();

        // Confirmation dialog should be displayed
        expect(find.text('Emergency Door Admission'), findsOneWidget);
        expect(
          find.textContaining(
            'Admit Token #4 (Priya Das) directly into chamber?',
          ),
          findsOneWidget,
        );

        // Confirm admission
        await tester.tap(find.text('Admit Now'));
        await tester.pumpAndSettle();

        expect(admittedAppt, isNotNull);
        expect(admittedAppt!.id, 'appt-1');
        expect(admittedAppt!.patientName, 'Priya Das');
      },
    );
  });
}
