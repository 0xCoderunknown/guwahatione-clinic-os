import 'package:flutter/material.dart';

import '../../models/prescription_item.dart';

/// Printable medications section: structured active Rx table and segregated discontinued audit box.
class PrintMedicationsTable extends StatelessWidget {
  final List<PrescriptionItem> activeMeds;
  final List<PrescriptionItem> stoppedMeds;

  const PrintMedicationsTable({
    super.key,
    required this.activeMeds,
    required this.stoppedMeds,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rx Symbol
        const Text(
          '℞  (Active Medication Schedule)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),

        // Active Rx Table
        if (activeMeds.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400, width: 0.6)),
            child: const Center(
              child: Text(
                'No active medications prescribed for this visit.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          )
        else
          Table(
            border: TableBorder.all(color: Colors.black87, width: 0.8),
            columnWidths: const {
              0: FixedColumnWidth(30),
              1: FlexColumnWidth(4.5),
              2: FlexColumnWidth(2.2),
              3: FlexColumnWidth(2.2),
              4: FlexColumnWidth(2.2),
            },
            children: [
              // Header Row
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade200),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                    child: Text('Medicine & Composition', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Text('Dose & Timing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Text('Frequency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Text('Duration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),

              // Item Rows (Strictly START & CONTINUE items)
              ...activeMeds.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final item = entry.value;

                final durationLabel = item.durationDays != null
                    ? "${item.durationDays} Days"
                    : "Ongoing (Chronic)";

                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Text('$idx', style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.effectiveName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                item.action == MedicationAction.continueAction ? '[CONT]' : '[NEW]',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            item.composition,
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade800),
                          ),
                          if (item.instructions != null && item.instructions!.isNotEmpty)
                            Text(
                              "Note: ${item.instructions}",
                              style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Text("${item.dosage}\n${item.timing}", style: const TextStyle(fontSize: 11)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Text(item.frequency, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Text(durationLabel, style: const TextStyle(fontSize: 11)),
                    ),
                  ],
                );
              }),
            ],
          ),

        if (stoppedMeds.isNotEmpty) ...[
          const SizedBox(height: 14),
          PrintDiscontinuedMedicationsBox(stoppedMeds: stoppedMeds),
        ],
      ],
    );
  }
}

/// Segregated audit box for discontinued / stopped chronic medications.
class PrintDiscontinuedMedicationsBox extends StatelessWidget {
  final List<PrescriptionItem> stoppedMeds;

  const PrintDiscontinuedMedicationsBox({
    super.key,
    required this.stoppedMeds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.black45, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🛑 Discontinued / Stopped Medications This Visit:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          ...stoppedMeds.map((item) {
            final reason = item.stopReason ?? 'Discontinued by physician';
            return Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 2),
              child: Text(
                "• ${item.effectiveName} (${item.composition}) — Reason: $reason",
                style: const TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic),
              ),
            );
          }),
        ],
      ),
    );
  }
}
