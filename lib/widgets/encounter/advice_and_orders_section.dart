import 'package:flutter/material.dart';
import '../../models/diagnostic_investigation.dart';
import '../../utils/formatters.dart';
import '../common/section_card.dart';

import 'encounter_form_state.dart';

/// Step 5: Advice, Diagnostic Orders & Follow-up Visit Scheduling
class AdviceAndOrdersSection extends StatelessWidget {
  final TextEditingController orderedTestInputController;
  final List<OrderedTest> orderedTests;
  final VoidCallback onAddOrderedTest;
  final ValueChanged<OrderedTest> onRemoveOrderedTest;
  final TextEditingController adviceController;
  final DateTime? nextFollowUpDate;
  final ValueChanged<DateTime?> onFollowUpDateChanged;
  final VoidCallback onPickCustomDate;

  const AdviceAndOrdersSection({
    super.key,
    required this.orderedTestInputController,
    required this.orderedTests,
    required this.onAddOrderedTest,
    required this.onRemoveOrderedTest,
    required this.adviceController,
    required this.nextFollowUpDate,
    required this.onFollowUpDateChanged,
    required this.onPickCustomDate,
  });

  /// Factory binding directly to EncounterFormState.
  AdviceAndOrdersSection.fromForm({
    super.key,
    required EncounterFormState form,
    required VoidCallback onUpdate,
    required this.onPickCustomDate,
  })  : orderedTestInputController = form.orderedTestInputController,
        orderedTests = form.orderedTests,
        onAddOrderedTest = (() {
          form.addOrderedTest();
          onUpdate();
        }),
        onRemoveOrderedTest = ((t) {
          form.removeOrderedTest(t);
          onUpdate();
        }),
        adviceController = form.adviceController,
        nextFollowUpDate = form.nextFollowUpDate,
        onFollowUpDateChanged = ((d) {
          form.nextFollowUpDate = d;
          onUpdate();
        });

  Widget _buildIntervalChip(String label, int days) {
    final target = DateTime.now().add(Duration(days: days));
    final isSelected = nextFollowUpDate != null &&
        nextFollowUpDate!.year == target.year &&
        nextFollowUpDate!.month == target.month &&
        nextFollowUpDate!.day == target.day;

    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (val) {
        onFollowUpDateChanged(val ? target : null);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Step 5: Advice & Follow-up Orders',
      icon: Icons.checklist_rtl_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order New Diagnostic Tests
          const Text(
            'Order New Investigations / Lab Tests',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: orderedTestInputController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Fasting Blood Sugar, Serum Creatinine, ECG...',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => onAddOrderedTest(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: onAddOrderedTest,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Order'),
              ),
            ],
          ),
          if (orderedTests.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: orderedTests.map((t) {
                return Chip(
                  label: Text(t.testName, style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.indigo.shade50,
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => onRemoveOrderedTest(t),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),

          // Lifestyle & Dietary Advice
          const Text(
            'Advice & Instructions',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: adviceController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'e.g., Low salt diet, hydrate well, avoid cold drinks, consult SOS if fever persists...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16),

          // Next Follow-up Date with Quick Interval Chips
          const Text(
            'Next Follow-up Visit',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildIntervalChip('3 Days', 3),
              _buildIntervalChip('5 Days', 5),
              _buildIntervalChip('7 Days', 7),
              _buildIntervalChip('14 Days', 14),
              _buildIntervalChip('1 Month', 30),
              _buildIntervalChip('3 Months', 90),
              ActionChip(
                avatar: const Icon(Icons.calendar_today, size: 14),
                label: Text(
                  nextFollowUpDate != null
                      ? AppFormatters.date(nextFollowUpDate!)
                      : 'Pick Date',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                backgroundColor: nextFollowUpDate != null ? Colors.teal.shade50 : null,
                onPressed: onPickCustomDate,
              ),
              if (nextFollowUpDate != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  tooltip: 'Clear Follow-up Date',
                  onPressed: () => onFollowUpDateChanged(null),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
