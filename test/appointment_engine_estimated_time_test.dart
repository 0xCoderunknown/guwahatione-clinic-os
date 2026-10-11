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
}
