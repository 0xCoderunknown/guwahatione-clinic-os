import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:appointment_app/providers/auth_provider.dart';
import 'package:appointment_app/services/security_service.dart';
import 'package:appointment_app/widgets/dashboard/security_settings_dialog.dart';

class _FakeSecurityService extends SecurityService {
  final StreamController<DocumentSnapshot<Map<String, dynamic>>> _controller =
      StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();

  String? lastUpdatedOwnerHash;
  String? lastUpdatedReceptionistHash;

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> securityStream() {
    return _controller.stream;
  }

  @override
  Future<void> updateSecurityPins({
    String? ownerMasterPinHash,
    String? receptionistPinHash,
  }) async {
    lastUpdatedOwnerHash = ownerMasterPinHash;
    lastUpdatedReceptionistHash = receptionistPinHash;
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('QOL-13: Security PIN Store & Cloud Synchronization Tests', () {
    test('updateSecurityPins updates local hashes and calls SecurityService', () async {
      final fakeSecurity = _FakeSecurityService();
      final auth = AuthProvider(securityService: fakeSecurity);
      await auth.initSession([]);

      expect(auth.isCustomReceptionistPinSet, isFalse);
      expect(auth.isCustomOwnerPinSet, isFalse);

      // Rotate Receptionist PIN to '1234' and Owner PIN to '654321'
      await auth.updateSecurityPins(
        newReceptionistPin: '1234',
        newOwnerPin: '654321',
      );

      expect(auth.isCustomReceptionistPinSet, isTrue);
      expect(auth.isCustomOwnerPinSet, isTrue);

      // Verify hashes in SecurityService
      expect(fakeSecurity.lastUpdatedReceptionistHash, AuthProvider.hashPin('1234'));
      expect(fakeSecurity.lastUpdatedOwnerHash, AuthProvider.hashPin('654321'));

      // Verify authentications
      expect(auth.verifyOwnerMasterPin('654321'), isTrue);
      expect(auth.verifyOwnerMasterPin('849201'), isFalse);
      expect(auth.verifyReceptionOrOwnerPin('1234'), isTrue);
      expect(auth.verifyReceptionOrOwnerPin('9999'), isFalse);
      expect(auth.verifyReceptionOrOwnerPin('0000'), isTrue); // Testing mode universally allows 0000

      fakeSecurity.dispose();
      auth.dispose();
    });

    test('Individual setOwnerMasterPin and setReceptionistPin call updateSecurityPins', () async {
      final fakeSecurity = _FakeSecurityService();
      final auth = AuthProvider(securityService: fakeSecurity);
      await auth.initSession([]);

      await auth.setReceptionistPin('4321');
      expect(fakeSecurity.lastUpdatedReceptionistHash, AuthProvider.hashPin('4321'));
      expect(auth.verifyReceptionOrOwnerPin('4321'), isTrue);

      await auth.setOwnerMasterPin('987654');
      expect(fakeSecurity.lastUpdatedOwnerHash, AuthProvider.hashPin('987654'));
      expect(auth.verifyOwnerMasterPin('987654'), isTrue);

      fakeSecurity.dispose();
      auth.dispose();
    });

    testWidgets('SecuritySettingsDialog renders verification step and navigates to PIN config on success', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeSecurity = _FakeSecurityService();
      final auth = AuthProvider(securityService: fakeSecurity);
      await auth.initSession([]);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: auth,
            child: const Scaffold(
              body: SecuritySettingsDialog(),
            ),
          ),
        ),
      );

      // Step 1: Verification Step
      expect(find.text('Clinic Security & PIN Store'), findsOneWidget);
      expect(find.text('Security Verification Required'), findsOneWidget);
      expect(find.text('Verify & Proceed'), findsOneWidget);

      // Enter incorrect passkey
      await tester.enterText(find.byType(TextField), '111111');
      await tester.tap(find.text('Verify & Proceed'));
      await tester.pump();

      expect(find.text('Incorrect Master Passkey. Access denied.'), findsOneWidget);

      // Enter default passkey (849201)
      await tester.enterText(find.byType(TextField), AuthProvider.defaultOwnerMasterPin);
      await tester.tap(find.text('Verify & Proceed'));
      await tester.pump();

      // Step 2: Settings Step
      expect(find.text('Receptionist Access PIN (4 Digits)'), findsOneWidget);
      expect(find.text('Owner Master Passkey (6 Digits)'), findsOneWidget);
      expect(find.text('Save & Sync to Cloud'), findsOneWidget);

      fakeSecurity.dispose();
      auth.dispose();
    });

    testWidgets('SecuritySettingsDialog saves new Reception and Owner PINs', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeSecurity = _FakeSecurityService();
      final auth = AuthProvider(securityService: fakeSecurity);
      await auth.initSession([]);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: auth,
            child: const Scaffold(
              body: SecuritySettingsDialog(),
            ),
          ),
        ),
      );

      // Pass verification
      await tester.enterText(find.byType(TextField), AuthProvider.defaultOwnerMasterPin);
      await tester.tap(find.text('Verify & Proceed'));
      await tester.pump();

      // Enter new Reception PIN (fields 0 and 1)
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(4));

      await tester.enterText(textFields.at(0), '5555');
      await tester.enterText(textFields.at(1), '5555');

      // Enter new Owner Passkey (fields 2 and 3)
      await tester.enterText(textFields.at(2), '777777');
      await tester.enterText(textFields.at(3), '777777');

      await tester.tap(find.text('Save & Sync to Cloud'));
      await tester.pumpAndSettle();

      expect(auth.isCustomReceptionistPinSet, isTrue);
      expect(auth.isCustomOwnerPinSet, isTrue);
      expect(auth.verifyReceptionOrOwnerPin('5555'), isTrue);
      expect(auth.verifyOwnerMasterPin('777777'), isTrue);

      expect(fakeSecurity.lastUpdatedReceptionistHash, AuthProvider.hashPin('5555'));
      expect(fakeSecurity.lastUpdatedOwnerHash, AuthProvider.hashPin('777777'));

      fakeSecurity.dispose();
      auth.dispose();
    });
  });
}
