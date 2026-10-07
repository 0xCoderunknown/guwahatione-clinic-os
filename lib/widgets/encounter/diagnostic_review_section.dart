import 'package:flutter/material.dart';
import '../../models/diagnostic_investigation.dart';
import '../../utils/formatters.dart';
import '../common/section_card.dart';

/// Step 3: Past Diagnostic Investigations Review
class DiagnosticReviewSection extends StatelessWidget {
  final List<DiagnosticInvestigationReview> reviewedInvestigations;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final void Function(int index, String value) onResultChanged;
  final void Function(int index, DateTime date) onDateChanged;
  final void Function(int index) onRemoveItem;
  final VoidCallback onAddOutsideLab;

  const DiagnosticReviewSection({
    super.key,
    required this.reviewedInvestigations,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onResultChanged,
    required this.onDateChanged,
    required this.onRemoveItem,
    required this.onAddOutsideLab,
  });

  @override
  Widget build(BuildContext context) {
    final count = reviewedInvestigations.length;

    return SectionCard(
      title: 'Step 3: Past Diagnostic Investigations Review',
      icon: Icons.biotech_outlined,
      isExpanded: isExpanded,
      onToggleExpand: onToggleExpand,
      badge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: count > 0 ? Colors.purple.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '$count items',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: count > 0 ? Colors.purple.shade700 : Colors.grey.shade600,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isExpanded)
            Text(
              count > 0
                  ? '$count investigations tracked. Click expand to enter results.'
                  : 'No pending lab tests from previous visits. (Click + to add outside reports)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
            )
          else ...[
            if (reviewedInvestigations.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'No past ordered tests recorded for this patient.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reviewedInvestigations.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                itemBuilder: (ctx, index) {
                  final inv = reviewedInvestigations[index];
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            inv.testName,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            initialValue: inv.resultValue,
                            decoration: const InputDecoration(
                              hintText: 'Result value / findings',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) => onResultChanged(index, val),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: inv.performedDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              onDateChanged(index, picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.event_outlined, size: 14, color: Colors.teal),
                                const SizedBox(width: 4),
                                Text(
                                  inv.performedDate != null
                                      ? AppFormatters.compactDate(inv.performedDate!)
                                      : 'Date Done',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                          onPressed: () => onRemoveItem(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Outside Lab Report'),
              onPressed: onAddOutsideLab,
            ),
          ],
        ],
      ),
    );
  }
}
