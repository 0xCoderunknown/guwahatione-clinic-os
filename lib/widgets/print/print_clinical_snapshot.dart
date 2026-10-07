import 'package:flutter/material.dart';

import '../../models/consultation.dart';

/// Printable clinical snapshot: vitals strip, chief complaints, and provisional diagnosis.
class PrintClinicalSnapshot extends StatelessWidget {
  final Consultation consultation;

  const PrintClinicalSnapshot({
    super.key,
    required this.consultation,
  });

  @override
  Widget build(BuildContext context) {
    final c = consultation;
    final vitals = c.vitals;

    final vitalsParts = <String>[];
    if (vitals != null) {
      if (vitals.bpFormatted != null) vitalsParts.add("BP: ${vitals.bpFormatted}");
      if (vitals.pulseRate != null) vitalsParts.add("Pulse: ${vitals.pulseRate} bpm");
      if (vitals.spO2 != null) vitalsParts.add("SpO2: ${vitals.spO2}%");
      if (vitals.temperature != null) vitalsParts.add("Temp: ${vitals.temperature}°F");
      if (vitals.weightKg != null) vitalsParts.add("Weight: ${vitals.weightKg} kg");
    }

    final hasComplaints = c.chiefComplaints.isNotEmpty;
    final hasDiagnosis = c.provisionalDiagnosis.isNotEmpty;
    final hasVitals = vitalsParts.isNotEmpty;

    if (!hasComplaints && !hasDiagnosis && !hasVitals) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasVitals)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                "Vitals: ${vitalsParts.join('  |  ')}",
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
          if (hasComplaints)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                "Chief Complaints: ${c.chiefComplaints.join('; ')}",
                style: const TextStyle(fontSize: 11),
              ),
            ),
          if (hasDiagnosis)
            Text(
              "Diagnosis: ${c.provisionalDiagnosis.join('; ')}",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}
