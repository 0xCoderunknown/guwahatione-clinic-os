import 'package:appointment_app/models/models.dart';
import 'package:appointment_app/providers/auth_provider.dart';
import 'package:appointment_app/providers/clinic_provider.dart';
import 'package:appointment_app/services/sound_service.dart';
import 'package:appointment_app/widgets/booking/add_appointment_dialog.dart';
import 'package:appointment_app/widgets/booking/booking_payment_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeClinicProvider extends ChangeNotifier implements ClinicProvider {
  final List<Doctor> _docs;

  _FakeClinicProvider(this._docs);

  @override
  List<Doctor> get doctors => _docs;

  @override
  List<Appointment> get todayAppointments => [];

  @override
  String get dashboardSearchQuery => '';

  @override
  bool get isOfflineFallback => false;

  @override
  DateTime? get offlineCacheTimestamp => null;

  @override
  int get completedCount => 0;

  @override
  int get absentCount => 0;

  @override
  List<Appointment> getFilteredAppointments({String? doctorId}) => [];

  @override
  int get waitingInLobbyCount => 0;

  @override
  int get expectedBookedCount => 0;

  @override
  int get inConsultationCount => 0;

  @override
  List<Medicine> get medicines => [];

  @override
  void startListeningToAppointments([DateTime? specificDate]) {}

  @override
  Stream<ChamberSession> streamChamberSession(String doctorId, DateTime date) =>
      Stream.value(
        ChamberSession(
          doctorId: doctorId,
          date: DateTime(2026, 10, 19),
          status: 'ready_for_next',
        ),
      );

  @override
  Stream<Map<String, ChamberSession>> streamAllChamberSessions(DateTime date) =>
      Stream.value({});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  UserRole? get currentRole => UserRole.receptionist;

  @override
  bool get isOwner => false;

  @override
  bool get isReceptionist => true;

  @override
  bool get isAuthenticated => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final doc1 = Doctor(
    id: 'doc_1',
    name: 'Dr. Bhaskar Baruah',
    specialty: 'Cardiologist',
    phone: '9876543210',
    availableDays: ['Mon', 'Tue', 'Wed'],
    blockedDates: const [],
    consultationFee: 500,
  );

  final doc2 = Doctor(
    id: 'doc_2',
    name: 'Dr. Anamika Das',
    specialty: 'Diabetology',
    phone: '9876543211',
    availableDays: ['Mon', 'Thu', 'Fri'],
    blockedDates: const [],
    consultationFee: 600,
  );

  group('Solo Doctor Auto-Select vs Multi-Doctor Dropdown Tests', () {
    testWidgets(
      'When only 1 doctor exists, BookingPaymentSection renders pre-selected card with NO dropdown',
      (tester) async {
        final amountController = TextEditingController(text: '500');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: BookingPaymentSection(
                  doctors: [doc1],
                  selectedDoctor: doc1,
                  onDoctorChanged: (_) {},
                  selectedPayment: PaymentType.paidCash,
                  onPaymentChanged: (_) {},
                  reviewEligibility: const PatientReviewEligibility(
                    hasVisitedDoctorEarlier: false,
                    isWithinReviewPeriod: false,
                    message: '',
                  ),
                  amountController: amountController,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Must display the doctor's name and fee in pre-selected card
        expect(find.text(doc1.titleName), findsOneWidget);
        expect(find.textContaining('Fee: ₹500'), findsOneWidget);

        // Must NOT render any DropdownButtonFormField for doctor selection
        expect(find.byType(DropdownButtonFormField<Doctor>), findsNothing);
      },
    );

    testWidgets(
      'When 2+ doctors exist, BookingPaymentSection renders DropdownButtonFormField for selection',
      (tester) async {
        final amountController = TextEditingController(text: '500');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: BookingPaymentSection(
                  doctors: [doc1, doc2],
                  selectedDoctor: doc1,
                  onDoctorChanged: (_) {},
                  selectedPayment: PaymentType.paidCash,
                  onPaymentChanged: (_) {},
                  reviewEligibility: const PatientReviewEligibility(
                    hasVisitedDoctorEarlier: false,
                    isWithinReviewPeriod: false,
                    message: '',
                  ),
                  amountController: amountController,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Must render DropdownButtonFormField for doctor selection
        expect(find.byType(DropdownButtonFormField<Doctor>), findsOneWidget);
        expect(find.text('Select Doctor'), findsOneWidget);
      },
    );

    testWidgets(
      'AddAppointmentDialog with 1 registered doctor comes pre-selected with that doctor',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final clinic = _FakeClinicProvider([doc1]);
        final auth = _FakeAuthProvider();
        final sound = SoundService.create(initialMuted: false);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ClinicProvider>.value(value: clinic),
              ChangeNotifierProvider<AuthProvider>.value(value: auth),
              ChangeNotifierProvider<SoundService>.value(value: sound),
            ],
            child: const MaterialApp(
              home: Scaffold(body: AddAppointmentDialog()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Doctor is pre-selected
        expect(find.text(doc1.titleName), findsOneWidget);
        expect(find.textContaining('Fee: ₹500'), findsOneWidget);
        // No doctor dropdown
        expect(find.byType(DropdownButtonFormField<Doctor>), findsNothing);
      },
    );
  });
}
