import 'package:flutter/material.dart';

import '../../models/consultation.dart';
import '../../utils/formatters.dart';

/// Printable diagnostic orders, lifestyle notes, follow-up advice, and physician signature block.
class PrintOrdersAndFooter extends StatelessWidget {
  final Consultation consultation;

  const PrintOrdersAndFooter({super.key, required this.consultation});

  @override
  Widget build(BuildContext context) {
    final c = consultation;
    final hasOrders = c.orderedTests.isNotEmpty;
    final hasAdvice = c.adviceNotes != null && c.adviceNotes!.isNotEmpty;
    final hasFollowUp = c.nextFollowUpDate != null;

    final hasOrdersOrAdvice = hasOrders || hasAdvice || hasFollowUp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasOrdersOrAdvice) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black87, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasOrders) ...[
                  const Text(
                    'Recommended Diagnostic Investigations (For Next Visit):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  ...c.orderedTests.map(
                    (o) => Text(
                      "• ${o.testName}${o.instructions != null ? ' (${o.instructions})' : ''}",
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                if (hasAdvice) ...[
                  const Text(
                    'Advice & Lifestyle Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(c.adviceNotes!, style: const TextStyle(fontSize: 11)),
                  const SizedBox(height: 6),
                ],
                if (hasFollowUp)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    color: Colors.grey.shade100,
                    child: Text(
                      'Next Follow-Up / Review: ${AppFormatters.dateWithDay(c.nextFollowUpDate!)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Physician Signature & Clinic Stamp Block
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clinic Seal / Stamp',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 40),
                Container(
                  width: 120,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.black45, width: 0.8),
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 180,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.black87, width: 1),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dr. ${consultation.doctorName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Authorized Medical Consultant',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
