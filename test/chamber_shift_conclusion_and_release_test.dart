import 'package:appointment_app/config/clinic_config.dart';
import 'package:appointment_app/models/chamber_session.dart';
import 'package:appointment_app/models/doctor.dart';
import 'package:appointment_app/providers/auth_provider.dart';
import 'package:appointment_app/widgets/chamber/chamber_app_bar.dart';
import 'package:appointment_app/widgets/chamber/chamber_control_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Chamber Shift Conclusion & Emergency Release Domain Tests', () {
    final testDate = DateTime(2026, 10, 19);

    test('ChamberStatus.shiftEnded enum wiring and parsing', () {
      expect(ChamberStatus.shiftEnded.wireName, equals('shift_ended'));
      expect(
        ChamberStatus.fromString('shift_ended'),
        equals(ChamberStatus.shiftEnded),
      );
    });

    test('ChamberSession correctly identifies shiftEnded state', () {
      final session = ChamberSession(
        doctorId: 'doc_1',
        date: testDate,
        status: 'shift_ended',
        lastCompletedQueueNumber: 14,
        lastCompletedPatientName: 'Jon Doe',
      );

      expect(session.isShiftEnded, isTrue);
      expect(session.isReadyForNext, isFalse);
      expect(session.isCalling, isFalse);
      expect(session.isInConsultation, isFalse);
      expect(session.hasActivePatient, isFalse);
      expect(session.statusEnum, equals(ChamberStatus.shiftEnded));
    });

    test('AuthProvider.verifyReceptionOrOwnerPin validates 0000 and owner pin', () {
      final auth = AuthProvider();

      expect(auth.verifyReceptionOrOwnerPin('0000'), isTrue);
      expect(auth.verifyReceptionOrOwnerPin('849201'), isTrue);
      expect(auth.verifyReceptionOrOwnerPin('1234'), isFalse);
      expect(auth.verifyReceptionOrOwnerPin(''), isFalse);
    });
  });

  group('ChamberControlBanner Widget Shift Actions Tests', () {
    testWidgets('renders shift concluded card when status is shiftEnded and triggers reopen', (tester) async {
      bool reopened = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChamberControlBanner(
              status: ChamberStatus.shiftEnded,
              lastCompletedQueueNumber: 8,
              onNextPatient: () {},
              onReopenShift: () => reopened = true,
            ),
          ),
        ),
      );

      expect(find.text('OPD Shift Concluded for Today'), findsOneWidget);
      expect(find.text('SHIFT ENDED'), findsOneWidget);
      expect(find.text('RE-OPEN SHIFT'), findsOneWidget);

      await tester.tap(find.text('RE-OPEN SHIFT'));
      await tester.pump();

      expect(reopened, isTrue);
    });

    testWidgets('renders NEXT PATIENT during breather (consultationEnded) without redundant banner end shift button', (tester) async {
      bool nextPatientCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChamberControlBanner(
              status: ChamberStatus.consultationEnded,
              lastCompletedQueueNumber: 5,
              onNextPatient: () => nextPatientCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('END SHIFT'), findsNothing);
      expect(find.text('NEXT PATIENT'), findsOneWidget);

      await tester.tap(find.text('NEXT PATIENT'));
      await tester.pump();

      expect(nextPatientCalled, isTrue);
    });

    testWidgets('renders READY FOR FIRST PATIENT when idle without redundant banner close shift button', (tester) async {
      bool firstPatientCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChamberControlBanner(
              status: ChamberStatus.idle,
              onNextPatient: () => firstPatientCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Close Shift'), findsNothing);
      expect(find.text('READY FOR FIRST PATIENT'), findsOneWidget);

      await tester.tap(find.text('READY FOR FIRST PATIENT'));
      await tester.pump();

      expect(firstPatientCalled, isTrue);
    });

    test('enforceSingleActiveDoctor flag is disabled by default to support multi-chamber polyclinics', () {
      expect(ClinicConfig.current.features.enforceSingleActiveDoctor, isFalse);
    });

    testWidgets('ChamberAppBar renders End Shift & Exit button and invokes onLogout', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool logoutCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: ChamberAppBar(
              doctor: Doctor(
                id: 'doc_test',
                name: 'Dr. Test',
                specialty: 'Medicine',
                phone: '1234567890',
                consultationFee: 500,
                availableDays: const ['Mon'],
                blockedDates: const [],
              ),
              isPreviewMode: false,
              onLogout: () => logoutCalled = true,
            ),
          ),
        ),
      );

      final endShiftBtn = find.text('End Shift & Exit');
      expect(endShiftBtn, findsOneWidget);

      await tester.tap(endShiftBtn);
      await tester.pump();

      expect(logoutCalled, isTrue);
    });
  });
}
