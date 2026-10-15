import 'package:flutter/material.dart';

import '../../../core/engines/engines.dart';
import '../../../models/medicine.dart';

/// Clinical search results view displaying composition cards [COMPOSITION]
/// with selectable trade brand products {Brand 1}, {Brand 2},
/// or a flat brand-first direct list when [enableGroupedCompositionCards] is false.
class RxSearchResultsView extends StatelessWidget {
  final List<CompositionGroupResult> results;
  final String query;
  final bool enableGroupedCompositionCards;
  final ValueChanged<CompositionGroupResult>? onStageGeneric;
  final ValueChanged<Medicine> onStageMedicine;
  final ValueChanged<String> onStageUnlisted;

  const RxSearchResultsView({
    super.key,
    required this.results,
    required this.query,
    this.enableGroupedCompositionCards = true,
    this.onStageGeneric,
    required this.onStageMedicine,
    required this.onStageUnlisted,
  });

  @override
  Widget build(BuildContext context) {
    final cleanQuery = query.trim();

    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(8),
        children: [
          if (results.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'No matching catalogue medicine found for "$cleanQuery".',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => onStageUnlisted(cleanQuery),
                    child: Text('Prescribe Outside: "$cleanQuery"'),
                  ),
                ],
              ),
            )
          else ...[
            if (enableGroupedCompositionCards)
              ..._buildCardLayout(cleanQuery)
            else
              ..._buildFlatListLayout(cleanQuery),
            const Divider(height: 10),
            InkWell(
              onTap: () => onStageUnlisted(cleanQuery),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 16,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Prescribe unlisted outside brand: "$cleanQuery"',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
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

  List<Widget> _buildCardLayout(String cleanQuery) {
    return results.take(6).map((group) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Composition Header Banner: e.g. [TELMISARTAN 40mg]
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(7),
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.teal.shade100),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      group.formattedHeader,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.5,
                        color: Colors.teal.shade900,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Text(
                      group.form,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                      ),
                    ),
                  ),
                  if (onStageGeneric != null) ...[
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => onStageGeneric!(group),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.purple.shade200,
                          ),
                        ),
                        child: Text(
                          'Generic',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Product Options List / Pills: e.g. {Telma 40}, {Telmikind 40}
            Padding(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: group.associatedBrands.map((brand) {
                  final isProductMatch = brand.productName
                      .toLowerCase()
                      .contains(cleanQuery);
                  return ActionChip(
                    avatar: Icon(
                      Icons.medication_outlined,
                      size: 15,
                      color: isProductMatch
                          ? Colors.teal.shade800
                          : Colors.blueGrey.shade700,
                    ),
                    label: Text(
                      "{${brand.productName}}${brand.manufacturer != null ? ' (${brand.manufacturer})' : ''}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isProductMatch
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: isProductMatch
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF334155),
                      ),
                    ),
                    backgroundColor: isProductMatch
                        ? Colors.teal.shade50
                        : Colors.white,
                    side: BorderSide(
                      color: isProductMatch
                          ? Colors.teal.shade400
                          : Colors.grey.shade300,
                      width: isProductMatch ? 1.5 : 1,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    onPressed: () => onStageMedicine(brand),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildFlatListLayout(String cleanQuery) {
    final flattenedBrands = <Medicine>[];
    for (final grp in results) {
      for (final brand in grp.associatedBrands) {
        if (!flattenedBrands.any((b) => b.id == brand.id)) {
          flattenedBrands.add(brand);
        }
      }
    }

    return flattenedBrands.take(8).map((brand) {
      final isProductMatch =
          brand.productName.toLowerCase().contains(cleanQuery);
      return InkWell(
        onTap: () => onStageMedicine(brand),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: isProductMatch
                ? Colors.teal.shade50.withValues(alpha: 0.5)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isProductMatch
                  ? Colors.teal.shade300
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.medication_outlined,
                size: 16,
                color: isProductMatch ? Colors.teal.shade800 : Colors.blueGrey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${brand.productName}${brand.manufacturer != null ? ' (${brand.manufacturer})' : ''}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${brand.fullCompositionLabel} [${brand.form}]",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blueGrey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.add_circle_outline,
                size: 18,
                color: Colors.teal.shade700,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
