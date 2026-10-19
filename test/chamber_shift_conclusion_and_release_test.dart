import 'package:appointment_app/models/chamber_session.dart';
import 'package:appointment_app/providers/auth_provider.dart';
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

    testWidgets('renders END SHIFT button during breather (consultationEnded) and triggers onEndShift', (tester) async {
      bool endShiftCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChamberControlBanner(
              status: ChamberStatus.consultationEnded,
              lastCompletedQueueNumber: 5,
              onNextPatient: () {},
              onEndShift: () => endShiftCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('END SHIFT'), findsOneWidget);
      expect(find.text('NEXT PATIENT'), findsOneWidget);

      await tester.tap(find.text('END SHIFT'));
      await tester.pump();

      expect(endShiftCalled, isTrue);
    });

    testWidgets('renders Close Shift button when idle and triggers onEndShift', (tester) async {
      bool endShiftCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChamberControlBanner(
              status: ChamberStatus.idle,
              onNextPatient: () {},
              onEndShift: () => endShiftCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Close Shift'), findsOneWidget);
      expect(find.text('READY FOR FIRST PATIENT'), findsOneWidget);

      await tester.tap(find.text('Close Shift'));
      await tester.pump();

      expect(endShiftCalled, isTrue);
    });
  });
}
