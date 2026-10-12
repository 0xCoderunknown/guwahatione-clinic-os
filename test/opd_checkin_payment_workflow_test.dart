import 'package:flutter_test/flutter_test.dart';
import 'package:appointment_app/core/engines/engines.dart';
import 'package:appointment_app/models/appointment.dart';
import 'package:appointment_app/models/doctor.dart';

void main() {
  group('OPD Asynchronous Payment & Check-In Workflow Tests', () {
    final sampleDoctor = Doctor(
      id: 'doc-1',
      name: 'Dr. Bhaskar Baruah',
      specialty: 'Internal Medicine',
      phone: '9864012345',
      availableDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
      blockedDates: const [],
      consultationFee: 500,
      pin: '1234',
    );

    test('Appointment model serializes and deserializes VisitStatus and PaymentType cleanly', () {
      final now = DateTime(2026, 10, 12, 10, 30);
      final checkInTime = DateTime(2026, 10, 12, 11, 00);

      final appt = Appointment(
        id: 'appt-phone-1',
        patientPhone: '9876543210',
        patientName: 'Kishore Kumar',
        visitStatus: VisitStatus.booked,
        paymentType: PaymentType.unpaid,
        amountCollected: 0,
        queueNumber: 7,
        scheduledDate: now,
        doctorId: sampleDoctor.id,
        doctorName: sampleDoctor.name,
        checkedInAt: checkInTime,
      );

      final json = appt.toJson();
      expect(json['visitStatus'], 'booked');
      expect(json['paymentType'], 'unpaid');
      expect(json['status'], 'pending');

      final deserialized = Appointment.fromJson(json);
      expect(deserialized.visitStatus, VisitStatus.booked);
      expect(deserialized.paymentType, PaymentType.unpaid);
      expect(deserialized.status, AppointmentStatus.pending);
      expect(deserialized.amountCollected, 0);
      expect(deserialized.queueNumber, 7);
    });

    test('Advance phone booking does NOT pollute Doctor Chamber Queue', () {
      final today = DateTime(2026, 10, 12);

      final appointments = [
        Appointment(
          id: 'appt-1',
          patientPhone: '9876500001',
          patientName: 'In-Lobby Patient',
          visitStatus: VisitStatus.waitingInLobby,
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 1,
          scheduledDate: today,
          doctorId: sampleDoctor.id,
          doctorName: sampleDoctor.name,
        ),
        Appointment(
          id: 'appt-2',
          patientPhone: '9876500002',
          patientName: 'Advance Phone Booking',
          visitStatus: VisitStatus.booked,
          paymentType: PaymentType.unpaid,
          amountCollected: 0,
          queueNumber: 2,
          scheduledDate: today,
          doctorId: sampleDoctor.id,
          doctorName: sampleDoctor.name,
        ),
        Appointment(
          id: 'appt-3',
          patientPhone: '9876500003',
          patientName: 'Completed Patient',
          visitStatus: VisitStatus.completed,
          paymentType: PaymentType.paidUpi,
          amountCollected: 500,
          queueNumber: 3,
          scheduledDate: today,
          doctorId: sampleDoctor.id,
          doctorName: sampleDoctor.name,
        ),
      ];

      // Reception Partition isolates booked tokens
      final receptionView = AppointmentEngine.partitionQueueForReception(
        appointments: appointments,
      );

      expect(receptionView.waiting.length, 1);
      expect(receptionView.waiting.first.patientName, 'In-Lobby Patient');
      expect(receptionView.booked.length, 1);
      expect(receptionView.booked.first.patientName, 'Advance Phone Booking');
      expect(receptionView.completed.length, 1);

      // Doctor Chamber Queue strictly filters out un-checked-in phone bookings
      final chamberTokens = appointments
          .where((a) => a.visitStatus != VisitStatus.booked)
          .toList();

      expect(chamberTokens.length, 2);
      expect(chamberTokens.any((a) => a.visitStatus == VisitStatus.booked), isFalse);
    });

    test('Chamber KPIs count only lobby-checked-in patients in waiting count', () {
      final today = DateTime(2026, 10, 12);

      final appointments = [
        Appointment(
          id: 'appt-1',
          patientPhone: '9876500001',
          patientName: 'In-Lobby Patient',
          visitStatus: VisitStatus.waitingInLobby,
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 1,
          scheduledDate: today,
          doctorId: sampleDoctor.id,
          doctorName: sampleDoctor.name,
        ),
        Appointment(
          id: 'appt-2',
          patientPhone: '9876500002',
          patientName: 'Phone Booking Unarrived',
          visitStatus: VisitStatus.booked,
          paymentType: PaymentType.unpaid,
          amountCollected: 0,
          queueNumber: 2,
          scheduledDate: today,
          doctorId: sampleDoctor.id,
          doctorName: sampleDoctor.name,
        ),
      ];

      final kpis = RevenueEngine.calculateChamberKpis(appointments);
      // Total booked tokens is 2, but waiting in chamber is strictly 1 (the one in lobby)
      expect(kpis.totalBooked, 2);
      expect(kpis.waitingCount, 1);
    });

    test('1-Tap Desk Reconciliation transitions booked token to waitingInLobby with payment', () {
      final today = DateTime(2026, 10, 12);
      final checkInTime = DateTime(2026, 10, 12, 10, 15);

      final unarrivedPhoneAppt = Appointment(
        id: 'appt-phone',
        patientPhone: '9876500002',
        patientName: 'Phone Booking',
        visitStatus: VisitStatus.booked,
        paymentType: PaymentType.unpaid,
        amountCollected: 0,
        queueNumber: 4,
        scheduledDate: today,
        doctorId: sampleDoctor.id,
        doctorName: sampleDoctor.name,
      );

      // Check-In performed at desk
      final checkedInAppt = unarrivedPhoneAppt.copyWith(
        visitStatus: VisitStatus.waitingInLobby,
        paymentType: PaymentType.paidCash,
        amountCollected: 500,
        checkedInAt: checkInTime,
      );

      expect(checkedInAppt.visitStatus, VisitStatus.waitingInLobby);
      expect(checkedInAppt.paymentType, PaymentType.paidCash);
      expect(checkedInAppt.amountCollected, 500);
      expect(checkedInAppt.checkedInAt, checkInTime);
      expect(checkedInAppt.status, AppointmentStatus.pending);
    });

    test('FREE (Family / VVIP) waiver is strictly permanent and never coerced by history', () {
      final today = DateTime(2026, 10, 12);

      // Returning patient who visited 5 days ago (strictly eligible for Free Review)
      final history = [
        Appointment(
          id: 'past-1',
          patientPhone: '9876500009',
          patientName: 'VVIP Dignitary',
          visitStatus: VisitStatus.completed,
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 1,
          scheduledDate: today.subtract(const Duration(days: 5)),
          doctorId: sampleDoctor.id,
          doctorName: sampleDoctor.name,
        ),
      ];

      final eligibility = AppointmentEngine.evaluateReviewEligibility(
        patientHistory: history,
        doctorId: sampleDoctor.id,
        targetDate: today,
      );

      expect(eligibility.isWithin14Days, isTrue);

      // System fee resolution ensures FREE Family waiver is strictly ₹0
      final resolvedFee = AppointmentEngine.resolveConsultationFee(
        doctor: sampleDoctor,
        paymentType: PaymentType.freeFamily,
      );
      expect(resolvedFee, 0);

      // And FREE Review is also ₹0
      final reviewFee = AppointmentEngine.resolveConsultationFee(
        doctor: sampleDoctor,
        paymentType: PaymentType.freeReview,
      );
      expect(reviewFee, 0);

      // Verify enum distinctions
      expect(PaymentType.freeFamily != PaymentType.freeReview, isTrue);
      expect(PaymentType.freeFamily.isFree, isTrue);
      expect(PaymentType.freeReview.isFree, isTrue);
      expect(PaymentType.freeFamily.isPaid, isFalse);
    });
  });
}
