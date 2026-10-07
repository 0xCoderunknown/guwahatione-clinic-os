import 'package:flutter/material.dart';

import '../../../models/prescription_item.dart';

/// Single row item for reconciled chronic medications from prior encounters.
class ReconciliationItemRow extends StatelessWidget {
  final PrescriptionItem item;
  final int index;
  final ValueChanged<int> onContinue;
  final void Function(PrescriptionItem item, int index) onPromptStop;

  const ReconciliationItemRow({
    super.key,
    required this.item,
    required this.index,
    required this.onContinue,
    required this.onPromptStop,
  });

  @override
  Widget build(BuildContext context) {
    final isContinued = item.action == MedicationAction.continueAction;
    final isStopped = item.action == MedicationAction.stop;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isStopped ? Colors.red.shade50.withValues(alpha: 0.4) : Colors.white,
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
                Text(
                  "${item.composition} • ${item.dosage} • ${item.frequency} • ${item.timing}${item.durationDays != null ? ' (${item.durationDays}d)' : ' (Chronic)'}",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                if (isStopped && item.stopReason != null && item.stopReason!.isNotEmpty)
                  Text(
                    "Stopped Reason: ${item.stopReason}",
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.red),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 1-Tap CONTINUE Button
          ChoiceChip(
            label: const Text('CONTINUE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            selected: isContinued,
            selectedColor: Colors.teal.shade100,
            onSelected: (val) {
              if (val) onContinue(index);
            },
          ),
          const SizedBox(width: 6),

          // 1-Tap STOP Button
          ChoiceChip(
            label: const Text('STOP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            selected: isStopped,
            selectedColor: Colors.red.shade100,
            onSelected: (val) {
              if (val) onPromptStop(item, index);
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

  const NewPrescriptionRow({
    super.key,
    required this.item,
    required this.index,
    required this.onRemove,
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
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.effectiveName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Text(
                  "${item.composition} • ${item.dosage} • ${item.frequency} • ${item.timing} • ${item.durationDays != null ? '${item.durationDays} days' : 'Chronic'}",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                if (item.instructions != null && item.instructions!.isNotEmpty)
                  Text(
                    "Note: ${item.instructions}",
                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade700),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
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
            Icon(Icons.medication_rounded, size: 18, color: Colors.blue.shade700),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Rx Schedule: $newCount new prescribed • $continuedCount continued • $stoppedCount stopped',
                style: TextStyle(fontSize: 12, color: Colors.blue.shade900, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              'Tap to expand',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
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
  final void Function(PrescriptionItem item, int index) onPromptStop;

  const ReconciliationListCard({
    super.key,
    required this.items,
    required this.onContinue,
    required this.onPromptStop,
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
              const Icon(Icons.published_with_changes_rounded, size: 18, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                "Medication Reconciliation (From Prior Visits)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
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

  const NewPrescriptionsList({
    super.key,
    required this.items,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prescribed Medications (This Encounter)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 6),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: Text(
                'No new medicines added yet. Type in search bar above to prescribe.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
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
              );
            },
          ),
      ],
    );
  }
}

