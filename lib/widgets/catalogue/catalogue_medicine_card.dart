import 'package:flutter/material.dart';

import '../../models/medicine.dart';

/// Interactive list card for a medicine entry in the master catalogue.
class CatalogueMedicineCard extends StatelessWidget {
  final Medicine item;
  final VoidCallback onDelete;

  const CatalogueMedicineCard({
    super.key,
    required this.item,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Medication Icon Pill
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.teal.shade200),
            ),
            child: Icon(
              Icons.medication_rounded,
              size: 20,
              color: Colors.teal.shade800,
            ),
          ),
          const SizedBox(width: 14),

          // Trade Name & Decoupled Composition
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (item.manufacturer != null &&
                        item.manufacturer!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.manufacturer!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  "Composition: ${item.composition}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (item.defaultFrequency != null ||
                    item.defaultDosage != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Text(
                          'OPD Default: ${item.defaultDosage ?? ''} ${item.defaultFrequency ?? ''} • ${item.defaultTiming ?? ''} • ${item.durationLabel}'
                              .trim(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Delete Action
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              size: 20,
              color: Colors.redAccent,
            ),
            tooltip: 'Remove from Catalogue',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

/// Illustrated empty state shown when catalogue filters return no results.
class CatalogueEmptyState extends StatelessWidget {
  final VoidCallback onClearFilter;

  const CatalogueEmptyState({super.key, required this.onClearFilter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 54,
            color: Colors.teal.shade200,
          ),
          const SizedBox(height: 16),
          const Text(
            'No medicines match the selected filter',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No medicines match your search. Clear the filters or add a medicine to the catalogue.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: onClearFilter,
            icon: const Icon(Icons.clear_all_rounded, size: 16),
            label: const Text('Clear Filter'),
          ),
        ],
      ),
    );
  }
}
