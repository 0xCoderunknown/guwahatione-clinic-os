import 'package:flutter_test/flutter_test.dart';
import 'package:appointment_app/models/models.dart';
import 'package:appointment_app/services/booking_service.dart';
import 'package:appointment_app/services/firestore_paths.dart';

void main() {
  group('Atomic Booking Locks & Forensic Audit Trail Tests (Phase 2)', () {
    test('FirestorePaths.bookingLock produces deterministic atomic key', () {
      final date = DateTime(2026, 10, 13);
      final lockKey1 = FirestorePaths.bookingLock(
        'doc-1',
        date,
        '9876543210',
        'Rahul Sharma',
      );
      final lockKey2 = FirestorePaths.bookingLock(
        'doc-1',
        date,
        ' 9876543210 ',
        'rahul   sharma',
      );

      expect(lockKey1, 'lock_doc-1_2026-10-13_9876543210_rahul_sharma');
      expect(lockKey1, equals(lockKey2));
    });

    test('FirestorePaths.bookingLock allows family members under same phone', () {
      final date = DateTime(2026, 10, 13);
      final parentLock = FirestorePaths.bookingLock(
        'doc-1',
        date,
        '9876543210',
        'Sunita Das',
      );
      final childLock = FirestorePaths.bookingLock(
        'doc-1',
        date,
        '9876543210',
        'Aarav Das',
      );

      expect(parentLock, isNot(equals(childLock)));
      expect(parentLock, 'lock_doc-1_2026-10-13_9876543210_sunita_das');
      expect(childLock, 'lock_doc-1_2026-10-13_9876543210_aarav_das');
    });

    test('DuplicateBookingException formats clean descriptive error message', () {
      final ex = DuplicateBookingException(
        'Patient Rahul Sharma already has an active booking with this doctor today.',
      );
      expect(
        ex.toString(),
        'Patient Rahul Sharma already has an active booking with this doctor today.',
      );
      expect(ex, isA<Exception>());
    });

    test('AppointmentEvent serializes and deserializes accurately', () {
      final now = DateTime(2026, 10, 13, 10, 30);
      final event = AppointmentEvent(
        id: 'evt-101',
        appointmentId: 'appt-202',
        eventType: AppointmentEventType.checkedIn,
        visitStatus: VisitStatus.waitingInLobby,
        amountCollected: 500,
        paymentType: PaymentType.paidCash,
        actorRole: 'receptionist',
        timestamp: now,
        note: 'Patient checked into lobby desk',
      );

      final json = event.toJson();
      expect(json['id'], 'evt-101');
      expect(json['appointmentId'], 'appt-202');
      expect(json['eventType'], 'checkedIn');
      expect(json['visitStatus'], 'waitingInLobby');
      expect(json['amountCollected'], 500);
      expect(json['paymentType'], 'paidCash');
      expect(json['actorRole'], 'receptionist');

      final fromJson = AppointmentEvent.fromJson({
        'id': 'evt-101',
        'appointmentId': 'appt-202',
        'eventType': 'checkedIn',
        'visitStatus': 'waitingInLobby',
        'amountCollected': 500,
        'paymentType': 'paidCash',
        'actorRole': 'receptionist',
        'timestamp': now.toIso8601String(),
        'note': 'Patient checked into lobby desk',
      });

      expect(fromJson.id, 'evt-101');
      expect(fromJson.appointmentId, 'appt-202');
      expect(fromJson.eventType, AppointmentEventType.checkedIn);
      expect(fromJson.visitStatus, VisitStatus.waitingInLobby);
      expect(fromJson.amountCollected, 500);
      expect(fromJson.paymentType, PaymentType.paidCash);
      expect(fromJson.actorRole, 'receptionist');
      expect(fromJson.note, 'Patient checked into lobby desk');
    });

    test('AppointmentEvent handles all lifecycle transition types', () {
      final events = [
        AppointmentEventType.created,
        AppointmentEventType.checkedIn,
        AppointmentEventType.admitted,
        AppointmentEventType.completed,
        AppointmentEventType.markedAbsent,
        AppointmentEventType.statusUpdated,
      ];

      for (final type in events) {
        final event = AppointmentEvent(
          id: 'evt-${type.name}',
          appointmentId: 'appt-1',
          eventType: type,
          visitStatus: VisitStatus.waitingInLobby,
          actorRole: 'receptionist',
          timestamp: DateTime.now(),
        );

        final json = event.toJson();
        final reconstituted = AppointmentEvent.fromJson(json);
        expect(reconstituted.eventType, type);
      }
    });
  });
}
