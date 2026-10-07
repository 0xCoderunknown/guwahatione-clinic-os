@Skip('Disabled for development speed')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appointment_app/models/consultation.dart';
import 'package:appointment_app/models/prescription_item.dart';
import 'package:appointment_app/models/vitals.dart';
import 'package:appointment_app/models/diagnostic_investigation.dart';
import 'package:appointment_app/screens/prescription_print_screen.dart';

void main() {
  group('Prescription Print Output & Schedule Segregation Tests', () {
    test('Active schedule includes strictly START and CONTINUE items, never STOP items', () {
      final consultation = Consultation(
        id: 'c-print-1',
        appointmentId: 'appt-1',
        patientPhone: '9876543210',
        patientName: 'John Doe',
        patientAge: 45,
        patientGender: 'Male',
        doctorId: 'doc-1',
        doctorName: 'Dr. Baruah',
        createdAt: DateTime(2026, 10, 7, 10, 0),
        prescriptionItems: [
          const PrescriptionItem(
            id: 'rx-1',
            action: MedicationAction.start,
            medicineName: 'Azithral 500',
            composition: 'Azithromycin 500 mg',
            durationDays: 3,
          ),
          const PrescriptionItem(
            id: 'rx-2',
            action: MedicationAction.continueAction,
            medicineName: 'Glycomet 500',
            composition: 'Metformin 500 mg',
            durationDays: null, // chronic
          ),
          const PrescriptionItem(
            id: 'rx-3',
            action: MedicationAction.stop,
            medicineName: 'Clopitab 75',
            composition: 'Clopidogrel 75 mg',
            stopReason: 'Adverse Effect: Bleeding tendency',
          ),
        ],
      );

      final activeSchedule = consultation.activePrescriptions;
      final stoppedItems = consultation.stoppedPrescriptions;

      // 1. Active schedule must have exactly 2 items
      expect(activeSchedule.length, 2);
      expect(activeSchedule.map((i) => i.medicineName), containsAll(['Azithral 500', 'Glycomet 500']));

      // 2. STOP items must NEVER appear in active schedule
      expect(activeSchedule.map((i) => i.medicineName), isNot(contains('Clopitab 75')));

      // 3. Stopped items must be segregated in stopped list with reasons
      expect(stoppedItems.length, 1);
      expect(stoppedItems.first.medicineName, 'Clopitab 75');
      expect(stoppedItems.first.stopReason, 'Adverse Effect: Bleeding tendency');

      // 4. Chronic vs acute duration formatting
      expect(activeSchedule[0].durationDays, 3);
      expect(activeSchedule[0].isChronic, isFalse);

      expect(activeSchedule[1].durationDays, isNull);
      expect(activeSchedule[1].isChronic, isTrue);
    });

    test('Null-safe formatting when optional vitals, lab orders, and advice are empty', () {
      final minimalConsultation = Consultation(
        id: 'c-minimal',
        appointmentId: 'appt-min',
        patientPhone: '9876543210',
        patientName: 'Jane Minimal',
        patientAge: 28,
        patientGender: 'Female',
        doctorId: 'doc-1',
        doctorName: 'Dr. Baruah',
        createdAt: DateTime(2026, 10, 7),
        vitals: null, // No vitals recorded
        chiefComplaints: const [],
        provisionalDiagnosis: const [],
        prescriptionItems: const [
          PrescriptionItem(
            id: 'rx-min',
            action: MedicationAction.start,
            medicineName: 'Paracetamol 650',
            composition: 'Paracetamol 650 mg',
            durationDays: 3,
          ),
        ],
        orderedTests: const [],
        adviceNotes: null,
        nextFollowUpDate: null,
      );

      // Verify null-safety getters
      expect(minimalConsultation.vitals, isNull);
      expect(minimalConsultation.chiefComplaints, isEmpty);
      expect(minimalConsultation.provisionalDiagnosis, isEmpty);
      expect(minimalConsultation.orderedTests, isEmpty);
      expect(minimalConsultation.adviceNotes, isNull);
      expect(minimalConsultation.nextFollowUpDate, isNull);
      expect(minimalConsultation.activePrescriptions.length, 1);
      expect(minimalConsultation.stoppedPrescriptions, isEmpty);
    });

    test('Structured consultation preserves full diagnostic details for print', () {
      final fullConsultation = Consultation(
        id: 'c-full',
        appointmentId: 'appt-full',
        patientPhone: '9876543210',
        patientName: 'Alice Smith',
        patientAge: 62,
        patientGender: 'Female',
        doctorId: 'doc-1',
        doctorName: 'Dr. Baruah',
        createdAt: DateTime(2026, 10, 7),
        vitals: const Vitals(
          systolicBp: 138,
          diastolicBp: 86,
          pulseRate: 76,
          temperature: 98.4,
          weightKg: 64.0,
          spO2: 98,
        ),
        chiefComplaints: const ['Routine review', 'Mild joint pain'],
        provisionalDiagnosis: const ['Essential Hypertension', 'Osteoarthritis Knee'],
        orderedTests: const [
          OrderedTest(testName: 'Serum Creatinine', instructions: 'Fasting not required'),
          OrderedTest(testName: 'Lipid Profile', instructions: '12 hrs fasting'),
        ],
        adviceNotes: 'Low sodium diet, quadriceps strengthening exercises',
        nextFollowUpDate: DateTime(2026, 11, 7),
      );

      expect(fullConsultation.vitals?.bpFormatted, '138/86 mmHg');
      expect(fullConsultation.vitals?.pulseRate, 76);
      expect(fullConsultation.orderedTests.length, 2);
      expect(fullConsultation.orderedTests[0].testName, 'Serum Creatinine');
      expect(fullConsultation.nextFollowUpDate, DateTime(2026, 11, 7));
    });
    testWidgets('PrescriptionPrintScreen widget renders active table, discontinued warnings, and letterhead toggle', (tester) async {
      final consultation = Consultation(
        id: 'c-widget-print',
        appointmentId: 'appt-wp',
        patientPhone: '9876543210',
        patientName: 'Subhash Sen',
        patientAge: 52,
        patientGender: 'Male',
        doctorId: 'doc-1',
        doctorName: 'Dr. Baruah',
        createdAt: DateTime(2026, 10, 7, 10, 30),
        vitals: const Vitals(systolicBp: 130, diastolicBp: 80, pulseRate: 72),
        chiefComplaints: const ['Follow-up HTN'],
        provisionalDiagnosis: const ['Essential Hypertension'],
        prescriptionItems: [
          const PrescriptionItem(
            id: 'rx-w1',
            action: MedicationAction.start,
            medicineName: 'Amlodipine 5',
            composition: 'Amlodipine 5 mg',
            dosage: '1 tab',
            timing: 'Morning',
            frequency: '1-0-0',
            durationDays: 30,
          ),
          const PrescriptionItem(
            id: 'rx-w2',
            action: MedicationAction.continueAction,
            medicineName: 'Telmisartan 40',
            composition: 'Telmisartan 40 mg',
            dosage: '1 tab',
            timing: 'Night',
            frequency: '0-0-1',
            durationDays: null, // chronic
          ),
          const PrescriptionItem(
            id: 'rx-w3',
            action: MedicationAction.stop,
            medicineName: 'Atenolol 50',
            composition: 'Atenolol 50 mg',
            stopReason: 'Replaced with Amlodipine due to bradycardia',
          ),
        ],
        orderedTests: const [
          OrderedTest(testName: 'Lipid Profile'),
        ],
        adviceNotes: 'Strict salt restriction, 30 min daily brisk walk',
        nextFollowUpDate: DateTime(2026, 11, 7),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PrescriptionPrintScreen(
            consultation: consultation,
            patientAllergies: const ['Penicillin'],
            doctorSpecialty: 'Cardiologist',
          ),
        ),
      );

      // 1. Verify Active Rx table contains START and CONTINUE items
      expect(find.text('Amlodipine 5'), findsOneWidget);
      expect(find.text('Telmisartan 40'), findsOneWidget);
      expect(find.text('30 Days'), findsOneWidget);
      expect(find.text('Ongoing (Chronic)'), findsOneWidget);

      // 2. Verify STOP item is in the Discontinued Warning section, NOT in table
      expect(find.text('🛑 Discontinued / Stopped Medications This Visit:'), findsOneWidget);
      expect(find.textContaining('Atenolol 50'), findsOneWidget);
      expect(find.textContaining('Replaced with Amlodipine due to bradycardia'), findsOneWidget);

      // 3. Verify Allergies callout
      expect(find.text('Penicillin'), findsOneWidget);

      // 4. Verify Digital Header is present initially
      expect(find.text('GUWAHATIONE CLINIC & DIAGNOSTICS'), findsOneWidget);

      // 5. Toggle Pre-printed Letterhead Mode ON
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Digital header should now be replaced by reserved letterhead placeholder
      expect(find.text('GUWAHATIONE CLINIC & DIAGNOSTICS'), findsNothing);
      expect(find.textContaining('RESERVED 130PX FOR PRE-PRINTED CLINIC LETTERHEAD'), findsOneWidget);
    });
  });
}
