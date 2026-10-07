import 'package:flutter/material.dart';

import '../../../models/medicine.dart';
import '../../../utils/medicine_search_scorer.dart';

/// Grouped search results view displaying chemical salts, associated clinic trade brands, and outside fallback options.
class RxSearchResultsView extends StatelessWidget {
  final List<CompositionGroupResult> results;
  final String query;
  final ValueChanged<CompositionGroupResult> onStageGeneric;
  final ValueChanged<Medicine> onStageMedicine;
  final ValueChanged<String> onStageUnlisted;

  const RxSearchResultsView({
    super.key,
    required this.results,
    required this.query,
    required this.onStageGeneric,
    required this.onStageMedicine,
    required this.onStageUnlisted,
  });

  @override
  Widget build(BuildContext context) {
    final cleanQuery = query.trim();

    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(8),
        children: [
          if (results.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'No matching medicine found for "$cleanQuery".',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                    onPressed: () => onStageUnlisted(cleanQuery),
                    child: Text('Prescribe Outside: "$cleanQuery"'),
                  ),
                ],
              ),
            )
          else ...[
            ...results.take(6).map((group) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "${group.compositionLabel} [${group.form}]",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                          ),
                        ),
                        InkWell(
                          onTap: () => onStageGeneric(group),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.purple.shade200),
                            ),
                            child: Text(
                              '+ Prescribe Generic',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple.shade800),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: group.associatedBrands.map((brand) {
                        return ActionChip(
                          avatar: const Icon(Icons.local_pharmacy_outlined, size: 14, color: Colors.teal),
                          label: Text(
                            "${brand.productName}${brand.manufacturer != null ? ' (${brand.manufacturer})' : ''}",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.teal.shade200),
                          onPressed: () => onStageMedicine(brand),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }),
            const Divider(height: 12),
            InkWell(
              onTap: () => onStageUnlisted(cleanQuery),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 6),
                    Text(
                      'Prescribe unlisted outside brand: "$cleanQuery"',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
