import 'package:flutter/material.dart';
import '../common/section_card.dart';

/// Step 2: Vitals & Clinical Examination (Chief complaints, diagnoses, and exam notes)
class VitalsAndExamSection extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  // Controllers
  final TextEditingController systolicBpController;
  final TextEditingController diastolicBpController;
  final TextEditingController pulseController;
  final TextEditingController tempController;
  final TextEditingController weightController;
  final TextEditingController spo2Controller;
  final TextEditingController complaintInputController;
  final TextEditingController diagnosisInputController;
  final TextEditingController examController;

  // Lists
  final List<String> chiefComplaints;
  final List<String> provisionalDiagnoses;

  // Callbacks
  final VoidCallback onAddChiefComplaint;
  final ValueChanged<String> onRemoveChiefComplaint;
  final VoidCallback onAddProvisionalDiagnosis;
  final ValueChanged<String> onRemoveProvisionalDiagnosis;

  const VitalsAndExamSection({
    super.key,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.systolicBpController,
    required this.diastolicBpController,
    required this.pulseController,
    required this.tempController,
    required this.weightController,
    required this.spo2Controller,
    required this.complaintInputController,
    required this.diagnosisInputController,
    required this.examController,
    required this.chiefComplaints,
    required this.provisionalDiagnoses,
    required this.onAddChiefComplaint,
    required this.onRemoveChiefComplaint,
    required this.onAddProvisionalDiagnosis,
    required this.onRemoveProvisionalDiagnosis,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Step 2: Vitals & Clinical Examination',
      icon: Icons.monitor_heart_outlined,
      isExpanded: isExpanded,
      onToggleExpand: onToggleExpand,
      trailing: TextButton.icon(
        icon: Icon(isExpanded ? Icons.unfold_less : Icons.edit_note, size: 18),
        label: Text(isExpanded ? 'Close Findings' : 'Add / Edit Findings'),
        onPressed: onToggleExpand,
      ),
      child: isExpanded
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact Vitals Grid
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildCompactVitalField(
                      label: 'BP (Systolic)',
                      unit: 'mmHg',
                      controller: systolicBpController,
                      hint: '120',
                      width: 140,
                    ),
                    _buildCompactVitalField(
                      label: 'BP (Diastolic)',
                      unit: 'mmHg',
                      controller: diastolicBpController,
                      hint: '80',
                      width: 140,
                    ),
                    _buildCompactVitalField(
                      label: 'Pulse Rate',
                      unit: 'bpm',
                      controller: pulseController,
                      hint: '72',
                      width: 130,
                    ),
                    _buildCompactVitalField(
                      label: 'SpO2',
                      unit: '%',
                      controller: spo2Controller,
                      hint: '98',
                      width: 110,
                    ),
                    _buildCompactVitalField(
                      label: 'Temp',
                      unit: '°F',
                      controller: tempController,
                      hint: '98.6',
                      width: 120,
                    ),
                    _buildCompactVitalField(
                      label: 'Weight',
                      unit: 'kg',
                      controller: weightController,
                      hint: '68.5',
                      width: 130,
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Chief Complaints
                const Text(
                  'Chief Complaints / Symptoms',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: complaintInputController,
                        decoration: const InputDecoration(
                          hintText: 'e.g., Fever x 3 days, dry cough, headache...',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => onAddChiefComplaint(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: onAddChiefComplaint,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                if (chiefComplaints.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: chiefComplaints.map((c) {
                      return Chip(
                        label: Text(c, style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.teal.shade50,
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => onRemoveChiefComplaint(c),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),

                // Provisional Diagnosis
                const Text(
                  'Provisional / Working Diagnosis',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: diagnosisInputController,
                        decoration: const InputDecoration(
                          hintText: 'e.g., Acute Viral Bronchitis, Essential Hypertension...',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => onAddProvisionalDiagnosis(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: onAddProvisionalDiagnosis,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                if (provisionalDiagnoses.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: provisionalDiagnoses.map((d) {
                      return Chip(
                        label: Text(d, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        backgroundColor: Colors.blue.shade50,
                        side: BorderSide(color: Colors.blue.shade200),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => onRemoveProvisionalDiagnosis(d),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),

                // Clinical Examination Notes
                const Text(
                  'Physical & Systemic Examination (Optional)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: examController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Chest clear, no wheezing, throat congested, abdomen soft...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.teal.shade50,
                      foregroundColor: Colors.teal.shade800,
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Close Findings & Proceed to Medicines'),
                    onPressed: onToggleExpand,
                  ),
                ),
              ],
            )
          : _buildCollapsedSummary(),
    );
  }

  Widget _buildCollapsedSummary() {
    final chips = <Widget>[];
    if (systolicBpController.text.isNotEmpty || diastolicBpController.text.isNotEmpty) {
      chips.add(_buildSummaryPill('BP', '${systolicBpController.text}/${diastolicBpController.text} mmHg', Icons.speed));
    }
    if (pulseController.text.isNotEmpty) {
      chips.add(_buildSummaryPill('Pulse', '${pulseController.text} bpm', Icons.favorite_border));
    }
    if (spo2Controller.text.isNotEmpty) {
      chips.add(_buildSummaryPill('SpO2', '${spo2Controller.text}%', Icons.air));
    }
    if (tempController.text.isNotEmpty) {
      chips.add(_buildSummaryPill('Temp', '${tempController.text}°F', Icons.thermostat));
    }
    if (weightController.text.isNotEmpty) {
      chips.add(_buildSummaryPill('Weight', '${weightController.text} kg', Icons.scale));
    }
    if (chiefComplaints.isNotEmpty) {
      chips.add(_buildSummaryPill('Complaints', chiefComplaints.join(', '), Icons.chat_bubble_outline));
    }
    if (provisionalDiagnoses.isNotEmpty) {
      chips.add(_buildSummaryPill('Diagnosis', provisionalDiagnoses.join(', '), Icons.medical_services_outlined, isAccent: true));
    }

    if (chips.isEmpty) {
      return InkWell(
        onTap: onToggleExpand,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Icon(Icons.add_circle_outline, size: 18, color: Colors.teal.shade700),
              const SizedBox(width: 8),
              Text(
                'No clinical findings or vitals recorded yet. Tap "Add / Edit Findings" to add.',
                style: TextStyle(fontSize: 12, color: Colors.teal.shade700, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: chips,
    );
  }

  Widget _buildSummaryPill(String label, String value, IconData icon, {bool isAccent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isAccent ? Colors.blue.shade50 : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isAccent ? Colors.blue.shade200 : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isAccent ? Colors.blue.shade700 : Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isAccent ? Colors.blue.shade900 : Colors.grey.shade800),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isAccent ? Colors.blue.shade900 : const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactVitalField({
    required String label,
    required String unit,
    required TextEditingController controller,
    required String hint,
    required double width,
  }) {
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
