import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appointment_app/models/models.dart';
import 'package:appointment_app/providers/clinic_provider.dart';
import 'package:appointment_app/screens/patient_directory_screen.dart';
import 'package:appointment_app/widgets/patient/patient_lookup_card.dart';
import 'package:provider/provider.dart';

void main() {
  group('Patient Directory & Lookup Widget Tests', () {
    final patient1 = Patient(
      id: '9876543210',
      phoneNumber: '9876543210',
      name: 'Ramesh Baruah',
      age: 52,
      gender: 'Male',
      allergies: ['Penicillin'],
      lastVisitDate: DateTime(2026, 10, 10),
    );

    final patient2 = Patient(
      id: '9876543211',
      phoneNumber: '9876543211',
      name: 'Rina Sarmah',
      age: 38,
      gender: 'Female',
      allergies: [],
      lastVisitDate: DateTime(2026, 10, 5),
    );

    final consultationDocA = Consultation(
      id: 'c1',
      appointmentId: 'appt-1',
      patientPhone: '9876543210',
      patientName: 'Ramesh Baruah',
      patientAge: 52,
      patientGender: 'Male',
      doctorId: 'doc-cardio',
      doctorName: 'Dr. Bhaskar Thakuria',
      createdAt: DateTime(2026, 10, 10),
      chiefComplaints: ['Chest discomfort', 'Fatigue'],
      provisionalDiagnosis: ['Hypertension (Stage 2)'],
      prescriptionItems: [
        const PrescriptionItem(
          id: 'p1',
          action: MedicationAction.start,
          medicineName: 'Telmisartan 40mg',
          composition: 'Telmisartan IP 40mg',
          dosage: '1 Tab',
          frequency: '1-0-0',
          timing: 'After Food',
          durationDays: 30,
        ),
      ],
      adviceNotes: 'Low sodium diet, brisk walk 30 mins',
      nextFollowUpDate: DateTime(2026, 11, 10),
    );

    final consultationDocB = Consultation(
      id: 'c2',
      appointmentId: 'appt-2',
      patientPhone: '9876543210',
      patientName: 'Ramesh Baruah',
      patientAge: 52,
      patientGender: 'Male',
      doctorId: 'doc-derma',
      doctorName: 'Dr. Ananya Roy',
      createdAt: DateTime(2026, 9, 15),
      chiefComplaints: ['Skin rash', 'Itching'],
      provisionalDiagnosis: ['Contact Dermatitis'],
      prescriptionItems: [
        const PrescriptionItem(
          id: 'p2',
          action: MedicationAction.start,
          medicineName: 'Cetirizine 10mg',
          composition: 'Cetirizine Hydrochloride 10mg',
          dosage: '1 Tab',
          frequency: '0-0-1',
          timing: 'Night',
          durationDays: 10,
        ),
      ],
      adviceNotes: 'Avoid harsh soaps',
    );

    testWidgets('Initial state loads with zero egress (instructional view shown, no searches executed)', (tester) async {
      final fakeProvider = _FakePatientClinicProvider(
        allPatients: [patient1, patient2],
        consultationsByPhone: {patient1.phoneNumber: [consultationDocA, consultationDocB]},
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<ClinicProvider>.value(
          value: fakeProvider,
          child: const MaterialApp(
            home: PatientDirectoryScreen(),
          ),
        ),
      );

      // Verify zero searches were triggered initially
      expect(fakeProvider.searchCallCount, 0);

      // Verify zero-egress initial view
      expect(find.text('Patient Directory & History'), findsOneWidget);
      expect(
        find.textContaining('Search by 10-digit primary mobile number or patient name'),
        findsOneWidget,
      );
    });

    testWidgets('Searching by phone query renders matching patient card and direct walk-in button', (tester) async {
      final fakeProvider = _FakePatientClinicProvider(
        allPatients: [patient1, patient2],
        consultationsByPhone: {patient1.phoneNumber: [consultationDocA, consultationDocB]},
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<ClinicProvider>.value(
          value: fakeProvider,
          child: const MaterialApp(
            home: PatientDirectoryScreen(),
          ),
        ),
      );

      // Type phone number and submit search
      await tester.enterText(find.byType(TextField), '9876543210');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // Verify search was executed exactly once
      expect(fakeProvider.searchCallCount, 1);
      expect(fakeProvider.lastQuery, '9876543210');

      // Verify patient card rendered
      expect(find.text('Ramesh Baruah'), findsOneWidget);
      expect(find.textContaining('52 Y • Male'), findsOneWidget);
      expect(find.text('9876543210'), findsNWidgets(2)); // Input field + card
      expect(find.text('Allergies: Penicillin'), findsOneWidget);
      expect(find.text('Book Walk-In'), findsOneWidget);
    });

    testWidgets('Multi-Doctor Consultations: Segregates 2 different physicians into distinct accordions', (tester) async {
      final fakeProvider = _FakePatientClinicProvider(
        allPatients: [patient1],
        consultationsByPhone: {patient1.phoneNumber: [consultationDocA, consultationDocB]},
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<ClinicProvider>.value(
          value: fakeProvider,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PatientLookupCard(patient: patient1),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Top-level patient card displays demographics
      expect(find.text('Ramesh Baruah'), findsOneWidget);

      // Multi-doctor section header
      expect(find.text('Clinical Consultations by Physician (2)'), findsOneWidget);

      // Both doctors appear as separate accordion titles
      expect(find.text('Dr. Bhaskar Thakuria'), findsOneWidget);
      expect(find.text('Dr. Ananya Roy'), findsOneWidget);

      // Expand Doctor A (Cardiology) accordion
      await tester.tap(find.text('Dr. Bhaskar Thakuria'));
      await tester.pumpAndSettle();

      // Verify Cardiology consultation items appear
      expect(find.text('Chest discomfort, Fatigue'), findsOneWidget);
      expect(find.text('Hypertension (Stage 2)'), findsOneWidget);
      expect(find.text('Telmisartan 40mg'), findsOneWidget);
      expect(find.textContaining('Low sodium diet'), findsOneWidget);

      // Expand Doctor B (Dermatology) accordion
      await tester.tap(find.text('Dr. Ananya Roy'));
      await tester.pumpAndSettle();

      // Verify Dermatology items appear strictly segregated
      expect(find.text('Skin rash, Itching'), findsOneWidget);
      expect(find.text('Contact Dermatitis'), findsOneWidget);
      expect(find.text('Cetirizine 10mg'), findsOneWidget);
      expect(find.textContaining('Avoid harsh soaps'), findsOneWidget);
    });

    testWidgets('Empty search results display helpful not-found prompt and register action', (tester) async {
      final fakeProvider = _FakePatientClinicProvider(
        allPatients: [patient1],
        consultationsByPhone: {},
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<ClinicProvider>.value(
          value: fakeProvider,
          child: const MaterialApp(
            home: PatientDirectoryScreen(),
          ),
        ),
      );

      // Search non-existent patient
      await tester.enterText(find.byType(TextField), '9999999999');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.text('No patients found matching "9999999999"'), findsOneWidget);
      expect(find.text('Book New Patient Walk-In'), findsOneWidget);
    });
  });
}

class _FakePatientClinicProvider extends ChangeNotifier implements ClinicProvider {
  final List<Patient> allPatients;
  final Map<String, List<Consultation>> consultationsByPhone;

  int searchCallCount = 0;
  String lastQuery = '';

  _FakePatientClinicProvider({
    required this.allPatients,
    required this.consultationsByPhone,
  });

  @override
  Future<List<Patient>> searchPatients(String query) async {
    searchCallCount++;
    lastQuery = query;
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return [];

    return allPatients.where((p) {
      return p.phoneNumber.contains(clean) || p.name.toLowerCase().contains(clean);
    }).toList();
  }

  @override
  Future<List<Consultation>> getPatientConsultations(
    String patientId, {
    String? phone,
  }) async {
    return consultationsByPhone[phone ?? patientId] ?? [];
  }

  @override
  List<Doctor> get doctors => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
