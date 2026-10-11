import 'package:flutter_test/flutter_test.dart';
import 'package:appointment_app/core/engines/engines.dart';
import 'package:appointment_app/models/appointment.dart';

void main() {
  group('AppointmentEngine - Dynamic Estimated Consultation Window Tests', () {
    final baseTime = DateTime(2026, 10, 11, 17, 30); // 5:30 PM

    List<Appointment> createMockQueue() {
      return [
        Appointment(
          id: 'appt_1',
          patientPhone: '9864011111',
          patientName: 'Patient One',
          doctorId: 'doc_1',
          doctorName: 'Dr. Bhaskar Thakuria',
          scheduledDate: baseTime,
          amountCollected: 500,
          paymentType: PaymentType.paid,
          status: AppointmentStatus.completed,
          queueNumber: 1,
        ),
        Appointment(
          id: 'appt_2',
          patientPhone: '9864022222',
          patientName: 'Patient Two',
          doctorId: 'doc_1',
          doctorName: 'Dr. Bhaskar Thakuria',
          scheduledDate: baseTime,
          amountCollected: 500,
          paymentType: PaymentType.paid,
          status: AppointmentStatus.pending,
          queueNumber: 2,
        ),
        Appointment(
          id: 'appt_3',
          patientPhone: '9864033333',
          patientName: 'Patient Three',
          doctorId: 'doc_1',
          doctorName: 'Dr. Bhaskar Thakuria',
          scheduledDate: baseTime,
          amountCollected: 500,
          paymentType: PaymentType.paid,
          status: AppointmentStatus.pending,
          queueNumber: 3,
        ),
        Appointment(
          id: 'appt_4',
          patientPhone: '9864044444',
          patientName: 'Patient Four',
          doctorId: 'doc_1',
          doctorName: 'Dr. Bhaskar Thakuria',
          scheduledDate: baseTime,
          amountCollected: 0,
          paymentType: PaymentType.paid,
          status: AppointmentStatus.absent,
          queueNumber: 4,
        ),
        Appointment(
          id: 'appt_5',
          patientPhone: '9864055555',
          patientName: 'Patient Five',
          doctorId: 'doc_1',
          doctorName: 'Dr. Bhaskar Thakuria',
          scheduledDate: baseTime,
          amountCollected: 500,
          paymentType: PaymentType.paid,
          status: AppointmentStatus.pending,
          queueNumber: 5,
        ),
      ];
    }

    test('Patient #2 is next in line because #1 is completed', () {
      final queue = createMockQueue();
      final estimate = AppointmentEngine.calculateEstimatedWindow(
        doctorAppointments: queue,
        targetQueueNumber: 2,
        currentTime: baseTime,
      );

      expect(estimate.patientsAhead, 0);
      expect(estimate.formattedRange, 'Now / Next Up');
      expect(estimate.relativeSummary, 'Next in line');
    });

    test('Patient #3 has 1 patient ahead (Token #2 is pending)', () {
      final queue = createMockQueue();
      final estimate = AppointmentEngine.calculateEstimatedWindow(
        doctorAppointments: queue,
        targetQueueNumber: 3,
        currentTime: baseTime,
        averageMinutesPerPatient: 8,
      );

      expect(estimate.patientsAhead, 1);
      // 1 ahead * 8 mins = 8 mins from baseTime (5:30 -> 5:38 PM)
      expect(estimate.estimatedStart, DateTime(2026, 10, 11, 17, 38));
      expect(estimate.relativeSummary, contains('~8 min wait (1 ahead)'));
      expect(estimate.formattedRange, contains('5:38 PM'));
    });

    test('Patient #5 ignores absent Patient #4 and completed Patient #1', () {
      final queue = createMockQueue();
      final estimate = AppointmentEngine.calculateEstimatedWindow(
        doctorAppointments: queue,
        targetQueueNumber: 5,
        currentTime: baseTime,
        averageMinutesPerPatient: 10,
      );

      // Pending ahead are only Token #2 and Token #3 (Total = 2)
      expect(estimate.patientsAhead, 2);
      // 2 * 10 mins = 20 mins from baseTime (5:30 -> 5:50 PM)
      expect(estimate.estimatedStart, DateTime(2026, 10, 11, 17, 50));
      expect(estimate.relativeSummary, contains('~20 min wait (2 ahead)'));
    });

    test('Considers future chamber start time when doctor is not yet sitting', () {
      final queue = createMockQueue();
      final currentTime = DateTime(2026, 10, 11, 16, 0); // 4:00 PM
      final scheduledStart = DateTime(2026, 10, 11, 17, 0); // Doctor arrives at 5:00 PM

      final estimate = AppointmentEngine.calculateEstimatedWindow(
        doctorAppointments: queue,
        targetQueueNumber: 3,
        currentTime: currentTime,
        chamberStartTime: scheduledStart,
        averageMinutesPerPatient: 10,
      );

      expect(estimate.patientsAhead, 1);
      // Calculated from scheduledStart (5:00 PM + 10 mins = 5:10 PM)
      expect(estimate.estimatedStart, DateTime(2026, 10, 11, 17, 10));
    });
  });

  group('AppointmentEngine - partitionQueueForReception Tests', () {
    final now = DateTime(2026, 10, 11, 10, 0);

    Appointment createAppt(String id, int token, AppointmentStatus status) {
      return Appointment(
        id: id,
        patientPhone: '98640000$token',
        patientName: 'Patient $token',
        doctorId: 'doc_1',
        doctorName: 'Dr. Bhaskar Thakuria',
        scheduledDate: now,
        amountCollected: 500,
        paymentType: PaymentType.paid,
        status: status,
        queueNumber: token,
      );
    }

    test('Partitions completed, waiting, and inChamber correctly', () {
      final appts = [
        createAppt('appt_11', 11, AppointmentStatus.completed),
        createAppt('appt_12', 12, AppointmentStatus.pending),
        createAppt('appt_13', 13, AppointmentStatus.pending),
        createAppt('appt_14', 14, AppointmentStatus.pending),
        createAppt('appt_15', 15, AppointmentStatus.pending),
      ];

      // Token 13 is currently called into chamber
      final view = AppointmentEngine.partitionQueueForReception(
        appointments: appts,
        activeAppointmentId: 'appt_13',
        activeQueueNumber: 13,
      );

      expect(view.completed.length, 1);
      expect(view.completed.first.id, 'appt_11');
      expect(view.inChamber?.id, 'appt_13');

      // Waiting list should have 12, 14, 15
      expect(view.waiting.map((a) => a.queueNumber).toList(), [12, 14, 15]);

      // Token 12 was bypassed because 12 < 13
      expect(view.isBypassed('appt_12'), isTrue);
      expect(view.isBypassed('appt_14'), isFalse);
      expect(view.isBypassed('appt_15'), isFalse);
    });

    test('When VIP is admitted out of order, earlier waiting tokens are bypassed', () {
      final appts = [
        createAppt('appt_12', 12, AppointmentStatus.pending),
        createAppt('appt_13', 13, AppointmentStatus.pending),
        createAppt('appt_14', 14, AppointmentStatus.pending),
        createAppt('appt_15', 15, AppointmentStatus.pending),
      ];

      // VIP Token 15 admitted directly
      final view = AppointmentEngine.partitionQueueForReception(
        appointments: appts,
        activeAppointmentId: 'appt_15',
        activeQueueNumber: 15,
      );

      expect(view.inChamber?.id, 'appt_15');
      expect(view.waiting.map((a) => a.queueNumber).toList(), [12, 13, 14]);

      // All 12, 13, 14 are bypassed
      expect(view.isBypassed('appt_12'), isTrue);
      expect(view.isBypassed('appt_13'), isTrue);
      expect(view.isBypassed('appt_14'), isTrue);
    });

    test('When doctor is idle (no inChamber), no tokens are flagged as bypassed', () {
      final appts = [
        createAppt('appt_12', 12, AppointmentStatus.pending),
        createAppt('appt_13', 13, AppointmentStatus.pending),
      ];

      final view = AppointmentEngine.partitionQueueForReception(
        appointments: appts,
      );

      expect(view.inChamber, isNull);
      expect(view.waiting.length, 2);
      expect(view.isBypassed('appt_12'), isFalse);
      expect(view.isBypassed('appt_13'), isFalse);
    });

    test('countDoctorAppointments accurately tallies appointments per doctor', () {
      final appts = [
        createAppt('appt_1', 1, AppointmentStatus.pending),
        createAppt('appt_2', 2, AppointmentStatus.pending),
        Appointment(
          id: 'appt_3',
          patientPhone: '9864033333',
          patientName: 'Patient Three',
          doctorId: 'doc_2',
          doctorName: 'Dr. Other',
          scheduledDate: DateTime(2026, 10, 11),
          amountCollected: 500,
          paymentType: PaymentType.paid,
          status: AppointmentStatus.pending,
          queueNumber: 1,
        ),
      ];

      expect(
        AppointmentEngine.countDoctorAppointments(
          appointments: appts,
          doctorId: 'doc_1',
        ),
        2,
      );
      expect(
        AppointmentEngine.countDoctorAppointments(
          appointments: appts,
          doctorId: 'doc_2',
        ),
        1,
      );
      expect(
        AppointmentEngine.countDoctorAppointments(
          appointments: appts,
          doctorId: 'doc_999',
        ),
        0,
      );
    });
  });
}

