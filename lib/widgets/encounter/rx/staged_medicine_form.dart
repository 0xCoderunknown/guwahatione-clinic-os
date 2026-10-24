import 'package:flutter/material.dart';

import '../../../core/engines/engines.dart';
import '../../../models/medicine.dart';
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
  final ValueChanged<String?>? onDurationPresetChanged;
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
    this.onDurationPresetChanged,
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
      onDurationPresetChanged: (val) {
        if (val == 'To continue') {
          form.stagedIsChronic = true;
          form.stagedDurationController.text = 'To continue';
        } else if (val == 'SOS') {
          form.stagedIsChronic = false;
          form.stagedDurationController.text = 'SOS';
        } else if (val == 'Custom') {
          form.stagedIsChronic = false;
        } else if (val != null && val.endsWith(' days')) {
          form.stagedIsChronic = false;
          form.stagedDurationController.text = val;
        }
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
      if (compName.isEmpty) compName = 'Generic medicine';
    } else if (stagedUnlistedName != null) {
      displayName = stagedUnlistedName!;
      if (compName.isEmpty) compName = 'Medicine not in catalogue';
    }

    final frequencyOptions = [
      '1-0-0',
      '1-0-1',
      '0-0-1',
      '1-1-1',
      '1-0-0 (OD)',
      '1-0-1 (BD)',
      '0-0-1 (HS)',
      '1-1-1 (TDS)',
      'SOS (As Needed)',
      'Once Weekly',
    ];
    if (!frequencyOptions.contains(stagedFrequency)) {
      frequencyOptions.insert(0, stagedFrequency);
    }

    final timingOptions = [
      'After Food (PC)',
      'Before Food / Khali Pet (AC)',
      'At Bedtime (HS)',
      'With Food',
      'After Food (Morning)',
      'As Needed (SOS)',
    ];
    if (!timingOptions.contains(stagedTiming)) {
      timingOptions.insert(0, stagedTiming);
    }

    final String currentDurationPreset;
    final durText = stagedDurationController.text.trim().toLowerCase();
    if (stagedIsChronic ||
        durText == 'to continue' ||
        durText == 'cont' ||
        durText == 'continue' ||
        durText == 'chronic') {
      currentDurationPreset = 'To continue';
    } else if (durText == 'sos' ||
        durText == 's.o.s' ||
        durText == 'as needed' ||
        durText.startsWith('sos ')) {
      currentDurationPreset = 'SOS';
    } else if (['30', '15', '14', '10', '7', '5', '3'].contains(
      durText.replaceAll(' days', '').replaceAll('d', '').trim(),
    )) {
      final days =
          durText.replaceAll(' days', '').replaceAll('d', '').trim();
      currentDurationPreset = '$days days';
    } else {
      currentDurationPreset = 'Custom';
    }

    final durationOptions = [
      'To continue',
      'SOS',
      '30 days',
      '15 days',
      '14 days',
      '10 days',
      '7 days',
      '5 days',
      '3 days',
      'Custom',
    ];

    final isMobile = MediaQuery.of(context).size.width < 600;

    final dosageWidget = TextField(
      controller: stagedDosageController,
      textInputAction: TextInputAction.next,
      onSubmitted: (_) => onConfirmAddStaged(),
      decoration: const InputDecoration(
        labelText: 'Dosage',
        hintText: '1 Tablet / 5 ml',
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(),
      ),
    );

    final frequencyWidget = DropdownButtonFormField<String>(
      initialValue: stagedFrequency,
      decoration: const InputDecoration(
        labelText: 'Frequency',
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(),
      ),
      items: frequencyOptions
          .map(
            (f) => DropdownMenuItem(
              value: f,
              child: Text(f, style: const TextStyle(fontSize: 12)),
            ),
          )
          .toList(),
      onChanged: onFrequencyChanged,
    );

    final timingWidget = DropdownButtonFormField<String>(
      initialValue: stagedTiming,
      decoration: const InputDecoration(
        labelText: 'Timing',
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(),
      ),
      items: timingOptions
          .map(
            (t) => DropdownMenuItem(
              value: t,
              child: Text(t, style: const TextStyle(fontSize: 12)),
            ),
          )
          .toList(),
      onChanged: onTimingChanged,
    );

    final durationWidget = DropdownButtonFormField<String>(
      initialValue: currentDurationPreset,
      decoration: const InputDecoration(
        labelText: 'Duration',
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(),
      ),
      items: durationOptions
          .map(
            (d) => DropdownMenuItem(
              value: d,
              child: Text(
                d == 'To continue'
                    ? 'To continue (Chronic)'
                    : d == 'SOS'
                        ? 'SOS (As needed)'
                        : d,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          )
          .toList(),
      onChanged: (val) {
        if (onDurationPresetChanged != null) {
          onDurationPresetChanged!(val);
        } else if (val == 'To continue') {
          onChronicChanged(true);
          stagedDurationController.text = 'To continue';
        } else if (val == 'SOS') {
          onChronicChanged(false);
          stagedDurationController.text = 'SOS';
        } else if (val != null && val.endsWith(' days')) {
          onChronicChanged(false);
          stagedDurationController.text = val;
        } else {
          onChronicChanged(false);
        }
      },
    );

    final customDurationWidget = TextField(
      controller: stagedDurationController,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => onConfirmAddStaged(),
      decoration: const InputDecoration(
        labelText: 'Custom Duration',
        hintText: '1-300, cont, SOS',
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(),
      ),
    );

    final instructionsWidget = TextField(
      controller: stagedInstructionsController,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => onConfirmAddStaged(),
      decoration: const InputDecoration(
        labelText: 'Instructions / Notes (Optional)',
        hintText: 'e.g., Take with warm water...',
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(),
      ),
    );

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
                  'Preparing: $displayName ($compName)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF065F46),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Cancel',
                onPressed: onCancelStaging,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 1-Tap Rapid Schedule Chips (Frequency + Timing In One Touch)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ActionChip(
                avatar: const Icon(Icons.wb_sunny_outlined, size: 13, color: Colors.teal),
                label: const Text('1-0-0 Khali Pet', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  onFrequencyChanged('1-0-0');
                  onTimingChanged('Before Food / Khali Pet (AC)');
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.wb_sunny, size: 13, color: Colors.orange),
                label: const Text('1-0-0 After Food', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  onFrequencyChanged('1-0-0');
                  onTimingChanged('After Food (PC)');
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.repeat, size: 13, color: Colors.indigo),
                label: const Text('1-0-1 (BD) After Food', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  onFrequencyChanged('1-0-1');
                  onTimingChanged('After Food (PC)');
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.rotate_right, size: 13, color: Colors.blue),
                label: const Text('1-1-1 (TDS)', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  onFrequencyChanged('1-1-1');
                  onTimingChanged('After Food (PC)');
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.nightlight_round, size: 13, color: Colors.deepPurple),
                label: const Text('0-0-1 Bedtime (HS)', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  onFrequencyChanged('0-0-1');
                  onTimingChanged('At Bedtime (HS)');
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.flash_on, size: 13, color: Colors.amber),
                label: const Text('SOS (When Needed)', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  onFrequencyChanged('SOS (As Needed)');
                  onTimingChanged('As Needed (SOS)');
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isMobile) ...[
            dosageWidget,
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: frequencyWidget),
                const SizedBox(width: 8),
                Expanded(child: timingWidget),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: durationWidget),
                if (currentDurationPreset == 'Custom') ...[
                  const SizedBox(width: 8),
                  Expanded(child: customDurationWidget),
                ],
              ],
            ),
            const SizedBox(height: 10),
            instructionsWidget,
          ] else ...[
            Row(
              children: [
                Expanded(flex: 2, child: dosageWidget),
                const SizedBox(width: 8),
                Expanded(flex: 3, child: frequencyWidget),
                const SizedBox(width: 8),
                Expanded(flex: 3, child: timingWidget),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(flex: 3, child: durationWidget),
                if (currentDurationPreset == 'Custom') ...[
                  const SizedBox(width: 8),
                  Expanded(flex: 3, child: customDurationWidget),
                ],
                const SizedBox(width: 10),
                Expanded(
                  flex: currentDurationPreset == 'Custom' ? 4 : 5,
                  child: instructionsWidget,
                ),
              ],
            ),
          ],
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
                  label: const Text(
                    'Add to Prescription',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
