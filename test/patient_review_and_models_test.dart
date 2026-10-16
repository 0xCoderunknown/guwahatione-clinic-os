import 'package:appointment_app/core/engines/engines.dart';
import 'package:appointment_app/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Appointment & Doctor Model Serialization Audit Tests', () {
    test('Appointment initializes with absent status and payment types', () {
      final appt = Appointment(
        id: 'appt-1',
        patientPhone: '9876543210',
        patientName: 'Test Patient',
        status: AppointmentStatus.pending,
        paymentType: PaymentType.paidCash,
        amountCollected: 500,
        queueNumber: 1,
        scheduledDate: DateTime(2026, 10, 5),
        doctorId: 'doc-1',
        doctorName: 'Dr. Baruah',
      );

      expect(appt.status, AppointmentStatus.pending);
      expect(appt.paymentType, PaymentType.paidCash);
      expect(appt.amountCollected, 500);
      expect(appt.queueNumber, 1);
    });

    test(
      'Appointment serializes and deserializes with Firestore Timestamp',
      () {
        final now = DateTime(2026, 10, 5, 10, 0);
        final original = Appointment(
          id: 'appt-timestamp',
          patientPhone: '9876543210',
          patientName: 'Native Patient',
          status: AppointmentStatus.absent,
          paymentType: PaymentType.paidCash,
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
      },
    );

    test('Appointment.fromJson reconciles stale visitStatus when status is completed', () {
      final rawMap = {
        'id': 'appt-drift-test',
        'patientPhone': '9876543210',
        'patientName': 'Stale Patient',
        'status': 'completed',
        'visitStatus': 'inConsultation', // Stale un-updated field
        'paymentType': 'paidCash',
        'amountCollected': 500,
        'queueNumber': 5,
        'scheduledDate': DateTime(2026, 10, 5),
        'doctorId': 'doc-1',
        'doctorName': 'Dr. Baruah',
      };

      final appt = Appointment.fromJson(rawMap);
      expect(appt.visitStatus, VisitStatus.completed);
      expect(appt.status, AppointmentStatus.completed);
    });

    test(
      'Appointment.fromJson reconciles stale visitStatus when status is absent',
      () {
        final rawMap = {
          'id': 'appt-drift-absent',
          'patientPhone': '9876543210',
          'patientName': 'No-Show Patient',
          'status': 'absent',
          'visitStatus': 'waitingInLobby', // Stale field
          'paymentType': 'paidCash',
          'amountCollected': 0,
          'queueNumber': 6,
          'scheduledDate': DateTime(2026, 10, 5),
          'doctorId': 'doc-1',
          'doctorName': 'Dr. Baruah',
        };

        final appt = Appointment.fromJson(rawMap);
        expect(appt.visitStatus, VisitStatus.cancelled);
        expect(appt.status, AppointmentStatus.absent);
      },
    );

    test('Appointment.toJson emits synchronized status and visitStatus', () {
      final appt = Appointment(
        id: 'appt-sync',
        patientPhone: '9876543210',
        patientName: 'Sync Patient',
        visitStatus: VisitStatus.completed,
        paymentType: PaymentType.paidCash,
        amountCollected: 500,
        queueNumber: 7,
        scheduledDate: DateTime(2026, 10, 5),
        doctorId: 'doc-1',
        doctorName: 'Dr. Baruah',
      );

      final json = appt.toJson();
      expect(json['visitStatus'], 'completed');
      expect(json['status'], 'completed');
    });

    test('Doctor model includes PIN, consultation fee, freeReviewDays, and medicalRegNumber', () {
      final doctor = Doctor(
        id: 'doc-1',
        name: 'Dr. Sharma',
        specialty: 'Cardiology',
        phone: '9876543210',
        availableDays: ['Mon', 'Wed', 'Fri'],
        blockedDates: [],
        pin: '4321',
        consultationFee: 700,
        freeReviewDays: 30,
        medicalRegNumber: 'AMC-24891',
      );

      expect(doctor.pin, '4321');
      expect(doctor.consultationFee, 700);
      expect(doctor.freeReviewDays, 30);
      expect(doctor.medicalRegNumber, 'AMC-24891');

      final json = doctor.toJson();
      expect(json['freeReviewDays'], 30);
      final fromJsonDoc = Doctor.fromJson(json);
      expect(fromJsonDoc.pin, '4321');
      expect(fromJsonDoc.consultationFee, 700);
      expect(fromJsonDoc.freeReviewDays, 30);
      expect(fromJsonDoc.medicalRegNumber, 'AMC-24891');
    });

    test('Doctor copyWith updates fields correctly while retaining id and unedited properties', () {
      final doctor = Doctor(
        id: 'doc-1',
        name: 'Dr. Sharma',
        specialty: 'Cardiology',
        phone: '9876543210',
        availableDays: ['Mon', 'Wed', 'Fri'],
        blockedDates: [],
        pin: '4321',
        consultationFee: 700,
        freeReviewDays: 14,
        searchPreference: 'brandFirst',
        medicalRegNumber: 'AMC-24891',
      );

      final updated = doctor.copyWith(
        name: 'Dr. A. Sharma',
        specialty: 'Senior Cardiologist',
        consultationFee: 800,
        freeReviewDays: 0,
        pin: '9999',
        availableDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
        medicalRegNumber: 'NMC-99999',
      );

      expect(updated.id, 'doc-1');
      expect(updated.name, 'Dr. A. Sharma');
      expect(updated.specialty, 'Senior Cardiologist');
      expect(updated.consultationFee, 800);
      expect(updated.freeReviewDays, 0);
      expect(updated.pin, '9999');
      expect(updated.availableDays, ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']);
      expect(updated.phone, '9876543210');
      expect(updated.searchPreference, 'brandFirst');
      expect(updated.medicalRegNumber, 'NMC-99999');
    });
  });

  group('Free Review 14-Day & Same Doctor Business Rule Tests', () {
    const doc1 = 'doc-baruah';
    const doc2 = 'doc-sharma';
    final today = DateTime(2026, 10, 20);

    test('Patient who never visited has no free review eligibility', () {
      final eligibility = PatientReviewEligibility.calculate(
        appointments: [],
        doctorId: doc1,
        targetDate: today,
        doctorName: 'Dr. Baruah',
      );

      expect(eligibility.hasVisitedDoctorEarlier, isFalse);
      expect(eligibility.isWithinReviewPeriod, isFalse);
    });

    test('Patient who visited a DIFFERENT doctor cannot get free review', () {
      final appts = [
        Appointment(
          id: 'appt-1',
          patientPhone: '9876543210',
          patientName: 'Test Patient',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 1,
          scheduledDate: DateTime(2026, 10, 15),
          // 5 days ago
          doctorId: doc2,
          // Different doctor!
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
      expect(eligibility.isWithinReviewPeriod, isFalse);
    });

    test('Patient who visited SAME doctor within 14 days is eligible', () {
      final appts = [
        Appointment(
          id: 'appt-1',
          patientPhone: '9876543210',
          patientName: 'Test Patient',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 1,
          scheduledDate: DateTime(2026, 10, 10),
          // 10 days ago
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
      expect(eligibility.isWithinReviewPeriod, isTrue);
      expect(eligibility.daysSinceLastVisit, 10);
    });

    test(
      'Patient who visited exactly 14 days ago is eligible (boundary test)',
      () {
        final appts = [
          Appointment(
            id: 'appt-1',
            patientPhone: '9876543210',
            patientName: 'Test Patient',
            status: AppointmentStatus.completed,
            paymentType: PaymentType.paidCash,
            amountCollected: 500,
            queueNumber: 1,
            scheduledDate: DateTime(2026, 10, 6),
            // exactly 14 days before Oct 20
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
        expect(eligibility.isWithinReviewPeriod, isTrue);
        expect(eligibility.daysSinceLastVisit, 14);
      },
    );

    test('Patient who visited 15 days ago has hasVisitedDoctorEarlier=true but isWithinReviewPeriod=false (triggers warning, not disabled)', () {
      final appts = [
        Appointment(
          id: 'appt-1',
          patientPhone: '9876543210',
          patientName: 'Test Patient',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 1,
          scheduledDate: DateTime(2026, 10, 5),
          // 15 days before Oct 20
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
      expect(eligibility.isWithinReviewPeriod, isFalse);
      expect(eligibility.daysSinceLastVisit, 15);
    });

    test('Absent past appointments do not count as previous visits', () {
      final appts = [
        Appointment(
          id: 'appt-1',
          patientPhone: '9876543210',
          patientName: 'Test Patient',
          status: AppointmentStatus.absent,
          paymentType: PaymentType.paidCash,
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
      expect(eligibility.isWithinReviewPeriod, isFalse);
    });

    test('Doctor with 0-day policy disallows free review even for recent returning patient', () {
      final appts = [
        Appointment(
          id: 'appt-1',
          patientPhone: '9876543210',
          patientName: 'Test Patient',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.paidCash,
          amountCollected: 1000,
          queueNumber: 1,
          scheduledDate: DateTime(2026, 10, 18),
          // 2 days ago
          doctorId: doc1,
          doctorName: 'Dr. Baruah',
        ),
      ];

      final eligibility = PatientReviewEligibility.calculate(
        appointments: appts,
        doctorId: doc1,
        targetDate: today,
        doctorName: 'Dr. Baruah',
        allowedReviewDays: 0, // No free reviews offered
      );

      expect(eligibility.hasVisitedDoctorEarlier, isTrue);
      expect(eligibility.allowedReviewDays, 0);
      expect(eligibility.isWithinReviewPeriod, isFalse);
      expect(eligibility.message, contains('does not offer free reviews'));

      final suggestedPayment = AppointmentEngine.suggestPaymentType(
        patientHistory: appts,
        doctorId: doc1,
        targetDate: today,
        freeReviewDays: 0,
      );
      expect(suggestedPayment, PaymentType.paidCash);
    });

    test('Doctor with 30-day policy allows free review up to 30 days and warns beyond 30 days', () {
      final appts = [
        Appointment(
          id: 'appt-1',
          patientPhone: '9876543210',
          patientName: 'Test Patient',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.paidCash,
          amountCollected: 800,
          queueNumber: 1,
          scheduledDate: DateTime(2026, 9, 25),
          // 25 days before Oct 20
          doctorId: doc1,
          doctorName: 'Dr. Baruah',
        ),
      ];

      // Test within 30-day window (25 days ago)
      final eligible30 = PatientReviewEligibility.calculate(
        appointments: appts,
        doctorId: doc1,
        targetDate: today,
        doctorName: 'Dr. Baruah',
        allowedReviewDays: 30,
      );

      expect(eligible30.hasVisitedDoctorEarlier, isTrue);
      expect(eligible30.allowedReviewDays, 30);
      expect(eligible30.isWithinReviewPeriod, isTrue);
      expect(eligible30.daysSinceLastVisit, 25);
      expect(eligible30.message, contains('Eligible for 30-day Free Review'));

      final suggestedPayment = AppointmentEngine.suggestPaymentType(
        patientHistory: appts,
        doctorId: doc1,
        targetDate: today,
        freeReviewDays: 30,
      );
      expect(suggestedPayment, PaymentType.freeReview);

      // Test expired 30-day window (35 days ago)
      final apptsExpired = [
        Appointment(
          id: 'appt-1',
          patientPhone: '9876543210',
          patientName: 'Test Patient',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.paidCash,
          amountCollected: 800,
          queueNumber: 1,
          scheduledDate: DateTime(2026, 9, 15),
          // 35 days before Oct 20
          doctorId: doc1,
          doctorName: 'Dr. Baruah',
        ),
      ];

      final expired30 = PatientReviewEligibility.calculate(
        appointments: apptsExpired,
        doctorId: doc1,
        targetDate: today,
        doctorName: 'Dr. Baruah',
        allowedReviewDays: 30,
      );

      expect(expired30.hasVisitedDoctorEarlier, isTrue);
      expect(expired30.allowedReviewDays, 30);
      expect(expired30.isWithinReviewPeriod, isFalse);
      expect(expired30.daysSinceLastVisit, 35);
      expect(expired30.message, contains('30 days have passed'));
    });

    test('Strict 1:1 cycle: single free review allowed per paid visit; second review is consumed', () {
      // Patient had a paid visit on Oct 5 (15 days ago), and used a Free Review on Oct 10 (10 days ago).
      // On Oct 14 (within 14 days of paid visit Oct 5), trying to book another Free Review should be REJECTED.
      final appts = [
        Appointment(
          id: 'appt-paid-1',
          patientPhone: '9876543210',
          patientName: 'Test Patient',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 1,
          scheduledDate: DateTime(2026, 10, 5),
          doctorId: doc1,
          doctorName: 'Dr. Baruah',
        ),
        Appointment(
          id: 'appt-review-1',
          patientPhone: '9876543210',
          patientName: 'Test Patient',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.freeReview,
          amountCollected: 0,
          queueNumber: 2,
          scheduledDate: DateTime(2026, 10, 10),
          doctorId: doc1,
          doctorName: 'Dr. Baruah',
        ),
      ];

      final eligibility = PatientReviewEligibility.calculate(
        appointments: appts,
        doctorId: doc1,
        targetDate: DateTime(2026, 10, 14),
        // 9 days after Oct 5
        doctorName: 'Dr. Baruah',
        allowedReviewDays: 14,
      );

      // Must be flagged as already consumed
      expect(eligibility.hasVisitedDoctorEarlier, isTrue);
      expect(eligibility.isReviewAlreadyConsumed, isTrue);
      expect(eligibility.isWithinReviewPeriod, isFalse);
      expect(eligibility.message, contains('Free review already used'));

      // AppointmentEngine must suggest paidCash, not freeReview
      final suggestedPayment = AppointmentEngine.suggestPaymentType(
        patientHistory: appts,
        doctorId: doc1,
        targetDate: DateTime(2026, 10, 14),
        freeReviewDays: 14,
      );
      expect(suggestedPayment, PaymentType.paidCash);
    });

    test('Subsequent paid consultation resets and unlocks a fresh single free review', () {
      final appts = [
        Appointment(
          id: 'appt-paid-1',
          patientPhone: '9876543210',
          patientName: 'Test Patient',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 1,
          scheduledDate: DateTime(2026, 10, 1),
          doctorId: doc1,
          doctorName: 'Dr. Baruah',
        ),
        Appointment(
          id: 'appt-review-1',
          patientPhone: '9876543210',
          patientName: 'Test Patient',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.freeReview,
          amountCollected: 0,
          queueNumber: 2,
          scheduledDate: DateTime(2026, 10, 5),
          doctorId: doc1,
          doctorName: 'Dr. Baruah',
        ),
        Appointment(
          id: 'appt-paid-2',
          patientPhone: '9876543210',
          patientName: 'Test Patient',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.paidUpi,
          amountCollected: 500,
          queueNumber: 3,
          scheduledDate: DateTime(2026, 10, 12),
          // Fresh paid consultation!
          doctorId: doc1,
          doctorName: 'Dr. Baruah',
        ),
      ];

      final eligibility = PatientReviewEligibility.calculate(
        appointments: appts,
        doctorId: doc1,
        targetDate: DateTime(2026, 10, 16),
        // 4 days after Oct 12
        doctorName: 'Dr. Baruah',
        allowedReviewDays: 14,
      );

      // New review cycle is unlocked by appt-paid-2
      expect(eligibility.hasVisitedDoctorEarlier, isTrue);
      expect(eligibility.isReviewAlreadyConsumed, isFalse);
      expect(eligibility.isWithinReviewPeriod, isTrue);
      expect(eligibility.daysSinceLastVisit, 4);
      expect(eligibility.message, contains('Eligible for 14-day Free Review'));
    });

    test('Unpaid or non-fee visit (unpaid phone booking) does not unlock free review', () {
      final appts = [
        Appointment(
          id: 'appt-unpaid-1',
          patientPhone: '9876543210',
          patientName: 'Test Patient',
          status: AppointmentStatus.completed,
          paymentType: PaymentType.unpaid,
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
        allowedReviewDays: 14,
      );

      expect(eligibility.hasVisitedDoctorEarlier, isFalse);
      expect(eligibility.isWithinReviewPeriod, isFalse);
    });
  });

  group('Appointment.paymentSummary Tests', () {
    test(
      'formats paid cash and upi cleanly with rupee amount and Paid label',
      () {
        final cashAppt = Appointment(
          id: 'appt-1',
          patientPhone: '9876543210',
          patientName: 'Test Patient',
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 1,
          scheduledDate: DateTime.now(),
          doctorId: 'doc-1',
          doctorName: 'Dr. Das',
        );
        final upiAppt = Appointment(
          id: 'appt-2',
          patientPhone: '9876543210',
          patientName: 'Test Patient',
          paymentType: PaymentType.paidUpi,
          amountCollected: 700,
          queueNumber: 2,
          scheduledDate: DateTime.now(),
          doctorId: 'doc-1',
          doctorName: 'Dr. Das',
        );

        expect(cashAppt.paymentSummary, '₹500 Paid');
        expect(upiAppt.paymentSummary, '₹700 Paid');
      },
    );

    test('formats free waivers, post-pay, and unpaid without brackets', () {
      final freeReview = Appointment(
        id: 'appt-3',
        patientPhone: '9876543210',
        patientName: 'Test Patient',
        paymentType: PaymentType.freeReview,
        amountCollected: 0,
        queueNumber: 3,
        scheduledDate: DateTime.now(),
        doctorId: 'doc-1',
        doctorName: 'Dr. Das',
      );
      final freeFamily = Appointment(
        id: 'appt-4',
        patientPhone: '9876543210',
        patientName: 'Test Patient',
        paymentType: PaymentType.freeFamily,
        amountCollected: 0,
        queueNumber: 4,
        scheduledDate: DateTime.now(),
        doctorId: 'doc-1',
        doctorName: 'Dr. Das',
      );
      final postPay = Appointment(
        id: 'appt-5',
        patientPhone: '9876543210',
        patientName: 'Test Patient',
        paymentType: PaymentType.postPay,
        amountCollected: 0,
        queueNumber: 5,
        scheduledDate: DateTime.now(),
        doctorId: 'doc-1',
        doctorName: 'Dr. Das',
      );
      final unpaid = Appointment(
        id: 'appt-6',
        patientPhone: '9876543210',
        patientName: 'Test Patient',
        paymentType: PaymentType.unpaid,
        amountCollected: 0,
        queueNumber: 6,
        scheduledDate: DateTime.now(),
        doctorId: 'doc-1',
        doctorName: 'Dr. Das',
      );

      expect(freeReview.paymentSummary, 'Free Review');
      expect(freeFamily.paymentSummary, 'Free Waiver');
      expect(postPay.paymentSummary, 'Post-Pay');
      expect(unpaid.paymentSummary, 'Unpaid');
    });
  });
}
