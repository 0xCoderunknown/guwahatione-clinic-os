import 'package:flutter/material.dart';

import '../../../models/medicine.dart';
import '../../../utils/medicine_search_scorer.dart';
import '../encounter_form_state.dart';

/// Form banner displaying the staged medication with prefilled OPD defaults and quick dosage controls.
class StagedMedicineForm extends StatelessWidget {
  final Medicine? stagedMedicine;
  final CompositionGroupResult? stagedGenericGroup;
  final String? stagedUnlistedName;
  final String? stagedComposition;
  final TextEditingController stagedDosageController;
  final TextEditingController stagedDurationController;
  final TextEditingController stagedInstructionsController;
  final String stagedFrequency;
  final ValueChanged<String?> onFrequencyChanged;
  final String stagedTiming;
  final ValueChanged<String?> onTimingChanged;
  final bool stagedIsChronic;
  final ValueChanged<bool> onChronicChanged;
  final VoidCallback onCancelStaging;
  final VoidCallback onConfirmAddStaged;

  const StagedMedicineForm({
    super.key,
    required this.stagedMedicine,
    required this.stagedGenericGroup,
    required this.stagedUnlistedName,
    required this.stagedComposition,
    required this.stagedDosageController,
    required this.stagedDurationController,
    required this.stagedInstructionsController,
    required this.stagedFrequency,
    required this.onFrequencyChanged,
    required this.stagedTiming,
    required this.onTimingChanged,
    required this.stagedIsChronic,
    required this.onChronicChanged,
    required this.onCancelStaging,
    required this.onConfirmAddStaged,
  });

  factory StagedMedicineForm.fromForm({
    Key? key,
    required EncounterFormState form,
    required String Function() uuidGenerator,
    required VoidCallback onUpdate,
  }) {
    return StagedMedicineForm(
      key: key,
      stagedMedicine: form.stagedMedicine,
      stagedGenericGroup: form.stagedGenericGroup,
      stagedUnlistedName: form.stagedUnlistedName,
      stagedComposition: form.stagedComposition,
      stagedDosageController: form.stagedDosageController,
      stagedDurationController: form.stagedDurationController,
      stagedInstructionsController: form.stagedInstructionsController,
      stagedFrequency: form.stagedFrequency,
      onFrequencyChanged: (val) {
        if (val != null) {
          form.stagedFrequency = val;
          onUpdate();
        }
      },
      stagedTiming: form.stagedTiming,
      onTimingChanged: (val) {
        if (val != null) {
          form.stagedTiming = val;
          onUpdate();
        }
      },
      stagedIsChronic: form.stagedIsChronic,
      onChronicChanged: (val) {
        form.stagedIsChronic = val;
        onUpdate();
      },
      onCancelStaging: () {
        form.cancelStaging();
        onUpdate();
      },
      onConfirmAddStaged: () {
        form.confirmAddStagedMedicine(uuidGenerator);
        onUpdate();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String displayName = '';
    String compName = stagedComposition ?? '';
    if (stagedMedicine != null) {
      displayName = stagedMedicine!.productName;
      if (compName.isEmpty) compName = stagedMedicine!.fullCompositionLabel;
    } else if (stagedGenericGroup != null) {
      displayName = stagedGenericGroup!.compositionLabel;
      if (compName.isEmpty) compName = 'Generic formulation';
    } else if (stagedUnlistedName != null) {
      displayName = stagedUnlistedName!;
      if (compName.isEmpty) compName = 'Outside / Unlisted';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.teal.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, size: 18, color: Colors.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Staging: $displayName ($compName)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF065F46)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Cancel Staging',
                onPressed: onCancelStaging,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: stagedDosageController,
                  decoration: const InputDecoration(
                    labelText: 'Dosage',
                    hintText: '1 Tablet / 5 ml',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  initialValue: stagedFrequency,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    '1-0-0 (OD)',
                    '1-0-1 (BD)',
                    '0-0-1 (HS)',
                    '1-1-1 (TDS)',
                    'SOS (As Needed)',
                    'Once Weekly',
                  ].map((f) => DropdownMenuItem(value: f, child: Text(f, style: TextStyle(fontSize: 12)))).toList(),
                  onChanged: onFrequencyChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  initialValue: stagedTiming,
                  decoration: const InputDecoration(
                    labelText: 'Timing',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    'After Food',
                    'Before Food',
                    'After Food (Morning)',
                    'At Bedtime',
                    'With Food',
                  ].map((t) => DropdownMenuItem(value: t, child: Text(t, style: TextStyle(fontSize: 12)))).toList(),
                  onChanged: onTimingChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: stagedDurationController,
                  enabled: !stagedIsChronic,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: stagedIsChronic ? 'Duration' : 'Days',
                    hintText: stagedIsChronic ? 'Continuous' : '30',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilterChip(
                label: const Text('Continuous (Chronic)', style: TextStyle(fontSize: 11)),
                selected: stagedIsChronic,
                onSelected: onChronicChanged,
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: TextField(
                  controller: stagedInstructionsController,
                  decoration: const InputDecoration(
                    labelText: 'Instructions / Notes (Optional)',
                    hintText: 'e.g., Take with warm water...',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: onCancelStaging,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add to Prescription', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: onConfirmAddStaged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
