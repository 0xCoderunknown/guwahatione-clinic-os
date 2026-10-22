import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/prescription_item.dart';

/// Single row item for reconciled chronic medications from prior encounters.
/// Supports in-place duration dropdown selection, inline dosage editing,
/// and rapid CONTINUE / STOP toggling per Invariant #3 & QOL-14.
class ReconciliationItemRow extends StatelessWidget {
  final PrescriptionItem item;
  final int index;
  final ValueChanged<int> onContinue;
  final void Function(PrescriptionItem item, int index)? onPromptStop;
  final ValueChanged<int>? onStop;
  final void Function(int index, PrescriptionItem item)? onItemUpdated;

  const ReconciliationItemRow({
    super.key,
    required this.item,
    required this.index,
    required this.onContinue,
    this.onPromptStop,
    this.onStop,
    this.onItemUpdated,
  });

  void _handleDurationSelect(BuildContext context, String value) {
    if (value == 'STOP') {
      if (onStop != null) {
        onStop!(index);
      } else if (onPromptStop != null) {
        onPromptStop!(item, index);
      } else {
        onItemUpdated?.call(
          index,
          item.copyWith(
            action: MedicationAction.stop,
            stopReason: 'Discontinued by doctor',
          ),
        );
      }
      return;
    }

    if (value == 'Custom...') {
      CustomDurationDialog.show(
        context,
        initialDays: item.durationDays,
        onApply: (days) {
          onItemUpdated?.call(
            index,
            item.copyWith(
              action: MedicationAction.continueAction,
              durationDays: days,
              durationText: '$days Days',
              stopReason: null,
            ),
          );
        },
      );
      return;
    }

    if (value == 'To Continue') {
      onItemUpdated?.call(
        index,
        item.copyWith(
          action: MedicationAction.continueAction,
          durationText: 'To Continue',
          clearDuration: true,
          stopReason: null,
        ),
      );
    } else if (value == 'SOS') {
      onItemUpdated?.call(
        index,
        item.copyWith(
          action: MedicationAction.continueAction,
          durationText: 'SOS',
          clearDuration: true,
          stopReason: null,
        ),
      );
    } else if (value.endsWith(' Days') || value.endsWith(' Month')) {
      final int days;
      if (value == '1 Month') {
        days = 30;
      } else {
        days = int.tryParse(value.split(' ').first) ?? 7;
      }
      onItemUpdated?.call(
        index,
        item.copyWith(
          action: MedicationAction.continueAction,
          durationDays: days,
          durationText: '$days Days',
          stopReason: null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isContinued = item.action == MedicationAction.continueAction;
    final isStopped = item.action == MedicationAction.stop;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isStopped
            ? Colors.red.shade50.withValues(alpha: 0.4)
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isContinued
              ? Colors.teal.shade300
              : isStopped
              ? Colors.red.shade300
              : const Color(0xFFCBD5E1),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.effectiveName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    decoration: isStopped ? TextDecoration.lineThrough : null,
                    color: isStopped ? Colors.grey : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),

                // Column 2: Tap-to-edit Dosage, Timing & Composition
                InkWell(
                  onTap: () {
                    InlineDosageEditDialog.show(
                      context,
                      item: item,
                      onSave: (updated) => onItemUpdated?.call(index, updated),
                    );
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            "${item.composition} • ${item.formattedDosageTiming}",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isStopped
                                  ? Colors.grey.shade600
                                  : const Color(0xFF0F766E),
                              decoration:
                                  isStopped ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.edit_note_rounded,
                          size: 15,
                          color: isStopped
                              ? Colors.grey.shade400
                              : const Color(0xFF0F766E),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isStopped &&
                    item.stopReason != null &&
                    item.stopReason!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      "Stopped Reason: ${item.stopReason}",
                      style: const TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // In-Place Duration Dropdown Menu (QOL-14)
          PopupMenuButton<String>(
            tooltip: 'Change Duration / Regimen Action',
            onSelected: (val) => _handleDurationSelect(context, val),
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'To Continue',
                child: Row(
                  children: [
                    Icon(Icons.autorenew_rounded, size: 16, color: Colors.teal),
                    SizedBox(width: 8),
                    Expanded(child: Text('To Continue')),
                  ],
                ),
              ),
              const PopupMenuItem(value: '3 Days', child: Text('3 Days')),
              const PopupMenuItem(value: '5 Days', child: Text('5 Days')),
              const PopupMenuItem(value: '7 Days', child: Text('7 Days')),
              const PopupMenuItem(value: '14 Days', child: Text('14 Days')),
              const PopupMenuItem(
                value: '1 Month',
                child: Text('1 Month (30 Days)'),
              ),
              const PopupMenuItem(value: 'SOS', child: Text('SOS (As Needed)')),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'Custom...',
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_calendar_outlined,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    SizedBox(width: 8),
                    Expanded(child: Text('Custom Days...')),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'STOP',
                child: Row(
                  children: [
                    Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'STOP (Discontinue)',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isStopped ? Colors.red.shade50 : const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isStopped
                      ? Colors.red.shade200
                      : const Color(0xFF99F6E4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isStopped ? Icons.block_rounded : Icons.schedule_rounded,
                    size: 13,
                    color: isStopped
                        ? Colors.red.shade700
                        : const Color(0xFF0F766E),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isStopped ? 'To STOP' : item.effectiveDuration,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isStopped
                          ? Colors.red.shade800
                          : const Color(0xFF0F766E),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 16,
                    color: isStopped
                        ? Colors.red.shade700
                        : const Color(0xFF0F766E),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),

          // 1-Tap CONTINUE Button
          ChoiceChip(
            label: const Text(
              'CONTINUE',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            selected: isContinued,
            selectedColor: Colors.teal.shade100,
            onSelected: (val) {
              if (val) onContinue(index);
            },
          ),
          const SizedBox(width: 6),

          // 1-Tap STOP Button
          ChoiceChip(
            label: const Text(
              'STOP',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            selected: isStopped,
            selectedColor: Colors.red.shade100,
            onSelected: (val) {
              if (val) {
                if (onStop != null) {
                  onStop!(index);
                } else if (onPromptStop != null) {
                  onPromptStop!(item, index);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Single row item for medications newly prescribed in the current encounter.
class NewPrescriptionRow extends StatelessWidget {
  final PrescriptionItem item;
  final int index;
  final ValueChanged<int> onRemove;
  final void Function(int index, PrescriptionItem item)? onItemUpdated;

  const NewPrescriptionRow({
    super.key,
    required this.item,
    required this.index,
    required this.onRemove,
    this.onItemUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text(
              'START',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.effectiveName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                InkWell(
                  onTap: onItemUpdated != null
                      ? () {
                          InlineDosageEditDialog.show(
                            context,
                            item: item,
                            onSave: (updated) => onItemUpdated!(index, updated),
                          );
                        }
                      : null,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            "${item.composition} • ${item.formattedDosageTiming} • ${item.effectiveDuration}",
                            style: TextStyle(
                              fontSize: 11,
                              color: onItemUpdated != null
                                  ? const Color(0xFF0F766E)
                                  : Colors.grey.shade600,
                              fontWeight: onItemUpdated != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (onItemUpdated != null) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.edit_note_rounded,
                            size: 15,
                            color: Color(0xFF0F766E),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (item.instructions != null && item.instructions!.isNotEmpty)
                  Text(
                    "Note: ${item.instructions}",
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade700,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              size: 18,
              color: Colors.grey,
            ),
            onPressed: () => onRemove(index),
          ),
        ],
      ),
    );
  }
}

/// Compact summary bar shown when the prescribing section is collapsed.
class CollapsedMedicineSummary extends StatelessWidget {
  final int continuedCount;
  final int stoppedCount;
  final int newCount;
  final VoidCallback onTap;

  const CollapsedMedicineSummary({
    super.key,
    required this.continuedCount,
    required this.stoppedCount,
    required this.newCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
            Icon(
              Icons.medication_rounded,
              size: 18,
              color: Colors.blue.shade700,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Rx Schedule: $newCount new prescribed • $continuedCount continued • $stoppedCount stopped',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              'Tap to expand',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Container displaying prior visit chronic medications for reconciliation.
class ReconciliationListCard extends StatelessWidget {
  final List<PrescriptionItem> items;
  final ValueChanged<int> onContinue;
  final void Function(PrescriptionItem item, int index)? onPromptStop;
  final ValueChanged<int>? onStop;
  final void Function(int index, PrescriptionItem item)? onItemUpdated;

  const ReconciliationListCard({
    super.key,
    required this.items,
    required this.onContinue,
    this.onPromptStop,
    this.onStop,
    this.onItemUpdated,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.published_with_changes_rounded,
                size: 18,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              const Text(
                "Medication Reconciliation (From Prior Visits)",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const Spacer(),
              Text(
                "${items.length} active previously",
                style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 6),
            itemBuilder: (ctx, index) {
              return ReconciliationItemRow(
                item: items[index],
                index: index,
                onContinue: onContinue,
                onPromptStop: onPromptStop,
                onStop: onStop,
                onItemUpdated: onItemUpdated,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Container displaying newly prescribed medications for the current encounter.
class NewPrescriptionsList extends StatelessWidget {
  final List<PrescriptionItem> items;
  final ValueChanged<int> onRemove;
  final void Function(int index, PrescriptionItem item)? onItemUpdated;

  const NewPrescriptionsList({
    super.key,
    required this.items,
    required this.onRemove,
    this.onItemUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prescribed Medications (This Encounter)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Text(
                'No new medicines prescribed yet. Search above to add.',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 6),
            itemBuilder: (ctx, index) {
              return NewPrescriptionRow(
                item: items[index],
                index: index,
                onRemove: onRemove,
                onItemUpdated: onItemUpdated,
              );
            },
          ),
      ],
    );
  }
}

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

/// Simple prompt dialog for entering custom course duration in days.
class CustomDurationDialog extends StatefulWidget {
  final int? initialDays;
  final ValueChanged<int> onApply;

  const CustomDurationDialog({
    super.key,
    this.initialDays,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    int? initialDays,
    required ValueChanged<int> onApply,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => CustomDurationDialog(
        initialDays: initialDays,
        onApply: onApply,
      ),
    );
  }

  @override
  State<CustomDurationDialog> createState() => _CustomDurationDialogState();
}

class _CustomDurationDialogState extends State<CustomDurationDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialDays != null && widget.initialDays! > 0
          ? widget.initialDays.toString()
          : '10',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    final text = _controller.text.trim();
    final parsed = int.tryParse(text);
    if (parsed == null || parsed <= 0) {
      setState(() => _error = 'Enter a valid number of days (e.g. 10)');
      return;
    }
    widget.onApply(parsed);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.edit_calendar_rounded, size: 20, color: Color(0xFF0F766E)),
          SizedBox(width: 8),
          Text('Custom Duration', style: TextStyle(fontSize: 16)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter prescription course duration in days:',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Duration (Days)',
              hintText: 'e.g. 10',
              errorText: _error,
              suffixText: 'Days',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onSubmitted: (_) => _apply(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0F766E),
          ),
          onPressed: _apply,
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
