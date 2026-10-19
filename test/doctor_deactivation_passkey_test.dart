import 'package:appointment_app/models/models.dart';
import 'package:appointment_app/providers/auth_provider.dart';
import 'package:appointment_app/providers/clinic_provider.dart';
import 'package:appointment_app/screens/doctor_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeClinicProvider extends ChangeNotifier implements ClinicProvider {
  final List<Doctor> _allDocs;
  bool setDoctorActiveStatusCalled = false;
  String? updatedDoctorId;
  bool? updatedActiveStatus;

  _FakeClinicProvider(this._allDocs);

  @override
  List<Doctor> get doctors => _allDocs.where((d) => d.isActive).toList();

  @override
  List<Doctor> get allDoctors => _allDocs;

  @override
  List<Doctor> get inactiveDoctors =>
      _allDocs.where((d) => !d.isActive).toList();

  @override
  Future<void> setDoctorActiveStatus(
    String doctorId,
    bool isActive, {
    UserRole? requestingRole,
  }) async {
    if (requestingRole != null && !requestingRole.isOwner) {
      throw Exception('Permission Denied');
    }
    setDoctorActiveStatusCalled = true;
    updatedDoctorId = doctorId;
    updatedActiveStatus = isActive;
    final index = _allDocs.indexWhere((d) => d.id == doctorId);
    if (index != -1) {
      _allDocs[index] = _allDocs[index].copyWith(isActive: isActive);
      notifyListeners();
    }
  }

  @override
  Doctor? getDoctorById(String doctorId) =>
      _allDocs.where((d) => d.id == doctorId).firstOrNull;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Doctor Model & Deactivation Field Invariance', () {
    test('Doctor defaults isActive to true', () {
      final doc = Doctor(
        id: 'doc-1',
        name: 'Dr. Bhaskar Baruah',
        specialty: 'Internal Medicine',
        phone: '9864012345',
        availableDays: ['Mon', 'Wed'],
        blockedDates: [],
      );

      expect(doc.isActive, isTrue);
      expect(doc.toJson()['isActive'], isTrue);
    });

    test('Doctor fromJson preserves isActive true and false correctly', () {
      final jsonActive = {
        'id': 'doc-1',
        'name': 'Dr. Active',
        'specialty': 'Medicine',
        'phone': '9864012345',
        'availableDays': ['Mon'],
        'blockedDates': [],
      };
      final docActive = Doctor.fromJson(jsonActive);
      expect(docActive.isActive, isTrue);

      final jsonInactive = {
        'id': 'doc-2',
        'name': 'Dr. Inactive',
        'specialty': 'Pediatrics',
        'phone': '9864054321',
        'availableDays': ['Tue'],
        'blockedDates': [],
        'isActive': false,
      };
      final docInactive = Doctor.fromJson(jsonInactive);
      expect(docInactive.isActive, isFalse);
      expect(docInactive.toJson()['isActive'], isFalse);
    });

    test('Doctor copyWith modifies isActive without altering other fields', () {
      final original = Doctor(
        id: 'doc-1',
        name: 'Dr. Test',
        specialty: 'ENT',
        phone: '9864011111',
        availableDays: ['Fri'],
        blockedDates: [],
        isActive: true,
      );

      final deactivated = original.copyWith(isActive: false);
      expect(deactivated.isActive, isFalse);
      expect(deactivated.name, original.name);
      expect(deactivated.phone, original.phone);
    });
  });

  group('AuthProvider Master Passkey Verification & Inactive Login Lock', () {
    test('verifyOwnerMasterPin validates default master PIN 849201', () async {
      final auth = AuthProvider();
      await auth.initSession([]);

      expect(auth.verifyOwnerMasterPin('849201'), isTrue);
      expect(auth.verifyOwnerMasterPin(' 849201 '), isTrue); // trims whitespace
      expect(auth.verifyOwnerMasterPin('000000'), isFalse);
      expect(auth.verifyOwnerMasterPin('1234'), isFalse);
      expect(auth.verifyOwnerMasterPin(''), isFalse);
    });

    test('verifyOwnerMasterPin respects custom setOwnerMasterPin', () async {
      final auth = AuthProvider();
      await auth.initSession([]);

      await auth.setOwnerMasterPin('998877');
      expect(auth.verifyOwnerMasterPin('998877'), isTrue);
      expect(auth.verifyOwnerMasterPin('000000'), isFalse);
    });

    test('Inactive doctor cannot authenticate via PIN', () async {
      final auth = AuthProvider();
      final inactiveDoc = Doctor(
        id: 'doc-inactive',
        name: 'Dr. Retired',
        specialty: 'Surgery',
        phone: '9864000000',
        availableDays: ['Mon'],
        blockedDates: [],
        pin: '5555',
        isActive: false,
      );

      await auth.initSession([inactiveDoc]);

      // 1. authenticateWithPin should reject inactive doctor PIN
      final result = await auth.authenticateWithPin(
        pin: '5555',
        doctors: [inactiveDoc],
      );
      expect(result.isSuccess, isFalse);

      // 2. loginAsDoctor directly should reject inactive doctor
      final directLogin = await auth.loginAsDoctor(inactiveDoc, '5555');
      expect(directLogin, isFalse);
      expect(auth.currentDoctor, isNull);
    });
  });

  group('ClinicProvider Doctor Segregation & Guardrails', () {
    test('doctors getter strictly filters out inactive doctors', () {
      final doc1 = Doctor(
        id: 'doc-1',
        name: 'Dr. Active One',
        specialty: 'General',
        phone: '9864011111',
        availableDays: ['Mon'],
        blockedDates: [],
        isActive: true,
      );
      final doc2 = Doctor(
        id: 'doc-2',
        name: 'Dr. Inactive Two',
        specialty: 'Dermatology',
        phone: '9864022222',
        availableDays: ['Tue'],
        blockedDates: [],
        isActive: false,
      );

      final fakeProvider = _FakeClinicProvider([doc1, doc2]);

      expect(fakeProvider.doctors.length, 1);
      expect(fakeProvider.doctors.first.name, 'Dr. Active One');
      expect(fakeProvider.allDoctors.length, 2);
      expect(fakeProvider.inactiveDoctors.length, 1);
      expect(fakeProvider.inactiveDoctors.first.name, 'Dr. Inactive Two');
    });
  });

  group('DoctorListScreen Owner UI & Admin Passkey Gate', () {
    testWidgets(
      'Owner sees Active and Inactive segments, [INACTIVE] badge, and Passkey prompt',
      (tester) async {
        final activeDoc = Doctor(
          id: 'doc-active',
          name: 'Dr. Bikash Sharma',
          specialty: 'Internal Medicine',
          phone: '9864012345',
          availableDays: ['Mon', 'Wed'],
          blockedDates: [],
          pin: '1234',
          isActive: true,
        );
        final inactiveDoc = Doctor(
          id: 'doc-inactive',
          name: 'Dr. Hiren Saikia',
          specialty: 'Pediatrics',
          phone: '9864054321',
          availableDays: ['Tue', 'Thu'],
          blockedDates: [],
          pin: '5678',
          isActive: false,
        );

        final authProvider = AuthProvider();
        await authProvider.initSession([activeDoc, inactiveDoc]);
        await authProvider.loginAsOwner('849201');

        final clinicProvider = _FakeClinicProvider([activeDoc, inactiveDoc]);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
              ChangeNotifierProvider<ClinicProvider>.value(
                value: clinicProvider,
              ),
            ],
            child: const MaterialApp(home: DoctorListScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verify Active segment is visible and selected by default
        expect(find.byKey(const Key('segment_active_doctors')), findsOneWidget);
        expect(
          find.byKey(const Key('segment_inactive_doctors')),
          findsOneWidget,
        );
        expect(find.text('Dr. Bikash Sharma'), findsOneWidget);
        expect(find.text('Dr. Hiren Saikia'), findsNothing);

        // 2. Switch to Inactive / Retired segment
        await tester.tap(find.byKey(const Key('segment_inactive_doctors')));
        await tester.pumpAndSettle();

        // 3. Verify Inactive Doctor card renders with [INACTIVE] badge and Reactivate button
        expect(find.text('Dr. Hiren Saikia'), findsOneWidget);
        expect(
          find.textContaining('INACTIVE', findRichText: true),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('reactivate_btn_doc-inactive')),
          findsOneWidget,
        );

        // 4. Tap Reactivate Doctor to open Passkey dialog
        await tester.tap(find.byKey(const Key('reactivate_btn_doc-inactive')));
        await tester.pumpAndSettle();

        expect(find.text('Reactivate Doctor'), findsWidgets);
        expect(
          find.text('Enter 6-digit Owner Master Passkey to authorize:'),
          findsOneWidget,
        );

        // 5. Enter wrong passkey -> shows error
        await tester.enterText(
          find.byKey(const Key('admin_passkey_input')),
          '000000',
        );
        await tester.tap(find.byKey(const Key('confirm_passkey_action_btn')));
        await tester.pumpAndSettle();

        expect(find.text('Incorrect Owner Master Passkey'), findsOneWidget);
        expect(clinicProvider.setDoctorActiveStatusCalled, isFalse);

        // 6. Enter correct master passkey -> confirms reactivation
        await tester.enterText(
          find.byKey(const Key('admin_passkey_input')),
          '849201',
        );
        await tester.tap(find.byKey(const Key('confirm_passkey_action_btn')));
        await tester.pumpAndSettle();

        expect(clinicProvider.setDoctorActiveStatusCalled, isTrue);
        expect(clinicProvider.updatedDoctorId, 'doc-inactive');
        expect(clinicProvider.updatedActiveStatus, isTrue);
      },
    );
  });
}
