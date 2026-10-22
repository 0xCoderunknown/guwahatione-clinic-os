import 'package:flutter_test/flutter_test.dart';
import 'package:appointment_app/config/clinic_config.dart';
import 'package:appointment_app/core/engines/engines.dart';
import 'package:appointment_app/models/models.dart';
import 'package:appointment_app/providers/delegates/live_queue_delegate.dart';
import 'package:appointment_app/services/booking_service.dart';

class _FakeBookingService extends BookingService {
  String? returnedApptId;
  String? pausedApptId;

  _FakeBookingService() : super();

  @override
  Future<void> returnAppointmentToLobby(String appointmentId) async {
    returnedApptId = appointmentId;
  }

  @override
  Future<void> pauseAppointment(String appointmentId) async {
    pausedApptId = appointmentId;
  }
}

void main() {
  group('AUDIT-13 & AUDIT-10 Tests: Discard Consultation & Default Fee Fallback', () {
    test('LiveQueueDelegate.returnAppointmentToLobby calls BookingService.returnAppointmentToLobby', () async {
      final fakeBooking = _FakeBookingService();
      final delegate = LiveQueueDelegate(
        bookingService: fakeBooking,
        enableMidnightObserver: false,
        notifyListeners: () {},
      );

      await delegate.returnAppointmentToLobby('appt-123');
      expect(fakeBooking.returnedApptId, 'appt-123');
    });

    test('AUDIT-10: AppointmentEngine.resolveConsultationFee falls back to ClinicConfig.current.defaultConsultationFee', () {
      expect(
        AppointmentEngine.resolveConsultationFee(
          doctor: null,
          paymentType: PaymentType.paidCash,
        ),
        ClinicConfig.current.defaultConsultationFee,
      );

      expect(
        AppointmentEngine.resolveConsultationFee(
          doctor: null,
          paymentType: PaymentType.paidUpi,
        ),
        ClinicConfig.current.defaultConsultationFee,
      );
    });
  });
}
