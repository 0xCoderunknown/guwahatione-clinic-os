import 'package:appointment_app/core/engines/engines.dart';
import 'package:appointment_app/models/models.dart';
import 'package:appointment_app/widgets/booking/booking_carry_over_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QOL-03: Prepaid Carry-Over & Patient No-Show Engine Tests', () {
    final today = DateTime(2026, 10, 22);
    final yesterday = DateTime(2026, 10, 21);
    final lastWeek = DateTime(2026, 10, 15);
    final twoMonthsAgo = DateTime(2026, 8, 1);

    test('findEligibleCarryOverAppointment returns most recent un-consulted paid appointment', () {
      final history = [
        // Old eligible visit
        Appointment(
          id: 'appt_old',
          patientId: 'pat_1',
          patientPhone: '9876543210',
          patientName: 'Rahul Das',
          status: AppointmentStatus.absent,
          visitStatus: VisitStatus.cancelled,
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 4,
          scheduledDate: lastWeek,
          doctorId: 'doc_1',
          doctorName: 'Dr. Sharma',
        ),
        // Yesterday's eligible visit (more recent)
        Appointment(
          id: 'appt_yesterday',
          patientId: 'pat_1',
          patientPhone: '9876543210',
          patientName: 'Rahul Das',
          status: AppointmentStatus.absent,
          visitStatus: VisitStatus.cancelled,
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 12,
          scheduledDate: yesterday,
          doctorId: 'doc_1',
          doctorName: 'Dr. Sharma',
        ),
      ];

      final result = AppointmentEngine.findEligibleCarryOverAppointment(
        patientHistory: history,
        doctorId: 'doc_1',
        targetDate: today,
        patientId: 'pat_1',
        patientName: 'Rahul Das',
      );

      expect(result, isNotNull);
      expect(result!.id, 'appt_yesterday');
      expect(result.queueNumber, 12);
      expect(result.amountCollected, 500);
    });

    test('findEligibleCarryOverAppointment excludes completed visits', () {
      final history = [
        Appointment(
          id: 'appt_completed',
          patientId: 'pat_1',
          patientPhone: '9876543210',
          patientName: 'Rahul Das',
          status: AppointmentStatus.completed,
          visitStatus: VisitStatus.completed,
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 2,
          scheduledDate: yesterday,
          doctorId: 'doc_1',
          doctorName: 'Dr. Sharma',
        ),
      ];

      final result = AppointmentEngine.findEligibleCarryOverAppointment(
        patientHistory: history,
        doctorId: 'doc_1',
        targetDate: today,
        patientId: 'pat_1',
      );

      expect(result, isNull);
    });

    test('findEligibleCarryOverAppointment excludes refunded and already carried-forward visits', () {
      final history = [
        Appointment(
          id: 'appt_refunded',
          patientId: 'pat_1',
          patientPhone: '9876543210',
          patientName: 'Rahul Das',
          status: AppointmentStatus.absent,
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 3,
          scheduledDate: yesterday,
          doctorId: 'doc_1',
          doctorName: 'Dr. Sharma',
          refundStatus: 'refunded',
        ),
        Appointment(
          id: 'appt_carried',
          patientId: 'pat_1',
          patientPhone: '9876543210',
          patientName: 'Rahul Das',
          status: AppointmentStatus.absent,
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 4,
          scheduledDate: yesterday,
          doctorId: 'doc_1',
          doctorName: 'Dr. Sharma',
          refundStatus: 'carried_forward',
        ),
      ];

      final result = AppointmentEngine.findEligibleCarryOverAppointment(
        patientHistory: history,
        doctorId: 'doc_1',
        targetDate: today,
        patientId: 'pat_1',
      );

      expect(result, isNull);
    });

    test('findEligibleCarryOverAppointment excludes visits exceeding validity window', () {
      final history = [
        Appointment(
          id: 'appt_too_old',
          patientId: 'pat_1',
          patientPhone: '9876543210',
          patientName: 'Rahul Das',
          status: AppointmentStatus.absent,
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 1,
          scheduledDate: twoMonthsAgo,
          doctorId: 'doc_1',
          doctorName: 'Dr. Sharma',
        ),
      ];

      final result = AppointmentEngine.findEligibleCarryOverAppointment(
        patientHistory: history,
        doctorId: 'doc_1',
        targetDate: today,
        patientId: 'pat_1',
        validityDays: 30,
      );

      expect(result, isNull);
    });

    test('findEligibleCarryOverAppointment ignores different doctor appointments', () {
      final history = [
        Appointment(
          id: 'appt_other_doc',
          patientId: 'pat_1',
          patientPhone: '9876543210',
          patientName: 'Rahul Das',
          status: AppointmentStatus.absent,
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 5,
          scheduledDate: yesterday,
          doctorId: 'doc_other',
          doctorName: 'Dr. Baruah',
        ),
      ];

      final result = AppointmentEngine.findEligibleCarryOverAppointment(
        patientHistory: history,
        doctorId: 'doc_1',
        targetDate: today,
        patientId: 'pat_1',
      );

      expect(result, isNull);
    });

    test('resolveConsultationFee returns 0 for PaymentType.paidCarryOver', () {
      final doc = Doctor(
        id: 'doc_1',
        name: 'Dr. Sharma',
        specialty: 'Medicine',
        phone: '9876543210',
        availableDays: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
        blockedDates: const [],
        consultationFee: 700,
      );

      final fee = AppointmentEngine.resolveConsultationFee(
        doctor: doc,
        paymentType: PaymentType.paidCarryOver,
      );
      expect(fee, 0);
    });
  });

  group('QOL-03: CashHandoverEngine & RevenueEngine Ledger Math Tests', () {
    final today = DateTime(2026, 10, 22);
    final yesterday = DateTime(2026, 10, 21);

    test('CashHandoverEngine: paidCarryOver visit counts as paid patient but ₹0 cash in drawer', () {
      final appts = [
        // Standard cash patient today
        Appointment(
          id: 'a1',
          patientPhone: '9000000001',
          patientName: 'Patient 1',
          status: AppointmentStatus.completed,
          visitStatus: VisitStatus.completed,
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 1,
          scheduledDate: today,
          doctorId: 'doc_1',
          doctorName: 'Dr. Sharma',
        ),
        // Paid Carry-Over patient today (paid ₹500 yesterday)
        Appointment(
          id: 'a2',
          patientPhone: '9000000002',
          patientName: 'Patient 2',
          status: AppointmentStatus.completed,
          visitStatus: VisitStatus.completed,
          paymentType: PaymentType.paidCarryOver,
          amountCollected: 0,
          carriedOverAmount: 500,
          carriedOverAppointmentId: 'appt_yday_12',
          carriedOverDate: yesterday,
          queueNumber: 2,
          scheduledDate: today,
          doctorId: 'doc_1',
          doctorName: 'Dr. Sharma',
        ),
      ];

      final handover = CashHandoverEngine.calculateCashHandover(
        appointments: appts,
        date: today,
      );

      // Both are paid patients
      expect(handover.totalPaidCount, 2);
      expect(handover.totalCompleted, 2);

      // But drawer only contains cash collected TODAY (₹500 from Patient 1)
      expect(handover.totalPhysicalCash, 500);
      expect(handover.totalRealizedCash, 500);
      expect(handover.totalRevenue, 500);

      final docRow = handover.doctorBreakdown.first;
      expect(docRow.paidCount, 2);
      expect(docRow.cashCollected, 500);
    });

    test('RevenueEngine: calculateDoctorTotalFees & calculateRealizedRevenue attribute carriedOverAmount', () {
      final appts = [
        // Paid Carry-Over patient completed today
        Appointment(
          id: 'a2',
          patientPhone: '9000000002',
          patientName: 'Patient 2',
          status: AppointmentStatus.completed,
          visitStatus: VisitStatus.completed,
          paymentType: PaymentType.paidCarryOver,
          amountCollected: 0,
          carriedOverAmount: 600,
          carriedOverAppointmentId: 'orig_1',
          queueNumber: 1,
          scheduledDate: today,
          doctorId: 'doc_1',
          doctorName: 'Dr. Sharma',
        ),
      ];

      // Effective fee earned by doctor
      expect(appts.first.effectiveFee, 600);

      final realizedRevenue = RevenueEngine.calculateRealizedRevenue(appts);
      expect(realizedRevenue, 600);

      final doctorFees = RevenueEngine.calculateDoctorTotalFees(appts);
      expect(doctorFees, 600);

      // 70% doctor share payout
      final payout = RevenueEngine.calculateDoctorPayout(
        totalDoctorFees: doctorFees,
        doctorSharePercentage: 70,
      );
      expect(payout, 420);

      final chamberKpis = RevenueEngine.calculateChamberKpis(appts);
      expect(chamberKpis.paidCount, 1);
      expect(chamberKpis.totalDoctorFees, 600);
    });
  });

  group('QOL-03: BookingCarryOverBanner Widget Tests', () {
    final priorAppt = Appointment(
      id: 'appt_prior_1',
      patientPhone: '9876543210',
      patientName: 'Anup Bordoloi',
      status: AppointmentStatus.absent,
      paymentType: PaymentType.paidCash,
      amountCollected: 500,
      queueNumber: 7,
      scheduledDate: DateTime(2026, 10, 21),
      doctorId: 'doc_1',
      doctorName: 'Dr. Pritisha Sharma',
    );

    testWidgets('renders eligible carry-over banner and triggers onApply', (tester) async {
      bool applied = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingCarryOverBanner(
              eligibleAppointment: priorAppt,
              isApplied: false,
              onApply: () => applied = true,
              onUndo: () {},
            ),
          ),
        ),
      );

      expect(find.text('Prepaid Carry-Over Available'), findsOneWidget);
      expect(find.textContaining('Token #7'), findsOneWidget);
      expect(find.textContaining('₹500'), findsOneWidget);

      await tester.tap(find.text('Apply (₹0 Today)'));
      await tester.pump();

      expect(applied, isTrue);
    });

    testWidgets('renders applied state and triggers onUndo', (tester) async {
      bool undone = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingCarryOverBanner(
              eligibleAppointment: priorAppt,
              isApplied: true,
              onApply: () {},
              onUndo: () => undone = true,
            ),
          ),
        ),
      );

      expect(find.text('Prepaid Carry-Over Applied'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pump();

      expect(undone, isTrue);
    });
  });
}
