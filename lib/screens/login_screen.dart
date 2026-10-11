import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/doctor.dart';
import '../providers/auth_provider.dart';
import '../providers/clinic_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _pin = '';
  String? _errorMessage;
  bool _isLoading = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handlePhysicalKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handlePhysicalKey);
    _focusNode.dispose();
    super.dispose();
  }

  bool _handlePhysicalKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _submitPin();
      return true;
    } else if (key == LogicalKeyboardKey.backspace) {
      _deleteDigit();
      return true;
    } else if (key == LogicalKeyboardKey.escape) {
      _clearPin();
      return true;
    } else {
      final char = event.character;
      if (char != null && RegExp(r'^[0-9]$').hasMatch(char)) {
        _appendDigit(char);
        return true;
      }
    }
    return false;
  }

  void _appendDigit(String digit) {
    if (_pin.length < 6) {
      setState(() {
        _pin += digit;
        _errorMessage = null;
      });
    }
  }

  void _deleteDigit() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _clearPin() {
    setState(() {
      _pin = '';
      _errorMessage = null;
    });
  }

  Future<void> _submitPin() async {
    if (_pin.length < 4) {
      setState(() {
        _errorMessage = 'PIN must be at least 4 digits.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final clinicProvider = Provider.of<ClinicProvider>(context, listen: false);
    final doctors = clinicProvider.doctors;

    final result = await authProvider.authenticateWithPin(
      pin: _pin,
      doctors: doctors,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!result.isSuccess) {
      if (result.matchingDoctors.isNotEmpty) {
        // Multiple doctors share this PIN
        _showDoctorSelectionDialog(result.matchingDoctors);
      } else {
        setState(() {
          _errorMessage = result.errorMessage ?? 'Invalid Access PIN.';
          _pin = '';
        });
      }
    }
  }

  void _showDoctorSelectionDialog(List<Doctor> matchingDoctors) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Consulting Doctor'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Multiple chambers match this PIN. Select your profile:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ...matchingDoctors.map((doc) => ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.shade50,
                      child: Text(
                        doc.name.isNotEmpty ? doc.name[0] : 'D',
                        style: TextStyle(
                          color: Colors.teal.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      doc.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(doc.specialty),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final auth =
                          Provider.of<AuthProvider>(context, listen: false);
                      await auth.loginAsDoctor(doc, _pin);
                    },
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _clearPin();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
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
                    // Clinic Logo
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
                    const SizedBox(height: 14),
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
                    const SizedBox(height: 28),

                    // Unified Neutral Prompt
                    const Text(
                      'Enter Access PIN',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '4-digit Reception/Chamber PIN or 6-digit Master PIN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Dynamic PIN Dots / Slots Display (up to 6 slots)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        final isFilled = index < _pin.length;
                        final isSlotActive = index == _pin.length;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isFilled
                                ? Colors.teal.shade700
                                : Colors.transparent,
                            border: Border.all(
                              color: isSlotActive
                                  ? Colors.teal.shade600
                                  : (isFilled
                                      ? Colors.teal.shade700
                                      : const Color(0xFFCBD5E1)),
                              width: isSlotActive ? 2 : 1.5,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),

                    // Error Message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 16,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
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

                    const SizedBox(height: 20),

                    // On-Screen Unified Numpad Grid (3 x 4)
                    _buildNumpad(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Column(
      children: [
        _buildNumpadRow(['1', '2', '3']),
        const SizedBox(height: 10),
        _buildNumpadRow(['4', '5', '6']),
        const SizedBox(height: 10),
        _buildNumpadRow(['7', '8', '9']),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Backspace / Clear key
            _buildActionKey(
              icon: Icons.backspace_outlined,
              tooltip: 'Backspace',
              onPressed: _pin.isNotEmpty ? _deleteDigit : null,
              onLongPress: _clearPin,
            ),
            const SizedBox(width: 14),
            // Digit 0
            _buildNumberKey('0'),
            const SizedBox(width: 14),
            // Submit Key [ ↵ ]
            _buildSubmitKey(),
          ],
        ),
      ],
    );
  }

  Widget _buildNumpadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildNumberKey(digits[0]),
        const SizedBox(width: 14),
        _buildNumberKey(digits[1]),
        const SizedBox(width: 14),
        _buildNumberKey(digits[2]),
      ],
    );
  }

  Widget _buildNumberKey(String digit) {
    return SizedBox(
      width: 72,
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFF8FAFC),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.zero,
        ),
        onPressed: () => _appendDigit(digit),
        child: Text(
          digit,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    VoidCallback? onLongPress,
  }) {
    return SizedBox(
      width: 72,
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFF8FAFC),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.zero,
        ),
        onPressed: onPressed,
        onLongPress: onLongPress,
        child: Icon(icon, color: const Color(0xFF64748B), size: 20),
      ),
    );
  }

  Widget _buildSubmitKey() {
    final canSubmit = _pin.length >= 4;

    return SizedBox(
      width: 72,
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: canSubmit ? Colors.teal.shade700 : Colors.teal.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.zero,
        ),
        onPressed: _isLoading ? null : (canSubmit ? _submitPin : null),
        child: _isLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(
                Icons.keyboard_return_rounded,
                color: Colors.white,
                size: 22,
              ),
      ),
    );
  }
}
