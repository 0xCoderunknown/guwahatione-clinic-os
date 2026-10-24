import 'package:appointment_app/models/models.dart';
import 'package:appointment_app/services/firestore_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Atomic Counter Paths & Appointment Lifecycle Tests', () {

    test(
      'FirestorePaths generates deterministic daily queue and chamber keys',
      () {
        final date = DateTime(2026, 10, 13);
        final queueKey = FirestorePaths.doctorQueueCounter('doc-1', date);
        final chamberKey = FirestorePaths.chamberSyncDoc('doc-1', date);

        expect(queueKey, 'queue_doc-1_2026-10-13');
        expect(chamberKey, 'chamber_doc-1_2026-10-13');
      },
    );

    test(
      'Appointment serialization preserves lifecycle timestamps and status',
      () {
        final now = DateTime(2026, 10, 13, 10, 30);
        final appt = Appointment(
          id: 'appt-202',
          patientPhone: '9876543210',
          patientName: 'Rahul Sharma',
          visitStatus: VisitStatus.waitingInLobby,
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 4,
          scheduledDate: now,
          doctorId: 'doc-1',
          doctorName: 'Dr. Bhaskar',
          checkedInAt: now,
        );

        final json = appt.toJson();
        expect(json['id'], 'appt-202');
        expect(json['queueNumber'], 4);
        expect(json['visitStatus'], 'waitingInLobby');
        expect(json['amountCollected'], 500);
        expect(json['paymentType'], 'paidCash');

        final fromJson = Appointment.fromJson(json);
        expect(fromJson.id, 'appt-202');
        expect(fromJson.queueNumber, 4);
        expect(fromJson.visitStatus, VisitStatus.waitingInLobby);
        expect(fromJson.amountCollected, 500);
        expect(fromJson.paymentType, PaymentType.paidCash);
        expect(fromJson.checkedInAt, isNotNull);
      },
    );
  });
}
