import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appointment_app/models/models.dart';
import 'package:appointment_app/providers/auth_provider.dart';
import 'package:appointment_app/providers/clinic_provider.dart';
import 'package:appointment_app/screens/dashboard_screen.dart';
import 'package:appointment_app/screens/owner_shell.dart';
import 'package:appointment_app/services/sound_service.dart';
import 'package:appointment_app/widgets/dashboard/dashboard_queue_card.dart';
import 'package:provider/provider.dart';

class _FakeMobileClinicProvider extends ChangeNotifier implements ClinicProvider {
  final List<Appointment> _appts;
  final List<Doctor> _docs;
  final ChamberSession _session;

  _FakeMobileClinicProvider({
    required this._appts,
    required this._docs,
    required this._session,
  });

  @override
  List<Appointment> get todayAppointments => List.unmodifiable(_appts);

  @override
  List<Doctor> get doctors => List.unmodifiable(_docs);

  @override
  String get dashboardSearchQuery => '';

  @override
  bool get isOfflineFallback => false;

  @override
  DateTime? get offlineCacheTimestamp => null;

  @override
  int get waitingInLobbyCount =>
      _appts.where((a) => a.visitStatus == VisitStatus.waitingInLobby).length;

  @override
  int get completedCount =>
      _appts.where((a) => a.status == AppointmentStatus.completed).length;

  @override
  int get absentCount =>
      _appts.where((a) => a.status == AppointmentStatus.absent).length;

  @override
  List<Appointment> getFilteredAppointments({String? doctorId}) {
    if (doctorId == null) return _appts;
    return _appts.where((a) => a.doctorId == doctorId).toList();
  }

  @override
  void startListeningToAppointments([DateTime? specificDate]) {}

  @override
  Stream<ChamberSession> streamChamberSession(String doctorId, DateTime date) {
    return Stream.value(_session);
  }

  @override
  Stream<Map<String, ChamberSession>> streamAllChamberSessions(DateTime date) {
    return Stream.value({
      if (_docs.isNotEmpty) _docs.first.id: _session,
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final testDoctor = Doctor(
    id: 'doc-1',
    name: 'Dr. Baruah',
    specialty: 'Cardiology',
    phone: '9876543210',
    availableDays: ['Mon', 'Wed', 'Fri'],
    blockedDates: [],
    shiftTiming: '6:00 PM – 8:30 PM',
  );

  final testAppt = Appointment(
    id: 'appt-1',
    queueNumber: 1,
    patientName: 'Pranab Bordoloi Long Patient Name',
    patientPhone: '9876543210',
    doctorId: 'doc-1',
    doctorName: 'Dr. Baruah',
    scheduledDate: DateTime.now(),
    status: AppointmentStatus.pending,
    visitStatus: VisitStatus.waitingInLobby,
    paymentType: PaymentType.paidCash,
    amountCollected: 500,
  );

  final chamberSession = ChamberSession(
    doctorId: 'doc-1',
    date: DateTime.now(),
    status: 'ready_for_next',
    activeAppointmentId: null,
    activeQueueNumber: null,
  );

  Widget createWidget({
    required Widget child,
    required Size screenSize,
    ClinicProvider? clinicProvider,
  }) {
    final authProvider = AuthProvider();
    final soundService = SoundService.create(initialMuted: false);
    final fakeClinic = clinicProvider ??
        _FakeMobileClinicProvider(
          appts: [testAppt],
          docs: [testDoctor],
          session: chamberSession,
        );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<ClinicProvider>.value(value: fakeClinic),
        ChangeNotifierProvider<SoundService>.value(value: soundService),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: child,
        ),
      ),
    );
  }

  group('Mobile Reception Dashboard & Queue Card Tests', () {
    testWidgets('OwnerShell on mobile renders FloatingActionButton for Walk-In booking', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createWidget(
          child: const OwnerShell(),
          screenSize: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      // Mobile FAB must be rendered
      expect(find.byKey(const Key('mobile_book_walkin_fab')), findsOneWidget);
      expect(find.text('Book Walk-In'), findsWidgets);
    });

    testWidgets('DashboardScreen on mobile displays sleek header without duplicate Walk-In header button', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createWidget(
          child: const DashboardScreen(),
          screenSize: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('GuwahatiOne Clinic'), findsOneWidget);
      expect(find.byKey(const Key('dashboard_mobile_walkin_button')), findsNothing);
    });

    testWidgets('DashboardTodayQueueCard on mobile renders mobile patient card without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 720); // Small Android phone
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final clinicProvider = _FakeMobileClinicProvider(
        appts: [testAppt],
        docs: [testDoctor],
        session: chamberSession,
      );

      await tester.pumpWidget(
        createWidget(
          child: Scaffold(
            body: SingleChildScrollView(
              child: DashboardTodayQueueCard(provider: clinicProvider),
            ),
          ),
          screenSize: const Size(360, 720),
          clinicProvider: clinicProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Verify patient details and mobile action button render cleanly without overflow
      expect(find.text('Pranab Bordoloi Long Patient Name'), findsOneWidget);
      expect(find.textContaining('9876543210'), findsOneWidget);
      expect(find.text('In Lobby'), findsOneWidget);
      expect(
        find.text('Send Token #1 into Chamber'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
