import 'package:flutter/material.dart';

import '../common/section_card.dart';
import 'encounter_form_state.dart';
import 'vitals_input_grid.dart';

/// Step 2: Vitals & Clinical Examination (Chief complaints, diagnoses, and exam notes)
class VitalsAndExamSection extends StatelessWidget {
  final EncounterFormState form;
  final VoidCallback onUpdate;

  const VitalsAndExamSection({
    super.key,
    required this.form,
    required this.onUpdate,
  });

  /// Factory binding directly to EncounterFormState.
  const VitalsAndExamSection.fromForm({
    super.key,
    required this.form,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Step 2: Vitals & Clinical Examination',
      icon: Icons.monitor_heart_outlined,
      isExpanded: form.isFindingsExpanded,
      onToggleExpand: () {
        form.isFindingsExpanded = !form.isFindingsExpanded;
        onUpdate();
      },
      trailing: TextButton.icon(
        icon: Icon(form.isFindingsExpanded ? Icons.unfold_less : Icons.edit_note, size: 18),
        label: Text(form.isFindingsExpanded ? 'Close Findings' : 'Add / Edit Findings'),
        onPressed: () {
          form.isFindingsExpanded = !form.isFindingsExpanded;
          onUpdate();
        },
      ),
      child: form.isFindingsExpanded
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact Vitals Grid
                VitalsInputGrid(form: form),
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
                        controller: form.complaintInputController,
                        decoration: const InputDecoration(
                          hintText: 'e.g., Fever x 3 days, dry cough, headache...',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) {
                          form.addChiefComplaint();
                          onUpdate();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        form.addChiefComplaint();
                        onUpdate();
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                if (form.chiefComplaints.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: form.chiefComplaints.map((c) {
                      return Chip(
                        label: Text(c, style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.teal.shade50,
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () {
                          form.removeChiefComplaint(c);
                          onUpdate();
                        },
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
                        controller: form.diagnosisInputController,
                        decoration: const InputDecoration(
                          hintText: 'e.g., Acute Viral Bronchitis, Essential Hypertension...',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) {
                          form.addProvisionalDiagnosis();
                          onUpdate();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        form.addProvisionalDiagnosis();
                        onUpdate();
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                if (form.provisionalDiagnoses.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: form.provisionalDiagnoses.map((d) {
                      return Chip(
                        label: Text(d, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        backgroundColor: Colors.blue.shade50,
                        side: BorderSide(color: Colors.blue.shade200),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () {
                          form.removeProvisionalDiagnosis(d);
                          onUpdate();
                        },
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
                  controller: form.examController,
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
                    onPressed: () {
                      form.isFindingsExpanded = !form.isFindingsExpanded;
                      onUpdate();
                    },
                  ),
                ),
              ],
            )
          : _buildCollapsedSummary(),
    );
  }

  Widget _buildCollapsedSummary() {
    final chips = <Widget>[];
    if (form.systolicBpController.text.isNotEmpty || form.diastolicBpController.text.isNotEmpty) {
      chips.add(_buildSummaryPill('BP', '${form.systolicBpController.text}/${form.diastolicBpController.text} mmHg', Icons.speed));
    }
    if (form.pulseController.text.isNotEmpty) {
      chips.add(_buildSummaryPill('Pulse', '${form.pulseController.text} bpm', Icons.favorite_border));
    }
    if (form.spo2Controller.text.isNotEmpty) {
      chips.add(_buildSummaryPill('SpO2', '${form.spo2Controller.text}%', Icons.air));
    }
    if (form.tempController.text.isNotEmpty) {
      chips.add(_buildSummaryPill('Temp', '${form.tempController.text}°F', Icons.thermostat));
    }
    if (form.weightController.text.isNotEmpty) {
      chips.add(_buildSummaryPill('Weight', '${form.weightController.text} kg', Icons.scale));
    }
    if (form.chiefComplaints.isNotEmpty) {
      chips.add(_buildSummaryPill('Complaints', form.chiefComplaints.join(', '), Icons.chat_bubble_outline));
    }
    if (form.provisionalDiagnoses.isNotEmpty) {
      chips.add(_buildSummaryPill('Diagnosis', form.provisionalDiagnoses.join(', '), Icons.medical_services_outlined, isAccent: true));
    }

    if (chips.isEmpty) {
      return InkWell(
        onTap: () {
          form.isFindingsExpanded = !form.isFindingsExpanded;
          onUpdate();
        },
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
}
