import 'package:flutter_test/flutter_test.dart';
import 'package:appointment_app/core/engines/data_export_engine.dart';
import 'package:appointment_app/models/appointment.dart';
import 'package:appointment_app/models/patient.dart';
import 'package:appointment_app/models/medicine.dart';
import 'package:appointment_app/models/consultation.dart';
import 'package:appointment_app/models/prescription_item.dart';

void main() {
  group('DataExportEngine RFC-4180 & Formatting Tests', () {
    test('formatIndianDate outputs DD-MM-YYYY format', () {
      final dt = DateTime(2026, 10, 22, 14, 30);
      expect(DataExportEngine.formatIndianDate(dt), '22-10-2026');
      expect(DataExportEngine.formatIndianDate(null), '');
    });

    test('escapeCsvCell correctly handles commas, quotes, and newlines', () {
      expect(DataExportEngine.escapeCsvCell('Simple'), 'Simple');
      expect(DataExportEngine.escapeCsvCell('Hello, World'), '"Hello, World"');
      expect(DataExportEngine.escapeCsvCell('Line 1\nLine 2'), '"Line 1\nLine 2"');
      expect(
        DataExportEngine.escapeCsvCell('She said "Hello"'),
        '"She said ""Hello"""',
      );
    });

    test('exportAppointmentsCsv formats rows correctly with Indian dates', () {
      final appts = [
        Appointment(
          id: 'appt_001',
          patientId: 'pat_001',
          patientPhone: '9876543210',
          patientName: 'Arun Sharma, Jr.',
          patientAgeDisplay: '34 Years',
          visitStatus: VisitStatus.completed,
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 1,
          scheduledDate: DateTime(2026, 10, 22),
          doctorId: 'doc_1',
          doctorName: 'Dr. B. K. Baruah',
          checkedInAt: DateTime(2026, 10, 22, 9, 15),
          isPaused: false,
        ),
      ];

      final csv = DataExportEngine.exportAppointmentsCsv(appts);
      expect(csv, contains('Date (DD-MM-YYYY)'));
      expect(csv, contains('22-10-2026'));
      expect(csv, contains('"Arun Sharma, Jr."'));
      expect(csv, contains('500'));
      expect(csv, contains('appt_001'));
    });

    test('exportRevenueLedgerCsv includes summary totals', () {
      final appts = [
        Appointment(
          id: 'appt_1',
          patientId: 'p1',
          patientPhone: '9876543210',
          patientName: 'Rina Das',
          visitStatus: VisitStatus.completed,
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 1,
          scheduledDate: DateTime(2026, 10, 22),
          doctorId: 'doc_1',
          doctorName: 'Dr. Baruah',
          isPaused: false,
        ),
        Appointment(
          id: 'appt_2',
          patientId: 'p2',
          patientPhone: '9876543211',
          patientName: 'Kalyan Saikia',
          visitStatus: VisitStatus.completed,
          paymentType: PaymentType.paidUpi,
          amountCollected: 600,
          queueNumber: 2,
          scheduledDate: DateTime(2026, 10, 22),
          doctorId: 'doc_1',
          doctorName: 'Dr. Baruah',
          isPaused: false,
        ),
        Appointment(
          id: 'appt_3',
          patientId: 'p3',
          patientPhone: '9876543212',
          patientName: 'Mridul Bora',
          visitStatus: VisitStatus.completed,
          paymentType: PaymentType.freeReview,
          amountCollected: 0,
          queueNumber: 3,
          scheduledDate: DateTime(2026, 10, 22),
          doctorId: 'doc_1',
          doctorName: 'Dr. Baruah',
          isPaused: false,
        ),
      ];

      final csv = DataExportEngine.exportRevenueLedgerCsv(appts);
      expect(csv, contains('Total Cash (INR),500'));
      expect(csv, contains('Total UPI (INR),600'));
      expect(csv, contains('Total Waived / Free Visits,1'));
      expect(csv, contains('Net Total Collected (INR),1100'));
    });

    test('exportPatientsCsv outputs patient details correctly', () {
      final patients = [
        Patient(
          id: 'pat_001',
          name: 'Hiren Sarma',
          age: 45,
          gender: 'Male',
          phoneNumber: '9864012345',
          allergies: ['Penicillin', 'Sulfa drugs'],
          lastVisitDate: DateTime(2026, 10, 15),
        ),
      ];

      final csv = DataExportEngine.exportPatientsCsv(patients);
      expect(csv, contains('pat_001'));
      expect(csv, contains('Hiren Sarma'));
      expect(csv, contains('9864012345'));
      expect(csv, contains('45 Years'));
      expect(csv, contains('Penicillin; Sulfa drugs'));
      expect(csv, contains('15-10-2026'));
    });

    test('exportMedicinesCsv outputs catalogue accurately', () {
      final meds = [
        const Medicine(
          id: 'med_telma40',
          productName: 'Telma 40 tablet',
          composition: 'Telmisartan 40mg',
          manufacturer: 'Glenmark',
          defaultDosage: '1 Tablet',
          defaultFrequency: '1-0-0',
          defaultTiming: 'Before Food',
          defaultDuration: 'To continue',
        ),
      ];

      final csv = DataExportEngine.exportMedicinesCsv(meds);
      expect(csv, contains('med_telma40'));
      expect(csv, contains('Telma 40 tablet'));
      expect(csv, contains('Telmisartan 40mg'));
      expect(csv, contains('Glenmark'));
      expect(csv, contains('To continue'));
    });

    test('exportConsultationsCsv formats clinical encounters', () {
      final consults = [
        Consultation(
          id: 'cons_001',
          appointmentId: 'appt_001',
          patientPhone: '9876543210',
          patientName: 'Anil Kalita',
          patientAge: 52,
          patientGender: 'Male',
          doctorId: 'doc_1',
          doctorName: 'Dr. Baruah',
          doctorRegNumber: 'NMC-12345',
          createdAt: DateTime(2026, 10, 22, 11, 0),
          chiefComplaints: ['Headache', 'Mild fever'],
          provisionalDiagnosis: ['Hypertension - Stage 1'],
          prescriptionItems: [
            const PrescriptionItem(
              id: 'rx_1',
              action: MedicationAction.start,
              medicineName: 'Telma 40 tablet',
              composition: 'TELMISARTAN 40MG',
              dosage: '1 tab',
              frequency: '1-0-0',
              timing: 'Morning',
              durationText: '30 Days',
            ),
          ],
          nextFollowUpDate: DateTime(2026, 11, 22),
        ),
      ];

      final csv = DataExportEngine.exportConsultationsCsv(consults);
      expect(csv, contains('22-10-2026'));
      expect(csv, contains('Anil Kalita'));
      expect(csv, contains('Hypertension - Stage 1'));
      expect(csv, contains('Telma 40 tablet (1 tab • 1-0-0 • Morning • 30 Days)'));
      expect(csv, contains('22-11-2026'));
    });
  });
}
