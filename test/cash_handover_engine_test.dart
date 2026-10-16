import 'package:appointment_app/core/engines/engines.dart';
import 'package:appointment_app/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CashHandoverEngine - Daily Cash Handover Tests (P8)', () {
    final today = DateTime(2026, 10, 12);

    test('Empty appointments list generates zero-cash handover summary', () {
      final summary = CashHandoverEngine.calculateCashHandover(
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
          paymentType: PaymentType.paidCash,
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
          paymentType: PaymentType.paidCash,
          amountCollected: 0,
          queueNumber: 2,
          scheduledDate: today,
          doctorId: 'doc-1',
          doctorName: 'Dr. A. Sharma',
        ),
      ];

      final summary = CashHandoverEngine.calculateCashHandover(
        appointments: appts,
        date: today,
      );

      expect(summary.totalAppointments, 2);
      expect(summary.totalCompleted, 0);
      expect(summary.totalRealizedCash, 0);
      expect(summary.doctorBreakdown.first.cashCollected, 0);
    });

    test('Accurately tallies Paid Cash, UPI, Free Review, and Free Family by doctor', () {
      final appts = [
        // Doctor 1: 1 Paid, 1 Free Review, 1 Pending (ignored)
        Appointment(
          id: 'a1',
          patientPhone: '9876543210',
          patientName: 'Paid Patient 1',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 1,
          scheduledDate: today,
          doctorId: 'doc-1',
          doctorName: 'Dr. A. Sharma',
        ),
        Appointment(
          id: 'a2',
          patientPhone: '9876543211',
          patientName: 'Review Patient',
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
          patientName: 'Pending Patient',
          status: AppointmentStatus.pending,
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 3,
          scheduledDate: today,
          doctorId: 'doc-1',
          doctorName: 'Dr. A. Sharma',
        ),

        // Doctor 2: 2 Paid (Cash + UPI), 1 Free Family (VVIP)
        Appointment(
          id: 'b1',
          patientPhone: '9876543220',
          patientName: 'Paid Cash 2',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.paidCash,
          amountCollected: 600,
          queueNumber: 1,
          scheduledDate: today,
          doctorId: 'doc-2',
          doctorName: 'Dr. B. Das',
        ),
        Appointment(
          id: 'b2',
          patientPhone: '9876543221',
          patientName: 'Paid UPI 1',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.paidUpi,
          amountCollected: 600,
          queueNumber: 2,
          scheduledDate: today,
          doctorId: 'doc-2',
          doctorName: 'Dr. B. Das',
        ),
        Appointment(
          id: 'b3',
          patientPhone: '9876543222',
          patientName: 'Courtesy Family Patient',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.freeFamily,
          amountCollected: 0,
          queueNumber: 3,
          scheduledDate: today,
          doctorId: 'doc-2',
          doctorName: 'Dr. B. Das',
        ),
      ];

      final summary = CashHandoverEngine.calculateCashHandover(
        appointments: appts,
        date: today,
      );

      // Overall totals (Cash vs UPI Segregation)
      expect(summary.totalAppointments, 6);
      expect(summary.totalCompleted, 5);
      expect(summary.totalPhysicalCash, 1100); // 500 (doc1) + 600 (doc2 cash)
      expect(summary.totalUpiRevenue, 600); // 600 (doc2 upi)
      expect(summary.totalRevenue, 1700); // 1100 cash + 600 upi
      expect(
        summary.totalRealizedCash,
        1100,
      ); // Drawer reconciliation evaluates physical cash
      expect(summary.totalPaidCount, 3);
      expect(summary.totalFreeReviewCount, 1);
      expect(summary.totalFreeFamilyCount, 1);

      // Doctor breakdown
      expect(summary.doctorBreakdown.length, 2);

      final doc1 = summary.doctorBreakdown.firstWhere(
        (d) => d.doctorId == 'doc-1',
      );
      expect(doc1.doctorName, 'Dr. A. Sharma');
      expect(doc1.completedCount, 2);
      expect(doc1.paidCount, 1);
      expect(doc1.freeReviewCount, 1);
      expect(doc1.cashCollected, 500);
      expect(doc1.upiCollected, 0);
      expect(doc1.totalRevenue, 500);

      final doc2 = summary.doctorBreakdown.firstWhere(
        (d) => d.doctorId == 'doc-2',
      );
      expect(doc2.doctorName, 'Dr. B. Das');
      expect(doc2.completedCount, 3);
      expect(doc2.paidCount, 2);
      expect(doc2.freeFamilyCount, 1);
      expect(doc2.cashCollected, 600);
      expect(doc2.upiCollected, 600);
      expect(doc2.totalRevenue, 1200);

      // Drawer discrepancy matches physical notes without UPI false deficit
      final drawerDiscrepancy = CashHandoverEngine.calculateDiscrepancy(
        physicalCounted: 1100,
        expectedCash: summary.totalPhysicalCash,
      );
      expect(drawerDiscrepancy, 0); // Perfectly balanced drawer
    });

    test(
      'calculateDenominationTotal sums Indian currency notes accurately',
      () {
        final counts = {
          500: 4, // 2000
          200: 5, // 1000
          100: 10, // 1000
          50: 2, // 100
          20: 5, // 100
          10: 10, // 100
        };

        final total = CashHandoverEngine.calculateDenominationTotal(counts);
        expect(total, 4300);
      },
    );

    test('calculateDiscrepancy correctly identifies balance, shortage, and surplus', () {
      // Balanced
      expect(
        CashHandoverEngine.calculateDiscrepancy(
          physicalCounted: 3500,
          expectedCash: 3500,
        ),
        0,
      );

      // Shortage
      expect(
        CashHandoverEngine.calculateDiscrepancy(
          physicalCounted: 3300,
          expectedCash: 3500,
        ),
        -200,
      );

      // Surplus
      expect(
        CashHandoverEngine.calculateDiscrepancy(
          physicalCounted: 3700,
          expectedCash: 3500,
        ),
        200,
      );
    });
  });
}
