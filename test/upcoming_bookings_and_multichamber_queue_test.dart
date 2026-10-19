import 'package:appointment_app/core/engines/engines.dart';
import 'package:appointment_app/models/models.dart';
import 'package:appointment_app/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Upcoming Advance Bookings & Multi-Chamber Queue Tests', () {
    test(
      'Upcoming advance appointments date grouping strictly formats DD-MM-YYYY',
      () {
        final tomorrowAppt = Appointment(
          id: 'appt_tomorrow',
          patientId: 'p2',
          patientPhone: '9876543211',
          patientName: 'Priya Sharma',
          visitStatus: VisitStatus.booked,
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 1,
          scheduledDate: DateTime(2026, 10, 20, 11, 0),
          doctorId: 'doc_1',
          doctorName: 'Dr. Bhaskar Thakuria',
        );

        final day3Appt = Appointment(
          id: 'appt_day3',
          patientId: 'p3',
          patientPhone: '9876543212',
          patientName: 'Anil Roy',
          visitStatus: VisitStatus.booked,
          paymentType: PaymentType.unpaid,
          amountCollected: 0,
          queueNumber: 2,
          scheduledDate: DateTime(2026, 10, 22, 12, 0),
          doctorId: 'doc_2',
          doctorName: 'Dr. Manas Borah',
        );

        final list = [tomorrowAppt, day3Appt];

        // Group by formatted date
        final Map<String, List<Appointment>> grouped = {};
        for (final appt in list) {
          final dateKey = AppFormatters.date(appt.scheduledDate);
          grouped.putIfAbsent(dateKey, () => []).add(appt);
        }

        expect(grouped.keys.toList(), ['20-10-2026', '22-10-2026']);
        expect(grouped['20-10-2026']!.length, 1);
        expect(grouped['20-10-2026']!.first.patientName, 'Priya Sharma');
        expect(grouped['22-10-2026']!.first.patientName, 'Anil Roy');
      },
    );

    test('Multi-chamber concurrent inChamberPatients isolation', () {
      final appts = [
        Appointment(
          id: 'appt_1',
          patientId: 'p1',
          patientPhone: '9876543210',
          patientName: 'Patient 1',
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 1,
          scheduledDate: DateTime(2026, 10, 19),
          doctorId: 'doc_A',
          doctorName: 'Dr. A',
        ),
        Appointment(
          id: 'appt_2',
          patientId: 'p2',
          patientPhone: '9876543211',
          patientName: 'Patient 2',
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 2,
          scheduledDate: DateTime(2026, 10, 19),
          doctorId: 'doc_A',
          doctorName: 'Dr. A',
        ),
        Appointment(
          id: 'appt_5',
          patientId: 'p5',
          patientPhone: '9876543212',
          patientName: 'Patient 5',
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 5,
          scheduledDate: DateTime(2026, 10, 19),
          doctorId: 'doc_B',
          doctorName: 'Dr. B',
        ),
        Appointment(
          id: 'appt_6',
          patientId: 'p6',
          patientPhone: '9876543213',
          patientName: 'Patient 6',
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 6,
          scheduledDate: DateTime(2026, 10, 19),
          doctorId: 'doc_B',
          doctorName: 'Dr. B',
        ),
      ];

      // Dr. A has Token 2 in Chamber 1, Dr. B has Token 5 in Chamber 2
      final view = AppointmentEngine.partitionQueueForReception(
        appointments: appts,
        activeAppointmentIds: {'appt_2', 'appt_5'},
      );

      expect(view.inChamberPatients.length, 2);
      expect(view.inChamberPatients.map((a) => a.id).toList(), ['appt_2', 'appt_5']);
      expect(view.inChamber?.id, 'appt_2'); // First in-chamber accessor

      // Waiting list retains remaining patients in clean FIFO order
      expect(view.waiting.map((a) => a.id).toList(), ['appt_1', 'appt_6']);
    });

    test('Doctor filtering strictly suppresses off-schedule doctors with 0 appointments', () {
      final docMondayOnly = Doctor(
        id: 'doc_mon',
        name: 'Dr. Monday Specialist',
        specialty: 'Neurology',
        phone: '9876543210',
        availableDays: ['Mon'],
        blockedDates: [],
      );

      final docSaturdayOnly = Doctor(
        id: 'doc_sat',
        name: 'Dr. Saturday Specialist',
        specialty: 'Cardiology',
        phone: '9876543211',
        availableDays: ['Sat'],
        blockedDates: [],
      );

      final docOnLeave = Doctor(
        id: 'doc_leave',
        name: 'Dr. On Leave',
        specialty: 'General Medicine',
        phone: '9876543212',
        availableDays: ['Mon', 'Wed', 'Fri'],
        blockedDates: [DateTime(2026, 10, 19)], // On leave on Monday 19-10-2026
      );

      final targetDate = DateTime(2026, 10, 19); // A Monday

      // Check availability
      expect(AppointmentEngine.isDoctorAvailableOnDate(doctor: docMondayOnly, date: targetDate), isTrue);
      expect(AppointmentEngine.isDoctorAvailableOnDate(doctor: docSaturdayOnly, date: targetDate), isFalse);
      expect(AppointmentEngine.isDoctorOnLeave(doctor: docOnLeave, date: targetDate), isTrue);

      final allDocs = [docMondayOnly, docSaturdayOnly, docOnLeave];
      final emptyAppointments = <Appointment>[];

      final activeDocs = allDocs.where((doc) {
        final isScheduled = AppointmentEngine.isDoctorAvailableOnDate(doctor: doc, date: targetDate);
        final isOnLeave = AppointmentEngine.isDoctorOnLeave(doctor: doc, date: targetDate);
        final hasAppts = emptyAppointments.any((a) => a.doctorId == doc.id);
        return (isScheduled && !isOnLeave) || hasAppts;
      }).toList();

      // Only Dr. Monday Specialist appears!
      expect(activeDocs.length, 1);
      expect(activeDocs.first.id, 'doc_mon');
    });
  });
}
