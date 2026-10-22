import 'package:appointment_app/config/clinic_config.dart';
import 'package:appointment_app/models/models.dart';
import 'package:appointment_app/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ClinicConfig.current = const ClinicConfig(
      features: ClinicFeatureFlags(enableTestingMode: false),
    );
  });

  tearDown(() {
    ClinicConfig.current = const ClinicConfig(
      features: ClinicFeatureFlags(enableTestingMode: true),
    );
  });

  group('AuthProvider 3-Tier PIN Authentication & Role Guarding Tests', () {
    final sampleDoctors = [
      Doctor(
        id: 'doc-1',
        name: 'Dr. Bhaskar Baruah',
        specialty: 'Internal Medicine',
        phone: '9864012345',
        availableDays: ['Mon', 'Wed', 'Fri'],
        blockedDates: [],
        pin: '1111',
      ),
      Doctor(
        id: 'doc-2',
        name: 'Dr. A. Sharma',
        specialty: 'Cardiology',
        phone: '9864054321',
        availableDays: ['Tue', 'Thu', 'Sat'],
        blockedDates: [],
        pin: '2222',
      ),
      Doctor(
        id: 'doc-3',
        name: 'Dr. Duplicate Pin',
        specialty: 'Pediatrics',
        phone: '9864099999',
        availableDays: ['Mon', 'Tue'],
        blockedDates: [],
        pin: '2222', // Shares PIN with doc-2
      ),
    ];

    test(
      'Initializes with default clinic PINs and unauthenticated state',
      () async {
        final auth = AuthProvider();
        await auth.initSession(sampleDoctors);

        expect(auth.isInitialized, isTrue);
        expect(auth.isAuthenticated, isFalse);
        expect(auth.currentRole, isNull);
        expect(auth.currentDoctor, isNull);
        expect(auth.receptionistPinHash, AuthProvider.hashPin('0000'));
        expect(auth.ownerMasterPinHash, AuthProvider.hashPin('849201'));
        expect(auth.verifyReceptionOrOwnerPin('0000'), isTrue);
        expect(auth.verifyReceptionOrOwnerPin('849201'), isTrue);
      },
    );

    test('6-digit Owner Master PIN authenticates as UserRole.owner', () async {
      final auth = AuthProvider();
      await auth.initSession(sampleDoctors);

      final result = await auth.authenticateWithPin(
        pin: '849201',
        doctors: sampleDoctors,
      );

      expect(result.isSuccess, isTrue);
      expect(result.role, UserRole.owner);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.isOwner, isTrue);
      expect(auth.isReceptionist, isFalse);
      expect(auth.isDoctor, isFalse);
      expect(auth.currentDoctor, isNull);
    });

    test(
      '4-digit Receptionist PIN (0000) authenticates as UserRole.receptionist',
      () async {
        final auth = AuthProvider();
        await auth.initSession(sampleDoctors);

        final result = await auth.authenticateWithPin(
          pin: '0000',
          doctors: sampleDoctors,
        );

        expect(result.isSuccess, isTrue);
        expect(result.role, UserRole.receptionist);
        expect(auth.isAuthenticated, isTrue);
        expect(auth.isReceptionist, isTrue);
        expect(auth.isOwner, isFalse);
        expect(auth.currentDoctor, isNull);
      },
    );

    test('Doctor chamber PIN resolves specific doctor profile', () async {
      final auth = AuthProvider();
      await auth.initSession(sampleDoctors);

      final result = await auth.authenticateWithPin(
        pin: '1111',
        doctors: sampleDoctors,
      );

      expect(result.isSuccess, isTrue);
      expect(result.role, UserRole.doctor);
      expect(result.doctor, isNotNull);
      expect(result.doctor?.id, 'doc-1');
      expect(result.doctor?.name, 'Dr. Bhaskar Baruah');
      expect(auth.isAuthenticated, isTrue);
      expect(auth.isDoctor, isTrue);
      expect(auth.currentDoctor?.id, 'doc-1');
    });

    test(
      'Duplicate doctor PIN yields multipleDoctors result without auto-login',
      () async {
        final auth = AuthProvider();
        await auth.initSession(sampleDoctors);

        final result = await auth.authenticateWithPin(
          pin: '2222',
          doctors: sampleDoctors,
        );

        expect(result.isSuccess, isFalse);
        expect(result.matchingDoctors.length, 2);
        expect(
          result.matchingDoctors.map((d) => d.id),
          containsAll(['doc-2', 'doc-3']),
        );
        expect(auth.isAuthenticated, isFalse);
      },
    );

    test('Invalid PIN fails with descriptive error message', () async {
      final auth = AuthProvider();
      await auth.initSession(sampleDoctors);

      final result = await auth.authenticateWithPin(
        pin: '9999',
        doctors: sampleDoctors,
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Invalid Access PIN'));
      expect(auth.isAuthenticated, isFalse);
    });

    test('stepDownToReception demotes Owner to Receptionist cleanly', () async {
      final auth = AuthProvider();
      await auth.initSession(sampleDoctors);

      await auth.authenticateWithPin(pin: '849201', doctors: sampleDoctors);
      expect(auth.isOwner, isTrue);

      await auth.stepDownToReception();
      expect(auth.isOwner, isFalse);
      expect(auth.isReceptionist, isTrue);
      expect(auth.currentDoctor, isNull);
    });

    test(
      'Direct login helpers (loginAsOwner, loginAsReceptionist, loginAsDoctor)',
      () async {
        final auth = AuthProvider();
        await auth.initSession(sampleDoctors);

        // loginAsOwner
        expect(await auth.loginAsOwner('849201'), isTrue);
        expect(auth.isOwner, isTrue);

        // loginAsReceptionist
        expect(await auth.loginAsReceptionist('0000'), isTrue);
        expect(auth.isReceptionist, isTrue);

        // loginAsDoctor
        expect(await auth.loginAsDoctor(sampleDoctors[0], '1111'), isTrue);
        expect(auth.isDoctor, isTrue);
        expect(auth.currentDoctor?.id, 'doc-1');

        // loginAsDoctor wrong pin
        expect(await auth.loginAsDoctor(sampleDoctors[0], '9999'), isFalse);
      },
    );

    test('Custom PIN updates persist and take immediate effect', () async {
      final auth = AuthProvider();
      await auth.initSession(sampleDoctors);

      await auth.setReceptionistPin('1234');
      await auth.setOwnerMasterPin('987654');

      expect(auth.receptionistPinHash, AuthProvider.hashPin('1234'));
      expect(auth.ownerMasterPinHash, AuthProvider.hashPin('987654'));

      // Authenticate with new PINs
      final recepResult = await auth.authenticateWithPin(
        pin: '1234',
        doctors: sampleDoctors,
      );
      expect(recepResult.role, UserRole.receptionist);

      final ownerResult = await auth.authenticateWithPin(
        pin: '987654',
        doctors: sampleDoctors,
      );
      expect(ownerResult.role, UserRole.owner);
    });

    test('logout clears in-memory state and persisted preferences', () async {
      final auth = AuthProvider();
      await auth.initSession(sampleDoctors);

      await auth.authenticateWithPin(pin: '1111', doctors: sampleDoctors);
      expect(auth.isAuthenticated, isTrue);

      await auth.logout();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentRole, isNull);
      expect(auth.currentDoctor, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_role'), isNull);
      expect(prefs.getString('auth_doctor_id'), isNull);
    });

    test(
      'initSession successfully restores persisted doctor session',
      () async {
        SharedPreferences.setMockInitialValues({
          'auth_role': 'doctor',
          'auth_doctor_id': 'doc-1',
        });

        final auth = AuthProvider();
        await auth.initSession(sampleDoctors);

        expect(auth.isAuthenticated, isTrue);
        expect(auth.isDoctor, isTrue);
        expect(auth.currentDoctor?.id, 'doc-1');
      },
    );

    test(
      'initSession cleans up session if persisted doctor was removed',
      () async {
        SharedPreferences.setMockInitialValues({
          'auth_role': 'doctor',
          'auth_doctor_id': 'doc-nonexistent',
        });

        final auth = AuthProvider();
        await auth.initSession(sampleDoctors);

        expect(auth.isAuthenticated, isFalse);
        expect(auth.currentRole, isNull);
        expect(auth.currentDoctor, isNull);
      },
    );

    test('AuthProvider.hashPin produces deterministic SHA-256 hashes', () {
      final hash1 = AuthProvider.hashPin('849201');
      final hash2 = AuthProvider.hashPin(' 849201 ');
      final hashOther = AuthProvider.hashPin('0000');

      expect(hash1, equals(hash2));
      expect(hash1.length, 64); // SHA-256 hex string length
      expect(hash1, isNot(equals(hashOther)));
      expect(hash1, isNot(contains('849201'))); // Non-reversible
    });

    test('initSession migrates legacy plaintext PINs to SHA-256 hashes and purges plaintext', () async {
      SharedPreferences.setMockInitialValues({
        'auth_owner_master_pin': '999999',
        'auth_receptionist_pin': '8888',
      });

      final auth = AuthProvider();
      await auth.initSession(sampleDoctors);

      final prefs = await SharedPreferences.getInstance();

      // Legacy plaintext keys must be purged from disk
      expect(prefs.containsKey('auth_owner_master_pin'), isFalse);
      expect(prefs.containsKey('auth_receptionist_pin'), isFalse);

      // New hash keys must be stored on disk
      expect(
        prefs.getString('auth_owner_master_pin_hash'),
        AuthProvider.hashPin('999999'),
      );
      expect(
        prefs.getString('auth_receptionist_pin_hash'),
        AuthProvider.hashPin('8888'),
      );

      // New hashes authenticate successfully
      final authResult = await auth.authenticateWithPin(
        pin: '999999',
        doctors: sampleDoctors,
      );
      expect(authResult.isSuccess, isTrue);
      expect(authResult.role, UserRole.owner);
    });

    test('loginAsReceptionistOrOwner authenticates 0000 as Receptionist and 849201 as Owner', () async {
      final auth = AuthProvider();
      await auth.initSession(sampleDoctors);

      // 1. Receptionist PIN (0000)
      final recepSuccess = await auth.loginAsReceptionistOrOwner('0000');
      expect(recepSuccess, isTrue);
      expect(auth.isReceptionist, isTrue);
      expect(auth.isOwner, isFalse);

      await auth.logout();

      // 2. Owner PIN (849201)
      final ownerSuccess = await auth.loginAsReceptionistOrOwner('849201');
      expect(ownerSuccess, isTrue);
      expect(auth.isOwner, isTrue);
      expect(auth.isReceptionist, isFalse);

      await auth.logout();

      // 3. Invalid PIN fails
      final invalidSuccess = await auth.loginAsReceptionistOrOwner('9999');
      expect(invalidSuccess, isFalse);
      expect(auth.isAuthenticated, isFalse);
    });

    test('Custom Owner PIN strictly replaces default 849201 (no backdoor fallback)', () async {
      SharedPreferences.setMockInitialValues({
        'auth_owner_master_pin_hash': AuthProvider.hashPin('999999'),
      });

      final auth = AuthProvider();
      await auth.initSession(sampleDoctors);

      // Default master PIN 849201 is rejected once custom PIN is set
      expect(await auth.loginAsOwner('849201'), isFalse);
      expect(auth.isAuthenticated, isFalse);

      // Stored custom PIN authenticates successfully
      expect(await auth.loginAsOwner('999999'), isTrue);
      expect(auth.isOwner, isTrue);
    });

    test(
      'initSession sanitizes stale owner pin hash if legacy 0000 was stored',
      () async {
        SharedPreferences.setMockInitialValues({
          'auth_owner_master_pin_hash': AuthProvider.hashPin('0000'),
        });

        final auth = AuthProvider();
        await auth.initSession(sampleDoctors);

        // Sanitized: 849201 works cleanly
        expect(await auth.loginAsOwner('849201'), isTrue);
        expect(auth.isOwner, isTrue);

        // 0000 does not log in as owner
        await auth.logout();
        expect(await auth.loginAsOwner('0000'), isFalse);
        // But 0000 logs in as receptionist
        expect(await auth.loginAsReceptionist('0000'), isTrue);
      },
    );

    test('Clinic floor continuity: failed PIN attempts never trigger counter lockout', () async {
      final auth = AuthProvider();
      await auth.initSession(sampleDoctors);

      // Multiple consecutive failed attempts
      for (int i = 0; i < 10; i++) {
        final result = await auth.loginAsReceptionistOrOwner('999$i');
        expect(result, isFalse);
      }

      // Legitimate Owner and Reception logins immediately succeed without delay or lockout freeze
      expect(await auth.loginAsOwner('849201'), isTrue);
      expect(auth.isOwner, isTrue);

      await auth.logout();
      expect(await auth.loginAsReceptionist('0000'), isTrue);
      expect(auth.isReceptionist, isTrue);
    });
  });

  group('AuthProvider Universal Testing Mode (PIN 0000) Tests', () {
    final sampleDoctors = [
      Doctor(
        id: 'doc-1',
        name: 'Dr. Bhaskar Baruah',
        specialty: 'Internal Medicine',
        phone: '9864012345',
        availableDays: ['Mon', 'Wed', 'Fri'],
        blockedDates: [],
        pin: '1111',
      ),
      Doctor(
        id: 'doc-inactive',
        name: 'Dr. Inactive',
        specialty: 'Dermatology',
        phone: '9864055555',
        availableDays: ['Mon'],
        blockedDates: [],
        pin: '3333',
        isActive: false,
      ),
    ];

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      ClinicConfig.current = const ClinicConfig(
        features: ClinicFeatureFlags(enableTestingMode: true),
      );
    });

    tearDown(() {
      ClinicConfig.current = const ClinicConfig(
        features: ClinicFeatureFlags(enableTestingMode: true),
      );
    });

    test('Doctor logs in with 0000 regardless of configured chamber PIN', () async {
      final auth = AuthProvider();
      await auth.initSession(sampleDoctors);

      final doc = sampleDoctors.first; // PIN is 1111
      final success = await auth.loginAsDoctor(doc, '0000');
      expect(success, isTrue);
      expect(auth.isDoctor, isTrue);
      expect(auth.currentDoctor?.id, 'doc-1');
    });

    test('Inactive doctor cannot log in even with 0000 in testing mode', () async {
      final auth = AuthProvider();
      await auth.initSession(sampleDoctors);

      final inactiveDoc = sampleDoctors.last;
      final success = await auth.loginAsDoctor(inactiveDoc, '0000');
      expect(success, isFalse);
      expect(auth.isAuthenticated, isFalse);
    });

    test('Receptionist logs in with 0000 in testing mode', () async {
      final auth = AuthProvider();
      await auth.initSession(sampleDoctors);

      final success = await auth.loginAsReceptionist('0000');
      expect(success, isTrue);
      expect(auth.isReceptionist, isTrue);
      expect(auth.currentDoctor, isNull);
    });

    test('Admin/Owner logs in with 000000 in testing mode', () async {
      final auth = AuthProvider();
      await auth.initSession(sampleDoctors);

      final success = await auth.loginAsOwner('000000');
      expect(success, isTrue);
      expect(auth.isOwner, isTrue);
      expect(auth.currentDoctor, isNull);
    });

    test('loginAsReceptionistOrOwner routes demo PINs (000000 → owner, 0000 → reception)', () async {
      final auth = AuthProvider();
      await auth.initSession(sampleDoctors);

      // Owner demo PIN: 000000
      final ownerSuccess = await auth.loginAsReceptionistOrOwner(
        '000000',
        targetRole: UserRole.owner,
      );
      expect(ownerSuccess, isTrue);
      expect(auth.isOwner, isTrue);

      await auth.logout();

      // Reception demo PIN: 0000
      final recepSuccess = await auth.loginAsReceptionistOrOwner(
        '0000',
        targetRole: UserRole.receptionist,
      );
      expect(recepSuccess, isTrue);
      expect(auth.isReceptionist, isTrue);
    });

    test('verifyOwnerMasterPin accepts 000000 in demo testing mode', () async {
      final auth = AuthProvider();
      await auth.initSession(sampleDoctors);

      expect(auth.verifyOwnerMasterPin('000000'), isTrue);
      expect(auth.verifyOwnerMasterPin(' 000000 '), isTrue);
      expect(auth.verifyOwnerMasterPin('9999'), isFalse);
    });

    test('verifyReceptionOrOwnerPin accepts 0000 in testing mode', () async {
      final auth = AuthProvider();
      await auth.initSession(sampleDoctors);

      expect(auth.verifyReceptionOrOwnerPin('0000'), isTrue);
      expect(auth.verifyReceptionOrOwnerPin(' 0000 '), isTrue);
      expect(auth.verifyReceptionOrOwnerPin('9999'), isFalse);
    });

    test('authenticateWithPin with demo PINs respects targetRole in testing mode', () async {
      final auth = AuthProvider();
      await auth.initSession(sampleDoctors);

      // Owner demo PIN: 000000
      final ownerResult = await auth.authenticateWithPin(
        pin: '000000',
        doctors: sampleDoctors,
        targetRole: UserRole.owner,
      );
      expect(ownerResult.isSuccess, isTrue);
      expect(ownerResult.role, UserRole.owner);

      await auth.logout();

      // Reception demo PIN: 0000
      final recepResult = await auth.authenticateWithPin(
        pin: '0000',
        doctors: sampleDoctors,
        targetRole: UserRole.receptionist,
      );
      expect(recepResult.isSuccess, isTrue);
      expect(recepResult.role, UserRole.receptionist);
    });
  });
}
