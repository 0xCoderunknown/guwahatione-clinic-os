import 'package:flutter/material.dart';

/// Step 1: Patient Demographics Header & Allergies Alert Banner
class PatientHeaderSection extends StatelessWidget {
  final String patientName;
  final int patientAge;
  final String patientGender;
  final String patientPhone;
  final List<String> allergies;
  final VoidCallback onAddAllergy;
  final ValueChanged<String> onRemoveAllergy;
  final VoidCallback onPriorMedsPressed;

  const PatientHeaderSection({
    super.key,
    required this.patientName,
    required this.patientAge,
    required this.patientGender,
    required this.patientPhone,
    required this.allergies,
    required this.onAddAllergy,
    required this.onRemoveAllergy,
    required this.onPriorMedsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final hasAllergies = allergies.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasAllergies ? Colors.red.shade200 : const Color(0xFFE2E8F0),
          width: hasAllergies ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Demographics Bar
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.teal.shade50,
                  foregroundColor: Colors.teal.shade700,
                  radius: 20,
                  child: const Icon(Icons.person, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        patientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        "Age: ${patientAge > 0 ? patientAge : '—'} yrs • Sex: $patientGender",
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                      Text(
                        "Phone: $patientPhone",
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.medication_outlined, size: 16),
                  label: const Text('Prior Meds', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                  onPressed: onPriorMedsPressed,
                ),
              ],
            ),
          ),

          // Prominent Allergies Banner (Visual Alert)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: hasAllergies ? Colors.red.shade50 : Colors.amber.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
              border: Border(
                top: BorderSide(
                  color: hasAllergies ? Colors.red.shade200 : Colors.amber.shade200,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  hasAllergies ? Icons.warning_amber_rounded : Icons.info_outline,
                  color: hasAllergies ? Colors.red.shade700 : Colors.amber.shade800,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "ALLERGIES: ",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: hasAllergies ? Colors.red.shade800 : Colors.amber.shade900,
                  ),
                ),
                Expanded(
                  child: hasAllergies
                      ? Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: allergies.map((allergy) {
                            return Chip(
                              backgroundColor: Colors.white,
                              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                              visualDensity: VisualDensity.compact,
                              side: BorderSide(color: Colors.red.shade300),
                              label: Text(
                                allergy,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade800,
                                ),
                              ),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () => onRemoveAllergy(allergy),
                            );
                          }).toList(),
                        )
                      : Text(
                          "No known allergies recorded (Click + to add)",
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.amber.shade900,
                          ),
                        ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  tooltip: 'Add Known Drug/Substance Allergy',
                  color: hasAllergies ? Colors.red.shade700 : Colors.amber.shade900,
                  onPressed: onAddAllergy,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
