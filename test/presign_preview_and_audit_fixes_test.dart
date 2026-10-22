import 'package:appointment_app/config/clinic_config.dart';
import 'package:appointment_app/models/models.dart';
import 'package:appointment_app/screens/prescription_print_screen.dart';
import 'package:appointment_app/widgets/common/clinic_date_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QOL-19: Pre-Sign Prescription Preview Gate Tests', () {
    late Consultation sampleConsultation;

    setUp(() {
      sampleConsultation = Consultation(
        id: 'cons-101',
        appointmentId: 'apt-101',
        patientId: 'pat-101',
        patientPhone: '9864012345',
        patientName: 'Pranab Saikia',
        patientAge: 42,
        patientAgeDisplay: '42 yrs',
        patientGender: 'Male',
        doctorId: 'doc-1',
        doctorName: 'Dr. Bhaskar Baruah',
        doctorRegNumber: 'ASM-12345',
        createdAt: DateTime(2026, 10, 22, 10, 30),
        vitals: const Vitals(systolicBp: 120, diastolicBp: 80, pulseRate: 74),
        prescriptionItems: const [
          PrescriptionItem(
            id: 'rx-1',
            action: MedicationAction.start,
            medicineId: 'med-telma-40',
            medicineName: 'Telma 40 tablet',
            composition: 'TELMISARTAN 40MG',
            dosage: '1 tab',
            frequency: '1-0-0',
            timing: 'Before Food',
            durationDays: 30,
            durationText: '30 Days',
            instructions: 'In morning',
          ),
        ],
      );
    });

    testWidgets('PrescriptionPrintScreen in pre-sign mode renders banner and confirm button', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool? popResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    popResult = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PrescriptionPrintScreen(
                          consultation: sampleConsultation,
                          patientAllergies: const ['Penicillin'],
                          doctorSpecialty: 'Cardiology',
                          doctorRegNumber: 'ASM-12345',
                          isPreSign: true,
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Preview'),
                ),
              );
            },
          ),
        ),
      );

      // Open the preview
      await tester.tap(find.text('Open Preview'));
      await tester.pumpAndSettle();

      // Verify Pre-Sign AppBar title and Pre-Sign Banner
      expect(find.text('Prescription Preview & Sign-Off'), findsOneWidget);
      expect(find.textContaining('PRE-SIGN CLINICAL REVIEW'), findsOneWidget);
      expect(find.text('Confirm & Sign Rx'), findsOneWidget);
      expect(find.text('Print Draft'), findsOneWidget);
      expect(find.text('Edit Encounter'), findsOneWidget);
      // WhatsApp button should NOT be shown in pre-sign mode
      expect(find.text('Send on WhatsApp'), findsNothing);

      // Tap Confirm & Sign Rx
      await tester.tap(find.text('Confirm & Sign Rx'));
      await tester.pumpAndSettle();

      expect(popResult, isTrue);
    });

    testWidgets('PrescriptionPrintScreen Edit Encounter returns false without signing', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool? popResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    popResult = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PrescriptionPrintScreen(
                          consultation: sampleConsultation,
                          isPreSign: true,
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Preview'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Preview'));
      await tester.pumpAndSettle();

      // Tap Edit Encounter
      await tester.tap(find.text('Edit Encounter'));
      await tester.pumpAndSettle();

      expect(popResult, isFalse);
    });
  });

  group('AUDIT-14 & AUDIT-27 Unit & Widget Tests', () {
    testWidgets('ClinicDateNavBar respects firstDate and lastDate bounds', (
      tester,
    ) async {
      final epoch = DateTime(2025, 1, 1);
      final futureCap = DateTime(2025, 1, 3);
      DateTime selected = DateTime(2025, 1, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ClinicDateNavBar(
                  selectedDate: selected,
                  onDateChanged: (d) => setState(() => selected = d),
                  firstDate: epoch,
                  lastDate: futureCap,
                );
              },
            ),
          ),
        ),
      );

      // On epoch date, left button is disabled (canGoBack is false)
      final prevFinder = find.widgetWithIcon(IconButton, Icons.chevron_left_rounded);
      expect(prevFinder, findsOneWidget);
      final prevButton = tester.widget<IconButton>(prevFinder);
      expect(prevButton.onPressed, isNull);

      // Right button is enabled (canGoForward is true)
      final nextFinder = find.widgetWithIcon(IconButton, Icons.chevron_right_rounded);
      expect(nextFinder, findsOneWidget);
      final nextButton = tester.widget<IconButton>(nextFinder);
      expect(nextButton.onPressed, isNotNull);

      // Tap next day -> moves to 02-01-2025
      await tester.tap(nextFinder);
      await tester.pumpAndSettle();
      expect(selected, DateTime(2025, 1, 2));

      // Both buttons enabled
      expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_left_rounded)).onPressed, isNotNull);
      expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_right_rounded)).onPressed, isNotNull);

      // Tap next day again -> moves to 03-01-2025 (lastDate)
      await tester.tap(find.widgetWithIcon(IconButton, Icons.chevron_right_rounded));
      await tester.pumpAndSettle();
      expect(selected, DateTime(2025, 1, 3));

      // On lastDate, right button is disabled
      expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_right_rounded)).onPressed, isNull);
    });

    test('ClinicFeatureFlags seed default medicines toggle (AUDIT-27)', () {
      const defaultFlags = ClinicFeatureFlags();
      expect(defaultFlags.enableSeedDefaultMedicines, isTrue);

      const prodFlags = ClinicFeatureFlags(enableSeedDefaultMedicines: false);
      expect(prodFlags.enableSeedDefaultMedicines, isFalse);
    });
  });
}
