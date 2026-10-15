import 'package:appointment_app/core/engines/whatsapp_engine.dart';
import 'package:appointment_app/models/models.dart';
import 'package:appointment_app/widgets/print/print_medications_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Prescription Snapshot & Catalogue Immunity Tests', () {
    test('PrescriptionItem snapshots name, composition, strength, form, and manufacturer at prescribing time', () {
      final catalogueMedicine = Medicine(
        id: 'med_dolo_650',
        productName: 'Dolo 650',
        composition: 'Paracetamol',
        strength: '650 mg',
        form: 'Tablet',
        manufacturer: 'Micro Labs Ltd',
      );

      // Create snapshot prescription item
      final item = PrescriptionItem(
        id: 'rx_item_1',
        action: MedicationAction.start,
        medicineId: catalogueMedicine.id,
        medicineName: catalogueMedicine.productName,
        composition: catalogueMedicine.composition,
        strength: catalogueMedicine.strength,
        form: catalogueMedicine.form,
        manufacturer: catalogueMedicine.manufacturer,
        dosage: '1 Tablet',
        frequency: '1-0-1',
        timing: 'After Food',
        durationDays: 5,
        instructions: 'SOS for fever',
      );

      // Verify fields exist on item
      expect(item.medicineName, 'Dolo 650');
      expect(item.composition, 'Paracetamol');
      expect(item.strength, '650 mg');
      expect(item.form, 'Tablet');
      expect(item.manufacturer, 'Micro Labs Ltd');

      // Serialization round-trip preserves all snapshot fields
      final json = item.toJson();
      expect(json['medicineName'], 'Dolo 650');
      expect(json['composition'], 'Paracetamol');
      expect(json['strength'], '650 mg');
      expect(json['form'], 'Tablet');
      expect(json['manufacturer'], 'Micro Labs Ltd');

      final fromJson = PrescriptionItem.fromJson(json);
      expect(fromJson.medicineName, 'Dolo 650');
      expect(fromJson.composition, 'Paracetamol');
      expect(fromJson.strength, '650 mg');
      expect(fromJson.form, 'Tablet');
      expect(fromJson.manufacturer, 'Micro Labs Ltd');
    });

    testWidgets('Editing and purging a catalogue medicine never alters or breaks a saved prescription or printout', (tester) async {
      // 1. Catalogue contains original drug
      final catalogue = <String, Medicine>{
        'med_azith_500': const Medicine(
          id: 'med_azith_500',
          productName: 'Azithral 500',
          composition: 'Azithromycin',
          strength: '500 mg',
          form: 'Tablet',
          manufacturer: 'Alembic Pharmaceuticals',
        ),
      };

      final originalDrug = catalogue['med_azith_500']!;

      // 2. Doctor prescribes the medicine in a consultation
      final consultation = Consultation(
        id: 'c_test_snapshot',
        appointmentId: 'appt_test_snapshot',
        patientId: 'pat_test_1',
        patientPhone: '9876543210',
        patientName: 'Test Patient',
        patientAge: 40,
        patientGender: 'Male',
        doctorId: 'doc_1',
        doctorName: 'Dr. Physician',
        createdAt: DateTime(2026, 10, 15, 10, 0),
        prescriptionItems: [
          PrescriptionItem(
            id: 'item_1',
            action: MedicationAction.start,
            medicineId: originalDrug.id,
            medicineName: originalDrug.productName,
            composition: originalDrug.composition,
            strength: originalDrug.strength,
            form: originalDrug.form,
            manufacturer: originalDrug.manufacturer,
            dosage: '1 Tablet',
            frequency: '1-0-0 (OD)',
            timing: 'After Food',
            durationDays: 3,
            instructions: 'Take at fixed time',
          ),
        ],
      );

      // Serialize consultation as stored in Firestore
      final savedConsultationJson = consultation.toJson();

      // 3. Catalogue mutation: Edit the drug
      catalogue['med_azith_500'] = const Medicine(
        id: 'med_azith_500',
        productName: 'Azithral Super 1000',
        composition: 'Azithromycin Double Strength',
        strength: '1000 mg',
        form: 'Capsule',
        manufacturer: 'New Chemical Corp',
      );

      // 4. Catalogue mutation: Complete purge (deletion)
      catalogue.remove('med_azith_500');
      expect(catalogue.containsKey('med_azith_500'), isFalse);

      // 5. Reopen the saved consultation from database
      final reopenedConsultation = Consultation.fromJson(savedConsultationJson);
      final rxItem = reopenedConsultation.prescriptionItems.first;

      // Assert: Snapshot in consultation is 100% immune to catalogue purge
      expect(rxItem.medicineName, equals('Azithral 500'));
      expect(rxItem.composition, equals('Azithromycin'));
      expect(rxItem.strength, equals('500 mg'));
      expect(rxItem.form, equals('Tablet'));
      expect(rxItem.manufacturer, equals('Alembic Pharmaceuticals'));

      // 6. Verify WhatsApp text summary uses snapshot data
      final waSummary = WhatsAppEngine.formatPrescriptionMessage(
        consultation: reopenedConsultation,
        queueNumber: 1,
      );
      expect(waSummary, contains('Azithral 500'));
      expect(waSummary, isNot(contains('Azithral Super 1000')));

      // 7. Verify printout renders the original snapshotted medicine
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrintMedicationsTable(
              activeMeds: reopenedConsultation.activePrescriptions,
              stoppedMeds: reopenedConsultation.stoppedPrescriptions,
            ),
          ),
        ),
      );

      expect(find.textContaining('Azithral 500'), findsOneWidget);
      expect(find.textContaining('Azithromycin'), findsOneWidget);
      expect(find.textContaining('Azithral Super 1000'), findsNothing);
      expect(find.textContaining('New Chemical Corp'), findsNothing);
    });
  });
}
