import 'package:flutter_test/flutter_test.dart';
import 'package:appointment_app/config/clinic_config.dart';
import 'package:appointment_app/core/engines/prescription_print_engine.dart';
import 'package:appointment_app/models/appointment.dart';
import 'package:appointment_app/models/consultation.dart';
import 'package:appointment_app/models/diagnostic_investigation.dart';
import 'package:appointment_app/models/prescription_item.dart';
import 'package:appointment_app/models/vitals.dart';

void main() {
  group('PrescriptionPrintEngine Unit Tests', () {
    final now = DateTime(2026, 10, 24, 10, 30);
    final consultation = Consultation(
      id: 'cons_123',
      appointmentId: 'apt_123',
      patientId: 'pat_123',
      patientName: 'Pranab Das',
      patientPhone: '9876543210',
      patientAge: 42,
      patientGender: 'M',
      patientAgeDisplay: '42 / M',
      doctorId: 'doc_1',
      doctorName: 'Bhaskar Thakuria',
      doctorRegNumber: 'AMC-98124',
      chiefComplaints: ['Fever x 3 days', 'Dry cough'],
      provisionalDiagnosis: ['Acute Viral Bronchitis'],
      clinicalExamination: 'Chest clear, throat mildly congested',
      vitals: const Vitals(
        systolicBp: 120,
        diastolicBp: 80,
        pulseRate: 76,
        spO2: 98,
        temperature: 99.2,
        weightKg: 68.5,
      ),
      prescriptionItems: [
        PrescriptionItem(
          id: 'item_1',
          medicineName: 'Telma 40',
          composition: 'Telmisartan 40mg',
          dosage: '1 Tablet',
          frequency: '1-0-0 (OD)',
          timing: 'After Food',
          durationText: 'To Continue',
          action: MedicationAction.continueAction,
        ),
        PrescriptionItem(
          id: 'item_2',
          medicineName: 'Dolo 650',
          composition: 'Paracetamol 650mg',
          dosage: '1 Tablet',
          frequency: '1-0-1',
          timing: 'After Food',
          durationText: '3 Days',
          durationDays: 3,
          action: MedicationAction.start,
        ),
        PrescriptionItem(
          id: 'item_3',
          medicineName: 'Amlong 5',
          composition: 'Amlodipine 5mg',
          dosage: '1 Tablet',
          frequency: '0-0-1',
          timing: 'At Bedtime',
          durationText: 'To STOP',
          action: MedicationAction.stop,
          stopReason: 'Substituted with Telma 40 due to pedal edema',
        ),
      ],
      orderedTests: const [
        OrderedTest(testName: 'CBC'),
        OrderedTest(testName: 'Chest X-Ray PA'),
      ],
      adviceNotes: 'Drink warm water and avoid cold food.\nReview SOS if fever spikes above 101F.',
      createdAt: now,
    );

    final appointment = Appointment(
      id: 'apt_123',
      doctorId: 'doc_1',
      doctorName: 'Dr. Bhaskar Thakuria',
      patientId: 'pat_123',
      patientName: 'Pranab Das',
      patientPhone: '9876543210',
      patientAgeDisplay: '42 / M',
      scheduledDate: DateTime(2026, 10, 24),
      queueNumber: 4,
      paymentType: PaymentType.paidCash,
      amountCollected: 500,
    );

    test('generates complete self-contained HTML with Indian date format', () {
      final html = PrescriptionPrintEngine.generateHtml(
        consultation: consultation,
        appointment: appointment,
        doctorSpecialty: 'Cardiology',
        patientAllergies: ['Penicillin', 'Sulfa'],
      );

      // Verify Indian Date Format DD-MM-YYYY
      expect(html, contains('24-10-2026'));
      expect(html, isNot(contains('2026-10-24')));

      // Verify Patient Demographics
      expect(html, contains('Pranab Das'));
      expect(html, contains('42 / M'));
      expect(html, contains('#4'));
      expect(html, contains('9876543210'));

      // Verify Doctor title and registration
      expect(html, contains('Dr. Bhaskar Thakuria'));
      expect(html, contains('Cardiology'));
      expect(html, contains('AMC-98124'));

      // Verify Allergies Alert
      expect(html, contains('ALLERGIES / CAUTION'));
      expect(html, contains('Penicillin, Sulfa'));

      // Verify Clinical Snapshot
      expect(html, contains('Fever x 3 days, Dry cough'));
      expect(html, contains('Acute Viral Bronchitis'));
      expect(html, contains('BP: 120/80 mmHg'));
      expect(html, contains('Pulse: 76 bpm'));
      expect(html, contains('Chest clear'));
    });

    test('strictly isolates 3 columns with uppercase bracketed NMC composition', () {
      final html = PrescriptionPrintEngine.generateHtml(
        consultation: consultation,
        appointment: appointment,
      );

      // Verify Column 1 (Brand [COMPOSITION])
      expect(html, contains('Telma 40'));
      expect(html, contains('[TELMISARTAN 40MG]'));
      expect(html, contains('Dolo 650'));
      expect(html, contains('[PARACETAMOL 650MG]'));

      // Verify Column 2 (Dosage & Timing)
      expect(html, contains('1 Tablet • 1-0-0 (OD) • After Food'));
      expect(html, contains('1 Tablet • 1-0-1 • After Food'));

      // Verify Column 3 (Duration)
      expect(html, contains('To Continue'));
      expect(html, contains('3 Days'));

      // Verify Discontinued section
      expect(html, contains('DISCONTINUED MEDICATIONS'));
      expect(html, contains('Amlong 5'));
      expect(html, contains('Substituted with Telma 40 due to pedal edema'));
    });

    test('suppresses bracketed composition when hidePrescriptionComposition is enabled', () {
      const config = ClinicConfig(
        features: ClinicFeatureFlags(
          hidePrescriptionComposition: true,
        ),
      );

      final html = PrescriptionPrintEngine.generateHtml(
        consultation: consultation,
        appointment: appointment,
        config: config,
      );

      expect(html, contains('Telma 40'));
      expect(html, isNot(contains('[TELMISARTAN 40MG]')));
    });

    test('handles pre-printed letterhead mode by reserving top margin', () {
      final html = PrescriptionPrintEngine.generateHtml(
        consultation: consultation,
        appointment: appointment,
        usePrePrintedLetterhead: true,
      );

      expect(html, contains('reserved-letterhead'));
      expect(html, isNot(contains('class="clinic-title"')));
    });

    test('handles A5 compact pad print styling', () {
      final htmlA5 = PrescriptionPrintEngine.generateHtml(
        consultation: consultation,
        appointment: appointment,
        isA5: true,
      );

      expect(htmlA5, contains('size: A5 portrait'));

      final htmlA4 = PrescriptionPrintEngine.generateHtml(
        consultation: consultation,
        appointment: appointment,
        isA5: false,
      );

      expect(htmlA4, contains('size: A4 portrait'));
    });
  });
}
