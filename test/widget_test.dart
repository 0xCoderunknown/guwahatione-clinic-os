import 'package:flutter_test/flutter_test.dart';
import 'package:appointment_app/models/appointment.dart';
import 'package:appointment_app/models/doctor.dart';

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

    test('Legacy cancelled status deserializes gracefully to absent', () {
      final json = {
        'id': 'appt-legacy',
        'patientPhone': '9876543210',
        'patientName': 'Legacy Patient',
        'status': 'cancelled',
        'paymentType': 'paid',
        'amountCollected': 0,
        'queueNumber': 4,
        'scheduledDate': '2026-10-05T10:00:00.000',
        'doctorId': 'doc-1',
        'doctorName': 'Dr. Baruah',
      };

      final appt = Appointment.fromJson(json);
      expect(appt.status, AppointmentStatus.absent);
      expect(appt.status.displayName, 'Absent');
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
}
