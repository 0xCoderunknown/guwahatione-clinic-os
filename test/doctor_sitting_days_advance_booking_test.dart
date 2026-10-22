import 'package:appointment_app/core/engines/engines.dart';
import 'package:appointment_app/models/models.dart';
import 'package:appointment_app/providers/delegates/live_queue_delegate.dart';
import 'package:appointment_app/services/booking_service.dart';
import 'package:appointment_app/widgets/booking/booking_duplicate_warning_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBookingService extends BookingService {
  @override
  Future<bool> hasAppointmentForDate({
    required String phone,
    required DateTime date,
    String? patientName,
    String? doctorId,
    String? patientId,
  }) async {
    return false;
  }

  @override
  Future<int> bookAppointment({
    required String appointmentId,
    required Patient patient,
    VisitStatus visitStatus = VisitStatus.waitingInLobby,
    required PaymentType paymentType,
    required int amountCollected,
    required DateTime scheduledDate,
    required String doctorId,
    required String doctorName,
    DateTime? checkedInAt,
  }) async {
    return 1;
  }
}

void main() {
  group('AUDIT-22: Doctor Sitting Days (availableDays) Validation Tests', () {
    final mwfDoctor = Doctor(
      id: 'doc_mwf',
      name: 'Dr. Pritisha Sharma',
      specialty: 'Pediatrics',
      phone: '9876543210',
      availableDays: ['Mon', 'Wed', 'Fri'],
      blockedDates: [],
      consultationFee: 500,
    );

    final fullDayDoctor = Doctor(
      id: 'doc_full',
      name: 'Dr. Bhaskar Baruah',
      specialty: 'Cardiology',
      phone: '9876543211',
      availableDays: ['Monday', 'Wednesday', 'Friday'],
      blockedDates: [],
      consultationFee: 600,
    );

    test('AppointmentEngine.isDoctorAvailableOnDate handles short, full, and mixed case names', () {
      // 2026-10-19 is a Monday (weekday == 1)
      final monday = DateTime(2026, 10, 19);
      // 2026-10-20 is a Tuesday (weekday == 2)
      final tuesday = DateTime(2026, 10, 20);
      // 2026-10-21 is a Wednesday (weekday == 3)
      final wednesday = DateTime(2026, 10, 21);
      // 2026-10-25 is a Sunday (weekday == 7)
      final sunday = DateTime(2026, 10, 25);

      // Short name matching ('Mon', 'Wed', 'Fri')
      expect(AppointmentEngine.isDoctorAvailableOnDate(doctor: mwfDoctor, date: monday), isTrue);
      expect(AppointmentEngine.isDoctorAvailableOnDate(doctor: mwfDoctor, date: tuesday), isFalse);
      expect(AppointmentEngine.isDoctorAvailableOnDate(doctor: mwfDoctor, date: wednesday), isTrue);
      expect(AppointmentEngine.isDoctorAvailableOnDate(doctor: mwfDoctor, date: sunday), isFalse);

      // Full name matching ('Monday', 'Wednesday', 'Friday')
      expect(AppointmentEngine.isDoctorAvailableOnDate(doctor: fullDayDoctor, date: monday), isTrue);
      expect(AppointmentEngine.isDoctorAvailableOnDate(doctor: fullDayDoctor, date: tuesday), isFalse);
      expect(AppointmentEngine.isDoctorAvailableOnDate(doctor: fullDayDoctor, date: wednesday), isTrue);

      // Null doctor or empty availableDays allows all days
      expect(AppointmentEngine.isDoctorAvailableOnDate(doctor: null, date: tuesday), isTrue);
      final allDaysDoctor = Doctor(
        id: 'doc_all',
        name: 'Dr. Available Everyday',
        specialty: 'General Medicine',
        phone: '9876543212',
        availableDays: [],
        blockedDates: [],
      );
      expect(AppointmentEngine.isDoctorAvailableOnDate(doctor: allDaysDoctor, date: sunday), isTrue);
    });

    test('LiveQueueDelegate.bookAppointment throws exception when booking on a non-sitting day', () async {
      final delegate = LiveQueueDelegate(
        bookingService: _FakeBookingService(),
        notifyListeners: () {},
        enableMidnightObserver: false,
      );

      // 2026-10-20 is Tuesday - mwfDoctor does not consult
      final tuesday = DateTime(2026, 10, 20);

      expect(
        () async => await delegate.bookAppointment(
          phoneNumber: '9876543210',
          name: 'Rahul Borah',
          age: 32,
          gender: 'Male',
          visitStatus: VisitStatus.booked,
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          scheduledDate: tuesday,
          selectedDoctor: mwfDoctor,
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Dr. Pritisha Sharma does not consult on Tuesdays (Schedule: Mon, Wed, Fri).'),
          ),
        ),
      );
    });

    test('LiveQueueDelegate.bookAppointment succeeds when booking on an active sitting day', () async {
      final delegate = LiveQueueDelegate(
        bookingService: _FakeBookingService(),
        notifyListeners: () {},
        enableMidnightObserver: false,
      );

      // 2026-10-19 is Monday - mwfDoctor does consult
      final monday = DateTime(2026, 10, 19);

      final appt = await delegate.bookAppointment(
        phoneNumber: '9876543210',
        name: 'Rahul Borah',
        age: 32,
        gender: 'Male',
        visitStatus: VisitStatus.booked,
        paymentType: PaymentType.paidCash,
        amountCollected: 500,
        scheduledDate: monday,
        selectedDoctor: mwfDoctor,
      );

      expect(appt.patientName, 'Rahul Borah');
      expect(appt.doctorId, 'doc_mwf');
      expect(appt.queueNumber, 1);
    });

    testWidgets('BookingOffDayWarningBanner renders warning message and schedule correctly', (tester) async {
      final tuesday = DateTime(2026, 10, 20);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingOffDayWarningBanner(
              doctor: mwfDoctor,
              date: tuesday,
            ),
          ),
        ),
      );

      expect(find.textContaining('Dr. Pritisha Sharma does not consult on Tuesdays'), findsOneWidget);
      expect(find.textContaining('Schedule: Mon, Wed, Fri'), findsOneWidget);
      expect(find.textContaining('Please select an active OPD day.'), findsOneWidget);
      expect(find.byIcon(Icons.event_busy), findsOneWidget);
    });
  });
}
