import 'package:flutter/material.dart';

import '../../models/doctor.dart';

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
                '${doc.name} (${doc.specialty})',
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
