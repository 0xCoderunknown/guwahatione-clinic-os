import 'package:flutter/material.dart';

import '../../../models/prescription_item.dart';
import 'custom_duration_dialog.dart';
import 'inline_dosage_edit_dialog.dart';

export 'custom_duration_dialog.dart';
export 'inline_dosage_edit_dialog.dart';
export 'new_prescription_row.dart';

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
