import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appointment_app/models/appointment.dart';
import 'package:appointment_app/services/offline_queue_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OfflineQueueCacheService Tests (P6)', () {
    final testDate = DateTime(2026, 10, 12, 10, 30);
    final sampleAppointments = [
      Appointment(
        id: 'appt-1',
        patientPhone: '9876543210',
        patientName: 'Pranab Das',
        status: AppointmentStatus.pending,
        paymentType: PaymentType.paidCash,
        amountCollected: 500,
        queueNumber: 1,
        scheduledDate: testDate,
        doctorId: 'doc-1',
        doctorName: 'Dr. A. Sharma',
      ),
      Appointment(
        id: 'appt-2',
        patientPhone: '9876543211',
        patientName: 'Rita Kalita',
        status: AppointmentStatus.completed,
        paymentType: PaymentType.freeReview,
        amountCollected: 0,
        queueNumber: 2,
        scheduledDate: testDate,
        doctorId: 'doc-1',
        doctorName: 'Dr. A. Sharma',
      ),
    ];

    test('getCachedQueue returns null when no cache exists', () async {
      final cached = await OfflineQueueCacheService.getCachedQueue(testDate);
      expect(cached, isNull);
    });

    test('getCacheTimestamp returns null when no cache exists', () async {
      final ts = await OfflineQueueCacheService.getCacheTimestamp(testDate);
      expect(ts, isNull);
    });

    test('saveQueue successfully persists and getCachedQueue retrieves identical data', () async {
      await OfflineQueueCacheService.saveQueue(testDate, sampleAppointments);

      final cached = await OfflineQueueCacheService.getCachedQueue(testDate);
      expect(cached, isNotNull);
      expect(cached!.length, 2);

      // Verify item 1
      expect(cached[0].id, 'appt-1');
      expect(cached[0].patientName, 'Pranab Das');
      expect(cached[0].patientPhone, '9876543210');
      expect(cached[0].status, AppointmentStatus.pending);
      expect(cached[0].paymentType, PaymentType.paidCash);
      expect(cached[0].amountCollected, 500);
      expect(cached[0].queueNumber, 1);
      expect(cached[0].doctorId, 'doc-1');
      expect(cached[0].doctorName, 'Dr. A. Sharma');

      // Verify item 2
      expect(cached[1].id, 'appt-2');
      expect(cached[1].patientName, 'Rita Kalita');
      expect(cached[1].status, AppointmentStatus.completed);
      expect(cached[1].paymentType, PaymentType.freeReview);
      expect(cached[1].amountCollected, 0);
      expect(cached[1].queueNumber, 2);

      // Verify timestamp
      final ts = await OfflineQueueCacheService.getCacheTimestamp(testDate);
      expect(ts, isNotNull);
      expect(ts!.isBefore(DateTime.now().add(const Duration(seconds: 1))), isTrue);
    });

    test('clearCache successfully removes cached appointments and timestamp', () async {
      await OfflineQueueCacheService.saveQueue(testDate, sampleAppointments);
      expect(await OfflineQueueCacheService.getCachedQueue(testDate), isNotNull);

      await OfflineQueueCacheService.clearCache(testDate);
      expect(await OfflineQueueCacheService.getCachedQueue(testDate), isNull);
      expect(await OfflineQueueCacheService.getCacheTimestamp(testDate), isNull);
    });

    test('getCachedQueue handles corrupted JSON gracefully by returning null', () async {
      SharedPreferences.setMockInitialValues({
        'offline_queue_2026-10-12': '{corrupted_not_a_valid_json_list',
      });

      final cached = await OfflineQueueCacheService.getCachedQueue(testDate);
      expect(cached, isNull);
    });

    test('Appointment.toCacheMap produces valid json-serializable map', () {
      final appt = sampleAppointments.first;
      final map = appt.toCacheMap();

      expect(map['id'], 'appt-1');
      expect(map['scheduledDate'], isA<String>());
      expect(map['scheduledDate'], contains('2026-10-12'));
    });
  });
}
