import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appointment_app/services/sound_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SoundService Unit Tests', () {
    test('Defaults to unmuted and toggles mute state cleanly', () async {
      final service = SoundService.create(initialMuted: false);
      expect(service.isMuted, isFalse);

      var notified = false;
      service.addListener(() => notified = true);

      await service.toggleMute();
      expect(service.isMuted, isTrue);
      expect(notified, isTrue);

      notified = false;
      await service.toggleMute();
      expect(service.isMuted, isFalse);
      expect(notified, isTrue);
    });

    test('announceToken triggers chime callback when unmuted', () {
      int? triggeredToken;
      String? triggeredDoctor;

      final service = SoundService.create(
        initialMuted: false,
        chimeTrigger: ({int? tokenNumber, String? doctorName}) {
          triggeredToken = tokenNumber;
          triggeredDoctor = doctorName;
        },
      );

      final result = service.announceToken(
        tokenNumber: 5,
        doctorName: 'Dr. A. Sharma',
        callKey: 'doc1_appt5',
      );

      expect(result, isTrue);
      expect(triggeredToken, 5);
      expect(triggeredDoctor, 'Dr. A. Sharma');
      expect(service.lastAnnouncedKey, 'doc1_appt5');
    });

    test('announceToken does NOT trigger chime when muted', () {
      var triggered = false;

      final service = SoundService.create(
        initialMuted: true,
        chimeTrigger: ({int? tokenNumber, String? doctorName}) {
          triggered = true;
        },
      );

      final result = service.announceToken(
        tokenNumber: 12,
        doctorName: 'Dr. B. Das',
        callKey: 'doc2_appt12',
      );

      expect(result, isFalse);
      expect(triggered, isFalse);
    });

    test('announceToken suppresses duplicate calls with same callKey', () {
      var triggerCount = 0;

      final service = SoundService.create(
        initialMuted: false,
        chimeTrigger: ({int? tokenNumber, String? doctorName}) {
          triggerCount++;
        },
      );

      // First call -> triggers
      final first = service.announceToken(
        tokenNumber: 3,
        doctorName: 'Dr. A. Sharma',
        callKey: 'session_key_1',
      );
      expect(first, isTrue);
      expect(triggerCount, 1);

      // Duplicate call with same key -> skipped
      final duplicate = service.announceToken(
        tokenNumber: 3,
        doctorName: 'Dr. A. Sharma',
        callKey: 'session_key_1',
      );
      expect(duplicate, isFalse);
      expect(triggerCount, 1);

      // Different key -> triggers
      final different = service.announceToken(
        tokenNumber: 4,
        doctorName: 'Dr. A. Sharma',
        callKey: 'session_key_2',
      );
      expect(different, isTrue);
      expect(triggerCount, 2);

      // Reset deduplication allows previous key again
      service.resetDeduplication();
      final afterReset = service.announceToken(
        tokenNumber: 3,
        doctorName: 'Dr. A. Sharma',
        callKey: 'session_key_1',
      );
      expect(afterReset, isTrue);
      expect(triggerCount, 3);
    });
  });

  group('SoundService Widget Integration Tests', () {
    testWidgets('ListenableBuilder reflects mute state toggles', (tester) async {
      final service = SoundService.create(initialMuted: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: service,
              builder: (context, _) {
                return IconButton(
                  icon: Icon(
                    service.isMuted
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                  ),
                  onPressed: () => service.toggleMute(),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
      expect(find.byIcon(Icons.volume_off_rounded), findsNothing);

      // Tap button to toggle
      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(service.isMuted, isTrue);
      expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
      expect(find.byIcon(Icons.volume_up_rounded), findsNothing);
    });
  });
}
