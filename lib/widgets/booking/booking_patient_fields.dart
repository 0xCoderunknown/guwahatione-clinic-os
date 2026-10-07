import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Form fields for patient demographic data (Phone with search trigger, Name, Age, Sex).
class BookingPatientFields extends StatelessWidget {
  final TextEditingController phoneController;
  final TextEditingController nameController;
  final TextEditingController ageController;
  final String selectedGender;
  final ValueChanged<String> onGenderChanged;
  final ValueChanged<String> onPhoneChanged;
  final bool isLoading;

  const BookingPatientFields({
    super.key,
    required this.phoneController,
    required this.nameController,
    required this.ageController,
    required this.selectedGender,
    required this.onGenderChanged,
    required this.onPhoneChanged,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Phone Input with Discovery Spinner
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (val) =>
                    (val == null || val.length < 10) ? 'Invalid Phone' : null,
                onChanged: onPhoneChanged,
              ),
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Patient Name, Age & Sex
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Patient Name',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    (val == null || val.isEmpty) ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: ageController,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (val) =>
                    (val == null || val.isEmpty) ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                initialValue: selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Sex',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (val) {
                  if (val != null) onGenderChanged(val);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
