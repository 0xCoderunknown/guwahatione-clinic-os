import 'package:appointment_app/core/engines/whatsapp_engine.dart';
import 'package:appointment_app/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WhatsAppEngine Tests (P7)', () {
    test('normalizeIndianPhone handles multiple common phone formats', () {
      expect(WhatsAppEngine.normalizeIndianPhone('9876543210'), '919876543210');
      expect(
        WhatsAppEngine.normalizeIndianPhone('+91 98765 43210'),
        '919876543210',
      );
      expect(
        WhatsAppEngine.normalizeIndianPhone('09876543210'),
        '919876543210',
      );
      expect(
        WhatsAppEngine.normalizeIndianPhone('919876543210'),
        '919876543210',
      );
    });

    test('formatPrescriptionMessage strictly enforces Indian date format and full clinical summary', () {
      final consultation = Consultation(
        id: 'c-101',
        appointmentId: 'a-101',
        patientPhone: '9876543210',
        patientName: 'Pranab Kalita',
        patientAge: 42,
        patientGender: 'Male',
        doctorId: 'doc-1',
        doctorName: 'Dr. A. Sharma',
        doctorRegNumber: 'AMC-24891',
        createdAt: DateTime(2026, 10, 12, 14, 30),
        vitals: const Vitals(
          systolicBp: 130,
          diastolicBp: 85,
          pulseRate: 76,
          spO2: 98,
          temperature: 98.4,
          weightKg: 68.0,
        ),
        provisionalDiagnosis: const ['Essential Hypertension', 'GERD'],
        prescriptionItems: const [
          PrescriptionItem(
            id: 'rx-1',
            action: MedicationAction.start,
            medicineName: 'Telma 40',
            composition: 'Telmisartan 40mg',
            dosage: '1 Tablet',
            frequency: '1-0-0 (OD)',
            timing: 'Morning',
            durationDays: 30,
          ),
          PrescriptionItem(
            id: 'rx-2',
            action: MedicationAction.continueAction,
            medicineName: 'Pan 40',
            composition: 'Pantoprazole 40mg',
            dosage: '1 Tablet',
            frequency: '1-0-0 (OD)',
            timing: 'Before Food (Empty Stomach)',
            durationDays: 14,
          ),
          PrescriptionItem(
            id: 'rx-3',
            action: MedicationAction.stop,
            medicineName: 'Amlodipine 5',
            composition: 'Amlodipine 5mg',
            stopReason: 'Substituted with Telma 40 due to pedal edema',
          ),
        ],
        adviceNotes: 'Brisk walking for 30 minutes. Low sodium diet.',
        nextFollowUpDate: DateTime(2026, 10, 26),
      );

      final msg = WhatsAppEngine.formatPrescriptionMessage(
        consultation: consultation,
        queueNumber: 4,
      );

      // Verify Indian Date format in header and follow-up
      expect(msg, contains('12-10-2026'));
      expect(msg, contains('26-10-2026'));
      expect(msg, isNot(contains('2026-10-12')));

      // Verify Demographics & Doctor credentials
      expect(msg, contains('Pranab Kalita (42y, Male)'));
      expect(msg, contains('Dr. A. Sharma'));
      expect(msg, contains('Reg. No: AMC-24891'));
      expect(msg, contains('Token: #4'));

      // Verify Vitals
      expect(msg, contains('BP: 130/85'));
      expect(msg, contains('Pulse: 76 bpm'));

      // Verify Diagnosis
      expect(msg, contains('Essential Hypertension, GERD'));

      // Verify Prescribed Medications
      expect(msg, contains('Telma 40'));
      expect(msg, contains('Pan 40'));
      expect(msg, contains('_[Ongoing]_'));
      expect(msg, contains('30 Days'));

      // Verify Discontinued Medications
      expect(msg, contains('~Amlodipine 5~'));
      expect(msg, contains('Substituted with Telma 40 due to pedal edema'));

      // Verify Advice & Free Review window
      expect(msg, contains('Low sodium diet'));
      expect(
        msg,
        contains('Within 14 days qualifies for Free Follow-Up Review'),
      );
    });

    test('buildDeepLink creates valid wa.me link with URL-encoded text', () {
      const phone = '9876543210';
      const message = 'Hello GuwahatiOne Clinic\nNext: 12-10-2026';

      final url = WhatsAppEngine.buildDeepLink(phone: phone, message: message);

      expect(url.startsWith('https://wa.me/919876543210?text='), isTrue);
      expect(url, contains(Uri.encodeComponent('Hello GuwahatiOne Clinic')));
      expect(url, contains(Uri.encodeComponent('Next: 12-10-2026')));
    });

    test(
      'formatPrescriptionMessage adapts to doctor-configured freeReviewDays',
      () {
        final consultation = Consultation(
          id: 'c-102',
          appointmentId: 'a-102',
          patientPhone: '9876543210',
          patientName: 'Test Patient',
          patientAge: 30,
          patientGender: 'Female',
          doctorId: 'doc-1',
          doctorName: 'Dr. A. Sharma',
          createdAt: DateTime(2026, 10, 12),
          nextFollowUpDate: DateTime(2026, 10, 19),
        );

        // Custom window (e.g. 7 days)
        final msg7 = WhatsAppEngine.formatPrescriptionMessage(
          consultation: consultation,
          freeReviewDays: 7,
        );
        expect(
          msg7,
          contains('Within 7 days qualifies for Free Follow-Up Review'),
        );

        // Zero review days (specialist policy / no free review)
        final msg0 = WhatsAppEngine.formatPrescriptionMessage(
          consultation: consultation,
          freeReviewDays: 0,
        );
        expect(msg0, contains('*Next Review Date:* 19-10-2026'));
        expect(msg0, isNot(contains('qualifies for Free Follow-Up Review')));
      },
    );
  });
}
