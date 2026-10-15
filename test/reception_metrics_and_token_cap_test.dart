import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appointment_app/core/engines/engines.dart';
import 'package:appointment_app/models/models.dart';
import 'package:appointment_app/providers/auth_provider.dart';
import 'package:appointment_app/providers/clinic_provider.dart';
import 'package:appointment_app/widgets/booking/booking_payment_section.dart';
import 'package:appointment_app/widgets/dashboard/dashboard_doctor_roster_card.dart';
import 'package:appointment_app/widgets/dashboard/dashboard_kpi_strip.dart';
import 'package:provider/provider.dart';

void main() {
  group('Token Cap & Schedule Pure Engine Tests', () {
    final targetDate = DateTime(2026, 10, 14);

    test('Doctor.formattedSchedule formats days and timing cleanly', () {
      final doc = Doctor(
        id: 'doc-1',
        name: 'Dr. Bhaskar',
        specialty: 'General Medicine',
        phone: '9876543210',
        availableDays: ['Mon', 'Wed', 'Fri'],
        blockedDates: [],
        shiftTiming: '6:00 PM – 8:30 PM',
        dailyTokenLimit: 18,
      );

      expect(doc.formattedSchedule, 'Mon, Wed, Fri • 6:00 PM – 8:30 PM');
      expect(doc.dailyTokenLimit, 18);
    });

    test('Doctor serialization and deserialization preserves shiftTiming and tokenLimit', () {
      final doc = Doctor(
        id: 'doc-2',
        name: 'Dr. Sharma',
        specialty: 'Cardiology',
        phone: '9876543211',
        availableDays: ['Tue', 'Thu'],
        blockedDates: [],
        shiftTiming: '10:00 AM – 1:00 PM',
        dailyTokenLimit: 25,
      );

      final json = doc.toJson();
      expect(json['shiftTiming'], '10:00 AM – 1:00 PM');
      expect(json['dailyTokenLimit'], 25);

      final recovered = Doctor.fromJson(json);
      expect(recovered.shiftTiming, '10:00 AM – 1:00 PM');
      expect(recovered.dailyTokenLimit, 25);
      expect(recovered.formattedSchedule, 'Tue, Thu • 10:00 AM – 1:00 PM');
    });

    test('calculateBookedTokensCount returns 0 when no appointments exist', () {
      final count = AppointmentEngine.calculateBookedTokensCount(
        appointments: [],
        doctorId: 'doc-1',
        targetDate: targetDate,
      );
      expect(count, 0);
    });

    test('calculateBookedTokensCount returns highest issued queue token for that doctor', () {
      final appts = [
        Appointment(
          id: 'a1',
          patientPhone: '111',
          patientName: 'Patient 1',
          status: AppointmentStatus.pending,
          visitStatus: VisitStatus.waitingInLobby,
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 1,
          scheduledDate: targetDate,
          doctorId: 'doc-1',
          doctorName: 'Dr. One',
        ),
        Appointment(
          id: 'a2',
          patientPhone: '222',
          patientName: 'Patient 2',
          status: AppointmentStatus.completed,
          visitStatus: VisitStatus.completed,
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 12,
          scheduledDate: targetDate,
          doctorId: 'doc-1',
          doctorName: 'Dr. One',
        ),
        Appointment(
          id: 'a3',
          patientPhone: '333',
          patientName: 'Patient 3',
          status: AppointmentStatus.pending,
          visitStatus: VisitStatus.waitingInLobby,
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 5,
          scheduledDate: targetDate.add(const Duration(days: 1)), // Next day
          doctorId: 'doc-1',
          doctorName: 'Dr. One',
        ),
        Appointment(
          id: 'a4',
          patientPhone: '444',
          patientName: 'Patient 4',
          status: AppointmentStatus.pending,
          visitStatus: VisitStatus.waitingInLobby,
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: 20,
          scheduledDate: targetDate,
          doctorId: 'doc-OTHER',
          doctorName: 'Dr. Other',
        ),
      ];

      final count = AppointmentEngine.calculateBookedTokensCount(
        appointments: appts,
        doctorId: 'doc-1',
        targetDate: targetDate,
      );
      expect(count, 12);
    });

    test('evaluateTokenCapStatus transitions smoothly across all 4 thresholds', () {
      const limit = 18;

      // Normal: booked < limit - 2 (< 16)
      expect(
        AppointmentEngine.evaluateTokenCapStatus(bookedCount: 0, limit: limit),
        TokenCapStatus.normal,
      );
      expect(
        AppointmentEngine.evaluateTokenCapStatus(bookedCount: 12, limit: limit),
        TokenCapStatus.normal,
      );
      expect(
        AppointmentEngine.evaluateTokenCapStatus(bookedCount: 15, limit: limit),
        TokenCapStatus.normal,
      );

      // Runway Alert: limit - 2 <= booked < limit (16 and 17)
      expect(
        AppointmentEngine.evaluateTokenCapStatus(bookedCount: 16, limit: limit),
        TokenCapStatus.runwayAlert,
      );
      expect(
        AppointmentEngine.evaluateTokenCapStatus(bookedCount: 17, limit: limit),
        TokenCapStatus.runwayAlert,
      );

      // At Limit: booked == limit (18)
      expect(
        AppointmentEngine.evaluateTokenCapStatus(bookedCount: 18, limit: limit),
        TokenCapStatus.atLimit,
      );

      // Over Cap: booked > limit (> 18)
      expect(
        AppointmentEngine.evaluateTokenCapStatus(bookedCount: 19, limit: limit),
        TokenCapStatus.overCap,
      );
      expect(
        AppointmentEngine.evaluateTokenCapStatus(bookedCount: 22, limit: limit),
        TokenCapStatus.overCap,
      );
    });

    test('AppointmentEngine.isDoctorAvailableOnDate validates schedule correctly', () {
      final docWithDays = Doctor(
        id: 'doc-1',
        name: 'Dr. A. Sharma',
        specialty: 'General Medicine',
        phone: '9876543210',
        availableDays: ['Mon', 'Wed', 'Fri'],
        blockedDates: [],
        shiftTiming: '6:00 PM – 8:30 PM',
        consultationFee: 500,
        freeReviewDays: 14,
        dailyTokenLimit: 18,
      );

      final docAllDays = Doctor(
        id: 'doc-2',
        name: 'Dr. All Days',
        specialty: 'Pediatrics',
        phone: '9876543211',
        availableDays: [],
        blockedDates: [],
        shiftTiming: '10:00 AM – 2:00 PM',
        consultationFee: 400,
        freeReviewDays: 14,
        dailyTokenLimit: 18,
      );

      // 12-10-2026 is Monday (Mon) -> true
      final monday = DateTime(2026, 10, 12);
      expect(AppointmentEngine.isDoctorAvailableOnDate(doctor: docWithDays, date: monday), isTrue);

      // 13-10-2026 is Tuesday (Tue) -> false
      final tuesday = DateTime(2026, 10, 13);
      expect(AppointmentEngine.isDoctorAvailableOnDate(doctor: docWithDays, date: tuesday), isFalse);

      // 14-10-2026 is Wednesday (Wed) -> true
      final wednesday = DateTime(2026, 10, 14);
      expect(AppointmentEngine.isDoctorAvailableOnDate(doctor: docWithDays, date: wednesday), isTrue);

      // Doctor with empty availableDays sits on all days
      expect(AppointmentEngine.isDoctorAvailableOnDate(doctor: docAllDays, date: tuesday), isTrue);

      // Null doctor returns true
      expect(AppointmentEngine.isDoctorAvailableOnDate(doctor: null, date: tuesday), isTrue);
    });
  });

  group('Token Cap Badge Widget Tests in BookingPaymentSection', () {
    final testDoctor = Doctor(
      id: 'doc-1',
      name: 'Dr. A. Sharma',
      specialty: 'General Medicine',
      phone: '9876543210',
      availableDays: ['Mon', 'Wed', 'Fri'],
      blockedDates: [],
      shiftTiming: '6:00 PM – 8:30 PM',
      dailyTokenLimit: 18,
    );

    Widget buildTestHarness(int bookedCount) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: BookingPaymentSection(
              doctors: [testDoctor],
              selectedDoctor: testDoctor,
              onDoctorChanged: (_) {},
              selectedPayment: PaymentType.paidCash,
              onPaymentChanged: (_) {},
              reviewEligibility: const PatientReviewEligibility(
                hasVisitedDoctorEarlier: false,
                isWithinReviewPeriod: false,
                message: '',
              ),
              amountController: TextEditingController(text: '500'),
              bookedTokensCount: bookedCount,
            ),
          ),
        ),
      );
    }

    testWidgets('Renders Normal badge [ 12/18 Booked ] when under threshold', (tester) async {
      await tester.pumpWidget(buildTestHarness(12));
      expect(find.text('12/18 Booked'), findsOneWidget);
    });

    testWidgets('Renders Runway Alert badge [ ⚠️ 16/18 Booked • 2 Left ] at Limit - 2', (tester) async {
      await tester.pumpWidget(buildTestHarness(16));
      expect(find.text('⚠️ 16/18 Booked • 2 Left'), findsOneWidget);
    });

    testWidgets('Renders At Limit badge [ ⚠️ 18/18 Full ] when at capacity', (tester) async {
      await tester.pumpWidget(buildTestHarness(18));
      expect(find.text('⚠️ 18/18 Full'), findsOneWidget);
    });

    testWidgets('Renders Over Cap badge [ 🔴 19/18 • Extra Token ] when exceeding limit', (tester) async {
      await tester.pumpWidget(buildTestHarness(19));
      expect(find.text('🔴 19/18 • Extra Token'), findsOneWidget);
    });
  });

  group('Doctor Chamber Roster Live Status & Schedule Display Tests', () {
    final testDoctor = Doctor(
      id: 'doc-test-1',
      name: 'Dr. Kaushik',
      specialty: 'Cardiology',
      phone: '9998887776',
      availableDays: ['Mon', 'Wed', 'Fri'],
      blockedDates: [],
      shiftTiming: '6:00 PM – 8:30 PM',
      dailyTokenLimit: 18,
    );

    testWidgets('Displays formatted schedule in subtitle and Consulting: [patient_name] badge', (tester) async {
      final fakeSession = ChamberSession(
        doctorId: 'doc-test-1',
        date: DateTime.now(),
        status: 'in_consultation',
        activeAppointmentId: 'appt-123',
        activeQueueNumber: 5,
        patientName: 'Kaushik Talukdar',
      );

      final authProvider = AuthProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: DashboardDoctorRosterCard(
                provider: _FakeClinicProvider(testDoctor, fakeSession),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check doctor title
      expect(find.text('Dr. Kaushik'), findsOneWidget);

      // Check schedule in subtitle replacing fee
      expect(
        find.text('Cardiology • Mon, Wed, Fri • 6:00 PM – 8:30 PM'),
        findsOneWidget,
      );

      // Check live status indicator preserving Consulting: [patient_name]
      expect(find.text('Consulting: Kaushik Talukdar'), findsOneWidget);

      // Check token indicator
      expect(find.text('Token #5'), findsOneWidget);
    });

    testWidgets('Displays IN CHAMBER status and schedule when chamber is empty', (tester) async {
      final fakeSession = ChamberSession.empty('doc-test-1', DateTime.now());
      final authProvider = AuthProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: DashboardDoctorRosterCard(
                provider: _FakeClinicProvider(testDoctor, fakeSession),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('IN CHAMBER'), findsOneWidget);
      expect(
        find.text('Cardiology • Mon, Wed, Fri • 6:00 PM – 8:30 PM'),
        findsOneWidget,
      );
    });

    testWidgets('Displays ABSENT status when doctor is on leave today', (tester) async {
      final today = DateTime.now();
      final absentDoctor = Doctor(
        id: 'doc-absent-1',
        name: 'Dr. Absent Doctor',
        specialty: 'Pediatrics',
        phone: '9876543210',
        availableDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        consultationFee: 500,
        blockedDates: [today],
      );
      final fakeSession = ChamberSession.empty('doc-absent-1', today);
      final authProvider = AuthProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: DashboardDoctorRosterCard(
                provider: _FakeClinicProvider(absentDoctor, fakeSession),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ABSENT'), findsOneWidget);
    });
  });

  group('Top Metrics Row (4-Stage Pipeline) Tests', () {
    testWidgets('DashboardKpiStrip renders Total Booked, In Lobby, Completed, and No-Show', (tester) async {
      final doctor = Doctor(
        id: 'doc-1',
        name: 'Dr. One',
        specialty: 'General',
        phone: '123',
        availableDays: ['Mon'],
        blockedDates: [],
      );

      final fakeProvider = _FakeClinicProviderWithMetrics(
        doctor: doctor,
        totalBooked: 24,
        inLobby: 6,
        completed: 15,
        absent: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardKpiStrip(
              provider: fakeProvider,
              screenWidth: 1200,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Total Booked'), findsOneWidget);
      expect(find.text('24'), findsOneWidget);

      expect(find.text('In Lobby'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);

      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);

      expect(find.text('No-Show'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });
  });
}

class _FakeClinicProvider extends ChangeNotifier implements ClinicProvider {
  final Doctor _doctor;
  final ChamberSession _session;

  _FakeClinicProvider(this._doctor, this._session);

  @override
  List<Doctor> get doctors => [_doctor];

  @override
  List<Appointment> get todayAppointments => [];

  @override
  Stream<ChamberSession> streamChamberSession(String doctorId, DateTime date) {
    return Stream.value(_session);
  }

  @override
  Stream<Map<String, ChamberSession>> streamAllChamberSessions(DateTime date) {
    return Stream.value({_doctor.id: _session});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeClinicProviderWithMetrics extends ChangeNotifier implements ClinicProvider {
  final Doctor doctor;
  final int totalBooked;
  final int inLobby;
  final int completed;
  final int absent;

  _FakeClinicProviderWithMetrics({
    required this.doctor,
    required this.totalBooked,
    required this.inLobby,
    required this.completed,
    required this.absent,
  });

  @override
  List<Appointment> get todayAppointments => List.generate(
        totalBooked,
        (i) => Appointment(
          id: 'appt-$i',
          patientPhone: '111',
          patientName: 'P$i',
          status: AppointmentStatus.pending,
          visitStatus: VisitStatus.waitingInLobby,
          paymentType: PaymentType.paidCash,
          amountCollected: 500,
          queueNumber: i + 1,
          scheduledDate: DateTime.now(),
          doctorId: doctor.id,
          doctorName: doctor.name,
        ),
      );

  @override
  int get waitingInLobbyCount => inLobby;

  @override
  int get completedCount => completed;

  @override
  int get absentCount => absent;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
