import 'package:flutter/material.dart';

import '../../../models/prescription_item.dart';

/// Modal dialog allowing the doctor to quickly tweak dosage, frequency, timing,
/// and instructions for a medication in-place without re-searching the catalogue.
class InlineDosageEditDialog extends StatefulWidget {
  final PrescriptionItem item;
  final ValueChanged<PrescriptionItem> onSave;

  const InlineDosageEditDialog({
    super.key,
    required this.item,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required PrescriptionItem item,
    required ValueChanged<PrescriptionItem> onSave,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => InlineDosageEditDialog(item: item, onSave: onSave),
    );
  }

  @override
  State<InlineDosageEditDialog> createState() => _InlineDosageEditDialogState();
}

class _InlineDosageEditDialogState extends State<InlineDosageEditDialog> {
  late final TextEditingController _dosageController;
  late final TextEditingController _frequencyController;
  late final TextEditingController _timingController;
  late final TextEditingController _instructionsController;

  static const _dosagePresets = [
    '1 Tablet',
    '0.5 Tablet',
    '2 Tablets',
    '5 ml',
    '10 ml',
    '1 Capsule',
    '1 Drop',
  ];

  static const _frequencyPresets = [
    '1-0-1 (BD)',
    '1-0-0 (OD)',
    '0-0-1 (HS)',
    '1-1-1 (TDS)',
    'SOS',
  ];

  static const _timingPresets = [
    'After Food (PC)',
    'Before Food / Khali Pet (AC)',
    'At Bedtime (HS)',
    'With Food',
  ];

  @override
  void initState() {
    super.initState();
    _dosageController = TextEditingController(text: widget.item.dosage);
    _frequencyController = TextEditingController(text: widget.item.frequency);
    _timingController = TextEditingController(text: widget.item.timing);
    _instructionsController =
        TextEditingController(text: widget.item.instructions ?? '');
  }

  @override
  void dispose() {
    _dosageController.dispose();
    _frequencyController.dispose();
    _timingController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _save() {
    final updated = widget.item.copyWith(
      dosage: _dosageController.text.trim().isNotEmpty
          ? _dosageController.text.trim()
          : widget.item.dosage,
      frequency: _frequencyController.text.trim().isNotEmpty
          ? _frequencyController.text.trim()
          : widget.item.frequency,
      timing: _timingController.text.trim().isNotEmpty
          ? _timingController.text.trim()
          : widget.item.timing,
      instructions: _instructionsController.text.trim().isNotEmpty
          ? _instructionsController.text.trim()
          : null,
    );

    widget.onSave(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF99F6E4)),
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: Color(0xFF0F766E),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Regimen: ${widget.item.effectiveName}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.item.composition,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Form fields in scrollable area
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Dosage
                      const Text(
                        'Dosage Quantity',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _dosagePresets.map((preset) {
                          final isSelected =
                              _dosageController.text.trim() == preset;
                          return ChoiceChip(
                            label: Text(preset,
                                style: const TextStyle(fontSize: 11)),
                            selected: isSelected,
                            selectedColor: Colors.teal.shade100,
                            onSelected: (_) => setState(
                                () => _dosageController.text = preset),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _dosageController,
                        decoration: InputDecoration(
                          hintText: 'e.g. 1 Tablet, 5 ml, 2 Capsules',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 9,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Section 2: Frequency
                      const Text(
                        'Frequency Schedule',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _frequencyPresets.map((freq) {
                          final isSelected =
                              _frequencyController.text.trim() == freq;
                          return ChoiceChip(
                            label:
                                Text(freq, style: const TextStyle(fontSize: 11)),
                            selected: isSelected,
                            selectedColor: Colors.teal.shade100,
                            onSelected: (_) => setState(
                                () => _frequencyController.text = freq),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _frequencyController,
                        decoration: InputDecoration(
                          hintText: 'e.g. 1-0-1 (BD), 1-0-0 (OD)',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 9,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Section 3: Timing
                      const Text(
                        'Timing Relation to Food',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _timingPresets.map((timing) {
                          final isSelected =
                              _timingController.text.trim() == timing;
                          return ChoiceChip(
                            label: Text(timing,
                                style: const TextStyle(fontSize: 11)),
                            selected: isSelected,
                            selectedColor: Colors.teal.shade100,
                            onSelected: (_) =>
                                setState(() => _timingController.text = timing),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _timingController,
                        decoration: InputDecoration(
                          hintText: 'e.g. After Food (PC), Before Food (AC)',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 9,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Section 4: Special Instructions
                      const Text(
                        'Special Instructions / Remarks (Optional)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _instructionsController,
                        decoration: InputDecoration(
                          hintText:
                              'e.g. Take with lukewarm water, swallow whole',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: _save,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
