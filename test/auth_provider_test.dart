import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appointment_app/models/models.dart';
import 'package:appointment_app/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
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

    test('Initializes with default clinic PINs and unauthenticated state', () async {
      final auth = AuthProvider();
      await auth.initSession(sampleDoctors);

      expect(auth.isInitialized, isTrue);
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentRole, isNull);
      expect(auth.currentDoctor, isNull);
      expect(auth.receptionistPin, '0000');
      expect(auth.ownerMasterPin, '849201');
    });

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

    test('4-digit Receptionist PIN (0000) authenticates as UserRole.receptionist', () async {
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
    });

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

    test('Duplicate doctor PIN yields multipleDoctors result without auto-login', () async {
      final auth = AuthProvider();
      await auth.initSession(sampleDoctors);

      final result = await auth.authenticateWithPin(
        pin: '2222',
        doctors: sampleDoctors,
      );

      expect(result.isSuccess, isFalse);
      expect(result.matchingDoctors.length, 2);
      expect(result.matchingDoctors.map((d) => d.id), containsAll(['doc-2', 'doc-3']));
      expect(auth.isAuthenticated, isFalse);
    });

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

      await auth.authenticateWithPin(
        pin: '849201',
        doctors: sampleDoctors,
      );
      expect(auth.isOwner, isTrue);

      await auth.stepDownToReception();
      expect(auth.isOwner, isFalse);
      expect(auth.isReceptionist, isTrue);
      expect(auth.currentDoctor, isNull);
    });

    test('Direct login helpers (loginAsOwner, loginAsReceptionist, loginAsDoctor)', () async {
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
    });

    test('Custom PIN updates persist and take immediate effect', () async {
      final auth = AuthProvider();
      await auth.initSession(sampleDoctors);

      await auth.setReceptionistPin('1234');
      await auth.setOwnerMasterPin('987654');

      expect(auth.receptionistPin, '1234');
      expect(auth.ownerMasterPin, '987654');

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

      await auth.authenticateWithPin(
        pin: '1111',
        doctors: sampleDoctors,
      );
      expect(auth.isAuthenticated, isTrue);

      await auth.logout();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentRole, isNull);
      expect(auth.currentDoctor, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_role'), isNull);
      expect(prefs.getString('auth_doctor_id'), isNull);
    });

    test('initSession successfully restores persisted doctor session', () async {
      SharedPreferences.setMockInitialValues({
        'auth_role': 'doctor',
        'auth_doctor_id': 'doc-1',
      });

      final auth = AuthProvider();
      await auth.initSession(sampleDoctors);

      expect(auth.isAuthenticated, isTrue);
      expect(auth.isDoctor, isTrue);
      expect(auth.currentDoctor?.id, 'doc-1');
    });

    test('initSession cleans up session if persisted doctor was removed', () async {
      SharedPreferences.setMockInitialValues({
        'auth_role': 'doctor',
        'auth_doctor_id': 'doc-nonexistent',
      });

      final auth = AuthProvider();
      await auth.initSession(sampleDoctors);

      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentRole, isNull);
      expect(auth.currentDoctor, isNull);
    });

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
      expect(prefs.getString('auth_owner_master_pin_hash'), AuthProvider.hashPin('999999'));
      expect(prefs.getString('auth_receptionist_pin_hash'), AuthProvider.hashPin('8888'));

      // New hashes authenticate successfully
      final authResult = await auth.authenticateWithPin(
        pin: '999999',
        doctors: sampleDoctors,
      );
      expect(authResult.isSuccess, isTrue);
      expect(authResult.role, UserRole.owner);
    });
  });
}
