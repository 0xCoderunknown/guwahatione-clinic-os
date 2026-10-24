import 'package:appointment_app/core/engines/engines.dart';
import 'package:appointment_app/models/appointment.dart';
import 'package:appointment_app/models/doctor.dart';
import 'package:flutter_test/flutter_test.dart';

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
          paymentType: PaymentType.paidCash,
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
          paymentType: PaymentType.paidCash,
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
          paymentType: PaymentType.paidCash,
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
          paymentType: PaymentType.paidCash,
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
          paymentType: PaymentType.paidCash,
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

    test(
      'Considers future chamber start time when doctor is not yet sitting',
      () {
        final queue = createMockQueue();
        final currentTime = DateTime(2026, 10, 11, 16, 0); // 4:00 PM
        final scheduledStart = DateTime(
          2026,
          10,
          11,
          17,
          0,
        ); // Doctor arrives at 5:00 PM

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
      },
    );
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
        paymentType: PaymentType.paidCash,
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
      expect(view.inChamberPatients.map((a) => a.id).toList(), ['appt_13']);

      // Waiting list should have 12, 14, 15 in FIFO queue
      expect(view.waiting.map((a) => a.queueNumber).toList(), [12, 14, 15]);
    });

    test(
      'When VIP is admitted out of order, earlier waiting tokens remain in clean FIFO queue without bypassed flags',
      () {
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
        expect(view.inChamberPatients.map((a) => a.id).toList(), ['appt_15']);
        expect(view.waiting.map((a) => a.queueNumber).toList(), [12, 13, 14]);
      },
    );

    test(
      'When multiple doctors consult concurrently, inChamberPatients isolates all active tokens and keeps waiting list clean',
      () {
        final appts = [
          createAppt('appt_3', 3, AppointmentStatus.pending),
          createAppt('appt_4', 4, AppointmentStatus.pending),
          createAppt('appt_8', 8, AppointmentStatus.pending),
          createAppt('appt_9', 9, AppointmentStatus.pending),
        ];

        // Dr. A has Token 3 in Chamber 1, Dr. B has Token 8 in Chamber 2
        final view = AppointmentEngine.partitionQueueForReception(
          appointments: appts,
          activeAppointmentIds: {'appt_3', 'appt_8'},
        );

        expect(view.inChamberPatients.length, 2);
        expect(view.inChamberPatients.map((a) => a.id).toList(), [
          'appt_3',
          'appt_8',
        ]);
        expect(view.waiting.map((a) => a.id).toList(), ['appt_4', 'appt_9']);
      },
    );

    test(
      'When doctor is idle (no inChamber), all pending patients are in waiting list',
      () {
        final appts = [
          createAppt('appt_12', 12, AppointmentStatus.pending),
          createAppt('appt_13', 13, AppointmentStatus.pending),
        ];

        final view = AppointmentEngine.partitionQueueForReception(
          appointments: appts,
        );

        expect(view.inChamber, isNull);
        expect(view.inChamberPatients, isEmpty);
        expect(view.waiting.length, 2);
      },
    );

    test(
      'countDoctorAppointments accurately tallies appointments per doctor',
      () {
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
            paymentType: PaymentType.paidCash,
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
      },
    );
  });

  group('AppointmentEngine - Duplicate Booking Prevention Tests', () {
    final targetDate = DateTime(2026, 10, 15, 11, 0);

    final existingAppts = [
      Appointment(
        id: 'appt_1',
        patientPhone: '9876543210',
        patientName: 'Ramesh Das',
        doctorId: 'doc_1',
        doctorName: 'Dr. Baruah',
        scheduledDate: DateTime(2026, 10, 15, 10, 0),
        amountCollected: 500,
        paymentType: PaymentType.paidCash,
        status: AppointmentStatus.pending,
        queueNumber: 1,
      ),
      Appointment(
        id: 'appt_2',
        patientPhone: '9876543210',
        patientName: 'Anita Das',
        // Family member sharing same phone
        doctorId: 'doc_1',
        doctorName: 'Dr. Baruah',
        scheduledDate: DateTime(2026, 10, 15, 10, 15),
        amountCollected: 500,
        paymentType: PaymentType.paidCash,
        status: AppointmentStatus.pending,
        queueNumber: 2,
      ),
      Appointment(
        id: 'appt_3',
        patientPhone: '9998887776',
        patientName: 'Suresh Kalita',
        doctorId: 'doc_1',
        doctorName: 'Dr. Baruah',
        scheduledDate: DateTime(2026, 10, 15, 10, 30),
        amountCollected: 0,
        paymentType: PaymentType.paidCash,
        status: AppointmentStatus.absent,
        // Absent slot
        queueNumber: 3,
      ),
    ];

    test(
      'findDuplicateBooking detects exact same patient on same date and doctor',
      () {
        final duplicate = AppointmentEngine.findDuplicateBooking(
          appointments: existingAppts,
          doctorId: 'doc_1',
          patientName: '  ramesh das  ',
          // case & whitespace insensitive
          patientPhone: '9876543210',
          targetDate: targetDate,
        );

        expect(duplicate, isNotNull);
        expect(duplicate?.id, 'appt_1');
      },
    );

    test(
      'Family member sharing same phone number is NOT blocked as duplicate',
      () {
        final duplicate = AppointmentEngine.findDuplicateBooking(
          appointments: existingAppts,
          doctorId: 'doc_1',
          patientName: 'Baby of Ramesh Das',
          patientPhone: '9876543210',
          targetDate: targetDate,
        );

        expect(duplicate, isNull);
      },
    );

    test('Absent appointment slot does NOT block re-booking on same date', () {
      final duplicate = AppointmentEngine.findDuplicateBooking(
        appointments: existingAppts,
        doctorId: 'doc_1',
        patientName: 'Suresh Kalita',
        patientPhone: '9998887776',
        targetDate: targetDate,
      );

      expect(duplicate, isNull);
    });

    test('Different doctor on same date is NOT blocked as duplicate', () {
      final duplicate = AppointmentEngine.findDuplicateBooking(
        appointments: existingAppts,
        doctorId: 'doc_2',
        patientName: 'Ramesh Das',
        patientPhone: '9876543210',
        targetDate: targetDate,
      );

      expect(duplicate, isNull);
    });
  });

  group('AppointmentEngine - Fee Resolution & Queue Partition Tests', () {
    final mockDoc = Doctor(
      id: 'doc_1',
      name: 'Dr. Baruah',
      specialty: 'Medicine',
      phone: '9876543210',
      availableDays: ['Mon'],
      blockedDates: [],
      consultationFee: 700,
    );

    test('resolveConsultationFee resolves zero for free reviews and family courtesy', () {
      expect(
        AppointmentEngine.resolveConsultationFee(
          doctor: mockDoc,
          paymentType: PaymentType.freeReview,
        ),
        0,
      );
      expect(
        AppointmentEngine.resolveConsultationFee(
          doctor: mockDoc,
          paymentType: PaymentType.freeFamily,
        ),
        0,
      );
    });

    test('resolveConsultationFee resolves doctor fee for paid visits', () {
      expect(
        AppointmentEngine.resolveConsultationFee(
          doctor: mockDoc,
          paymentType: PaymentType.paidCash,
        ),
        700,
      );
      expect(
        AppointmentEngine.resolveConsultationFee(
          doctor: null,
          paymentType: PaymentType.paidCash,
        ),
        500, // Default constant
      );
    });

    test('calculateProvisionalNextToken increments highest queue number for doctor on date', () {
      final today = DateTime(2026, 10, 11);
      final appts = [
        Appointment(
          id: '1',
          patientPhone: '111',
          patientName: 'A',
          doctorId: 'doc_1',
          doctorName: 'Dr. B',
          scheduledDate: DateTime(2026, 10, 11, 10, 0),
          amountCollected: 500,
          paymentType: PaymentType.paidCash,
          status: AppointmentStatus.pending,
          queueNumber: 4,
        ),
        Appointment(
          id: '2',
          patientPhone: '222',
          patientName: 'B',
          doctorId: 'doc_1',
          doctorName: 'Dr. B',
          scheduledDate: DateTime(2026, 10, 11, 11, 0),
          amountCollected: 500,
          paymentType: PaymentType.paidCash,
          status: AppointmentStatus.pending,
          queueNumber: 7,
        ),
      ];

      final next = AppointmentEngine.calculateProvisionalNextToken(
        appointments: appts,
        doctorId: 'doc_1',
        targetDate: today,
      );

      expect(next, 8);
    });
  });
}
