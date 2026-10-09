import 'firebase_options.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/clinic_provider.dart';
import 'screens/doctor_chamber_screen.dart';
import 'screens/login_screen.dart';
import 'screens/owner_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ClinicApp());
}

class ClinicApp extends StatelessWidget {
  const ClinicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ClinicProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'GuwahatiOne Clinic OS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal,
            primary: Colors.teal,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF0F172A),
            elevation: 0.5,
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _hasAttemptedInit = false;

  @override
  Widget build(BuildContext context) {
    final clinic = Provider.of<ClinicProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    // Wait for the first doctor snapshot before validating a saved doctor session.
    if (!_hasAttemptedInit && !auth.isInitialized && clinic.hasLoadedDoctors) {
      _hasAttemptedInit = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        clinic.startListeningToAppointments();
        auth.initSession(clinic.doctors);
      });
    }

    if (!auth.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }

    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    if (auth.isDoctor && auth.currentDoctor != null) {
      return DoctorChamberScreen(
        doctor: auth.currentDoctor!,
        isPreviewMode: false,
      );
    }

    return const OwnerShell();
  }
}
