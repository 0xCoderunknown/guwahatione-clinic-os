import 'package:appointment_app/config/clinic_config.dart';
import 'package:appointment_app/core/engines/engines.dart';
import 'package:appointment_app/models/models.dart';
import 'package:appointment_app/widgets/print/token_receipt_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Token Receipt & Bulk Session Close Tests (OPD Optimizations)', () {
    final sampleDoctor = Doctor(
      id: 'doc-cardio-1',
      name: 'Dr. Bhaskar Baruah',
      specialty: 'Cardiology',
      phone: '9864012345',
      availableDays: ['Mon', 'Wed', 'Fri'],
      blockedDates: const [],
      consultationFee: 500,
    );

    test('ClinicFeatureFlags includes token receipt and bulk session close toggles', () {
      const flags = ClinicFeatureFlags();
      expect(flags.enableTokenReceiptPrint, isFalse);
      expect(flags.enableBulkSessionClose, isTrue);
    });

    test('AppointmentEngine.isDoctorAvailableOnDate detects off-days', () {
      // 12-10-2026 is Monday
      final monday = DateTime(2026, 10, 12);
      // 13-10-2026 is Tuesday
      final tuesday = DateTime(2026, 10, 13);
      // 14-10-2026 is Wednesday
      final wednesday = DateTime(2026, 10, 14);

      expect(
        AppointmentEngine.isDoctorAvailableOnDate(
          doctor: sampleDoctor,
          date: monday,
        ),
        isTrue,
      );
      expect(
        AppointmentEngine.isDoctorAvailableOnDate(
          doctor: sampleDoctor,
          date: tuesday,
        ),
        isFalse,
      );
      expect(
        AppointmentEngine.isDoctorAvailableOnDate(
          doctor: sampleDoctor,
          date: wednesday,
        ),
        isTrue,
      );

      final docNoDays = Doctor(
        id: 'doc-all',
        name: 'Dr. Regular',
        specialty: 'General Medicine',
        phone: '9864011111',
        availableDays: const [],
        blockedDates: const [],
      );
      expect(
        AppointmentEngine.isDoctorAvailableOnDate(
          doctor: docNoDays,
          date: tuesday,
        ),
        isTrue,
      );
    });

    testWidgets(
      'TokenReceiptDialog renders token hero, Indian date, and patient details',
      (tester) async {
        final appt = Appointment(
          id: 'appt-receipt-1',
          patientPhone: '9864099999',
          patientName: 'Anindita Das',
          visitStatus: VisitStatus.waitingInLobby,
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 15,
          scheduledDate: DateTime(2026, 10, 14),
          doctorId: sampleDoctor.id,
          doctorName: sampleDoctor.name,
          checkedInAt: DateTime(2026, 10, 14, 18, 30),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: TokenReceiptDialog(appointment: appt)),
          ),
        );

        await tester.pumpAndSettle();

        // Check Header & Hero Token
        expect(
          find.text('TOKEN RECEIPT SLIP'),
          findsNothing,
        ); // Dialog title has standard casing
        expect(find.text('Token Receipt Slip'), findsOneWidget);
        expect(find.text('#15'), findsOneWidget);
        expect(find.text('OPD QUEUE TOKEN'), findsOneWidget);

        // Check Indian Date format DD-MM-YYYY
        expect(find.text('Date: 14-10-2026'), findsOneWidget);

        // Check Patient and Doctor details
        expect(find.text('Anindita Das'), findsOneWidget);
        expect(find.text('9864099999'), findsOneWidget);
        expect(find.text('Dr. Bhaskar Baruah'), findsOneWidget);
        expect(find.text('₹500 • Cash'), findsOneWidget);

        // Check Print and Close buttons
        expect(find.text('Print Slip'), findsOneWidget);
        expect(find.text('Close'), findsOneWidget);
      },
    );

    test('Batch chunking logic partitions large volumes into <= 450 items', () {
      final largeList = List.generate(1050, (index) => 'doc-$index');
      const chunkSize = 450;
      final chunks = <List<String>>[];

      for (int i = 0; i < largeList.length; i += chunkSize) {
        chunks.add(
          largeList.sublist(
            i,
            (i + chunkSize > largeList.length)
                ? largeList.length
                : i + chunkSize,
          ),
        );
      }

      expect(chunks.length, equals(3));
      expect(chunks[0].length, equals(450));
      expect(chunks[1].length, equals(450));
      expect(chunks[2].length, equals(150));
      expect(chunks.expand((c) => c).length, equals(1050));
    });
  });
}
