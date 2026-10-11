import 'package:flutter/material.dart';

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
          'Full access to book appointments, manage doctors, and view financial audits.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Reception / Owner PIN',
            hintText: 'Enter PIN (default: 0000)',
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
