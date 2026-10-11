import 'package:flutter_test/flutter_test.dart';
import 'package:appointment_app/core/engines/revenue_engine.dart';
import 'package:appointment_app/models/appointment.dart';

void main() {
  group('RevenueEngine - Daily Cash Handover Tests (P8)', () {
    final today = DateTime(2026, 10, 12);

    test('Empty appointments list generates zero-cash handover summary', () {
      final summary = RevenueEngine.calculateCashHandover(
        appointments: [],
        date: today,
      );

      expect(summary.totalAppointments, 0);
      expect(summary.totalCompleted, 0);
      expect(summary.totalRealizedCash, 0);
      expect(summary.totalPaidCount, 0);
      expect(summary.totalFreeReviewCount, 0);
      expect(summary.totalFreeFamilyCount, 0);
      expect(summary.doctorBreakdown, isEmpty);
    });

    test('Pending and absent appointments are strictly excluded from realized cash', () {
      final appts = [
        Appointment(
          id: 'a1',
          patientPhone: '9876543210',
          patientName: 'Waiting Patient',
          status: AppointmentStatus.pending,
          paymentType: PaymentType.paid,
          amountCollected: 500,
          queueNumber: 1,
          scheduledDate: today,
          doctorId: 'doc-1',
          doctorName: 'Dr. A. Sharma',
        ),
        Appointment(
          id: 'a2',
          patientPhone: '9876543211',
          patientName: 'No Show Patient',
          status: AppointmentStatus.absent,
          paymentType: PaymentType.paid,
          amountCollected: 0,
          queueNumber: 2,
          scheduledDate: today,
          doctorId: 'doc-1',
          doctorName: 'Dr. A. Sharma',
        ),
      ];

      final summary = RevenueEngine.calculateCashHandover(
        appointments: appts,
        date: today,
      );

      expect(summary.totalAppointments, 2);
      expect(summary.totalCompleted, 0);
      expect(summary.totalRealizedCash, 0);
      expect(summary.doctorBreakdown.first.cashCollected, 0);
      expect(summary.doctorBreakdown.first.completedCount, 0);
    });

    test('Accurately aggregates multi-doctor paid, review, and family appointments', () {
      final appts = [
        // Doctor 1: 1 Paid (500), 1 Free Review, 1 Absent
        Appointment(
          id: 'a1',
          patientPhone: '9876543210',
          patientName: 'Patient 1',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.paid,
          amountCollected: 500,
          queueNumber: 1,
          scheduledDate: today,
          doctorId: 'doc-1',
          doctorName: 'Dr. A. Sharma',
        ),
        Appointment(
          id: 'a2',
          patientPhone: '9876543211',
          patientName: 'Patient 2',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.freeReview,
          amountCollected: 0,
          queueNumber: 2,
          scheduledDate: today,
          doctorId: 'doc-1',
          doctorName: 'Dr. A. Sharma',
        ),
        Appointment(
          id: 'a3',
          patientPhone: '9876543212',
          patientName: 'Patient 3',
          status: AppointmentStatus.absent,
          paymentType: PaymentType.paid,
          amountCollected: 0,
          queueNumber: 3,
          scheduledDate: today,
          doctorId: 'doc-1',
          doctorName: 'Dr. A. Sharma',
        ),
        // Doctor 2: 2 Paid (600 each = 1200), 1 Free Family
        Appointment(
          id: 'b1',
          patientPhone: '9876543213',
          patientName: 'Patient 4',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.paid,
          amountCollected: 600,
          queueNumber: 1,
          scheduledDate: today,
          doctorId: 'doc-2',
          doctorName: 'Dr. B. Das',
        ),
        Appointment(
          id: 'b2',
          patientPhone: '9876543214',
          patientName: 'Patient 5',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.paid,
          amountCollected: 600,
          queueNumber: 2,
          scheduledDate: today,
          doctorId: 'doc-2',
          doctorName: 'Dr. B. Das',
        ),
        Appointment(
          id: 'b3',
          patientPhone: '9876543215',
          patientName: 'Patient 6',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.freeFamily,
          amountCollected: 0,
          queueNumber: 3,
          scheduledDate: today,
          doctorId: 'doc-2',
          doctorName: 'Dr. B. Das',
        ),
      ];

      final summary = RevenueEngine.calculateCashHandover(
        appointments: appts,
        date: today,
      );

      // Global totals
      expect(summary.totalAppointments, 6);
      expect(summary.totalCompleted, 5);
      expect(summary.totalRealizedCash, 1700); // 500 + 600 + 600
      expect(summary.totalPaidCount, 3);
      expect(summary.totalFreeReviewCount, 1);
      expect(summary.totalFreeFamilyCount, 1);

      // Doctor breakdown
      expect(summary.doctorBreakdown.length, 2);

      final doc1 = summary.doctorBreakdown.firstWhere((d) => d.doctorId == 'doc-1');
      expect(doc1.doctorName, 'Dr. A. Sharma');
      expect(doc1.completedCount, 2);
      expect(doc1.paidCount, 1);
      expect(doc1.freeReviewCount, 1);
      expect(doc1.cashCollected, 500);

      final doc2 = summary.doctorBreakdown.firstWhere((d) => d.doctorId == 'doc-2');
      expect(doc2.doctorName, 'Dr. B. Das');
      expect(doc2.completedCount, 3);
      expect(doc2.paidCount, 2);
      expect(doc2.freeFamilyCount, 1);
      expect(doc2.cashCollected, 1200);
    });

    test('calculateDenominationTotal sums Indian currency notes accurately', () {
      final counts = {
        500: 4,  // 2000
        200: 5,  // 1000
        100: 10, // 1000
        50: 2,   // 100
        20: 5,   // 100
        10: 10,  // 100
      };

      final total = RevenueEngine.calculateDenominationTotal(counts);
      expect(total, 4300);
    });

    test('calculateDiscrepancy correctly identifies balance, shortage, and surplus', () {
      // Balanced
      expect(RevenueEngine.calculateDiscrepancy(physicalCounted: 3500, expectedCash: 3500), 0);

      // Shortage
      expect(RevenueEngine.calculateDiscrepancy(physicalCounted: 3300, expectedCash: 3500), -200);

      // Surplus
      expect(RevenueEngine.calculateDiscrepancy(physicalCounted: 3700, expectedCash: 3500), 200);
    });
  });
}
