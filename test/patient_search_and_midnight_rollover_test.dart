import 'package:appointment_app/core/engines/engines.dart';
import 'package:appointment_app/models/models.dart';
import 'package:appointment_app/providers/clinic_provider.dart';
import 'package:appointment_app/services/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PatientSearchEngine Tests (Pure Dart)', () {
    test('normalizePhone strips Indian prefixes (+91, 0) and formatting', () {
      expect(PatientSearchEngine.normalizePhone('+91 98640-12345'), '9864012345');
      expect(PatientSearchEngine.normalizePhone('09864012345'), '9864012345');
      expect(PatientSearchEngine.normalizePhone('98640 12345'), '9864012345');
      expect(PatientSearchEngine.normalizePhone('9864012345'), '9864012345');
    });

    test('tokenizeName splits name into lowercase terms', () {
      final tokens = PatientSearchEngine.tokenizeName('Dr. Ratul Sharma Baruah');
      expect(tokens, ['dr.', 'ratul', 'sharma', 'baruah']);
    });

    test('matches finds patient by canonical pat_* ID, phone, name, or surname', () {
      final p = Patient(
        id: 'pat_1710920000000_1234',
        name: 'Jyotish Baruah',
        age: 45,
        gender: 'Male',
        phoneNumber: '9864012345',
      );

      // Matches canonical ID
      expect(PatientSearchEngine.matches(p, 'pat_1710920'), isTrue);
      // Matches phone exact and partial
      expect(PatientSearchEngine.matches(p, '9864012345'), isTrue);
      expect(PatientSearchEngine.matches(p, '12345'), isTrue);
      // Matches first name
      expect(PatientSearchEngine.matches(p, 'Jyotish'), isTrue);
      expect(PatientSearchEngine.matches(p, 'jyot'), isTrue);
      // Matches surname
      expect(PatientSearchEngine.matches(p, 'Baruah'), isTrue);
      expect(PatientSearchEngine.matches(p, 'baru'), isTrue);
      // Unrelated does not match
      expect(PatientSearchEngine.matches(p, 'Sharma'), isFalse);
    });

    test('filterAndRank prioritizes exact phone and name over partial substring matches', () {
      final p1 = Patient(
        id: 'pat_1',
        name: 'Ratul Sharma',
        age: 30,
        gender: 'Male',
        phoneNumber: '9864011111',
      );
      final p2 = Patient(
        id: 'pat_2',
        name: 'Sharma Roy',
        age: 35,
        gender: 'Male',
        phoneNumber: '9864022222',
      );
      final p3 = Patient(
        id: 'pat_3',
        name: 'Anupam Sharma',
        age: 40,
        gender: 'Male',
        phoneNumber: '9864033333',
      );

      // When searching "Sharma", "Sharma Roy" (starts with) ranks highest, followed by surname matches
      final ranked = PatientSearchEngine.filterAndRank([p1, p2, p3], 'Sharma');
      expect(ranked.length, 3);
      expect(ranked.first.id, 'pat_2'); // First name starts with Sharma
    });
  });

  group('Same-Day Return Visits & Lab Review Eligibility Tests', () {
    final today = DateTime(2026, 10, 20);

    test('Patient completed earlier today is eligible for same-day free lab review', () {
      final morningVisit = Appointment(
        id: 'appt-morning',
        patientId: 'pat-1',
        patientPhone: '9864012345',
        patientName: 'Same Day Patient',
        status: AppointmentStatus.completed,
        visitStatus: VisitStatus.completed,
        paymentType: PaymentType.paidCash,
        amountCollected: 500,
        queueNumber: 1,
        scheduledDate: today,
        doctorId: 'doc-1',
        doctorName: 'Dr. A. Sharma',
      );

      final eligibility = AppointmentEngine.evaluateReviewEligibility(
        patientHistory: [morningVisit],
        doctorId: 'doc-1',
        doctorName: 'Dr. A. Sharma',
        targetDate: today,
        freeReviewDays: 7,
      );

      expect(eligibility.hasVisitedDoctorEarlier, isTrue);
      expect(eligibility.isWithinReviewPeriod, isTrue);
      expect(eligibility.daysSinceLastVisit, 0);
      expect(eligibility.message, contains('Same-day return / lab review'));

      final suggested = AppointmentEngine.suggestPaymentType(
        patientHistory: [morningVisit],
        doctorId: 'doc-1',
        targetDate: today,
        freeReviewDays: 7,
      );
      expect(suggested, PaymentType.freeReview);
    });

    test('Zero review day policy disables same-day free review', () {
      final morningVisit = Appointment(
        id: 'appt-morning',
        patientId: 'pat-1',
        patientPhone: '9864012345',
        patientName: 'Strict Doctor Patient',
        status: AppointmentStatus.completed,
        visitStatus: VisitStatus.completed,
        paymentType: PaymentType.paidCash,
        amountCollected: 500,
        queueNumber: 1,
        scheduledDate: today,
        doctorId: 'doc-strict',
        doctorName: 'Dr. Strict',
      );

      final eligibility = AppointmentEngine.evaluateReviewEligibility(
        patientHistory: [morningVisit],
        doctorId: 'doc-strict',
        doctorName: 'Dr. Strict',
        targetDate: today,
        freeReviewDays: 0,
      );

      expect(eligibility.hasVisitedDoctorEarlier, isTrue);
      expect(eligibility.isWithinReviewPeriod, isFalse);
      expect(eligibility.message, contains('0-day policy'));
    });
  });

  group('Appointment Model & RefundStatus Tests', () {
    test('refundStatus defaults to none and serializes correctly', () {
      final appt = Appointment(
        id: 'a1',
        patientPhone: '9864012345',
        patientName: 'Test Patient',
        paymentType: PaymentType.paidCash,
        amountCollected: 500,
        queueNumber: 1,
        scheduledDate: DateTime(2026, 10, 20),
        doctorId: 'doc-1',
        doctorName: 'Dr. Sharma',
      );

      expect(appt.refundStatus, 'none');
      final json = appt.toJson();
      // 'none' is omitted in json to keep documents compact
      expect(json['refundStatus'], isNull);

      final fromJson = Appointment.fromJson(json);
      expect(fromJson.refundStatus, 'none');

      final pendingRefund = appt.copyWith(refundStatus: 'pending_refund');
      expect(pendingRefund.refundStatus, 'pending_refund');
      expect(pendingRefund.toJson()['refundStatus'], 'pending_refund');

      final fromPendingJson = Appointment.fromJson(pendingRefund.toJson());
      expect(fromPendingJson.refundStatus, 'pending_refund');
    });
  });

  group('ClinicProvider Midnight Date Rollover Tests', () {
    test('checkAndHandleMidnightRollover triggers date shift when calendar day crosses midnight', () {
      final now = DateTime.now();
      final day1 = DateTime(now.year, now.month, now.day);
      final day2 = day1.add(const Duration(days: 1));

      final mockBooking = _MockBookingService();
      final mockDoctor = _MockDoctorService();
      final mockCatalogue = _MockCatalogueService();

      final provider = ClinicProvider(
        bookingService: mockBooking,
        doctorService: mockDoctor,
        catalogueService: mockCatalogue,
      );

      provider.startListeningToAppointments();
      expect(provider.activeListeningDate, isNotNull);
      expect(provider.isCustomDateSelected, isFalse);

      // Check on same day: no change
      provider.checkAndHandleMidnightRollover(day1);
      expect(provider.isCustomDateSelected, isFalse);

      // Now midnight arrives and nextDay (day2) comes:
      provider.checkAndHandleMidnightRollover(day2);
      expect(DateUtils.isSameDay(provider.activeListeningDate, day2), isTrue);
      expect(DateUtils.isSameDay(mockBooking.lastQueriedDate, day2), isTrue);

      provider.dispose();
    });
  });
}

class _MockBookingService extends BookingService {
  DateTime? lastQueriedDate;

  _MockBookingService();

  @override
  Stream<List<Appointment>> getAppointmentsForDate(DateTime date) {
    lastQueriedDate = date;
    return Stream.value([]);
  }
}

class _MockDoctorService extends DoctorService {
  _MockDoctorService();

  @override
  Stream<List<Doctor>> getDoctors() => Stream.value([]);
}

class _MockCatalogueService extends CatalogueService {
  _MockCatalogueService();

  @override
  Stream<List<Medicine>> getMedicines() => Stream.value([]);
}

