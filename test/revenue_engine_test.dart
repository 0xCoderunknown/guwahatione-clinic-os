import 'package:appointment_app/core/engines/revenue_engine.dart';
import 'package:appointment_app/models/appointment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RevenueEngine - Realized Revenue Calculation Tests', () {
    test('Empty appointment list yields zero revenue', () {
      expect(RevenueEngine.calculateRealizedRevenue([]), 0);
    });

    test(
      'Pending and absent appointments strictly do not generate revenue',
      () {
        final appts = [
          Appointment(
            id: '1',
            patientPhone: '9876543210',
            patientName: 'Pending Patient',
            status: AppointmentStatus.pending,
            paymentType: PaymentType.paidCash,
            amountCollected: 500,
            queueNumber: 1,
            scheduledDate: DateTime(2026, 10, 11),
            doctorId: 'doc-1',
            doctorName: 'Dr. Baruah',
          ),
          Appointment(
            id: '2',
            patientPhone: '9876543211',
            patientName: 'Absent Patient',
            status: AppointmentStatus.absent,
            paymentType: PaymentType.paidCash,
            amountCollected: 0,
            queueNumber: 2,
            scheduledDate: DateTime(2026, 10, 11),
            doctorId: 'doc-1',
            doctorName: 'Dr. Baruah',
          ),
        ];

        expect(RevenueEngine.calculateRealizedRevenue(appts), 0);
      },
    );

    test('Completed appointments correctly sum realized revenue', () {
      final appts = [
        Appointment(
          id: '1',
          patientPhone: '9876543210',
          patientName: 'Completed Paid 1',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.paidCash,
          amountCollected: 600,
          queueNumber: 1,
          scheduledDate: DateTime(2026, 10, 11),
          doctorId: 'doc-1',
          doctorName: 'Dr. Baruah',
        ),
        Appointment(
          id: '2',
          patientPhone: '9876543211',
          patientName: 'Completed Free Review',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.freeReview,
          amountCollected: 0,
          queueNumber: 2,
          scheduledDate: DateTime(2026, 10, 11),
          doctorId: 'doc-1',
          doctorName: 'Dr. Baruah',
        ),
        Appointment(
          id: '3',
          patientPhone: '9876543212',
          patientName: 'Completed Paid 2',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.paidCash,
          amountCollected: 400,
          queueNumber: 3,
          scheduledDate: DateTime(2026, 10, 11),
          doctorId: 'doc-1',
          doctorName: 'Dr. Baruah',
        ),
        Appointment(
          id: '4',
          patientPhone: '9876543213',
          patientName: 'Pending Paid',
          status: AppointmentStatus.pending,
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 4,
          scheduledDate: DateTime(2026, 10, 11),
          doctorId: 'doc-1',
          doctorName: 'Dr. Baruah',
        ),
      ];

      expect(RevenueEngine.calculateRealizedRevenue(appts), 1000);
    });
  });

  group('RevenueEngine - calculateDoctorTotalFees Tests', () {
    test('Calculates total fees for completed paid visits', () {
      final appts = [
        Appointment(
          id: '1',
          patientPhone: '9876543210',
          patientName: 'Patient 1',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.paidCash,
          amountCollected: 700,
          queueNumber: 1,
          scheduledDate: DateTime(2026, 10, 11),
          doctorId: 'doc-1',
          doctorName: 'Dr. Baruah',
        ),
        Appointment(
          id: '2',
          patientPhone: '9876543211',
          patientName: 'Patient 2',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.freeFamily,
          amountCollected: 0,
          queueNumber: 2,
          scheduledDate: DateTime(2026, 10, 11),
          doctorId: 'doc-1',
          doctorName: 'Dr. Baruah',
        ),
      ];

      expect(RevenueEngine.calculateDoctorTotalFees(appts), 700);
    });
  });

  group('RevenueEngine - calculateDailyMetrics Tests', () {
    test('Empty list returns all zeros', () {
      final metrics = RevenueEngine.calculateDailyMetrics([]);
      expect(metrics.totalAppointments, 0);
      expect(metrics.completedCount, 0);
      expect(metrics.pendingCount, 0);
      expect(metrics.absentCount, 0);
      expect(metrics.realizedRevenue, 0);
    });

    test('Computes aggregate counts and realized revenue accurately', () {
      final appts = [
        Appointment(
          id: '1',
          patientPhone: '9876543210',
          patientName: 'P1',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 1,
          scheduledDate: DateTime(2026, 10, 11),
          doctorId: 'doc-1',
          doctorName: 'Dr. Baruah',
        ),
        Appointment(
          id: '2',
          patientPhone: '9876543211',
          patientName: 'P2',
          status: AppointmentStatus.pending,
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 2,
          scheduledDate: DateTime(2026, 10, 11),
          doctorId: 'doc-1',
          doctorName: 'Dr. Baruah',
        ),
        Appointment(
          id: '3',
          patientPhone: '9876543212',
          patientName: 'P3',
          status: AppointmentStatus.absent,
          paymentType: PaymentType.paidCash,
          amountCollected: 0,
          queueNumber: 3,
          scheduledDate: DateTime(2026, 10, 11),
          doctorId: 'doc-1',
          doctorName: 'Dr. Baruah',
        ),
        Appointment(
          id: '4',
          patientPhone: '9876543213',
          patientName: 'P4',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.freeReview,
          amountCollected: 0,
          queueNumber: 4,
          scheduledDate: DateTime(2026, 10, 11),
          doctorId: 'doc-1',
          doctorName: 'Dr. Baruah',
        ),
      ];

      final metrics = RevenueEngine.calculateDailyMetrics(appts);
      expect(metrics.totalAppointments, 4);
      expect(metrics.completedCount, 2);
      expect(metrics.pendingCount, 1);
      expect(metrics.absentCount, 1);
      expect(metrics.realizedRevenue, 500);
    });
  });

  group('RevenueEngine - calculateChamberKpis Tests', () {
    test('Calculates chamber KPIs correctly', () {
      final appts = [
        Appointment(
          id: '1',
          patientPhone: '9876543210',
          patientName: 'P1',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.paidCash,
          amountCollected: 600,
          queueNumber: 1,
          scheduledDate: DateTime(2026, 10, 11),
          doctorId: 'doc-1',
          doctorName: 'Dr. Baruah',
        ),
        Appointment(
          id: '2',
          patientPhone: '9876543211',
          patientName: 'P2',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.freeReview,
          amountCollected: 0,
          queueNumber: 2,
          scheduledDate: DateTime(2026, 10, 11),
          doctorId: 'doc-1',
          doctorName: 'Dr. Baruah',
        ),
        Appointment(
          id: '3',
          patientPhone: '9876543212',
          patientName: 'P3',
          status: AppointmentStatus.pending,
          paymentType: PaymentType.paidCash,
          amountCollected: 600,
          queueNumber: 3,
          scheduledDate: DateTime(2026, 10, 11),
          doctorId: 'doc-1',
          doctorName: 'Dr. Baruah',
        ),
        Appointment(
          id: '4',
          patientPhone: '9876543213',
          patientName: 'P4',
          status: AppointmentStatus.absent,
          paymentType: PaymentType.paidCash,
          amountCollected: 0,
          queueNumber: 4,
          scheduledDate: DateTime(2026, 10, 11),
          doctorId: 'doc-1',
          doctorName: 'Dr. Baruah',
        ),
      ];

      final kpi = RevenueEngine.calculateChamberKpis(appts);
      expect(kpi.totalBooked, 4);
      expect(kpi.attendedCount, 2);
      expect(kpi.paidCount, 1);
      expect(kpi.freeCount, 1);
      expect(kpi.waitingCount, 1);
      expect(kpi.absentCount, 1);
      expect(kpi.totalDoctorFees, 600);
    });
  });

  group('RevenueEngine - calculateDoctorAnalytics Tests', () {
    test('Returns empty list when appointments list is empty', () {
      expect(RevenueEngine.calculateDoctorAnalytics([]), isEmpty);
    });

    test(
      'Groups multi-doctor appointments and calculates individual analytics',
      () {
        final appts = [
          Appointment(
            id: '1',
            patientPhone: '9876543210',
            patientName: 'P1',
            status: AppointmentStatus.completed,
            paymentType: PaymentType.paidCash,
            amountCollected: 500,
            queueNumber: 1,
            scheduledDate: DateTime(2026, 10, 11),
            doctorId: 'doc-1',
            doctorName: 'Dr. Baruah',
          ),
          Appointment(
            id: '2',
            patientPhone: '9876543211',
            patientName: 'P2',
            status: AppointmentStatus.pending,
            paymentType: PaymentType.paidCash,
            amountCollected: 500,
            queueNumber: 2,
            scheduledDate: DateTime(2026, 10, 11),
            doctorId: 'doc-1',
            doctorName: 'Dr. Baruah',
          ),
          Appointment(
            id: '3',
            patientPhone: '9876543212',
            patientName: 'P3',
            status: AppointmentStatus.completed,
            paymentType: PaymentType.paidCash,
            amountCollected: 700,
            queueNumber: 1,
            scheduledDate: DateTime(2026, 10, 11),
            doctorId: 'doc-2',
            doctorName: 'Dr. Sharma',
          ),
          Appointment(
            id: '4',
            patientPhone: '9876543213',
            patientName: 'P4',
            status: AppointmentStatus.completed,
            paymentType: PaymentType.freeReview,
            amountCollected: 0,
            queueNumber: 2,
            scheduledDate: DateTime(2026, 10, 11),
            doctorId: 'doc-2',
            doctorName: 'Dr. Sharma',
          ),
        ];

        final analytics = RevenueEngine.calculateDoctorAnalytics(appts);
        expect(analytics.length, 2);

        final doc1 = analytics.firstWhere((d) => d.doctorId == 'doc-1');
        expect(doc1.doctorName, 'Dr. Baruah');
        expect(doc1.totalPatients, 2);
        expect(doc1.completed, 1);
        expect(doc1.pending, 1);
        expect(doc1.absent, 0);
        expect(doc1.free, 0);
        expect(doc1.realizedRevenue, 500);

        final doc2 = analytics.firstWhere((d) => d.doctorId == 'doc-2');
        expect(doc2.doctorName, 'Dr. Sharma');
        expect(doc2.totalPatients, 2);
        expect(doc2.completed, 2);
        expect(doc2.pending, 0);
        expect(doc2.absent, 0);
        expect(doc2.free, 1);
        expect(doc2.realizedRevenue, 700);
      },
    );
  });
}
