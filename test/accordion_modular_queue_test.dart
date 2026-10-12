import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appointment_app/models/appointment.dart';
import 'package:appointment_app/widgets/queue/accordion_status_actions.dart';

void main() {
  group('AccordionStatusActions Widget Tests', () {
    final pendingAppt = Appointment(
      id: 'appt-1',
      queueNumber: 5,
      patientName: 'Ramesh Sharma',
      patientPhone: '9876543210',
      status: AppointmentStatus.pending,
      visitStatus: VisitStatus.waitingInLobby,
      paymentType: PaymentType.paidCash,
      amountCollected: 500,
      scheduledDate: DateTime.now(),
      doctorId: 'doc-1',
      doctorName: 'Dr. Baruah',
    );

    final completedAppt = Appointment(
      id: 'appt-2',
      queueNumber: 6,
      patientName: 'Priya Das',
      patientPhone: '9876543211',
      status: AppointmentStatus.completed,
      visitStatus: VisitStatus.completed,
      paymentType: PaymentType.paidCash,
      amountCollected: 500,
      scheduledDate: DateTime.now(),
      doctorId: 'doc-1',
      doctorName: 'Dr. Baruah',
    );

    testWidgets('Triggers Mark Complete callback on button tap', (tester) async {
      AppointmentStatus? updatedStatus;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccordionStatusActions(
              appointment: pendingAppt,
              onUpdateStatus: (status) => updatedStatus = status,
            ),
          ),
        ),
      );

      expect(find.text('Mark Complete'), findsOneWidget);
      expect(find.text('Mark Absent'), findsOneWidget);
      expect(find.text('Send WhatsApp Digital Prescription'), findsNothing);

      await tester.tap(find.text('Mark Complete'));
      await tester.pump();

      expect(updatedStatus, AppointmentStatus.completed);
    });

    testWidgets('Opens confirmation modal and triggers Mark Absent on confirm',
        (tester) async {
      AppointmentStatus? updatedStatus;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccordionStatusActions(
              appointment: pendingAppt,
              onUpdateStatus: (status) => updatedStatus = status,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mark Absent'));
      await tester.pumpAndSettle();

      // Check modal content (ensuring Invariant #1 audit-proof message)
      expect(find.text('Mark Patient Absent?'), findsOneWidget);
      expect(
        find.textContaining('The token slot will be preserved on record with ₹0 fee collected.'),
        findsOneWidget,
      );

      // Tap Confirm Absent
      await tester.tap(find.text('Confirm Absent'));
      await tester.pumpAndSettle();

      expect(updatedStatus, AppointmentStatus.absent);
    });

    testWidgets('Canceling absent modal does not trigger status update',
        (tester) async {
      AppointmentStatus? updatedStatus;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccordionStatusActions(
              appointment: pendingAppt,
              onUpdateStatus: (status) => updatedStatus = status,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mark Absent'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(updatedStatus, isNull);
    });

    testWidgets('Renders WhatsApp button for completed appointments',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccordionStatusActions(
              appointment: completedAppt,
              onUpdateStatus: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Send WhatsApp Digital Prescription'), findsOneWidget);
    });
  });
}
