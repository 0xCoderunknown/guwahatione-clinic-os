import 'package:flutter/material.dart';

import '../../config/clinic_config.dart';
import '../../models/prescription_item.dart';

/// Printable medications section adhering strictly to the 3-Column Isolation rule:
/// - Column 1 (Medicine): Trade brand name with uppercase bracketed composition [COMPOSITION]
///   (or brand only if [hidePrescriptionComposition] is true). No badges like [NEW].
/// - Column 2 (Dosage & Timing): Dosage, frequency, timing, and optional patient instructions.
/// - Column 3 (Duration): Course duration (e.g. '5 Days'), 'To Continue', or 'To STOP'.
class PrintMedicationsTable extends StatelessWidget {
  final List<PrescriptionItem> activeMeds;
  final List<PrescriptionItem> stoppedMeds;
  final ClinicConfig? config;

  const PrintMedicationsTable({
    super.key,
    required this.activeMeds,
    required this.stoppedMeds,
    this.config,
  });

  /// Formats the medicine display text with uppercase bracketed composition.
  /// Suppresses bracketed composition if [hideComposition] is enabled or if the
  /// medicine name is already identical to or contains the composition.
  static String formatMedicineName(
    PrescriptionItem item, {
    bool hideComposition = false,
  }) {
    final name = item.effectiveName.trim();
    if (hideComposition || item.composition.trim().isEmpty) {
      return name;
    }
    final comp = item.composition.trim();
    final nameLower = name.toLowerCase();
    final compLower = comp.toLowerCase();

    // If already identical or already contains composition, do not redundantly duplicate
    if (nameLower == compLower || nameLower.contains(compLower)) {
      return name;
    }
    return '$name [${comp.toUpperCase()}]';
  }

  @override
  Widget build(BuildContext context) {
    final activeConfig = config ?? ClinicConfig.current;
    final hideComp = activeConfig.features.hidePrescriptionComposition;
    final allMeds = [...activeMeds, ...stoppedMeds];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rx Symbol
        const Text(
          '℞  (Prescribed Medicines)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),

        // 3-Column Isolated Rx Table
        if (allMeds.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400, width: 0.6),
            ),
            child: const Center(
              child: Text(
                'No active or discontinued medications for this visit.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          )
        else
          Table(
            border: TableBorder.all(color: Colors.black87, width: 0.8),
            columnWidths: const {
              0: FlexColumnWidth(5.0), // Col 1: Medicine
              1: FlexColumnWidth(3.5), // Col 2: Dosage & Timing
              2: FlexColumnWidth(1.8), // Col 3: Duration
            },
            children: [
              // Header Row (Strict 3 Columns)
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade200),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    child: Text(
                      'Medicine',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    child: Text(
                      'Dosage & Timing',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    child: Text(
                      'Duration',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),

              // Item Rows (Strict 3-Column Isolation)
              ...allMeds.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final item = entry.value;

                final String durationText;
                final Color durationColor;
                if (item.action == MedicationAction.stop) {
                  durationText = 'To STOP';
                  durationColor = Colors.red.shade800;
                } else if (item.durationDays != null &&
                    item.durationDays! > 0) {
                  durationText = '${item.durationDays} Days';
                  durationColor = Colors.black87;
                } else {
                  durationText = 'To Continue';
                  durationColor = Colors.teal.shade900;
                }

                return TableRow(
                  children: [
                    // Col 1: Dedicated to Medicine (Name + [COMPOSITION])
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      child: Text(
                        '$idx. ${formatMedicineName(item, hideComposition: hideComp)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    // Col 2: Dedicated to Dosage & Timing
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${item.dosage} • ${item.frequency} • ${item.timing}",
                            style: const TextStyle(fontSize: 11),
                          ),
                          if (item.instructions != null &&
                              item.instructions!.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                "Note: ${item.instructions!.trim()}",
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Col 3: Dedicated to Duration
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      child: Text(
                        durationText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: durationColor,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),

        if (stoppedMeds.isNotEmpty) ...[
          const SizedBox(height: 14),
          PrintDiscontinuedMedicationsBox(
            stoppedMeds: stoppedMeds,
            hideComposition: hideComp,
          ),
        ],
      ],
    );
  }
}

/// Segregated audit box for discontinued / stopped chronic medications.
class PrintDiscontinuedMedicationsBox extends StatelessWidget {
  final List<PrescriptionItem> stoppedMeds;
  final bool hideComposition;

  const PrintDiscontinuedMedicationsBox({
    super.key,
    required this.stoppedMeds,
    this.hideComposition = false,
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          ...stoppedMeds.map((item) {
            final reason = item.stopReason ?? 'Stopped by doctor';
            final medLabel = PrintMedicationsTable.formatMedicineName(
              item,
              hideComposition: hideComposition,
            );
            return Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 2),
              child: Text(
                "• $medLabel — Reason: $reason",
                style: const TextStyle(
                  fontSize: 10.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
