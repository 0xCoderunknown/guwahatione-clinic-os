
import 'package:flutter_test/flutter_test.dart';
import 'package:appointment_app/models/appointment.dart';
import 'package:appointment_app/models/doctor.dart';
import 'package:appointment_app/models/patient_review_eligibility.dart';

void main() {
  group('Appointment Model Audit Tests', () {
    test('Appointment initializes with absent status and payment types', () {
      final appt = Appointment(
        id: 'appt-1',
        patientPhone: '9876543210',
        patientName: 'Test Patient',
        status: AppointmentStatus.pending,
        paymentType: PaymentType.paid,
        amountCollected: 500,
        queueNumber: 1,
        scheduledDate: DateTime(2026, 10, 5),
        doctorId: 'doc-1',
        doctorName: 'Dr. Baruah',
      );

      expect(appt.status, AppointmentStatus.pending);
      expect(appt.paymentType, PaymentType.paid);
      expect(appt.amountCollected, 500);
      expect(appt.queueNumber, 1);
    });

    test('Appointment serializes and deserializes with Firestore Timestamp', () {
      final now = DateTime(2026, 10, 5, 10, 0);
      final original = Appointment(
        id: 'appt-timestamp',
        patientPhone: '9876543210',
        patientName: 'Native Patient',
        status: AppointmentStatus.absent,
        paymentType: PaymentType.paid,
        amountCollected: 0,
        queueNumber: 4,
        scheduledDate: now,
        doctorId: 'doc-1',
        doctorName: 'Dr. Baruah',
      );

      final json = original.toJson();
      final fromJson = Appointment.fromJson(json);

      expect(fromJson.status, AppointmentStatus.absent);
      expect(fromJson.status.displayName, 'Absent');
      expect(fromJson.scheduledDate, now);
    });

    test('Doctor model includes PIN and consultation fee', () {
      final doctor = Doctor(
        id: 'doc-1',
        name: 'Dr. Sharma',
        specialty: 'Cardiology',
        phone: '9876543210',
        availableDays: ['Mon', 'Wed', 'Fri'],
        blockedDates: [],
        pin: '4321',
        consultationFee: 700,
      );

      expect(doctor.pin, '4321');
      expect(doctor.consultationFee, 700);

      final json = doctor.toJson();
      final fromJsonDoc = Doctor.fromJson(json);
      expect(fromJsonDoc.pin, '4321');
      expect(fromJsonDoc.consultationFee, 700);
    });
  });

  group('Free Review 14-Day & Same Doctor Business Rule Tests', () {
    final doc1 = 'doc-baruah';
    final doc2 = 'doc-sharma';
    final today = DateTime(2026, 10, 20);

    test('Patient who never visited has no free review eligibility', () {
      final eligibility = PatientReviewEligibility.calculate(
        appointments: [],
        doctorId: doc1,
        targetDate: today,
        doctorName: 'Dr. Baruah',
      );

      expect(eligibility.hasVisitedDoctorEarlier, isFalse);
      expect(eligibility.isWithin14Days, isFalse);
    });

    test('Patient who visited a DIFFERENT doctor cannot get free review', () {
      final appts = [
        Appointment(
          id: 'appt-1',
          patientPhone: '9876543210',
          patientName: 'Test Patient',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.paid,
          amountCollected: 500,
          queueNumber: 1,
          scheduledDate: DateTime(2026, 10, 15), // 5 days ago
          doctorId: doc2, // Different doctor!
          doctorName: 'Dr. Sharma',
        ),
      ];

      final eligibility = PatientReviewEligibility.calculate(
        appointments: appts,
        doctorId: doc1, // Booking with Dr. Baruah
        targetDate: today,
        doctorName: 'Dr. Baruah',
      );

      expect(eligibility.hasVisitedDoctorEarlier, isFalse);
      expect(eligibility.isWithin14Days, isFalse);
    });

    test('Patient who visited SAME doctor within 14 days is eligible', () {
      final appts = [
        Appointment(
          id: 'appt-1',
          patientPhone: '9876543210',
          patientName: 'Test Patient',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.paid,
          amountCollected: 500,
          queueNumber: 1,
          scheduledDate: DateTime(2026, 10, 10), // 10 days ago
          doctorId: doc1,
          doctorName: 'Dr. Baruah',
        ),
      ];

      final eligibility = PatientReviewEligibility.calculate(
        appointments: appts,
        doctorId: doc1,
        targetDate: today,
        doctorName: 'Dr. Baruah',
      );

      expect(eligibility.hasVisitedDoctorEarlier, isTrue);
      expect(eligibility.isWithin14Days, isTrue);
      expect(eligibility.daysSinceLastVisit, 10);
    });

    test('Patient who visited exactly 14 days ago is eligible (boundary test)', () {
      final appts = [
        Appointment(
          id: 'appt-1',
          patientPhone: '9876543210',
          patientName: 'Test Patient',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.paid,
          amountCollected: 500,
          queueNumber: 1,
          scheduledDate: DateTime(2026, 10, 6), // exactly 14 days before Oct 20
          doctorId: doc1,
          doctorName: 'Dr. Baruah',
        ),
      ];

      final eligibility = PatientReviewEligibility.calculate(
        appointments: appts,
        doctorId: doc1,
        targetDate: today,
        doctorName: 'Dr. Baruah',
      );

      expect(eligibility.hasVisitedDoctorEarlier, isTrue);
      expect(eligibility.isWithin14Days, isTrue);
      expect(eligibility.daysSinceLastVisit, 14);
    });

    test('Patient who visited 15 days ago has hasVisitedDoctorEarlier=true but isWithin14Days=false (triggers warning, not disabled)', () {
      final appts = [
        Appointment(
          id: 'appt-1',
          patientPhone: '9876543210',
          patientName: 'Test Patient',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.paid,
          amountCollected: 500,
          queueNumber: 1,
          scheduledDate: DateTime(2026, 10, 5), // 15 days before Oct 20
          doctorId: doc1,
          doctorName: 'Dr. Baruah',
        ),
      ];

      final eligibility = PatientReviewEligibility.calculate(
        appointments: appts,
        doctorId: doc1,
        targetDate: today,
        doctorName: 'Dr. Baruah',
      );

      // Must allow UI to see they visited earlier (so option is NOT disabled),
      // but warn that 14 days has passed.
      expect(eligibility.hasVisitedDoctorEarlier, isTrue);
      expect(eligibility.isWithin14Days, isFalse);
      expect(eligibility.daysSinceLastVisit, 15);
    });

    test('Absent past appointments do not count as previous visits', () {
      final appts = [
        Appointment(
          id: 'appt-1',
          patientPhone: '9876543210',
          patientName: 'Test Patient',
          status: AppointmentStatus.absent,
          paymentType: PaymentType.paid,
          amountCollected: 0,
          queueNumber: 1,
          scheduledDate: DateTime(2026, 10, 15),
          doctorId: doc1,
          doctorName: 'Dr. Baruah',
        ),
      ];

      final eligibility = PatientReviewEligibility.calculate(
        appointments: appts,
        doctorId: doc1,
        targetDate: today,
        doctorName: 'Dr. Baruah',
      );

      expect(eligibility.hasVisitedDoctorEarlier, isFalse);
      expect(eligibility.isWithin14Days, isFalse);
    });
  });
}
