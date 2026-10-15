import 'package:appointment_app/core/engines/engines.dart';
import 'package:appointment_app/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Patient Identity & Household Multi-Patient Tests', () {
    const sharedPhone = '9876543210';

    test('Family members sharing the same contact phone have distinct identities and never overwrite each other', () {
      final mother = Patient(
        id: 'pat_mother_101',
        phoneNumber: sharedPhone,
        name: 'Sunita Sharma',
        age: 34,
        gender: 'Female',
        allergies: ['Penicillin'],
      );

      final infant = Patient(
        id: 'pat_baby_102',
        phoneNumber: sharedPhone,
        name: 'Aarav Sharma',
        age: 0,
        ageMonths: 4,
        gender: 'Male',
        allergies: const [],
        guardianName: 'Sunita Sharma',
        guardianRelation: 'Mother',
      );

      final grandfather = Patient(
        id: 'pat_elder_103',
        phoneNumber: sharedPhone,
        name: 'Ramesh Sharma',
        age: 72,
        gender: 'Male',
        allergies: ['Sulfa'],
        guardianName: 'Sunita Sharma',
        guardianRelation: 'Daughter-in-law',
      );

      // Verify distinct IDs despite shared contact number
      expect(mother.id, isNot(equals(infant.id)));
      expect(infant.id, isNot(equals(grandfather.id)));
      expect(mother.phoneNumber, equals(sharedPhone));
      expect(infant.phoneNumber, equals(sharedPhone));
      expect(grandfather.phoneNumber, equals(sharedPhone));

      // Serialization round-trip
      final infantJson = infant.toJson();
      expect(infantJson['id'], 'pat_baby_102');
      expect(infantJson['phoneNumber'], sharedPhone);
      expect(infantJson['ageMonths'], 4);
      expect(infantJson['guardianName'], 'Sunita Sharma');
      expect(infantJson['guardianRelation'], 'Mother');

      final deserializedInfant = Patient.fromJson(infantJson);
      expect(deserializedInfant.id, 'pat_baby_102');
      expect(deserializedInfant.name, 'Aarav Sharma');
      expect(deserializedInfant.ageMonths, 4);
      expect(deserializedInfant.guardianName, 'Sunita Sharma');
      expect(deserializedInfant.guardianRelation, 'Mother');
    });

    test('Infant and paediatric age display cleanly formats months and days instead of 0 years', () {
      final infant4Months = Patient(
        id: 'pat_infant_1',
        phoneNumber: sharedPhone,
        name: 'Baby 1',
        age: 0,
        ageMonths: 4,
        gender: 'Male',
      );
      expect(infant4Months.formattedAge, '4 Months');

      final newborn18Days = Patient(
        id: 'pat_newborn_2',
        phoneNumber: sharedPhone,
        name: 'Baby 2',
        age: 0,
        ageMonths: 0,
        ageDays: 18,
        gender: 'Female',
      );
      expect(newborn18Days.formattedAge, '18 Days');

      final child5Years = Patient(
        id: 'pat_child_3',
        phoneNumber: sharedPhone,
        name: 'Child 3',
        age: 5,
        gender: 'Male',
      );
      expect(child5Years.formattedAge, '5 Years');
    });

    test('Consultations key to patientId to strictly isolate charts across family members on the same phone', () {
      final now = DateTime(2026, 10, 15, 10, 0);

      final motherConsultation = Consultation(
        id: 'c_mother_1',
        appointmentId: 'appt-mother-1',
        patientId: 'pat_mother_101',
        patientPhone: sharedPhone,
        patientName: 'Sunita Sharma',
        patientAge: 34,
        patientGender: 'Female',
        doctorId: 'doc-gyn',
        doctorName: 'Dr. Gynaecologist',
        createdAt: now.subtract(const Duration(days: 7)),
        provisionalDiagnosis: const ['Antenatal Care Routine'],
      );

      final infantConsultation = Consultation(
        id: 'c_baby_1',
        appointmentId: 'appt-baby-1',
        patientId: 'pat_baby_102',
        patientPhone: sharedPhone,
        patientName: 'Aarav Sharma',
        patientAge: 0,
        patientAgeDisplay: '4 Months',
        guardianName: 'Sunita Sharma',
        guardianRelation: 'Mother',
        patientGender: 'Male',
        doctorId: 'doc-paed',
        doctorName: 'Dr. Paediatrician',
        createdAt: now,
        provisionalDiagnosis: const ['Acute Bronchiolitis'],
      );

      final grandfatherConsultation = Consultation(
        id: 'c_grand_1',
        appointmentId: 'appt-grand-1',
        patientId: 'pat_elder_103',
        patientPhone: sharedPhone,
        patientName: 'Ramesh Sharma',
        patientAge: 72,
        patientGender: 'Male',
        doctorId: 'doc-cardio',
        doctorName: 'Dr. Cardiologist',
        createdAt: now.subtract(const Duration(days: 14)),
        provisionalDiagnosis: const ['Hypertension'],
      );

      final allConsultations = [
        motherConsultation,
        infantConsultation,
        grandfatherConsultation,
      ];

      // Filtering strictly by patientId isolates the infant's chart from the rest of the household
      final infantChart = allConsultations
          .where((c) => c.patientId == 'pat_baby_102')
          .toList();

      expect(infantChart.length, 1);
      expect(infantChart.first.patientName, 'Aarav Sharma');
      expect(infantChart.first.patientAgeDisplay, '4 Months');
      expect(infantChart.first.guardianName, 'Sunita Sharma');
      expect(infantChart.first.guardianRelation, 'Mother');

      // Serialization round-trip preserves patientId and guardian details
      final json = infantConsultation.toJson();
      expect(json['patientId'], 'pat_baby_102');
      expect(json['patientAgeDisplay'], '4 Months');
      expect(json['guardianName'], 'Sunita Sharma');
      expect(json['guardianRelation'], 'Mother');

      final fromJson = Consultation.fromJson(json);
      expect(fromJson.patientId, 'pat_baby_102');
      expect(fromJson.patientAgeDisplay, '4 Months');
      expect(fromJson.guardianName, 'Sunita Sharma');
    });

    test('Backward-compatibility: Legacy patient and consultation records read cleanly without patientId', () {
      final legacyPatientJson = {
        'id': sharedPhone,
        'phoneNumber': sharedPhone,
        'name': 'Legacy Patient',
        'age': 45,
        'gender': 'Male',
        'allergies': ['Ibuprofen'],
      };

      final legacyPatient = Patient.fromJson(legacyPatientJson);
      expect(legacyPatient.id, sharedPhone);
      expect(legacyPatient.phoneNumber, sharedPhone);
      expect(legacyPatient.isLegacy, isTrue);
      expect(legacyPatient.formattedAge, '45 Years');

      final legacyConsultationJson = {
        'id': 'c_legacy_99',
        'appointmentId': 'appt-legacy-99',
        'patientPhone': sharedPhone,
        'patientName': 'Legacy Patient',
        'patientAge': 45,
        'patientGender': 'Male',
        'doctorId': 'doc-1',
        'doctorName': 'Dr. Old',
        'createdAt': '2026-10-01T10:00:00.000',
      };

      final legacyConsultation = Consultation.fromJson(legacyConsultationJson);
      // When patientId is omitted in historical data, it defaults gracefully to patientPhone
      expect(legacyConsultation.patientId, sharedPhone);
      expect(legacyConsultation.patientPhone, sharedPhone);
    });

    test('Duplicate-booking guard allows family members sharing a phone to consult on the same day, but blocks the same person', () {
      final today = DateTime(2026, 10, 15);

      final motherAppt = Appointment(
        id: 'appt_1',
        patientId: 'pat_mother_101',
        patientPhone: sharedPhone,
        patientName: 'Sunita Sharma',
        visitStatus: VisitStatus.waitingInLobby,
        paymentType: PaymentType.paidCash,
        amountCollected: 500,
        queueNumber: 1,
        scheduledDate: today,
        doctorId: 'doc_shared',
        doctorName: 'Dr. Sharma',
      );

      final babyAppt = Appointment(
        id: 'appt_2',
        patientId: 'pat_baby_102',
        patientPhone: sharedPhone,
        patientName: 'Aarav Sharma',
        patientAgeDisplay: '4 Months',
        guardianName: 'Sunita Sharma',
        guardianRelation: 'Mother',
        visitStatus: VisitStatus.waitingInLobby,
        paymentType: PaymentType.paidCash,
        amountCollected: 500,
        queueNumber: 2,
        scheduledDate: today,
        doctorId: 'doc_shared',
        doctorName: 'Dr. Sharma',
      );

      final existingAppointments = [motherAppt, babyAppt];

      // 1. Mother trying to book AGAIN on the same day with same doctor -> DUPLICATE
      final isMotherDuplicate = AppointmentEngine.hasDuplicateAppointment(
        existingAppointments: existingAppointments,
        patientPhone: sharedPhone,
        patientName: 'Sunita Sharma',
        patientId: 'pat_mother_101',
        doctorId: 'doc_shared',
        targetDate: today,
      );
      expect(isMotherDuplicate, isTrue);

      // 2. Baby trying to book AGAIN on the same day with same doctor -> DUPLICATE
      final isBabyDuplicate = AppointmentEngine.hasDuplicateAppointment(
        existingAppointments: existingAppointments,
        patientPhone: sharedPhone,
        patientName: 'Aarav Sharma',
        patientId: 'pat_baby_102',
        doctorId: 'doc_shared',
        targetDate: today,
      );
      expect(isBabyDuplicate, isTrue);

      // 3. Grandfather (new family member on same phone) booking on same day -> ALLOWED (NOT DUPLICATE)
      final isGrandfatherDuplicate = AppointmentEngine.hasDuplicateAppointment(
        existingAppointments: existingAppointments,
        patientPhone: sharedPhone,
        patientName: 'Ramesh Sharma',
        patientId: 'pat_elder_103',
        doctorId: 'doc_shared',
        targetDate: today,
      );
      expect(isGrandfatherDuplicate, isFalse);
    });
  });
}
