import 'package:flutter/material.dart';

import 'encounter_form_state.dart';

/// Compact numerical vitals input fields (BP Systolic, Diastolic, Pulse, SpO2, Temp, Weight).
class VitalsInputGrid extends StatelessWidget {
  final EncounterFormState form;

  const VitalsInputGrid({
    super.key,
    required this.form,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildField('BP (Systolic)', 'mmHg', form.systolicBpController, '120', 140),
        _buildField('BP (Diastolic)', 'mmHg', form.diastolicBpController, '80', 140),
        _buildField('Pulse Rate', 'bpm', form.pulseController, '72', 130),
        _buildField('SpO2', '%', form.spo2Controller, '98', 110),
        _buildField('Temp', '°F', form.tempController, '98.6', 120),
        _buildField('Weight', 'kg', form.weightController, '68.5', 130),
      ],
    );
  }

  Widget _buildField(String label, String unit, TextEditingController controller, String hint, double width) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 3),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: hint,
              suffixText: unit,
              suffixStyle: const TextStyle(fontSize: 10, color: Colors.grey),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
