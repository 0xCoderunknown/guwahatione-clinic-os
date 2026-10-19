import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:appointment_app/models/models.dart';
import 'package:appointment_app/providers/auth_provider.dart';
import 'package:appointment_app/providers/clinic_provider.dart';
import 'package:appointment_app/screens/owner_shell.dart';
import 'package:appointment_app/services/sound_service.dart';
import 'package:appointment_app/widgets/booking/add_appointment_dialog.dart';

class _FakeClinicProvider extends ChangeNotifier implements ClinicProvider {
  @override
  List<Doctor> doctors = [
    Doctor(
      id: 'doc_1',
      name: 'Dr. Bhaskar Baruah',
      phone: '9876543210',
      specialty: 'Cardiologist',
      consultationFee: 500,
      availableDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
      blockedDates: [],
    ),
  ];

  @override
  List<Doctor> get allDoctors => doctors;

  @override
  List<Doctor> get inactiveDoctors => [];

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
  UserRole _role = UserRole.receptionist;

  @override
  UserRole? get currentRole => _role;

  @override
  bool get isOwner => _role == UserRole.owner;

  @override
  bool get isReceptionist => _role == UserRole.receptionist;

  @override
  bool get isAuthenticated => true;

  @override
  Future<void> stepDownToReception() async {
    _role = UserRole.receptionist;
    notifyListeners();
  }

  @override
  Future<void> logout() async {
    _role = UserRole.receptionist;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrapShell(Widget child, {Size size = const Size(1280, 800)}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => _FakeAuthProvider()),
      ChangeNotifierProvider<ClinicProvider>(create: (_) => _FakeClinicProvider()),
      ChangeNotifierProvider<SoundService>(
        create: (_) => SoundService.create(initialMuted: false),
      ),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: child,
      ),
    ),
  );
}

void main() {
  group('OwnerShell - Universal Booking Modal & LOGOUT Button Tests', () {
    testWidgets('Desktop sidebar renders Book Walk-In (F2) and clear LOGOUT button', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _wrapShell(const OwnerShell(), size: const Size(1280, 800)),
      );
      await tester.pumpAndSettle();

      // Sidebar booking button with F2 indicator
      expect(find.byKey(const Key('sidebar_book_walkin_btn')), findsOneWidget);
      expect(find.text('Book Walk-In (F2)'), findsOneWidget);

      // Explicit LOGOUT button with text label
      expect(find.byKey(const Key('sidebar_logout_btn')), findsOneWidget);
      expect(find.text('LOGOUT'), findsOneWidget);
    });

    testWidgets(
      'Re-entrancy Guard: Rapid double clicks on Book Walk-In modal launch exactly ONE dialog',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          _wrapShell(const OwnerShell(), size: const Size(1280, 800)),
        );
        await tester.pumpAndSettle();

        final bookButton = find.byKey(const Key('sidebar_book_walkin_btn'));
        expect(bookButton, findsOneWidget);

        // Tap once
        await tester.tap(bookButton);
        // Immediately tap again before settle (simulating rapid double-click)
        await tester.tap(bookButton, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Exactly ONE AddAppointmentDialog modal should exist
        expect(find.byType(AddAppointmentDialog), findsOneWidget);

        // Cancel modal
        final cancelBtn = find.text('Cancel');
        expect(cancelBtn, findsOneWidget);
        await tester.tap(cancelBtn);
        await tester.pumpAndSettle();

        // Modal dismissed, back to dashboard
        expect(find.byType(AddAppointmentDialog), findsNothing);
      },
    );

    testWidgets('Mobile shell displays floating Walk-In button across all tabs', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _wrapShell(const OwnerShell(), size: const Size(390, 844)),
      );
      await tester.pumpAndSettle();

      // Tab 0 (Dashboard)
      expect(find.byKey(const Key('mobile_book_walkin_fab')), findsOneWidget);

      // Switch to Tab 2 (Patients)
      await tester.tap(find.text('Patients'));
      await tester.pumpAndSettle();

      // FAB remains present on Patients tab
      expect(find.byKey(const Key('mobile_book_walkin_fab')), findsOneWidget);

      // Switch to Tab 3 (Schedules)
      await tester.tap(find.text('Schedules'));
      await tester.pumpAndSettle();

      // FAB remains present on Schedules tab
      expect(find.byKey(const Key('mobile_book_walkin_fab')), findsOneWidget);
    });
  });
}
