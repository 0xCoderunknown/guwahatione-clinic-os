import 'package:flutter/material.dart';

import '../../../models/prescription_item.dart';
import 'inline_dosage_edit_dialog.dart';

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
