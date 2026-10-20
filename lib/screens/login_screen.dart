import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/doctor.dart';
import '../providers/auth_provider.dart';
import '../providers/clinic_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _ownerPinController = TextEditingController();
  final TextEditingController _doctorPinController = TextEditingController();
  Doctor? _selectedDoctor;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ownerPinController.dispose();
    _doctorPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctors = context.select<ClinicProvider, List<Doctor>>(
      (p) => p.doctors,
    );
    final effectiveDoctor =
        _selectedDoctor ?? (doctors.isNotEmpty ? doctors.first : null);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28.0,
                  vertical: 36.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Clinic Logo & Title
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.local_hospital_rounded,
                        size: 38,
                        color: Colors.teal.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'GuwahatiOne Clinic OS',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Transparent OPD & Chamber Management',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Role Selector TabBar
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        labelColor: Colors.teal.shade800,
                        unselectedLabelColor: Colors.grey.shade600,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        tabs: const [
                          Tab(
                            text: 'Doctor Chamber',
                            icon: Icon(Icons.meeting_room_outlined, size: 18),
                          ),
                          Tab(
                            text: 'Reception Desk',
                            icon: Icon(
                              Icons.admin_panel_settings_outlined,
                              size: 18,
                            ),
                          ),
                        ],
                        onTap: (_) {
                          setState(() {
                            _errorMessage = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tab View Content
                    SizedBox(
                      height: 275,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Doctor Chamber Tab
                          DoctorLoginForm(
                            doctors: doctors,
                            selectedDoctor: effectiveDoctor,
                            pinController: _doctorPinController,
                            isLoading: _isLoading,
                            onDoctorChanged: (val) {
                              setState(() {
                                _selectedDoctor = val;
                                _errorMessage = null;
                              });
                            },
                            onLogin: _handleDoctorLogin,
                          ),
                          // Reception Desk / Owner Tab
                          ReceptionLoginForm(
                            pinController: _ownerPinController,
                            isLoading: _isLoading,
                            onLogin: _handleOwnerLogin,
                          ),
                        ],
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 16,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDoctorLogin() async {
    if (_isLoading) return;
    final clinic = Provider.of<ClinicProvider>(context, listen: false);
    final doc =
        _selectedDoctor ??
        (clinic.doctors.isNotEmpty ? clinic.doctors.first : null);
    if (doc == null) {
      setState(() => _errorMessage = 'Please select a doctor.');
      return;
    }
    final pin = _doctorPinController.text.trim();
    if (pin.isEmpty) {
      setState(() => _errorMessage = 'Please enter chamber PIN.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.loginAsDoctor(doc, pin);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!success) {
      setState(() => _errorMessage = 'Incorrect PIN for ${doc.name}.');
    }
  }

  Future<void> _handleOwnerLogin() async {
    if (_isLoading) return;
    final pin = _ownerPinController.text.trim();
    if (pin.isEmpty) {
      setState(() => _errorMessage = 'Please enter Reception or Owner PIN.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.loginAsReceptionistOrOwner(pin);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!success) {
      setState(
        () => _errorMessage =
            'Incorrect PIN (Testing: Reception: 0000 | Admin: 849201).',
      );
    }
  }
}

/// Presentation form for Doctor Chamber authentication.
class DoctorLoginForm extends StatelessWidget {
  final List<Doctor> doctors;
  final Doctor? selectedDoctor;
  final TextEditingController pinController;
  final bool isLoading;
  final ValueChanged<Doctor?> onDoctorChanged;
  final VoidCallback onLogin;

  const DoctorLoginForm({
    super.key,
    required this.doctors,
    required this.selectedDoctor,
    required this.pinController,
    required this.isLoading,
    required this.onDoctorChanged,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    if (doctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 36, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No doctors registered yet.\nLogin as Reception to add doctors.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<Doctor>(
          initialValue: selectedDoctor,
          decoration: InputDecoration(
            labelText: 'Select Doctor',
            prefixIcon: const Icon(Icons.person_pin_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
          items: doctors.map((doc) {
            return DropdownMenuItem<Doctor>(
              value: doc,
              child: Text(
                '${doc.titleName} (${doc.specialty})',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onDoctorChanged,
        ),
        const SizedBox(height: 14),
        TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Chamber PIN',
            hintText: 'Enter 4-digit PIN (default: 1234)',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
          onSubmitted: (_) => onLogin(),
        ),
        const Spacer(),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.teal,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: isLoading ? null : onLogin,
          child: isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Enter Chamber View',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}

/// Presentation form for Reception Desk / Owner authentication.
class ReceptionLoginForm extends StatelessWidget {
  final TextEditingController pinController;
  final bool isLoading;
  final VoidCallback onLogin;

  const ReceptionLoginForm({
    super.key,
    required this.pinController,
    required this.isLoading,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Reception Desk & Admin Mode',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Full access to book appointments, manage doctors, and view financial reports.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Reception / Owner PIN',
            hintText: 'PIN (Reception: 0000 | Admin: 849201)',
            helperText: 'Testing PINs — Reception: 0000 | Admin: 849201',
            helperStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey.shade700,
            ),
            prefixIcon: const Icon(Icons.security_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
          onSubmitted: (_) => onLogin(),
        ),
        const Spacer(),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: isLoading ? null : onLogin,
          child: isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Access Reception Desk',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}
